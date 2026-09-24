import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/models/coupon.dart';
import 'package:indirimci/core/models/deal.dart';
import 'package:indirimci/core/providers/providers.dart';
import 'package:indirimci/core/services/ai_service.dart';
import 'package:indirimci/core/services/api_service.dart';
import 'package:indirimci/core/services/scraper_service.dart';

class EmptyDealSource implements OfficialDealSource {
  @override
  Future<List<Deal>> fetchDeals() async => [];
}

class EmptyCouponSource implements OfficialCouponSource {
  @override
  Future<List<Coupon>> fetchCoupons() async => [];
}

class FakeStatusSearchService extends AIService {
  @override
  Future<SearchResultBundle> searchDealsSmartBundle(String query) async {
    return SearchResultBundle(
      deals: [
        Deal(
          id: 'trusted-source-result',
          title: 'Kalem',
          description: 'kanıtlı',
          imageUrl: '',
          platform: 'Trendyol',
          category: 'genel',
          originalPrice: 100,
          discountedPrice: 90,
          discountPercent: 10,
          url: 'https://example.com/kalem',
          createdAt: DateTime.now(),
          source: DataSourceType.scraper,
          fetchedAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ],
      statuses: const [
        SearchSourceStatus(
          name: 'Trendyol',
          count: 1,
          ok: true,
          message: '1 sonuç',
        ),
        SearchSourceStatus(
          name: 'Cimri',
          count: 0,
          ok: false,
          message: '403 engellendi',
        ),
      ],
    );
  }
}

void main() {
  test(
    'search bundle provider keeps source statuses next to trusted deals',
    () async {
      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(
            ApiService(
              dealSource: EmptyDealSource(),
              couponSource: EmptyCouponSource(),
            ),
          ),
          aiServiceProvider.overrideWithValue(FakeStatusSearchService()),
        ],
      );
      addTearDown(container.dispose);

      container.read(activeSearchQueryProvider.notifier).state = 'kalem';
      final bundle = await container.read(searchResultBundleProvider.future);

      expect(bundle.deals.map((deal) => deal.id), ['trusted-source-result']);
      expect(bundle.statuses.map((status) => status.name), [
        'Trendyol',
        'Cimri',
      ]);
      expect(bundle.statuses.last.ok, isFalse);
      expect(bundle.statuses.last.message, contains('403'));
    },
  );
}
