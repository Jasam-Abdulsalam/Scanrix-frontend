import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/error/exceptions.dart';
import 'package:scanrix_frontend/core/network/api_client.dart';
import 'package:scanrix_frontend/core/theme/app_theme_colors.dart';
import 'package:scanrix_frontend/features/natural_remedy/data/models/natural_remedy_model.dart';
import 'package:scanrix_frontend/features/natural_remedy/domain/entities/natural_remedy_entity.dart';
import 'package:scanrix_frontend/features/natural_remedy/domain/usecases/get_natural_remedy_usecase.dart';
import 'package:scanrix_frontend/features/natural_remedy/presentation/bloc/natural_remedy_bloc.dart';
import 'package:scanrix_frontend/features/natural_remedy/presentation/bloc/natural_remedy_event.dart';
import 'package:scanrix_frontend/features/natural_remedy/presentation/bloc/natural_remedy_state.dart';
import 'package:scanrix_frontend/features/natural_remedy/presentation/widgets/remedy_sections.dart';
import 'package:scanrix_frontend/features/products/domain/entities/ai_analysis_entity.dart';

class _FakeGetRemedy implements GetNaturalRemedyUseCase {
  final NaturalRemedyResult? result;
  final Object? error;
  final Duration latency;
  int calls = 0;

  _FakeGetRemedy({this.result, this.error, this.latency = Duration.zero});

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<NaturalRemedyResult> call(AiAnalysisRequest request) async {
    calls++;
    await Future<void>.delayed(latency);
    if (error != null) throw error!;
    return result!;
  }
}

Map<String, dynamic> _json() => {
      'product_type': 'foaming face wash',
      'remedies': [
        {
          'name': 'Besan and rose water cleanser',
          'replaces': 'face wash',
          'ingredients': [
            {'item': 'besan', 'amount': '2 tsp'},
            {'item': 'rose water', 'amount': '1 tbsp'},
            {'amount': 'no item: dropped'},
          ],
          'steps': ['Mix to a smooth paste.', 'Massage gently, rinse.', 7],
          'how_often': 'Once a day',
          'keeps_for': 'Make fresh each time',
          'why': 'Cleans without sulfates.',
          'caution': null,
        },
        {'name': 'No steps', 'ingredients': [{'item': 'x'}], 'steps': []},
        'junk',
      ],
      'no_remedy_reason': null,
      'cached': false,
      'credits_remaining': 3,
      'disclaimer': 'AI suggestion.',
      'patch_test_note': 'Patch test first.',
    };

const _request = AiAnalysisRequest.barcode('8901');

