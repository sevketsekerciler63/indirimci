import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/models/coupon.dart';

void main() {
  group('Coupon status tracking', () {
    test(
      'worked status increments usage, marks verified and success rate 100',
      () {
        final coupon = Coupon(
          id: 'manual-1',
          code: 'YEMEK50',
          platform: 'Yemeksepeti',
          description: 'Kullanıcının eklediği kupon',
          discountAmount: 50,
          source: DataSourceType.manual,
        );

        final updated = coupon.copyWithCheckedStatus(
          CouponStatus.worked,
          checkedAt: DateTime(2026, 9, 21, 17, 0),
        );

        expect(updated.status, CouponStatus.worked);
        expect(updated.usageCount, 1);
        expect(updated.successRate, 100);
        expect(updated.isVerified, isTrue);
        expect(updated.verifiedAt, DateTime(2026, 9, 21, 17, 0));
        expect(updated.lastCheckedAt, DateTime(2026, 9, 21, 17, 0));
      },
    );

    test('failed status increments usage and lowers success rate', () {
      final coupon = Coupon(
        id: 'manual-1',
        code: 'GETIR25',
        platform: 'Getir',
        description: 'Kullanıcının eklediği kupon',
        discountAmount: 25,
        source: DataSourceType.manual,
        usageCount: 1,
        successRate: 100,
        isVerified: true,
      );

      final updated = coupon.copyWithCheckedStatus(
        CouponStatus.failed,
        checkedAt: DateTime(2026, 9, 21, 18, 0),
      );

      expect(updated.status, CouponStatus.failed);
      expect(updated.usageCount, 2);
      expect(updated.successRate, 50);
      expect(updated.isVerified, isFalse);
      expect(updated.lastCheckedAt, DateTime(2026, 9, 21, 18, 0));
    });
  });
}
