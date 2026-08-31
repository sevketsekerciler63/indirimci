import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/models/coupon.dart';
import 'package:indirimci/core/models/deal.dart';
import 'package:indirimci/core/services/api_service.dart';

class ThrowingDealSource implements OfficialDealSource {
  @override
  Future<List<Deal>> fetchDeals() async {
    throw Exception('failed');
  }
}

class ThrowingCouponSource implements OfficialCouponSource {
  @override
  Future<List<Coupon>> fetchCoupons() async {
    throw Exception('failed');
  }
}

void main() {
  group('ApiService', () {
    test('returns empty deals list on source failure', () async {
      final api = ApiService(dealSource: ThrowingDealSource());
      final deals = await api.fetchRealDeals();
      expect(deals, isEmpty);
    });

    test('returns empty coupons list on source failure', () async {
      final api = ApiService(couponSource: ThrowingCouponSource());
      final coupons = await api.fetchCoupons();
      expect(coupons, isEmpty);
    });
  });
}
