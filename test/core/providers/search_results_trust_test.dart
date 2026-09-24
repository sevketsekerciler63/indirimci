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

class FakeSearchService extends AIService {
  @override
  Future<SearchResultBundle> searchDealsSmartBundle(String query) async {
    return SearchResultBundle(
      statuses: const [],
      deals: [
        Deal(
          id: 'untrusted-scraper',
          title: 'Faber Castell kalem',
          description: 'kanıtsız scraper sonucu',
          imageUrl: '',
          platform: 'Scraper',
          category: 'genel',
          originalPrice: 100,
          discountedPrice: 80,
          discountPercent: 20,
          url: 'https://example.com/faber',
          createdAt: DateTime.now(),
          source: DataSourceType.scraper,
        ),
        Deal(
          id: 'trusted-official',
          title: 'Faber Castell kalem resmi',
          description: 'kanıtlı resmi sonuç',
          imageUrl: '',
          platform: 'Official',
          category: 'genel',
          originalPrice: 100,
          discountedPrice: 90,
          discountPercent: 10,
          url: 'https://example.com/official',
          createdAt: DateTime.now(),
          source: DataSourceType.officialApi,
          fetchedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ],
    );
  }
}

void main() {
  test('search results expose only trusted deals', () async {
    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(
          ApiService(
            dealSource: EmptyDealSource(),
            couponSource: EmptyCouponSource(),
          ),
        ),
        aiServiceProvider.overrideWithValue(FakeSearchService()),
      ],
    );
    addTearDown(container.dispose);

    container.read(activeSearchQueryProvider.notifier).state = 'faber';
    final results = await container.read(searchResultsProvider.future);

    expect(results.map((deal) => deal.id), ['trusted-official']);
  });
}
