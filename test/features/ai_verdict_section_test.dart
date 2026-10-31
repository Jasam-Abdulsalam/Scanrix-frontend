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
import 'package:scanrix_frontend/features/products/presentation/widgets/ai_verdict_style.dart';

import 'ai_analysis_test_support.dart';

const _weak = SafetyEngine(coverage: 0.33, recognisedCount: 1, totalCount: 3);
const _strong = SafetyEngine(coverage: 0.9, recognisedCount: 9, totalCount: 10);
const _request = AiAnalysisRequest.barcode('8901');

/// Advances real frames (pumpAndSettle would never return: the thinking orb loops).
Future<void> _frames(WidgetTester t, {int ms = 1000}) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _back(WidgetTester t) async {
  t.state<NavigatorState>(find.byType(Navigator)).pop();
  await _frames(t);
}

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
      expect(find.textContaining('Only 1 of 3 known'), findsOneWidget);
      expect(find.text('Get AI verdict'), findsOneWidget);
      expect(find.textContaining('4 of 6 left'), findsOneWidget);
    });
  });

  group('credits', () {
    testWidgets('no credits left: the button does nothing and says when they reset', (t) async {
      final analyze = _ok();
      await _pump(t, engine: _weak, analyze: analyze, credits: AiCredits(limit: 6, remaining: 0, resetsAt: DateTime.utc(2026, 10, 19, 12)));
      await t.pump();
      expect(find.textContaining('resets '), findsOneWidget);
      await t.tap(find.text('Get AI verdict'));
      await t.pump();
      expect(analyze.calls, 0);
    });
  });

  group('asking for the verdict', () {
    testWidgets('tap: opens the AI screen, thinking, then an unverified result that never says "Safe"', (t) async {
      final completer = Completer<AiAnalysis>();
      final analyze = FakeAnalyzeWithAi((_) => completer.future);
      await _pump(t, engine: _weak, analyze: analyze, credits: _credits);

      await t.tap(find.text('Get AI verdict'));
      await t.pump();
      await _frames(t, ms: 500);
      expect(find.text('AI verdict'), findsOneWidget, reason: 'the full-screen page is open');
      expect(find.text('Reading the ingredient list…'), findsOneWidget);

      completer.complete(const AiAnalysis(
        verdict: AiVerdict.good,
        score: 80,
        summary: 'Mostly simple ingredients.',
        concerns: [
          AiConcern(ingredient: 'parfum', effect: 'may cause skin irritation'),
          AiConcern(ingredient: 'perfuwe', effect: 'unknown'),
          AiConcern(ingredient: '2319', effect: 'Unknown'),
        ],
        positives: ['Short list'],
        adjustedByDatabase: true,
        disclaimer: 'AI-generated estimate. Not medical advice.',
      ));
      await t.pump();
      await _frames(t, ms: 2000);

      expect(analyze.calls, 1);
      expect(find.text('AI estimate · unverified'), findsOneWidget);
      expect(find.text('Low concern'), findsOneWidget);
      expect(find.text('80'), findsOneWidget);
      expect(find.text('Mostly simple ingredients.'), findsOneWidget);
      expect(find.text('Parfum'), findsOneWidget);
      expect(find.text('May cause skin irritation'), findsOneWidget);
      expect(find.textContaining('lowered this verdict'), findsOneWidget);
      expect(find.text('AI-generated estimate. Not medical advice.'), findsOneWidget);
      expect(find.textContaining('Safe'), findsNothing);
      expect(find.textContaining('safe'), findsNothing);

      // Unidentified names are not concerns: they sit behind the Unclear tile, in a sheet.
      expect(find.text('Biggest concern'), findsOneWidget);
      expect(find.text('perfuwe'), findsNothing);
      await t.tap(find.text('Unclear'));
      await _frames(t, ms: 600);
      expect(find.text("2 ingredients couldn't be identified"), findsOneWidget);
      expect(find.text('perfuwe'), findsOneWidget);
      await _back(t); // close the sheet
      expect(find.text('perfuwe'), findsNothing);

      // Back on the product page the answer is one compact row.
      await _back(t);
      expect(find.text('AI verdict'), findsNothing);
      expect(find.text('Low concern'), findsOneWidget);
      expect(find.text('AI estimate · unverified'), findsOneWidget);
    });

    testWidgets('going back mid-request keeps it running; the row reopens the screen', (t) async {
      final completer = Completer<AiAnalysis>();
      final analyze = FakeAnalyzeWithAi((_) => completer.future);
      await _pump(t, engine: _weak, analyze: analyze, credits: _credits);

      await t.tap(find.text('Get AI verdict'));
      await _frames(t, ms: 500);
      await _back(t);
      expect(find.text('Analysing with AI…'), findsOneWidget);

      await t.tap(find.text('Analysing with AI…'));
      await _frames(t, ms: 500);
      expect(find.text('AI verdict'), findsOneWidget);
      completer.complete(sampleAnalysis);
      await t.pump();
      await _frames(t, ms: 2000);
      expect(find.text('Use with caution'), findsOneWidget);
      expect(analyze.calls, 1, reason: 'reopening never sends a second paid request');
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
      await t.pump(const Duration(seconds: 1));
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
