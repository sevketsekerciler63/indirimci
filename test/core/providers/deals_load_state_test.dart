import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/models/coupon.dart';
import 'package:indirimci/core/models/deal.dart';
import 'package:indirimci/core/providers/providers.dart';
import 'package:indirimci/core/services/api_service.dart';

class ControlledDealSource implements OfficialDealSource {
  ControlledDealSource(this._responses);

  final List<List<Deal>> _responses;
  int _index = 0;

  @override
  Future<List<Deal>> fetchDeals() async {
    final index = _index < _responses.length ? _index : _responses.length - 1;
    _index++;
    return _responses[index];
  }
}

class EmptyCouponSource implements OfficialCouponSource {
  @override
  Future<List<Coupon>> fetchCoupons() async => [];
}

Deal _deal({
  required String id,
  required DataSourceType source,
  required DateTime? fetchedAt,
}) {
  return Deal(
    id: id,
    title: 'Test urunu',
    description: 'Test aciklamasi',
    imageUrl: '',
    platform: 'Test',
    category: 'genel',
    originalPrice: 100,
    discountedPrice: 80,
    discountPercent: 20,
    url: 'https://example.com/$id',
    createdAt: DateTime.now(),
    source: source,
    fetchedAt: fetchedAt,
  );
}

Future<void> _waitForInitialLoad(ProviderContainer container) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (container.read(dealsLoadStateProvider).hasLoaded) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  test(
    'home deal state exposes loaded empty instead of looking unfinished',
    () async {
      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(
            ApiService(
              dealSource: ControlledDealSource([const []]),
              couponSource: EmptyCouponSource(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(dealsProvider);
      await _waitForInitialLoad(container);

      expect(container.read(dealsProvider), isEmpty);
      expect(container.read(dealsLoadStateProvider).hasLoaded, isTrue);
      expect(container.read(dealsLoadStateProvider).isLoading, isFalse);
      expect(
        container.read(dealsLoadStateProvider).message,
        'Bağlı ve doğrulanmış fırsat kaynağı henüz yok.',
      );
    },
  );

  test(
    'refresh filters untrusted rows and replaces stale visible deals',
    () async {
      final now = DateTime.now();
      final trusted = _deal(
        id: 'trusted',
        source: DataSourceType.officialApi,
        fetchedAt: now.subtract(const Duration(minutes: 5)),
      );
      final stale = _deal(
        id: 'stale',
        source: DataSourceType.officialApi,
        fetchedAt: now.subtract(const Duration(hours: 8)),
      );
      final unknown = _deal(
        id: 'unknown',
        source: DataSourceType.unknown,
        fetchedAt: now,
      );

      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(
            ApiService(
              dealSource: ControlledDealSource([
                [trusted],
                [stale, unknown],
              ]),
              couponSource: EmptyCouponSource(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(dealsProvider);
      await _waitForInitialLoad(container);
      expect(container.read(dealsProvider).map((deal) => deal.id), ['trusted']);

      await container.read(dealsProvider.notifier).refresh();

      expect(container.read(dealsProvider), isEmpty);
      expect(container.read(dealsLoadStateProvider).hasLoaded, isTrue);
      expect(container.read(dealsLoadStateProvider).isLoading, isFalse);
      expect(
        container.read(dealsLoadStateProvider).message,
        'Kaynak yanıt verdi ancak güncel ve doğrulanmış fırsat bulunamadı.',
      );
    },
  );
}
