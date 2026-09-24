import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/models/coupon.dart';
import 'package:indirimci/core/services/coupon_recommendation_service.dart';

void main() {
  group('CouponRecommendationService', () {
    test(
      'recommends highest saving coupon for matching platform and basket',
      () {
        final service = CouponRecommendationService();
        final coupons = [
          const Coupon(
            id: 'getir-low',
            code: 'GETIR25',
            platform: 'Getir',
            description: '25 TL',
            discountAmount: 25,
            minOrderAmount: 100,
            source: DataSourceType.manual,
          ),
          const Coupon(
            id: 'getir-high',
            code: 'GETIR75',
            platform: 'Getir',
            description: '75 TL',
            discountAmount: 75,
            minOrderAmount: 250,
            source: DataSourceType.manual,
            usageCount: 2,
            successRate: 100,
            status: CouponStatus.worked,
          ),
          const Coupon(
            id: 'trendyol-high',
            code: 'TY100',
            platform: 'Trendyol',
            description: '100 TL',
            discountAmount: 100,
            minOrderAmount: 250,
            source: DataSourceType.manual,
          ),
        ];

        final recommendation = service.recommendBest(
          coupons: coupons,
          platform: 'getir',
          basketTotal: 300,
        );

        expect(recommendation.best?.coupon.code, 'GETIR75');
        expect(recommendation.best?.calculation.discount, 75);
        expect(recommendation.eligible.map((item) => item.coupon.code), [
          'GETIR75',
          'GETIR25',
        ]);
        expect(
          recommendation.rejected.map((item) => item.coupon.code),
          contains('TY100'),
        );
      },
    );

    test('explains when coupons are below minimum basket or expired', () {
      final service = CouponRecommendationService();
      final coupons = [
        Coupon(
          id: 'expired',
          code: 'OLD50',
          platform: 'Yemeksepeti',
          description: 'Süresi geçmiş',
          discountAmount: 50,
          expiryDate: DateTime(2020, 1, 1),
          source: DataSourceType.manual,
        ),
        const Coupon(
          id: 'minimum',
          code: 'YEMEK100',
          platform: 'Yemeksepeti',
          description: 'Min 500',
          discountAmount: 100,
          minOrderAmount: 500,
          source: DataSourceType.manual,
        ),
      ];

      final recommendation = service.recommendBest(
        coupons: coupons,
        platform: 'Yemeksepeti',
        basketTotal: 300,
      );

      expect(recommendation.best, isNull);
      expect(recommendation.eligible, isEmpty);
      expect(recommendation.rejected, hasLength(2));
      expect(
        recommendation.rejected.map((item) => item.reason),
        containsAll([
          'Kuponun süresi dolmuş',
          'Minimum sepet tutarı sağlanmıyor',
        ]),
      );
    });
  });
}
