import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/models/deal.dart';
import 'package:indirimci/core/providers/providers.dart';

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
    test('toggleFavorite adds and removes deal', () {
      final notifier = FavoritesNotifier();
      final deal = _buildDeal(id: 'a', originalPrice: 100, discountedPrice: 80);

      notifier.toggleFavorite(deal);
      expect(notifier.state.length, 1);
      expect(notifier.isFavorite('a'), isTrue);

      notifier.toggleFavorite(deal);
      expect(notifier.state, isEmpty);
      expect(notifier.isFavorite('a'), isFalse);
    });

    test('totalSavingsProvider sums favorite savings', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);
      final d1 = _buildDeal(id: '1', originalPrice: 100, discountedPrice: 70);
      final d2 = _buildDeal(id: '2', originalPrice: 250, discountedPrice: 200);

      notifier.toggleFavorite(d1);
      notifier.toggleFavorite(d2);

      final total = container.read(totalSavingsProvider);
      expect(total, 80);
    });
  });
}
