import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/models/coupon.dart';

void main() {
  group('Coupon masking', () {
    test(
      'masks personal coupon code while keeping enough hint for the user',
      () {
        const coupon = Coupon(
          id: 'personal-1',
          code: 'YEMEKSEPETI100',
          platform: 'Yemeksepeti',
          description: 'Kişisel kod',
          discountAmount: 100,
          source: DataSourceType.manual,
          isHidden: true,
        );

        expect(coupon.maskedCode, 'YEM********100');
        expect(coupon.maskedCode.contains(coupon.code), isFalse);
      },
    );

    test('masks short personal coupon code completely', () {
      const coupon = Coupon(
        id: 'personal-2',
        code: 'AB12',
        platform: 'Getir',
        description: 'Kısa kod',
        discountAmount: 20,
        source: DataSourceType.manual,
        isHidden: true,
      );

      expect(coupon.maskedCode, '••••');
    });

    test('does not mask public non-hidden coupon code', () {
      const coupon = Coupon(
        id: 'public-1',
        code: 'PUBLIC50',
        platform: 'Trendyol',
        description: 'Herkese açık',
        discountAmount: 50,
        source: DataSourceType.officialApi,
      );

      expect(coupon.maskedCode, 'PUBLIC50');
    });
  });
}
