import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/models/coupon.dart';
import 'package:indirimci/core/models/deal.dart';
import 'package:indirimci/core/providers/providers.dart';
import 'package:indirimci/core/services/ai_service.dart';
import 'package:indirimci/core/services/api_service.dart';
import 'package:indirimci/core/services/storage_service.dart';

class FailingCouponStorage implements StorageRepository {
  @override
  Future<void> init() async {}

  @override
  Future<List<Coupon>> loadCoupons() async => [];

  @override
  Future<List<Deal>> loadFavorites() async => [];

  @override
  Future<void> saveCoupon(Coupon coupon) async {
    throw const StorageException(StorageFailure.writeFailed);
  }

  @override
  Future<void> saveFavorites(List<Deal> deals) async {}
}

void main() {
  test(
    'CouponsNotifier does not publish a manual coupon when persistence fails',
    () async {
      final notifier = CouponsNotifier(
        ApiService(),
        AIService(),
        storage: FailingCouponStorage(),
      );
      final coupon = Coupon(
        id: 'manual-a',
        code: 'SECRET',
        platform: 'Test',
        description: 'Manual',
        source: DataSourceType.manual,
      );

      await expectLater(
        notifier.addManualCoupon(coupon),
        throwsA(
          isA<StorageException>().having(
            (error) => error.failure,
            'failure',
            StorageFailure.writeFailed,
          ),
        ),
      );
      expect(notifier.state, isEmpty);
    },
  );
}
