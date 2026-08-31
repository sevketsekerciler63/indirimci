import '../models/deal.dart';

/// Ağdaki mağaza araması sonucu bulur; bu sınıf en alakalı olanı öne alır.
class SearchMatcher {
  static List<Deal> rank(String query, Iterable<Deal> deals) {
    final normalizedQuery = _normalize(query);
    final terms = normalizedQuery
        .split(' ')
        .where((term) => term.length > 1)
        .toSet();
    final unique = <String, Deal>{};
    for (final deal in deals) {
      final key = '${deal.platform.toLowerCase()}:${_normalize(deal.title)}';
      unique.putIfAbsent(key, () => deal);
    }
    final ranked =
        unique.values
            .map(
              (deal) => _RankedDeal(deal, _score(deal, normalizedQuery, terms)),
            )
            .where((item) => item.score > 0)
            .toList()
          ..sort((a, b) {
            final scoreOrder = b.score.compareTo(a.score);
            return scoreOrder != 0
                ? scoreOrder
                : a.deal.discountedPrice.compareTo(b.deal.discountedPrice);
          });
    return ranked.map((item) => item.deal).toList();
  }

  static int _score(Deal deal, String query, Set<String> terms) {
    final title = _normalize(deal.title);
    final description = _normalize(deal.description);
    final category = _normalize(deal.category);
    if (title == query) return 1000;
    var score = 0;
    for (final term in terms) {
      if (title.contains(term)) {
        score += 100;
      } else if (description.contains(term) || category.contains(term)) {
        score += 25;
      }
    }
    if (terms.isNotEmpty && terms.every(title.contains)) score += 300;
    if (title.startsWith(query)) score += 150;
    return score;
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}

class _RankedDeal {
  const _RankedDeal(this.deal, this.score);
  final Deal deal;
  final int score;
}
