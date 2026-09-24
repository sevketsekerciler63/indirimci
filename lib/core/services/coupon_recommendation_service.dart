import '../models/coupon.dart';
import 'coupon_calculator.dart';

class CouponRecommendationItem {
  final Coupon coupon;
  final CouponCalculation calculation;
  final String? reason;

  const CouponRecommendationItem({
    required this.coupon,
    required this.calculation,
    this.reason,
  });
}

class CouponRecommendation {
  final CouponRecommendationItem? best;
  final List<CouponRecommendationItem> eligible;
  final List<CouponRecommendationItem> rejected;

  const CouponRecommendation({
    required this.best,
    required this.eligible,
    required this.rejected,
  });
}

class CouponRecommendationService {
  CouponRecommendation recommendBest({
    required List<Coupon> coupons,
    required String platform,
    required double basketTotal,
  }) {
    if (basketTotal <= 0 || basketTotal.isNaN || basketTotal.isInfinite) {
      return const CouponRecommendation(best: null, eligible: [], rejected: []);
    }

    final normalizedPlatform = _normalizePlatform(platform);
    final eligible = <CouponRecommendationItem>[];
    final rejected = <CouponRecommendationItem>[];

    for (final coupon in coupons) {
      final calculation = CouponCalculator.apply(
        price: basketTotal,
        coupon: coupon,
      );

      if (_normalizePlatform(coupon.platform) != normalizedPlatform) {
        rejected.add(
          CouponRecommendationItem(
            coupon: coupon,
            calculation: calculation,
            reason: 'Platform eşleşmiyor',
          ),
        );
        continue;
      }

      if (!calculation.applicable) {
        rejected.add(
          CouponRecommendationItem(
            coupon: coupon,
            calculation: calculation,
            reason: calculation.reason ?? 'Kupon uygulanamadı',
          ),
        );
        continue;
      }

      eligible.add(
        CouponRecommendationItem(coupon: coupon, calculation: calculation),
      );
    }

    eligible.sort(_compareEligibleCoupons);

    return CouponRecommendation(
      best: eligible.isEmpty ? null : eligible.first,
      eligible: List.unmodifiable(eligible),
      rejected: List.unmodifiable(rejected),
    );
  }

  int _compareEligibleCoupons(
    CouponRecommendationItem a,
    CouponRecommendationItem b,
  ) {
    final discountComparison = b.calculation.discount.compareTo(
      a.calculation.discount,
    );
    if (discountComparison != 0) return discountComparison;

    final aWorked = a.coupon.status == CouponStatus.worked;
    final bWorked = b.coupon.status == CouponStatus.worked;
    if (aWorked != bWorked) return bWorked ? 1 : -1;

    final successComparison = b.coupon.successRate.compareTo(
      a.coupon.successRate,
    );
    if (successComparison != 0) return successComparison;

    final aExpiry = a.coupon.expiryDate;
    final bExpiry = b.coupon.expiryDate;
    if (aExpiry != null && bExpiry != null) {
      final expiryComparison = aExpiry.compareTo(bExpiry);
      if (expiryComparison != 0) return expiryComparison;
    } else if (aExpiry != null) {
      return -1;
    } else if (bExpiry != null) {
      return 1;
    }

    return a.coupon.code.compareTo(b.coupon.code);
  }

  String _normalizePlatform(String value) {
    return value.trim().toLowerCase().replaceAll('ı', 'i');
  }
}
