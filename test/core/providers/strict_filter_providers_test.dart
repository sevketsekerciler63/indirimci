import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/models/coupon.dart';
import 'package:indirimci/core/models/deal.dart';
import 'package:indirimci/core/providers/providers.dart';
import 'package:indirimci/core/services/api_service.dart';

class FakeDealSource implements OfficialDealSource {
  @override
  Future<List<Deal>> fetchDeals() async {
    final now = DateTime.now();
    return [
      Deal(
        id: 'trusted',
        title: 'A',
        description: 'A',
        imageUrl: '',
        platform: 'Trendyol',
        category: 'c',
        originalPrice: 100,
        discountedPrice: 80,
        discountPercent: 20,
        url: 'https://example.com/a',
        createdAt: now,
        source: DataSourceType.officialApi,
        fetchedAt: now.subtract(const Duration(minutes: 30)),
      ),
      Deal(
        id: 'stale',
        title: 'B',
        description: 'B',
        imageUrl: '',
        platform: 'Trendyol',
        category: 'c',
        originalPrice: 100,
        discountedPrice: 90,
        discountPercent: 10,
        url: 'https://example.com/b',
        createdAt: now,
        source: DataSourceType.officialApi,
        fetchedAt: now.subtract(const Duration(hours: 8)),
      ),
    ];
  }
}

class FakeCouponSource implements OfficialCouponSource {
  @override
  Future<List<Coupon>> fetchCoupons() async {
    final now = DateTime.now();
    return [
      Coupon(
        id: 'trusted-c',
        code: 'TRUST',
        platform: 'Trendyol',
        description: 'trusted',
        isVerified: true,
        expiryDate: now.add(const Duration(days: 1)),
        lastCheckedAt: now.subtract(const Duration(hours: 1)),
      ),
      Coupon(
        id: 'unverified-c',
        code: 'BAD',
        platform: 'Trendyol',
        description: 'bad',
        isVerified: false,
        expiryDate: now.add(const Duration(days: 1)),
        lastCheckedAt: now.subtract(const Duration(hours: 1)),
      ),
    ];
  }
}

void main() {
  test('providers expose only trusted deals and coupons', () async {
    final api = ApiService(
      dealSource: FakeDealSource(),
      couponSource: FakeCouponSource(),
    );

    final container = ProviderContainer(
      overrides: [apiServiceProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);

    // Provider asenkron yüklendiği için sabit ve kırılgan bir bekleme yerine
    // beklenen veri gelene kadar kontrollü şekilde bekle.
    for (var attempt = 0; attempt < 20; attempt++) {
      if (container.read(dealsProvider).isNotEmpty &&
          container.read(couponsProvider).isNotEmpty) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    final deals = container.read(dealsProvider);
    final coupons = container.read(couponsProvider);

    expect(deals.map((d) => d.id).toList(), ['trusted']);
    expect(coupons.map((c) => c.id).toList(), ['trusted-c']);
  });
}
