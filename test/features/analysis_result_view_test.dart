import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/theme/app_theme_colors.dart';
import 'package:scanrix_frontend/features/products/data/models/safety_engine_model.dart';
import 'package:scanrix_frontend/features/products/domain/entities/safety_engine_entity.dart';
import 'package:scanrix_frontend/features/products/presentation/widgets/analysis_result_view.dart';
import 'package:scanrix_frontend/features/products/presentation/widgets/severity_style.dart';
import 'package:scanrix_frontend/features/scan/domain/entities/text_analysis_entity.dart';
import 'package:scanrix_frontend/features/scan/presentation/pages/ingredient_analysis_result_page.dart';
import 'package:scanrix_frontend/features/scan/presentation/widgets/scan_category.dart';

import 'safety_engine_models_test.dart' show safetyEngineJson;

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        theme: ThemeData(extensions: const [AppThemeColors.darkGreen]),
        home: Scaffold(body: child),
      ),
    );

Future<void> _pump(WidgetTester t, Widget view) async {
  // The test font (Ahem) is far wider than the real one and can overflow
  // fixed-width rows. Ignore only that class of error; everything else still
  // fails the test.
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
  await t.pumpAndSettle(); // entrance animation: ring fill and count-up
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
      ),
    );

    // One card, three columns: label and count are separate texts.
    expect(find.bySemanticsLabel('1 Watch out'), findsOneWidget);
    expect(find.bySemanticsLabel('1 Good'), findsOneWidget);
    expect(find.bySemanticsLabel('1 Not assessed'), findsOneWidget);
    expect(find.text('Not medical advice.'), findsOneWidget);
    // Moved off this screen.
    expect(find.textContaining('Not assessed ('), findsNothing);
    expect(find.text('Zorbex-9'), findsNothing);
    expect(find.text('See Full Analysis'), findsNothing);
    // Removed unsupported claims.
    expect(find.textContaining('Non-comedogenic'), findsNothing);
    expect(find.textContaining('Safe for'), findsNothing);
    expect(find.textContaining('angerous'), findsNothing);
  });

  testWidgets('label scan: an unmatched name is counted once, even when unknown_ingredients spells it cleaner',
      (t) async {
    // The backend reports each unmatched ingredient twice: raw OCR text in the
    // engine findings ("ZORBEX-9 (AND)") and the cleaned name in
    // unknown_ingredients ("zorbex-9"). Merging both used to count it twice.
    final json = Map<String, dynamic>.from(safetyEngineJson);
    json['findings'] = [
      for (final f in safetyEngineJson['findings'] as List)
        (f as Map)['raw_name'] == 'Zorbex-9' ? {...f, 'raw_name': 'ZORBEX-9 (AND)'} : f,
    ];
    await _pump(
      t,
      IngredientAnalysisResultPage(
        analysis: TextAnalysisEntity(
          verdict: 'avoid',
          overallScore: 32,
          summary: 'summary text',
          unknownIngredients: const ['zorbex-9'],
          safetyEngine: SafetyEngineModel.fromJson(json),
        ),
        category: ScanCategory.cosmetics,
      ),
    );
    expect(find.bySemanticsLabel('1 Not assessed'), findsOneWidget);
  });

  testWidgets('tapping a pill opens the breakdown on its tab', (t) async {
    await _pump(
      t,
      AnalysisResultView(
        verdict: 'avoid',
        overallScore: 32,
        summary: 'summary text',
        safetyEngine: SafetyEngineModel.fromJson(safetyEngineJson),
      ),
    );
    await t.tap(find.text('Watch out'));
    await t.pumpAndSettle();
    expect(find.text('Evidence: IARC / Prop 65'), findsOneWidget);
    await t.tap(find.text('Not assessed (1)'));
    await t.pumpAndSettle();
    expect(find.text('Zorbex-9'), findsOneWidget);
  });

  testWidgets('Add to My Routine only for cosmetics; View Alternatives always', (t) async {
    await _pump(t, const AnalysisResultView(verdict: 'safe', overallScore: 85, summary: 'ok', category: 'Food'));
    expect(find.byTooltip('Add to My Routine'), findsNothing);
    expect(find.byTooltip('View alternatives'), findsOneWidget);
    await _pump(t, const AnalysisResultView(verdict: 'safe', overallScore: 85, summary: 'ok', category: 'Cosmetic'));
    expect(find.byTooltip('Add to My Routine'), findsOneWidget);
  });

  testWidgets('action labels are never cut off: the pills stack when the labels do not fit side by side',
      (t) async {
    // The test font is much wider than the real one, so the labels can't fit
    // in two halves here: this checks the fallback (stack, full labels).
    bool clipped(String text) => t.renderObject<RenderParagraph>(find.text(text)).didExceedMaxLines;
    await _pump(t, const AnalysisResultView(verdict: 'safe', overallScore: 85, summary: 'ok', category: 'Cosmetic'));
    expect(clipped('Alternatives'), isFalse);
    expect(clipped('Add to routine'), isFalse);
    final alt = t.getTopLeft(find.byTooltip('View alternatives'));
    final routine = t.getTopLeft(find.byTooltip('Add to My Routine'));
    expect(routine.dy, greaterThan(alt.dy), reason: 'stacked: main action first');
  });

  testWidgets('no heart without a handler (label scans have no product to save)', (t) async {
    await _pump(t, const AnalysisResultView(verdict: 'safe', overallScore: 85, summary: 'ok'));
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    await _pump(t, AnalysisResultView(verdict: 'safe', overallScore: 85, summary: 'ok', onFavorite: () {}, isFavorite: true));
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('label scan (no product): "Label scan" header, no product card; a product shows its card', (t) async {
    await _pump(t, const AnalysisResultView(verdict: 'caution', overallScore: 55, summary: 'ok', category: 'Cosmetics'));
    expect(find.text('Label scan'), findsOneWidget);
    expect(find.text('Label scan · Cosmetics'), findsOneWidget);
    expect(find.text('Unidentified Product'), findsNothing);
    expect(find.byIcon(Icons.inventory_2_outlined), findsNothing);

    await _pump(
      t,
      const AnalysisResultView(verdict: 'caution', overallScore: 55, summary: 'ok', productName: 'Himalaya Neem Face Wash'),
    );
    expect(find.text('Label scan'), findsNothing);
    expect(find.text('Database result'), findsOneWidget);
    expect(find.text('Himalaya'), findsOneWidget);
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
