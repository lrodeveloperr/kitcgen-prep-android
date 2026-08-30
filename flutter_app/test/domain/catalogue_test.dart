import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_prep_board/catalogue/kitchen_catalogue.dart';

void main() {
  test('Every neutral category has bundled items', () {
    for (final category in GroceryCategory.values) {
      expect(
        kitchenCatalogue.where((item) => item.category == category),
        isNotEmpty,
        reason: category.name,
      );
    }
  });

  test('Catalogue IDs are stable and unique', () {
    final ids = kitchenCatalogue.map((item) => item.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('Accent-insensitive search works', () {
    final locale = const Locale('es');
    final broccoli = kitchenCatalogue.firstWhere((item) => item.id == 'broccoli');
    expect(broccoli.matches('brocoli', locale), isTrue);
  });
}
