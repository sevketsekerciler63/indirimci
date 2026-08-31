import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/models/coupon.dart';
import 'package:indirimci/core/services/coupon_calculator.dart';

void main() {
  test('applies percentage coupon', () {
    final result = CouponCalculator.apply(
      price: 1000,
      coupon: const Coupon(
        id: 'p', code: 'P20', platform: 'Test', description: 'Test',
        discountPercent: 20,
      ),
    );
    expect(result.applicable, isTrue);
    expect(result.finalPrice, 800);
  });

  test('does not apply coupon below minimum order', () {
    final result = CouponCalculator.apply(
      price: 100,
      coupon: const Coupon(
        id: 'm', code: 'M50', platform: 'Test', description: 'Test',
        discountAmount: 50, minOrderAmount: 200,
      ),
    );
    expect(result.applicable, isFalse);
    expect(result.finalPrice, 100);
  });
}