void main() {
  group('NaturalRemedyResultModel', () {
    test('parses the backend response and drops unusable remedies', () {
      final r = NaturalRemedyResultModel.fromJson(_json());
      expect(r.productType, 'foaming face wash');
      expect(r.remedies.map((x) => x.name), ['Besan and rose water cleanser']);
      final first = r.remedies.first;
      expect(first.ingredients, const [
        RemedyIngredient(item: 'besan', amount: '2 tsp'),
        RemedyIngredient(item: 'rose water', amount: '1 tbsp'),
      ]);
      expect(first.steps, ['Mix to a smooth paste.', 'Massage gently, rinse.']);
      expect(first.caution, isNull);
      expect(r.creditsRemaining, 3);
      expect(r.patchTestNote, 'Patch test first.');
    });

    test('missing fields never throw and the patch test note is never empty', () {
      final r = NaturalRemedyResultModel.fromJson({'remedies': 'nope', 'no_remedy_reason': 'Sunscreen.'});
      expect(r.remedies, isEmpty);
      expect(r.noRemedyReason, 'Sunscreen.');
      expect(r.patchTestNote, kDefaultPatchTestNote);
      expect(r.disclaimer, isNotEmpty);
    });

    test('credit hint', () {
      const base = NaturalRemedyResult(productType: 'x', disclaimer: 'd', patchTestNote: 'p');
      expect(remedyCreditHint(const NaturalRemedyResult(
          productType: 'x', disclaimer: 'd', patchTestNote: 'p', cached: true)), 'Saved answer · no credit used');
      expect(remedyCreditHint(base), 'Used 1 AI credit');
      expect(remedyCreditHint(const NaturalRemedyResult(
          productType: 'x', disclaimer: 'd', patchTestNote: 'p', creditsRemaining: 2)), 'Used 1 AI credit · 2 left this week');
    });
  });

  group('NaturalRemedyBloc', () {
    Future<NaturalRemedyFailure> failWith(Object error) async {
      final b = NaturalRemedyBloc(getNaturalRemedyUseCase: _FakeGetRemedy(error: error));
      b.add(const NaturalRemedyRequested(_request));
      final s = await b.stream.firstWhere((s) => s is NaturalRemedyFailure) as NaturalRemedyFailure;
      await b.close();
      return s;
    }

    test('loaded', () async {
      final result = NaturalRemedyResultModel.fromJson(_json());
      final b = NaturalRemedyBloc(getNaturalRemedyUseCase: _FakeGetRemedy(result: result));
      b.add(const NaturalRemedyRequested(_request));
      expect(await b.stream.firstWhere((s) => s is NaturalRemedyLoaded), NaturalRemedyLoaded(result));
      await b.close();
    });

    test('failures map to kinds; only retryable ones offer a retry', () async {
      final credits = await failWith(const ServerException(
          message: 'x', statusCode: 429, code: 'ai_credits_exhausted', details: {'resets_at': '2030-01-07T00:00:00+00:00'}));
      expect(credits.kind, NaturalRemedyFailureKind.creditsExhausted);
      expect(credits.resetsAt, DateTime.utc(2030, 1, 7));
      expect(credits.canRetry, isFalse);

      final down = await failWith(const ServerException(message: 'x', statusCode: 503, code: 'ai_unavailable'));
      expect(down.kind, NaturalRemedyFailureKind.unavailable);
      expect(down.message, contains('not charged'));
      expect(down.canRetry, isTrue);

      expect((await failWith(const ServerException(message: 'x', statusCode: 422, code: 'not_cosmetic'))).kind,
          NaturalRemedyFailureKind.notCosmetic);
      expect((await failWith(const ServerException(message: 'x', statusCode: 422, code: 'ingredients_missing'))).kind,
          NaturalRemedyFailureKind.ingredientsMissing);
      expect((await failWith(const NetworkException())).kind, NaturalRemedyFailureKind.network);
    });

    test('a double tap fires one request (droppable)', () async {
      final fake = _FakeGetRemedy(
          result: NaturalRemedyResultModel.fromJson(_json()), latency: const Duration(milliseconds: 30));
      final b = NaturalRemedyBloc(getNaturalRemedyUseCase: fake);
      b
        ..add(const NaturalRemedyRequested(_request))
        ..add(const NaturalRemedyRequested(_request));
      await b.stream.firstWhere((s) => s is NaturalRemedyLoaded);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fake.calls, 1);
      await b.close();
    });
  });

  testWidgets('recipe list shows the patch test, ingredients and numbered steps', (tester) async {
    tester.view
      ..physicalSize = const Size(375, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        theme: ThemeData(extensions: const [AppThemeColors.darkGreen]),
        home: Scaffold(body: RemedyRecipeList(result: NaturalRemedyResultModel.fromJson(_json()))),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Patch test first'), findsOneWidget);
    expect(find.text('Besan and rose water cleanser'), findsOneWidget);
    expect(find.text('Instead of your face wash'), findsOneWidget);
    expect(find.text('besan'), findsOneWidget);
    expect(find.text('2 tsp'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // step number
    expect(find.text('Massage gently, rinse.'), findsOneWidget);
    expect(find.text('Used 1 AI credit · 3 left this week'), findsOneWidget);
  });
}
