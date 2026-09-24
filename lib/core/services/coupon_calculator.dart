import '../models/coupon.dart';

class CouponCalculation {
  final double originalPrice;
  final double discount;
  final double finalPrice;
  final bool applicable;
  final String? reason;

  const CouponCalculation({
    required this.originalPrice,
    required this.discount,
    required this.finalPrice,
    required this.applicable,
    this.reason,
  });
}

class CouponCalculator {
  static CouponCalculation apply({
    required double price,
    required Coupon coupon,
  }) {
    if (price <= 0) {
      return const CouponCalculation(
        originalPrice: 0,
        discount: 0,
        finalPrice: 0,
        applicable: false,
        reason: 'Geçersiz ürün fiyatı',
      );
    }
    if (coupon.isExpired) {
      return CouponCalculation(
        originalPrice: price,
        discount: 0,
        finalPrice: price,
        applicable: false,
        reason: 'Kuponun süresi dolmuş',
      );
    }
    if (coupon.minOrderAmount != null && price < coupon.minOrderAmount!) {
      return CouponCalculation(
        originalPrice: price,
        discount: 0,
        finalPrice: price,
        applicable: false,
        reason: 'Minimum sepet tutarı sağlanmıyor',
      );
    }
    if (coupon.discountPercent != null && coupon.discountAmount != null) {
      return CouponCalculation(
        originalPrice: price,
        discount: 0,
        finalPrice: price,
        applicable: false,
        reason: 'Kuponda tek indirim türü olmalı',
      );
    }

    final percentDiscount = coupon.discountPercent == null
        ? 0
        : price * coupon.discountPercent! / 100;
    final amountDiscount = coupon.discountAmount ?? 0;
    final discount = (percentDiscount + amountDiscount)
        .clamp(0, price)
        .toDouble();
    return CouponCalculation(
      originalPrice: price,
      discount: discount,
      finalPrice: price - discount,
      applicable: discount > 0,
      reason: discount > 0 ? null : 'Kupon indirimi tanımlı değil',
    );
  }
}
