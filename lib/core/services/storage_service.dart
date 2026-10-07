import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/coupon.dart';
import '../models/deal.dart';

abstract class CouponKeyStore {
  Future<String?> read();
  Future<void> write(String value);
}

class SecureCouponKeyStore implements CouponKeyStore {
  SecureCouponKeyStore(this._storage);

  static const _keyName = 'coupon_box_encryption_key_v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _keyName);

  @override
  Future<void> write(String value) =>
      _storage.write(key: _keyName, value: value);
}

enum StorageFailure {
  notInitialized,
  initializationFailed,
  missingCouponKey,
  invalidCouponKey,
  couponBoxUnavailable,
  migrationFailed,
  readFailed,
  writeFailed,
}

class StorageException implements Exception {
  const StorageException(this.failure, {this.cause});

  final StorageFailure failure;
  final Object? cause;

  @override
  String toString() => 'StorageException($failure)';
}

abstract class StorageRepository {
  Future<void> init();
  Future<List<Deal>> loadFavorites();
  Future<void> saveFavorites(List<Deal> deals);
  Future<List<Coupon>> loadCoupons();
  Future<void> saveCoupon(Coupon coupon);
}

class StorageService implements StorageRepository {
  StorageService({
    CouponKeyStore? keyStore,
    FutureOr<void> Function()? hiveInitializer,
  }) : _keyStore =
           keyStore ?? SecureCouponKeyStore(const FlutterSecureStorage()),
       _hiveInitializer = hiveInitializer ?? Hive.initFlutter;

  static const favoritesBox = 'favoritesBox';
  static const legacyCouponsBox = 'couponsBox';
  static const encryptedCouponsBox = 'couponsBox.v2';
  static const _favoritesSnapshotKey = 'favorites_snapshot_v2';
  static const _migrationCompleteKey = 'coupon_migration_v1_complete';

  static final StorageService shared = StorageService();

  final CouponKeyStore _keyStore;
  final FutureOr<void> Function() _hiveInitializer;
  bool _initialized = false;
  String? _activeCouponBox;

  bool get isReady =>
      _initialized &&
      Hive.isBoxOpen(favoritesBox) &&
      _activeCouponBox != null &&
      Hive.isBoxOpen(_activeCouponBox!);

  @override
  Future<void> init() async {
    if (_initialized) return;
    try {
      await _hiveInitializer();
      await Hive.openBox<dynamic>(favoritesBox, crashRecovery: false);
      await _openCouponVault();
      _initialized = true;
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(StorageFailure.initializationFailed, cause: error);
    }
  }

  Future<void> _openCouponVault() async {
    final hasEncryptedVault = await Hive.boxExists(encryptedCouponsBox);
    final hasLegacyVault = await Hive.boxExists(legacyCouponsBox);
    if (hasEncryptedVault) {
      final key = await _requireStoredCouponKey();
      await _openEncryptedCouponBox(encryptedCouponsBox, key);
      final migrationComplete =
          Hive.box<dynamic>(encryptedCouponsBox).get(_migrationCompleteKey) ==
          true;
      if (migrationComplete || !hasLegacyVault) {
        _activeCouponBox = encryptedCouponsBox;
        return;
      }
      await Hive.box<dynamic>(encryptedCouponsBox).close();
    }

    if (!hasLegacyVault) {
      final key = await _readOrCreateCouponKeyForEmptyInstall();
      await _openEncryptedCouponBox(encryptedCouponsBox, key);
      _activeCouponBox = encryptedCouponsBox;
      return;
    }

    final storedKey = await _readStoredCouponKey();
    if (storedKey != null && !hasEncryptedVault) {
      try {
        await _openEncryptedCouponBox(legacyCouponsBox, storedKey);
        _activeCouponBox = legacyCouponsBox;
        return;
      } catch (_) {
        // The key exists but this legacy box may be the historical plaintext
        // format. Only migrate after opening that original successfully.
      }
    }

    Box<dynamic> legacy;
    try {
      legacy = await Hive.openBox<dynamic>(
        legacyCouponsBox,
        crashRecovery: false,
      );
    } catch (error) {
      throw StorageException(
        storedKey == null
            ? StorageFailure.missingCouponKey
            : StorageFailure.couponBoxUnavailable,
        cause: error,
      );
    }

    try {
      final key = storedKey ?? await _createAndStoreCouponKey();
      await _migratePlaintextCoupons(legacy, key);
    } finally {
      if (Hive.isBoxOpen(legacyCouponsBox)) {
        await Hive.box<dynamic>(legacyCouponsBox).close();
      }
    }
  }

  Future<List<int>?> _readStoredCouponKey() async {
    final encoded = await _keyStore.read();
    if (encoded == null) return null;
    try {
      final key = base64Url.decode(base64Url.normalize(encoded));
      if (key.length != 32) throw const FormatException('Hive AES key length');
      return key;
    } catch (error) {
      throw StorageException(StorageFailure.invalidCouponKey, cause: error);
    }
  }

  Future<List<int>> _requireStoredCouponKey() async {
    final key = await _readStoredCouponKey();
    if (key == null) {
      throw const StorageException(StorageFailure.missingCouponKey);
    }
    return key;
  }

  Future<List<int>> _readOrCreateCouponKeyForEmptyInstall() async {
    final key = await _readStoredCouponKey();
    return key ?? _createAndStoreCouponKey();
  }

