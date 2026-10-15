import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/ingredient_entity.dart';
import '../../domain/entities/safety_engine_entity.dart';
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

  const AnalysisHighlightsCard({super.key, this.safetyEngine, this.legacyIngredients = const []});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rows = safetyEngine != null
        ? _engineRows(safetyEngine!, colors)
        : _legacyRows(legacyIngredients, colors);
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

  List<Widget> _engineRows(SafetyEngine engine, AppThemeColors colors) {
    final flagged = engine.flagged..sort((a, b) => b.severity.index.compareTo(a.severity.index));
    final clear = engine.clear;
    return [
      if (flagged.isNotEmpty)
        HighlightRow(
          icon: Icons.warning_rounded,
          iconColor: flagged.first.severity.color(colors),
          title: 'Watch out',
          subtitle: _watchOutText(flagged),
          colors: colors,
        ),
      HighlightRow(
        icon: Icons.science_rounded,
        iconColor: clear.isNotEmpty ? colors.neonEmerald : colors.secondaryText,
        title: 'Good Ingredients',
        subtitle: clear.isNotEmpty
            ? 'No classified hazards found for ${_names(clear)}.'
            : 'No recognised ingredient could be confirmed as free of classified hazards.',
        colors: colors,
      ),
      HighlightRow(
        icon: Icons.fact_check_rounded,
        iconColor: colors.secondaryText,
        title: '${engine.recognisedCount} of ${engine.totalCount} ingredients recognised',
        subtitle: engine.recognisedCount < engine.totalCount
            ? 'The rest were not assessed - see "Not assessed" below.'
            : 'Every ingredient on the label was found in our database.',
        colors: colors,
      ),
    ];
  }

  /// "Contains X: flag; Contains Y: flag" - states what the ingredient is
  /// classified as, not that it is harmful.
  String _watchOutText(List<IngredientFinding> flagged) {
    final parts = flagged.take(_maxNamed).map((f) {
      final flag = f.flags.isNotEmpty ? f.flags.first : '${f.severity.label.toLowerCase()} severity classification';
      return 'Contains ${f.displayName}: $flag';
    });
    final more = flagged.length - _maxNamed;
    return '${parts.join('\n')}${more > 0 ? '\n+$more more below' : ''}';
  }

  String _names(List<IngredientFinding> findings) {
    final names = findings.take(_maxNamed).map((f) => f.displayName).join(', ');
    final more = findings.length - _maxNamed;
    return more > 0 ? '$names and $more more' : names;
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
