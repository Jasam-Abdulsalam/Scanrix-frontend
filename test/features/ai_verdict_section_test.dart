import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/di/injection_container.dart';
import 'package:scanrix_frontend/core/error/exceptions.dart';
import 'package:scanrix_frontend/core/theme/app_theme_colors.dart';
import 'package:scanrix_frontend/features/products/domain/entities/ai_analysis_entity.dart';
import 'package:scanrix_frontend/features/products/domain/entities/safety_engine_entity.dart';
import 'package:scanrix_frontend/features/products/presentation/bloc/ai_analysis_bloc.dart';
import 'package:scanrix_frontend/features/products/presentation/widgets/ai_verdict_section.dart';

import 'ai_analysis_test_support.dart';

const _weak = SafetyEngine(coverage: 0.33, recognisedCount: 1, totalCount: 3);
const _strong = SafetyEngine(coverage: 0.9, recognisedCount: 9, totalCount: 10);
const _request = AiAnalysisRequest.barcode('8901');

Future<void> _pump(
  WidgetTester t, {
  required SafetyEngine? engine,
  String verdict = 'caution',
  AiAnalysis? initial,
  required FakeAnalyzeWithAi analyze,
  AiCredits? credits,
}) async {
  if (sl.isRegistered<AiAnalysisBloc>()) await sl.reset();
  sl.registerFactory(() => AiAnalysisBloc(analyzeWithAiUseCase: analyze, getAiCreditsUseCase: FakeGetAiCredits(credits)));
  addTearDown(sl.reset);
  t.view.physicalSize = const Size(1125, 6000);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        theme: ThemeData(extensions: const [AppThemeColors.darkGreen]),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AiVerdictSection(request: _request, engine: engine, verdict: verdict, initial: initial),
          ),
        ),
      ),
    ),
  );
  await t.pump();
}

FakeAnalyzeWithAi _ok() => FakeAnalyzeWithAi((_) async => sampleAnalysis);
final _credits = AiCredits(limit: 6, remaining: 4, resetsAt: DateTime.utc(2026, 10, 19));

