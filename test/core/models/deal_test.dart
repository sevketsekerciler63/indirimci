import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/models/deal.dart';

void main() {
  group('Deal', () {
    test('toMap/fromMap roundtrip preserves core fields', () {
      final now = DateTime(2026, 5, 4, 12, 0, 0);
      final expiry = DateTime(2026, 5, 10, 10, 30, 0);
      final deal = Deal(
        id: '1',
        title: 'Kulaklik',
        description: 'Bluetooth kulaklik',
        imageUrl: 'https://example.com/i.png',
        platform: 'Trendyol',
        category: 'elektronik',
        originalPrice: 1000,
        discountedPrice: 750,
        discountPercent: 25,
        couponCode: 'KOD25',
        url: 'https://example.com',
        expiryDate: null,
        isFlashDeal: true,
        isHot: true,
        createdAt: now,
      );

      final map = deal.toMap()
        ..['expiryDate'] = expiry.toIso8601String();
      final parsed = Deal.fromMap(map);

      expect(parsed.id, deal.id);
      expect(parsed.title, deal.title);
      expect(parsed.originalPrice, deal.originalPrice);
      expect(parsed.discountedPrice, deal.discountedPrice);
      expect(parsed.discountPercent, deal.discountPercent);
      expect(parsed.couponCode, deal.couponCode);
      expect(parsed.url, deal.url);
      expect(parsed.isFlashDeal, isTrue);
      expect(parsed.isHot, isTrue);
      expect(parsed.createdAt, now);
      expect(parsed.expiryDate, expiry);
    });

    test('fromMap handles invalid numeric values safely', () {
      final parsed = Deal.fromMap({
        'id': '2',
        'title': 'Test',
        'description': 'A',
        'imageUrl': '',
        'platform': '',
        'category': '',
        'originalPrice': 'abc',
        'discountedPrice': null,
        'discountPercent': {},
        'url': '',
      });

      expect(parsed.originalPrice, 0.0);
      expect(parsed.discountedPrice, 0.0);
      expect(parsed.discountPercent, 0.0);
    });

    test('savingsAmount calculates correctly', () {
      final deal = Deal(
        id: '3',
        title: 'Urün',
        description: 'Aciklama',
        imageUrl: '',
        platform: 'Amazon',
        category: 'elektronik',
        originalPrice: 1200,
        discountedPrice: 900,
        discountPercent: 25,
        url: 'https://example.com',
        createdAt: DateTime(2026, 5, 4),
      );

      expect(deal.savingsAmount, 300);
    });
  });
}
