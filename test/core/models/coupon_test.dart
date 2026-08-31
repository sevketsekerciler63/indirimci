import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/models/coupon.dart';

void main() {
  group('Coupon trust rules', () {
    test('isTrusted true only when verified, not expired and fresh', () {
      final now = DateTime.now();
      final trusted = Coupon(
        id: '1',
        code: 'KOD',
        platform: 'Trendyol',
        description: 'Test',
        isVerified: true,
        expiryDate: now.add(const Duration(days: 1)),
        lastCheckedAt: now.subtract(const Duration(hours: 1)),
      );

      expect(trusted.isTrusted(), isTrue);
    });

    test('isTrusted false when stale', () {
      final now = DateTime.now();
      final stale = Coupon(
        id: '2',
        code: 'KOD2',
        platform: 'Trendyol',
        description: 'Test',
        isVerified: true,
        expiryDate: now.add(const Duration(days: 1)),
        lastCheckedAt: now.subtract(const Duration(hours: 20)),
      );

      expect(stale.isTrusted(), isFalse);
    });
  });
}
