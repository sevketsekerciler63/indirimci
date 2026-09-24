import 'package:flutter_test/flutter_test.dart';
import 'package:indirimci/config/theme/app_theme.dart';

void main() {
  test('app theme does not require a remote font at startup', () {
    final theme = AppTheme.darkTheme;

    expect(theme.textTheme.bodyLarge?.fontFamily, isNot('Poppins'));
    expect(theme.appBarTheme.titleTextStyle?.fontFamily, isNot('Poppins'));
    expect(
      theme.elevatedButtonTheme.style?.textStyle?.resolve({})?.fontFamily,
      isNot('Poppins'),
    );
  });
}
