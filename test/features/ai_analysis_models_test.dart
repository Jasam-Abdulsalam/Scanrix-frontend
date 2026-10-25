import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/features/products/data/models/ai_analysis_model.dart';
import 'package:scanrix_frontend/features/products/data/models/product_model.dart';
import 'package:scanrix_frontend/features/products/domain/entities/ai_analysis_entity.dart';

import 'ai_analysis_test_support.dart';

void main() {
  test('parses a full backend response', () {
    final a = AiAnalysisModel.fromJson(aiAnalysisJson());
    expect(a.verdict, AiVerdict.caution);
    expect(a.score, 55);
    expect(a.concerns.single.ingredient, 'Parfum');
    expect(a.positives, ['Short ingredient list']);
    expect(a.certainty, AiCertainty.uncertain);
    expect(a.creditsRemaining, 4);
    expect(a.generatedAt, DateTime.utc(2026, 10, 14, 10));
  });

  test('an unrecognised verdict can never become "good"', () {
    for (final v in [null, 'safe', 'great', 7, '']) {
      expect(AiAnalysisModel.fromJson({...aiAnalysisJson(), 'verdict': v}).verdict, AiVerdict.unknown, reason: '$v');
    }
  });

  test('is lenient: missing fields, wrong types and out-of-range scores never throw', () {
    final a = AiAnalysisModel.fromJson({'verdict': 'avoid', 'score': 500, 'concerns': 'x', 'positives': [1, 'ok']});
    expect(a.score, 100);
    expect(a.concerns, isEmpty);
    expect(a.positives, ['ok']);
    expect(a.summary, '');
    expect(AiAnalysisModel.fromJson({'score': -5}).score, 0);
    expect(AiAnalysisModel.tryParse(null), isNull);
    expect(AiAnalysisModel.tryParse('nope'), isNull);
  });

  test('concerns with empty parts are dropped', () {
    final a = AiAnalysisModel.fromJson({
      ...aiAnalysisJson(),
      'concerns': [
        {'ingredient': '', 'effect': 'x'},
        {'ingredient': 'Parfum', 'effect': 'may irritate'},
        'junk',
      ],
    });
    expect(a.concerns.map((c) => c.ingredient), ['Parfum']);
  });

  test('credits parse and never exceed the limit', () {
    final c = AiCreditsModel.fromJson({'limit': 6, 'remaining': 9, 'resets_at': '2026-10-19T00:00:00Z'});
    expect(c.limit, 6);
    expect(c.remaining, 6);
    expect(c.resetsAt, DateTime.utc(2026, 10, 19));
  });

  test('request body has exactly one source', () {
    expect(const AiAnalysisRequest.barcode('8901').toJson(), {'barcode': '8901'});
    expect(const AiAnalysisRequest.text('water, sugar', category: 'cosmetic').toJson(),
        {'ingredients_text': 'water, sugar', 'category': 'cosmetic'});
  });

  test('GET /products/{barcode} carries the cached AI analysis; absent means null', () {
    Map<String, dynamic> product() => {
          'id': '1',
          'barcode': '8901',
          'name': 'Face wash',
          'brand': 'X',
          'category': 'cosmetic',
          'ingredients': <dynamic>[],
          'verdict': 'unknown',
          'source': 'openfoodfacts',
          'created_at': '2026-10-14T10:00:00Z',
        };
    expect(ProductModel.fromJson({...product(), 'ai_analysis': aiAnalysisJson()}).aiAnalysis?.verdict, AiVerdict.caution);
    expect(ProductModel.fromJson(product()).aiAnalysis, isNull);
    expect(ProductModel.fromJson({...product(), 'ai_analysis': null}).aiAnalysis, isNull);
  });
}
