import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/theme/app_theme_colors.dart';
import 'package:scanrix_frontend/features/products/data/models/safety_engine_model.dart';
import 'package:scanrix_frontend/features/products/domain/entities/safety_engine_entity.dart';
import 'package:scanrix_frontend/features/products/presentation/widgets/analysis_result_view.dart';
import 'package:scanrix_frontend/features/products/presentation/widgets/severity_style.dart';

import 'safety_engine_models_test.dart' show safetyEngineJson;

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        theme: ThemeData(extensions: const [AppThemeColors.darkGreen]),
        home: Scaffold(body: child),
      ),
    );

Future<void> _pump(WidgetTester t, Widget view) async {
  // The test font (Ahem) is far wider than the real one, which overflows the
  // pre-existing "Analyzed Product" pill in the hero. Ignore only that class
  // of error; everything else still fails the test.
  final original = FlutterError.onError;
  FlutterError.onError = (d) {
    if (d.exceptionAsString().contains('overflowed')) return;
    original?.call(d);
  };
  addTearDown(() => FlutterError.onError = original);
  t.view.physicalSize = const Size(1125, 15000);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(_host(view));
}

void main() {
  testWidgets('result screen stays short: summary rows only, lists live on the breakdown page', (t) async {
    await _pump(
      t,
      AnalysisResultView(
        verdict: 'avoid',
        overallScore: 32,
        summary: 'summary text',
        safetyEngine: SafetyEngineModel.fromJson(safetyEngineJson),
        unknownIngredients: const ['Zorbex-9', 'Mystery Gum'],
      ),
    );

    expect(find.text('1 Watch out'), findsOneWidget);
    expect(find.textContaining(' Good'), findsOneWidget);
    expect(find.text('2 Not assessed'), findsOneWidget);
    expect(find.text('Not medical advice.'), findsOneWidget);
    // Moved off this screen.
    expect(find.textContaining('Not assessed ('), findsNothing);
    expect(find.text('Mystery Gum'), findsNothing);
    expect(find.text('See Full Analysis'), findsNothing);
    // Removed unsupported claims.
    expect(find.textContaining('Non-comedogenic'), findsNothing);
    expect(find.textContaining('Safe for'), findsNothing);
    expect(find.textContaining('angerous'), findsNothing);
  });

  testWidgets('tapping a pill opens the breakdown on its tab', (t) async {
    await _pump(
      t,
      AnalysisResultView(
        verdict: 'avoid',
        overallScore: 32,
        summary: 'summary text',
        safetyEngine: SafetyEngineModel.fromJson(safetyEngineJson),
        unknownIngredients: const ['Zorbex-9', 'Mystery Gum'],
      ),
    );
    await t.tap(find.text('1 Watch out'));
    await t.pumpAndSettle();
    expect(find.text('Evidence: IARC / Prop 65'), findsOneWidget);
    await t.tap(find.text('Not assessed (2)'));
    await t.pumpAndSettle();
    expect(find.text('Mystery Gum'), findsOneWidget);
  });

  testWidgets('Add to My Routine only for cosmetics; View Alternatives always', (t) async {
    await _pump(t, const AnalysisResultView(verdict: 'safe', overallScore: 85, summary: 'ok', category: 'Food'));
    expect(find.text('Add to My Routine'), findsNothing);
    expect(find.text('View Alternatives'), findsOneWidget);
    await _pump(t, const AnalysisResultView(verdict: 'safe', overallScore: 85, summary: 'ok', category: 'Cosmetic'));
    expect(find.text('Add to My Routine'), findsOneWidget);
  });

  testWidgets('null safetyEngine falls back without crashing', (t) async {
    await _pump(t, const AnalysisResultView(verdict: 'safe', overallScore: 85, summary: 'ok'));
    expect(find.text('85'), findsOneWidget);
    expect(find.text('ok'), findsOneWidget);
  });

  group('SeverityStyle', () {
    const c = AppThemeColors.darkGreen;
    test('none is emerald only when matched; unmatched is grey', () {
      expect(SafetySeverity.none.color(c), c.neonEmerald);
      expect(SafetySeverity.none.color(c, matched: false), c.secondaryText);
      expect(SafetySeverity.unknown.color(c), c.secondaryText);
    });
  });
}
