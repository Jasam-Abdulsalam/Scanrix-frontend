import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/constants/api_constants.dart';
import 'package:scanrix_frontend/features/favorites/data/models/favorite_model.dart';

import 'favorites_test_support.dart';

void main() {
  test('parses a saved product', () {
    final m = FavoriteModel.fromJson(favoriteJson());
    expect(m.barcode, 'b1');
    expect(m.brand, 'Britannia');
    expect(m.verdict, 'safe');
    expect(m.overallScore, 80);
  });

  test('added_at without a zone is UTC (the backend sends it that way)', () {
    expect(FavoriteModel.fromJson(favoriteJson(addedAt: '2026-10-16T08:41:00')).addedAt.toUtc(),
        DateTime.utc(2026, 10, 16, 8, 41));
  });

  test('missing optional fields are fine', () {
    final json = favoriteJson()
      ..['brand'] = null
      ..['verdict'] = null
      ..['overall_score'] = null;
    final m = FavoriteModel.fromJson(json);
    expect(m.brand, isNull);
    expect(m.verdict, isNull);
    expect(m.overallScore, isNull);
  });

  test('the barcode is URL-encoded in the path', () {
    expect(ApiConstants.favorite('8901'), '/favorites/8901');
    expect(ApiConstants.favorite('a b/c'), '/favorites/a%20b%2Fc');
  });
}
