import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/bold_card.dart';
import '../../domain/entities/ingredient_entity.dart';
import '../../domain/entities/safety_engine_entity.dart';
import '../pages/ingredients_breakdown_page.dart';
import 'highlight_row.dart';
import 'severity_style.dart';
import 'status_colors.dart';

const _maxNamed = 3;

/// The summary card under the gauge. With a [SafetyEngine] every row is built
/// from findings (Watch out / Good ingredients / coverage); without one
/// (older cached barcode result) it falls back to the legacy per-ingredient
/// `concerns` rows so those products still render.
class AnalysisHighlightsCard extends StatelessWidget {
  final SafetyEngine? safetyEngine;
  final List<IngredientEntity> legacyIngredients;

  /// Opens the ingredient breakdown screen on the given tab (engine rows only).
  final void Function(BreakdownTab tab)? onOpenTab;

  const AnalysisHighlightsCard({
    super.key,
    this.safetyEngine,
    this.legacyIngredients = const [],
    this.onOpenTab,
    this.progress,
  });

  /// The screen's entrance animation: the counts tick up with it.
  final Animation<double>? progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (safetyEngine != null) return _enginePills(safetyEngine!, colors);
    final rows = _legacyRows(legacyIngredients, colors);
    if (rows.isEmpty) return const SizedBox.shrink();

    return BoldCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) RowDivider(colors: colors),
            rows[i],
          ],
        ],
      ),
    );
  }

  /// One card, three columns (Watch out | Good | Not assessed), each opening
  /// the matching tab of the breakdown screen. Empty groups stay visible but
  /// dimmed, so the layout never shifts between products.
  Widget _enginePills(SafetyEngine engine, AppThemeColors colors) {
    final flagged = engine.flagged..sort((a, b) => b.severity.index.compareTo(a.severity.index));
    // The engine's findings are the single source: the OCR response's
    // `unknown_ingredients` names the same unmatched items (spelled cleaner),
    // so adding them would count some twice.
    final notAssessed = engine.notAssessed.length;
    VoidCallback? open(BreakdownTab t) => onOpenTab == null ? null : () => onOpenTab!(t);
    return StatColumnsCard(
      progress: progress,
      columns: [
        StatColumnData(
          icon: Icons.warning_rounded,
          label: 'Watch out',
          count: flagged.length,
          color: flagged.isNotEmpty ? flagged.first.severity.color(colors) : kWarnAmber,
          onTap: open(BreakdownTab.watchOut),
        ),
        StatColumnData(
          icon: Icons.check_rounded,
          label: 'Good',
          count: engine.clear.length,
          color: colors.neonEmerald,
          onTap: open(BreakdownTab.good),
        ),
        StatColumnData(
          icon: Icons.question_mark_rounded,
          label: 'Not assessed',
          count: notAssessed,
          color: colors.secondaryText,
          onTap: open(BreakdownTab.notAssessed),
        ),
      ],
    );
  }

  List<Widget> _legacyRows(List<IngredientEntity> ingredients, AppThemeColors colors) {
    final concerning = ingredients.where((i) => i.concerns.isNotEmpty).toList();
    final good = ingredients.where((i) => i.concerns.isEmpty).toList();
    return [
      HighlightRow(
        icon: Icons.science_rounded,
        iconColor: colors.neonEmerald,
        title: 'Good Ingredients',
        subtitle: good.isNotEmpty
            ? 'Contains ${good.take(_maxNamed).map((i) => i.name).join(', ')}.'
            : 'No standout beneficial ingredients found.',
        colors: colors,
      ),
      if (concerning.isNotEmpty)
        HighlightRow(
          icon: Icons.warning_rounded,
          iconColor: kWarnAmber,
          title: 'Watch out',
          subtitle: 'Contains ${concerning.first.name} which may ${concerning.first.concerns.first}.',
          colors: colors,
        ),
    ];
  }
}
