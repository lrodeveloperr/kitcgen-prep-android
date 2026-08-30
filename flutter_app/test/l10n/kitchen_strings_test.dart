import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_prep_board/l10n/kitchen_strings.dart';

void main() {
  test('Every launch language has exact key parity', () {
    expect(KitchenStrings.tablesComplete, isTrue);
    expect(KitchenStrings.keys, isNotEmpty);
  });

  test('Both Chinese scripts resolve independently', () {
    final simplified = KitchenStrings(
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    );
    final traditional = KitchenStrings(
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    );
    expect(simplified.t('appName'), isNot(traditional.t('appName')));
  });

  test('Arabic chrome does not fall back to English for known keys', () {
    final arabic = KitchenStrings(const Locale('ar'));
    for (final key in KitchenStrings.keys) {
      expect(arabic.t(key), isNot(key));
    }
  });
}
