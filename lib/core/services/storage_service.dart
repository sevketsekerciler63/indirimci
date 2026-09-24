import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/deal.dart';
import '../models/coupon.dart';

class StorageService {
  static const String _favoritesBox = 'favoritesBox';
  static const String _couponsBox = 'couponsBox';
  static const String _couponEncryptionKey = 'coupon_box_encryption_key_v1';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Hive.initFlutter();
      await Hive.openBox(_favoritesBox);
      await Hive.openBox(
        _couponsBox,
        encryptionCipher: HiveAesCipher(await _getOrCreateCouponKey()),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('StorageService init error: $e');
    }
  }

  static Future<List<int>> _getOrCreateCouponKey() async {
    final storedKey = await _secureStorage.read(key: _couponEncryptionKey);
    if (storedKey != null) {
      return base64Url.decode(storedKey);
    }

    final key = Hive.generateSecureKey();
    await _secureStorage.write(
      key: _couponEncryptionKey,
      value: base64Url.encode(key),
    );
    return key;
  }

  static bool get isReady {
    return _initialized &&
        Hive.isBoxOpen(_favoritesBox) &&
        Hive.isBoxOpen(_couponsBox);
  }

  static List<Deal> getFavorites() {
    if (!isReady) return [];

    try {
      final box = Hive.box(_favoritesBox);
      final List<Deal> favorites = [];

      for (var i = 0; i < box.length; i++) {
        try {
          final item = box.getAt(i);
          if (item != null && item is Map) {
            favorites.add(Deal.fromMap(item));
          }
        } catch (e) {
          debugPrint('StorageService: Favori okuma hatası index=$i: $e');
          continue;
        }
      }

      return favorites;
    } catch (e) {
      debugPrint('StorageService getFavorites error: $e');
      return [];
    }
  }

  static Future<void> saveFavorites(List<Deal> deals) async {
    if (!isReady) return;

    try {
      final box = Hive.box(_favoritesBox);
      await box.clear(); // Mevcutları temizle

      for (var deal in deals) {
        await box.add(deal.toMap());
      }
    } catch (e) {
      debugPrint('StorageService saveFavorites error: $e');
    }
  }

  static List<Coupon> getCoupons() {
    if (!isReady) return [];
    final box = Hive.box(_couponsBox);
    return box.values.whereType<Map>().map(Coupon.fromMap).toList();
  }

  static Future<void> saveCoupon(Coupon coupon) async {
    if (!isReady) return;
    final box = Hive.box(_couponsBox);
    final existing = box.values.toList().indexWhere(
      (value) => value is Map && value['id']?.toString() == coupon.id,
    );
    if (existing >= 0) {
      await box.putAt(existing, coupon.toMap());
    } else {
      await box.add(coupon.toMap());
    }
  }
}
