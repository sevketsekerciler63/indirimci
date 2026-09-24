import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indirimci/core/providers/providers.dart';

void main() {
  test('priceHistoryProvider does not expose mock history by default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(priceHistoryProvider), isEmpty);
  });
}
