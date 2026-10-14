import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/features/products/data/models/product_model.dart';
import 'package:scanrix_frontend/features/products/data/models/safety_engine_model.dart';
import 'package:scanrix_frontend/features/products/domain/entities/safety_engine_entity.dart';
import 'package:scanrix_frontend/features/scan/data/models/scan_result_model.dart';
import 'package:scanrix_frontend/features/scan/data/models/text_analysis_model.dart';

const safetyEngineJson = {
  'ruleset_version': '2026.05',
  'coverage': 0.67,
  'recognised_count': 2,
  'total_count': 3,
  'overall_severity': 'high',
  'disclaimer': 'Not medical advice.',
  'future_unknown_key': {'a': 1},
  'dimensions': {
    'cancer_class': {
      'dimension': 'cancer_class',
      'worst_severity': 'high',
      'flagged_ingredients': ['Butylated Hydroxyanisole'],
      'findings_count': 1,
    },
  },
  'findings': [
    {
      'raw_name': 'BHA',
      'canonical_name': 'Butylated Hydroxyanisole',
      'matched': true,
      'match_type': 'exact',
      'confidence': 1.0,
      'severity': 'high',
      'evidence_tier': 2,
      'flags': ['IARC Group 2B'],
      'facts': [
        {'k': 'v'}
      ],
    },
    {
      'raw_name': 'Water',
      'canonical_name': 'Water',
      'matched': true,
      'match_type': 'exact',
      'confidence': 1,
      'severity': 'none',
      'evidence_tier': null,
      'flags': [],
      'facts': [],
    },
    {
      'raw_name': 'Zorbex-9',
      'canonical_name': null,
      'matched': false,
      'match_type': 'unknown',
      'confidence': 0.0,
      'severity': 'none',
      'evidence_tier': null,
      'flags': [],
      'facts': [],
    },
  ],
};

const textAnalysisJson = {
  'success': true,
  'verdict': 'avoid',
  'overall_score': 32,
  'summary': 'Contains an ingredient classified as possibly carcinogenic.',
  'unknown_ingredients': ['Zorbex-9'],
  'safety_engine': safetyEngineJson,
};

Map<String, dynamic> productJson() => {
      'id': 'p1',
      'barcode': '123',
      'name': 'Chips',
      'brand': 'Acme',
      'category': 'food',
      'verdict': 'caution',
      'source': 'db',
      'created_at': '2026-01-01T00:00:00Z',
    };

void main() {
  group('TextAnalysisModel', () {
    test('parses the new top-level shape (no "analysis" wrapper)', () {
      final a = TextAnalysisModel.fromJson(Map<String, dynamic>.from(textAnalysisJson));
      expect(a.verdict, 'avoid');
      expect(a.overallScore, 32);
      expect(a.unknownIngredients, ['Zorbex-9']);
      final se = a.safetyEngine!;
      expect(se.rulesetVersion, '2026.05');
      expect(se.recognisedCount, 2);
      expect(se.totalCount, 3);
      expect(se.coverage, closeTo(0.67, 1e-9));
      expect(se.overallSeverity, SafetySeverity.high);
      expect(se.dimensions['cancer_class']!.flaggedIngredients, ['Butylated Hydroxyanisole']);
      expect(se.findings, hasLength(3));
      expect(se.findings.first.evidenceTier, 2);
      expect(se.findings.first.flags, ['IARC Group 2B']);
    });

    test('classifies findings: flagged / clear / not assessed', () {
      final se = TextAnalysisModel.fromJson(Map<String, dynamic>.from(textAnalysisJson)).safetyEngine!;
      expect(se.flagged.map((f) => f.rawName), ['BHA']);
      expect(se.clear.map((f) => f.rawName), ['Water']);
      // Unmatched with severity "none" must NOT count as clear.
      expect(se.notAssessed.map((f) => f.rawName), ['Zorbex-9']);
    });

    test('empty / minimal / null-ish payloads do not throw', () {
      final empty = TextAnalysisModel.fromJson({});
      expect(empty.verdict, 'unknown');
      expect(empty.overallScore, isNull);
      expect(empty.safetyEngine, isNull);
      expect(empty.unknownIngredients, isEmpty);

      final weird = TextAnalysisModel.fromJson({
        'verdict': 'safe',
        'overall_score': 80.0, // num, not int
        'unknown_ingredients': ['a', 1, null],
        'safety_engine': {
          'dimensions': {'x': 'not-a-map'},
          'findings': [null, 'str', {'raw_name': 'Foo', 'severity': 'galactic', 'flags': 'oops'}],
        },
      });
      expect(weird.overallScore, 80);
      expect(weird.unknownIngredients, ['a']);
      final f = weird.safetyEngine!.findings.single;
      expect(f.matched, isFalse);
      expect(f.severity, SafetySeverity.unknown);
      expect(f.flags, isEmpty);
      expect(f.isClear, isFalse);
    });

    test('unrecognised severity is never treated as clear', () {
      final f = IngredientFindingModel.fromJson({'raw_name': 'x', 'matched': true, 'severity': 'new_level'});
      expect(f.isClear, isFalse);
      expect(f.isNotAssessed, isTrue);
    });
  });

  group('barcode flow', () {
    test('safety_engine sibling of "product" ends up on the product', () {
      final r = ScanResultModel.fromJson({'product': productJson(), 'safety_engine': safetyEngineJson});
      expect(r.product.safetyEngine, isNotNull);
      expect(r.product.safetyEngine!.findings, hasLength(3));
    });

    test('safety_engine null or absent => product.safetyEngine null', () {
      expect(ScanResultModel.fromJson({'product': productJson(), 'safety_engine': null}).product.safetyEngine, isNull);
      expect(ScanResultModel.fromJson({'product': productJson()}).product.safetyEngine, isNull);
    });

    test('ProductModel reads an embedded safety_engine (GET /products shape)', () {
      final p = ProductModel.fromJson({...productJson(), 'safety_engine': safetyEngineJson});
      expect(p.safetyEngine, isNotNull);
    });
  });
}
