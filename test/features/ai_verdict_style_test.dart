import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/features/products/presentation/widgets/ai_verdict_style.dart';

void main() {
  group('splitPositive', () {
    test('splits "name (role, role)" into the name and trimmed roles', () {
      final p = splitPositive('dimethicone (antifoaming, emollient)');
      expect(p.name, 'dimethicone');
      expect(p.roles, ['antifoaming', 'emollient']);
    });

    test('keeps any other shape whole, with no roles', () {
      expect(splitPositive('Short ingredient list').roles, isEmpty);
      expect(splitPositive('Short ingredient list').name, 'Short ingredient list');
      expect(splitPositive('a (b) and (c)').roles, isEmpty, reason: 'nested/multiple brackets are not guessed at');
      expect(splitPositive('  ').name, '');
    });
  });

  test('icons come from keywords, with a neutral default', () {
    expect(positiveIcon(['antioxidant']), Icons.shield_outlined);
    expect(positiveIcon(['skin conditioning']), Icons.water_drop_outlined);
    expect(positiveIcon([]), Icons.check_rounded);
    expect(concernIcon('may cause skin irritation'), Icons.whatshot_outlined);
    expect(concernIcon('Possible allergen'), Icons.sick_outlined);
    expect(concernIcon('something else'), Icons.priority_high_rounded);
  });
}