void main() {
  group('when the button is offered', () {
    test('only for a weak database result', () {
      expect(AiVerdictSection.shouldOffer(engine: _weak, verdict: 'caution'), isTrue);
      expect(AiVerdictSection.shouldOffer(engine: _strong, verdict: 'unknown'), isTrue);
      expect(AiVerdictSection.shouldOffer(engine: null, verdict: 'unknown'), isTrue);
      expect(AiVerdictSection.shouldOffer(engine: _strong, verdict: 'safe'), isFalse);
      expect(AiVerdictSection.shouldOffer(engine: null, verdict: 'safe'), isFalse);
      expect(AiVerdictSection.shouldOffer(engine: const SafetyEngine(coverage: 0.7), verdict: 'safe'), isFalse);
    });

    testWidgets('a strong result shows nothing at all', (t) async {
      final analyze = _ok();
      await _pump(t, engine: _strong, verdict: 'safe', analyze: analyze);
      expect(find.text('Get AI verdict'), findsNothing);
      expect(find.textContaining('AI'), findsNothing);
      expect(analyze.calls, 0);
    });

    testWidgets('a weak result offers the button with the coverage and credit info', (t) async {
      await _pump(t, engine: _weak, analyze: _ok(), credits: _credits);
      await t.pump();
      expect(find.text('Not enough data for a full verdict'), findsOneWidget);
      expect(find.textContaining('Only 1 of 3 ingredients are in our database'), findsOneWidget);
      expect(find.text('Get AI verdict'), findsOneWidget);
      expect(find.text('Uses 1 AI credit · 4 of 6 left this week'), findsOneWidget);
    });
  });

  group('credits', () {
    testWidgets('no credits left: the button does nothing and says when they reset', (t) async {
      final analyze = _ok();
      await _pump(t, engine: _weak, analyze: analyze, credits: AiCredits(limit: 6, remaining: 0, resetsAt: DateTime.utc(2026, 10, 19, 12)));
      await t.pump();
      expect(find.textContaining('No AI credits left. They reset'), findsOneWidget);
      await t.tap(find.text('Get AI verdict'));
      await t.pump();
      expect(analyze.calls, 0);
    });
  });

  group('asking for the verdict', () {
    testWidgets('tap: loading, then an unverified AI card that never says "Safe"', (t) async {
      final completer = Completer<AiAnalysis>();
      final analyze = FakeAnalyzeWithAi((_) => completer.future);
      await _pump(t, engine: _weak, analyze: analyze, credits: _credits);

      await t.tap(find.text('Get AI verdict'));
      await t.pump();
      expect(find.text('Analysing with AI…'), findsOneWidget);
      expect(find.text('Get AI verdict'), findsNothing, reason: 'button is gone while loading: no double charge');

      completer.complete(const AiAnalysis(
        verdict: AiVerdict.good,
        score: 80,
        summary: 'Mostly simple ingredients.',
        concerns: [AiConcern(ingredient: 'Parfum', effect: 'may cause skin irritation')],
        positives: ['Short list'],
        adjustedByDatabase: true,
        disclaimer: 'AI-generated estimate. Not medical advice.',
      ));
      await t.pump();
      await t.pump();

      expect(analyze.calls, 1);
      expect(find.text('AI estimate · unverified'), findsOneWidget);
      expect(find.text('Low concern'), findsOneWidget);
      expect(find.text('80/100'), findsOneWidget);
      expect(find.text('Mostly simple ingredients.'), findsOneWidget);
      expect(find.textContaining('Parfum'), findsOneWidget);
      expect(find.text('Lowered to match a hazard in our database.'), findsOneWidget);
      expect(find.text('AI-generated estimate. Not medical advice.'), findsOneWidget);
      expect(find.textContaining('Safe'), findsNothing);
      expect(find.textContaining('safe'), findsNothing);
    });

    testWidgets('a cached analysis that came with the product is shown without asking', (t) async {
      final analyze = _ok();
      await _pump(t, engine: _strong, verdict: 'safe', initial: sampleAnalysis, analyze: analyze);
      expect(find.text('AI estimate · unverified'), findsOneWidget);
      expect(find.text('Get AI verdict'), findsNothing);
      expect(analyze.calls, 0);
    });
  });

  group('failures', () {
    Future<void> failWith(WidgetTester t, ServerException e) async {
      await _pump(t, engine: _weak, analyze: FakeAnalyzeWithAi((_) async => throw e), credits: _credits);
      await t.pump();
      await t.tap(find.text('Get AI verdict'));
      await t.pump();
      await t.pump();
    }

    testWidgets('no ingredient list: tells the user to scan the label, no retry button', (t) async {
      await failWith(t, const ServerException(message: 'm', statusCode: 422, code: 'ingredients_missing'));
      expect(find.text('No ingredient list yet'), findsOneWidget);
      expect(find.textContaining('scan the ingredients label'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('credits used up: says when they reset, no retry button', (t) async {
      await failWith(
        t,
        const ServerException(
          message: 'm',
          statusCode: 429,
          code: 'ai_credits_exhausted',
          details: {'resets_at': '2026-10-19T00:00:00Z'},
        ),
      );
      expect(find.text('No AI credits left'), findsOneWidget);
      expect(find.textContaining('used all AI credits for this week'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('AI unavailable: says the user was not charged and offers Try again', (t) async {
      await failWith(t, const ServerException(message: 'raw server text', statusCode: 503, code: 'ai_unavailable'));
      expect(find.textContaining('You were not charged'), findsOneWidget);
      expect(find.text('raw server text'), findsNothing, reason: 'known failures use our own wording');
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  test('reset date formatting', () {
    expect(formatResetDate(DateTime(2026, 10, 19, 12)), 'Mon 19 Oct');
  });
}
