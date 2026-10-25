import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/ingredient_entity.dart';
import '../../domain/entities/safety_engine_entity.dart';
import '../pages/ingredients_breakdown_page.dart';
import 'highlight_row.dart';
import 'not_assessed_section.dart';
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

  /// OCR response's extra names the database couldn't match (counted as not assessed).
  final List<String> unknownIngredients;

  const AnalysisHighlightsCard({
    super.key,
    this.safetyEngine,
    this.legacyIngredients = const [],
    this.onOpenTab,
    this.unknownIngredients = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (safetyEngine != null) return _enginePills(safetyEngine!, colors);
    final rows = _legacyRows(legacyIngredients, colors);
    if (rows.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
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

  /// Three tappable pills instead of a card: only the non-empty groups show
  /// (Good always), each opening the matching tab of the breakdown screen.
  Widget _enginePills(SafetyEngine engine, AppThemeColors colors) {
    final flagged = engine.flagged..sort((a, b) => b.severity.index.compareTo(a.severity.index));
    final notAssessed = NotAssessedSection.merge(
      engine.notAssessed.map((f) => f.rawName),
      unknownIngredients,
    ).length;
    void open(BreakdownTab t) => onOpenTab?.call(t);
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: [
        if (flagged.isNotEmpty)
          _StatPill(
            icon: Icons.warning_rounded,
            label: '${flagged.length} Watch out',
            color: flagged.first.severity.color(colors),
            onTap: () => open(BreakdownTab.watchOut),
          ),
        _StatPill(
          icon: Icons.check_circle_rounded,
          label: '${engine.clear.length} Good',
          color: engine.clear.isNotEmpty ? colors.neonEmerald : colors.secondaryText,
          onTap: () => open(BreakdownTab.good),
        ),
        if (notAssessed > 0)
          _StatPill(
            icon: Icons.help_outline_rounded,
            label: '$notAssessed Not assessed',
            color: colors.secondaryText,
            onTap: () => open(BreakdownTab.notAssessed),
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

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatPill({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 17.r),
            SizedBox(width: 7.w),
            Text(label, style: TextStyle(color: Colors.white, fontSize: 13.5.sp, fontWeight: FontWeight.w700)),
            SizedBox(width: 2.w),
            Icon(Icons.chevron_right_rounded, color: color, size: 17.r),
          ],
        ),
      ),
    );
  }
}
