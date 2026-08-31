import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/models/deal.dart';
import 'package:indirimci/core/services/search_matcher.dart';

Deal _deal(String id, String title, double price) => Deal(
  id: id,
  title: title,
  description: 'Ürün',
  imageUrl: '',
  platform: 'Test',
  category: 'genel',
  originalPrice: price,
  discountedPrice: price,
  discountPercent: 0,
  url: 'https://example.com/$id',
  createdAt: DateTime.now(),
);

void main() {
  test('exact and multi-term product matches rank before loose matches', () {
    final results = SearchMatcher.rank('Faber Castell kalem', [
      _deal('1', 'Kırmızı tükenmez kalem', 30),
      _deal('2', 'Faber-Castell Grip kalem', 40),
      _deal('3', 'Faber Castell Kalem 0.7 mm', 35),
    ]);
    expect(results.map((deal) => deal.id), ['3', '2', '1']);
  });

  test('same relevance is sorted by lower price first', () {
    final results = SearchMatcher.rank('kalem', [
      _deal('expensive', 'Mavi kalem', 50),
      _deal('cheap', 'Siyah kalem', 20),
    ]);
    expect(results.map((deal) => deal.id), ['cheap', 'expensive']);
  });
}
