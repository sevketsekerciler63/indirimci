import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/models/coupon.dart';
import 'package:indirimci/core/services/coupon_calculator.dart';

void main() {
  group('CouponCalculator invalid coupon rules', () {
    test('does not stack percentage and fixed discount from same coupon', () {
      const coupon = Coupon(
        id: 'invalid-mixed-discount',
        code: 'MIXED100',
        platform: 'Yemeksepeti',
        description: 'Hatalı kupon',
        discountPercent: 10,
        discountAmount: 50,
        source: DataSourceType.manual,
      );

      final result = CouponCalculator.apply(price: 300, coupon: coupon);

      expect(result.applicable, isFalse);
      expect(result.discount, 0);
      expect(result.finalPrice, 300);
      expect(result.reason, 'Kuponda tek indirim türü olmalı');
    });
  });
}
