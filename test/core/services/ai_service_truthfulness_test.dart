import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/core/services/ai_service.dart';

void main() {
  group('AIService truthfulness', () {
    test(
      'does not invent discount percentages or coupon claims without evidence',
      () async {
        final response = await AIService().askAI('yemeksepeti burger kodu');

        expect(response, isNot(contains(RegExp(r'%\s*\d+'))));
        expect(response.toLowerCase(), isNot(contains('kupon')));
        expect(response.toLowerCase(), contains('kanıtlı'));
      },
    );
  });
}
