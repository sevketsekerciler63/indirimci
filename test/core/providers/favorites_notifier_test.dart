import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/models/coupon.dart';
import 'package:indirimci/core/models/deal.dart';
import 'package:indirimci/core/providers/providers.dart';
import 'package:indirimci/core/services/storage_service.dart';

class MemoryStorage implements StorageRepository {
  MemoryStorage({this.failFavoriteWrites = false, this.loadGate});

  final bool failFavoriteWrites;
  final Completer<void>? loadGate;
  List<Deal> favorites = [];

  @override
  Future<void> init() async {}

  @override
  Future<List<Coupon>> loadCoupons() async => [];

  @override
  Future<List<Deal>> loadFavorites() async {
    await loadGate?.future;
    return List.of(favorites);
  }

  @override
  Future<void> saveCoupon(Coupon coupon) async {}

  @override
  Future<void> saveFavorites(List<Deal> deals) async {
    if (failFavoriteWrites) {
      throw const StorageException(StorageFailure.writeFailed);
    }
    favorites = List.of(deals);
  }
}

Deal _buildDeal({
  required String id,
  required double originalPrice,
  required double discountedPrice,
}) {
  return Deal(
    id: id,
    title: 'Urun $id',
    description: 'Aciklama',
    imageUrl: '',
    platform: 'Trendyol',
    category: 'genel',
    originalPrice: originalPrice,
    discountedPrice: discountedPrice,
    discountPercent: 0,
    url: 'https://example.com/$id',
    createdAt: DateTime(2026, 5, 4),
  );
}

void main() {
  group('FavoritesNotifier', () {
    test(
      'toggleFavorite commits state only after the snapshot is saved',
      () async {
        final notifier = FavoritesNotifier(storage: MemoryStorage());
        final deal = _buildDeal(
          id: 'a',
          originalPrice: 100,
          discountedPrice: 80,
        );

        await notifier.toggleFavorite(deal);
        expect(notifier.state.length, 1);
        expect(notifier.isFavorite('a'), isTrue);

        await notifier.toggleFavorite(deal);
        expect(notifier.state, isEmpty);
        expect(notifier.isFavorite('a'), isFalse);
      },
    );

    test(
      'toggleFavorite leaves visible state unchanged when snapshot save fails',
      () async {
        final notifier = FavoritesNotifier(
          storage: MemoryStorage(failFavoriteWrites: true),
        );
        final deal = _buildDeal(
          id: 'a',
          originalPrice: 100,
          discountedPrice: 80,
        );

        await expectLater(
          notifier.toggleFavorite(deal),
          throwsA(
            isA<StorageException>().having(
              (error) => error.failure,
              'failure',
              StorageFailure.writeFailed,
            ),
          ),
        );
        expect(notifier.state, isEmpty);
      },
    );

    test(
      'delayed initial load cannot overwrite a queued favorite toggle',
      () async {
        final loadGate = Completer<void>();
        final storage = MemoryStorage(loadGate: loadGate)
          ..favorites = [
            _buildDeal(id: 'a', originalPrice: 100, discountedPrice: 80),
          ];
        final notifier = FavoritesNotifier(storage: storage);
        final second = _buildDeal(
          id: 'b',
          originalPrice: 200,
          discountedPrice: 150,
        );

        final toggle = notifier.toggleFavorite(second);
        loadGate.complete();
        await toggle;

        expect(notifier.state.map((deal) => deal.id), ['a', 'b']);
        expect(storage.favorites.map((deal) => deal.id), ['a', 'b']);
      },
    );

    test(
      'concurrent toggles are serialized against the latest state',
      () async {
        final notifier = FavoritesNotifier(storage: MemoryStorage());
        final deal = _buildDeal(
          id: 'a',
          originalPrice: 100,
          discountedPrice: 80,
        );

        await Future.wait([
          notifier.toggleFavorite(deal),
          notifier.toggleFavorite(deal),
        ]);

        expect(notifier.state, isEmpty);
      },
    );

    test('totalSavingsProvider sums favorite savings', () async {
      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(MemoryStorage())],
      );
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);
      final d1 = _buildDeal(id: '1', originalPrice: 100, discountedPrice: 70);
      final d2 = _buildDeal(id: '2', originalPrice: 250, discountedPrice: 200);

      await notifier.toggleFavorite(d1);
      await notifier.toggleFavorite(d2);

      final total = container.read(totalSavingsProvider);
      expect(total, 80);
    });
  });
}