  Future<List<int>> _createAndStoreCouponKey() async {
    final key = Hive.generateSecureKey();
    try {
      await _keyStore.write(base64Url.encode(key));
    } catch (error) {
      throw StorageException(StorageFailure.initializationFailed, cause: error);
    }
    return key;
  }

  Future<void> _openEncryptedCouponBox(String name, List<int> key) async {
    try {
      await Hive.openBox<dynamic>(
        name,
        encryptionCipher: HiveAesCipher(key),
        crashRecovery: false,
      );
    } catch (error) {
      throw StorageException(StorageFailure.couponBoxUnavailable, cause: error);
    }
  }

  Future<void> _migratePlaintextCoupons(
    Box<dynamic> legacy,
    List<int> key,
  ) async {
    Box<dynamic>? encrypted;
    try {
      encrypted = await Hive.openBox<dynamic>(
        encryptedCouponsBox,
        encryptionCipher: HiveAesCipher(key),
        crashRecovery: false,
      );
      await encrypted.clear();
      await encrypted.flush();
      for (final legacyKey in legacy.keys) {
        await encrypted.put(legacyKey, legacy.get(legacyKey));
      }
      await encrypted.flush();
      await encrypted.close();

      encrypted = await Hive.openBox<dynamic>(
        encryptedCouponsBox,
        encryptionCipher: HiveAesCipher(key),
        crashRecovery: false,
      );
      for (final legacyKey in legacy.keys) {
        if (!_sameValue(legacy.get(legacyKey), encrypted.get(legacyKey))) {
          throw const StorageException(StorageFailure.migrationFailed);
        }
      }
      await encrypted.put(_migrationCompleteKey, true);
      await encrypted.flush();
      _activeCouponBox = encryptedCouponsBox;
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(StorageFailure.migrationFailed, cause: error);
    } finally {
      if (_activeCouponBox != encryptedCouponsBox &&
          Hive.isBoxOpen(encryptedCouponsBox)) {
        await Hive.box<dynamic>(encryptedCouponsBox).close();
      }
    }
  }

  bool _sameValue(Object? left, Object? right) {
    try {
      return jsonEncode(left) == jsonEncode(right);
    } catch (_) {
      return left == right;
    }
  }

  Box<dynamic> get _favorites {
    _ensureReady();
    return Hive.box<dynamic>(favoritesBox);
  }

  Box<dynamic> get _coupons {
    _ensureReady();
    return Hive.box<dynamic>(_activeCouponBox!);
  }

  void _ensureReady() {
    if (!isReady) throw const StorageException(StorageFailure.notInitialized);
  }

  @override
  Future<List<Deal>> loadFavorites() async {
    try {
      final snapshot = _favorites.get(_favoritesSnapshotKey);
      if (snapshot is List) return _decodeDeals(snapshot);

      final legacy = <Deal>[];
      var hadUnreadableLegacyValue = false;
      for (final key in _favorites.keys) {
        if (key == _favoritesSnapshotKey) continue;
        final value = _favorites.get(key);
        if (value is! Map) {
          hadUnreadableLegacyValue = true;
          continue;
        }
        try {
          final deal = Deal.fromMap(value);
          if (deal.id.trim().isEmpty ||
              deal.title.trim().isEmpty ||
              deal.title == 'Bilinmeyen Ürün') {
            hadUnreadableLegacyValue = true;
            continue;
          }
          legacy.add(deal);
        } catch (_) {
          hadUnreadableLegacyValue = true;
        }
      }
      if (legacy.isEmpty && hadUnreadableLegacyValue) {
        throw const StorageException(StorageFailure.readFailed);
      }
      await _favorites.put(
        _favoritesSnapshotKey,
        legacy.map((deal) => deal.toMap()).toList(),
      );
      await _favorites.flush();
      return legacy;
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(StorageFailure.readFailed, cause: error);
    }
  }

  List<Deal> _decodeDeals(Iterable<dynamic> values) {
    try {
      return values.map((value) {
        if (value is! Map) throw const FormatException('Invalid favorite');
        return Deal.fromMap(value);
      }).toList();
    } catch (error) {
      throw StorageException(StorageFailure.readFailed, cause: error);
    }
  }

  @override
  Future<void> saveFavorites(List<Deal> deals) async {
    try {
      await _favorites.put(
        _favoritesSnapshotKey,
        deals.map((deal) => deal.toMap()).toList(),
      );
      await _favorites.flush();
    } catch (error) {
      throw StorageException(StorageFailure.writeFailed, cause: error);
    }
  }

  @override
  Future<List<Coupon>> loadCoupons() async {
    try {
      final coupons = <Coupon>[];
      for (final key in _coupons.keys) {
        if (key == _migrationCompleteKey) continue;
        final value = _coupons.get(key);
        if (value is! Map) throw const FormatException('Invalid coupon');
        coupons.add(Coupon.fromMap(value));
      }
      return coupons;
    } catch (error) {
      throw StorageException(StorageFailure.readFailed, cause: error);
    }
  }

  @override
  Future<void> saveCoupon(Coupon coupon) async {
    try {
      dynamic existingKey;
      for (final key in _coupons.keys) {
        final value = _coupons.get(key);
        if (value is Map && value['id']?.toString() == coupon.id) {
          existingKey = key;
          break;
        }
      }
      await _coupons.put(existingKey ?? coupon.id, coupon.toMap());
      await _coupons.flush();
    } catch (error) {
      throw StorageException(StorageFailure.writeFailed, cause: error);
    }
  }
}
