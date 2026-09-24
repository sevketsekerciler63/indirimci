import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/models/coupon.dart';
import 'package:indirimci/core/models/deal.dart';

void main() {
  group('Deal trust rules', () {
    test('untrusted scraper deal is not trusted without fresh provenance', () {
      final deal = Deal(
        id: 'scraper-no-time',
        title: 'Belirsiz ürün',
        description: 'kanıtsız',
        imageUrl: '',
        platform: 'Bilinmeyen',
        category: 'genel',
        originalPrice: 100,
        discountedPrice: 80,
        discountPercent: 20,
        url: 'https://example.com/item',
        createdAt: DateTime.now(),
        source: DataSourceType.scraper,
      );

      expect(deal.isTrusted, isFalse);
    });

    test('fresh official deal is trusted', () {
      final deal = Deal(
        id: 'official-fresh',
        title: 'Kanıtlı ürün',
        description: 'resmi',
        imageUrl: '',
        platform: 'Resmi',
        category: 'genel',
        originalPrice: 100,
        discountedPrice: 80,
        discountPercent: 20,
        url: 'https://example.com/item',
        createdAt: DateTime.now(),
        source: DataSourceType.officialApi,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      expect(deal.isTrusted, isTrue);
    });
  });
}
