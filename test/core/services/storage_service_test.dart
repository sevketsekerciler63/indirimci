import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:indirimci/core/models/coupon.dart';
import 'package:indirimci/core/models/deal.dart';
import 'package:indirimci/core/services/storage_service.dart';

class FakeCouponKeyStore implements CouponKeyStore {
  String? value;
  bool failWrites = false;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    if (failWrites) throw StateError('key store write failed');
    this.value = value;
  }
}

Coupon _coupon(String id) => Coupon(
  id: id,
  code: 'SAVE$id',
  platform: 'Test',
  description: 'Test coupon',
);

Deal _deal(String id) => Deal(
  id: id,
  title: 'Deal $id',
  description: 'Test deal',
  imageUrl: '',
  platform: 'Test',
  category: 'test',
  originalPrice: 100,
  discountedPrice: 80,
  discountPercent: 20,
  url: 'https://example.test/$id',
  createdAt: DateTime(2026, 10, 7),
);

void main() {
  group('StorageService', () {
    late Directory directory;
    late FakeCouponKeyStore keyStore;

    setUp(() async {
      await Hive.close();
      directory = await Directory.systemTemp.createTemp(
        'indirimci-storage-test-',
      );
      keyStore = FakeCouponKeyStore();
    });

    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    StorageService service({FutureOr<void> Function()? initializer}) =>
        StorageService(
          keyStore: keyStore,
          hiveInitializer:
              initializer ?? (() async => Hive.init(directory.path)),
        );

    test('empty installation opens an encrypted coupon vault', () async {
      final storage = service();

      await storage.init();

      expect(await storage.loadCoupons(), isEmpty);
      expect(keyStore.value, isNotNull);
      expect(Hive.isBoxOpen(StorageService.encryptedCouponsBox), isTrue);
    });

    test(
      'migrates plaintext coupons only after encrypted copy verifies',
      () async {
        Hive.init(directory.path);
        final legacy = await Hive.openBox<dynamic>(
          StorageService.legacyCouponsBox,
        );
        await legacy.put('coupon-a', _coupon('a').toMap());
        await legacy.close();

        final storage = service(initializer: () {});
        await storage.init();

        expect((await storage.loadCoupons()).single.code, 'SAVEa');
        expect(
          Hive.box<dynamic>(StorageService.encryptedCouponsBox).get('coupon-a'),
          _coupon('a').toMap(),
        );
        expect(
          Hive.box<dynamic>(
            StorageService.encryptedCouponsBox,
          ).get('coupon_migration_v1_complete'),
          isTrue,
        );

        final preservedLegacy = await Hive.openBox<dynamic>(
          StorageService.legacyCouponsBox,
        );
        expect(preservedLegacy.get('coupon-a'), _coupon('a').toMap());
      },
    );

    test(
      'reopening after migration is idempotent and keeps the coupon',
      () async {
        Hive.init(directory.path);
        final legacy = await Hive.openBox<dynamic>(
          StorageService.legacyCouponsBox,
        );
        await legacy.put('coupon-a', _coupon('a').toMap());
        await legacy.close();

        await service(initializer: () {}).init();
        await Hive.close();

        final reopened = service();
        await reopened.init();

        expect((await reopened.loadCoupons()).map((coupon) => coupon.id), [
          'a',
        ]);
        expect(Hive.box<dynamic>(StorageService.encryptedCouponsBox).length, 2);
      },
    );

    test(
      'retries an unmarked encrypted target from the preserved plaintext source',
      () async {
        final key = Hive.generateSecureKey();
        keyStore.value = base64Url.encode(key);
        Hive.init(directory.path);
        final legacy = await Hive.openBox<dynamic>(
          StorageService.legacyCouponsBox,
        );
        await legacy.put('coupon-a', _coupon('a').toMap());
        await legacy.close();
        final partialTarget = await Hive.openBox<dynamic>(
          StorageService.encryptedCouponsBox,
          encryptionCipher: HiveAesCipher(key),
        );
        await partialTarget.put('stale', _coupon('stale').toMap());
        await partialTarget.close();

        final storage = service(initializer: () {});
        await storage.init();

        expect((await storage.loadCoupons()).map((coupon) => coupon.id), ['a']);
        expect(
          Hive.box<dynamic>(
            StorageService.encryptedCouponsBox,
          ).get('coupon_migration_v1_complete'),
          isTrue,
        );
        final preservedLegacy = await Hive.openBox<dynamic>(
          StorageService.legacyCouponsBox,
        );
        expect(preservedLegacy.get('coupon-a'), _coupon('a').toMap());
      },
    );

    test(
      'existing encrypted legacy vault reopens without migration or data loss',
      () async {
        final key = Hive.generateSecureKey();
        keyStore.value = base64Url.encode(key);
        Hive.init(directory.path);
        final encryptedLegacy = await Hive.openBox<dynamic>(
          StorageService.legacyCouponsBox,
          encryptionCipher: HiveAesCipher(key),
        );
        await encryptedLegacy.put('coupon-a', _coupon('a').toMap());
        await encryptedLegacy.close();

        final storage = service(initializer: () {});
        await storage.init();

        expect((await storage.loadCoupons()).single.id, 'a');
        expect(Hive.isBoxOpen(StorageService.legacyCouponsBox), isTrue);
        expect(
          await Hive.boxExists(StorageService.encryptedCouponsBox),
          isFalse,
        );
      },
    );

    test(
      'missing key for an existing encrypted vault fails without creating a new vault',
      () async {
        final key = Hive.generateSecureKey();
        Hive.init(directory.path);
        final encrypted = await Hive.openBox<dynamic>(
          StorageService.encryptedCouponsBox,
          encryptionCipher: HiveAesCipher(key),
        );
        await encrypted.put('coupon-a', _coupon('a').toMap());
        await encrypted.close();

        await expectLater(
          service(initializer: () {}).init(),
          throwsA(
            isA<StorageException>().having(
              (error) => error.failure,
              'failure',
              StorageFailure.missingCouponKey,
            ),
          ),
        );
        expect(keyStore.value, isNull);
      },
    );

    test('invalid stored key fails instead of replacing it', () async {
      keyStore.value = 'not-a-valid-hive-key';
      final storage = service();

      await expectLater(
        storage.init(),
        throwsA(
          isA<StorageException>().having(
            (error) => error.failure,
            'failure',
            StorageFailure.invalidCouponKey,
          ),
        ),
      );
      expect(keyStore.value, 'not-a-valid-hive-key');
    });

    test(
      'migration setup failure preserves the plaintext legacy vault',
      () async {
        keyStore.failWrites = true;
        Hive.init(directory.path);
        final legacy = await Hive.openBox<dynamic>(
          StorageService.legacyCouponsBox,
        );
        await legacy.put('coupon-a', _coupon('a').toMap());
        await legacy.close();

        await expectLater(
          service(initializer: () {}).init(),
          throwsA(
            isA<StorageException>().having(
              (error) => error.failure,
              'failure',
              StorageFailure.initializationFailed,
            ),
          ),
        );

        final preservedLegacy = await Hive.openBox<dynamic>(
          StorageService.legacyCouponsBox,
        );
        expect(preservedLegacy.get('coupon-a'), _coupon('a').toMap());
      },
    );

    test(
      'legacy favorites are read and migrated to one snapshot key',
      () async {
        Hive.init(directory.path);
        final favorites = await Hive.openBox<dynamic>(
          StorageService.favoritesBox,
        );
        await favorites.add(_deal('a').toMap());
        await favorites.add(_deal('b').toMap());
        await favorites.close();

        final storage = service(initializer: () {});
        await storage.init();

        expect((await storage.loadFavorites()).map((deal) => deal.id), [
          'a',
          'b',
        ]);
        final snapshot = Hive.box<dynamic>(
          StorageService.favoritesBox,
        ).get('favorites_snapshot_v2');
        expect(snapshot, isA<List>());
        expect((snapshot as List).length, 2);
      },
    );

    test(
      'legacy favorite migration skips a corrupt row and preserves valid rows',
      () async {
        Hive.init(directory.path);
        final favorites = await Hive.openBox<dynamic>(
          StorageService.favoritesBox,
        );
        await favorites.add(_deal('a').toMap());
        await favorites.add({'id': 'broken'});
        await favorites.close();

        final storage = service(initializer: () {});
        await storage.init();

        expect((await storage.loadFavorites()).map((deal) => deal.id), ['a']);
        final snapshot = Hive.box<dynamic>(
          StorageService.favoritesBox,
        ).get('favorites_snapshot_v2');
        expect((snapshot as List).map((item) => item['id']), ['a']);
      },
    );

    test(
      'favorite snapshot write failure is surfaced and leaves existing snapshot readable',
      () async {
        final storage = service();
        await storage.init();
        await storage.saveFavorites([_deal('a')]);
        await Hive.box<dynamic>(StorageService.favoritesBox).close();

        await expectLater(
          storage.saveFavorites([_deal('b')]),
          throwsA(
            isA<StorageException>().having(
              (error) => error.failure,
              'failure',
              StorageFailure.writeFailed,
            ),
          ),
        );

        final favorites = await Hive.openBox<dynamic>(
          StorageService.favoritesBox,
        );
        expect(
          (favorites.get('favorites_snapshot_v2') as List).single['id'],
          'a',
        );
      },
    );
  });
}
