import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/safety_engine_entity.dart';
import 'severity_style.dart';

/// Per-ingredient list for the recognised ingredients (flagged + clear).
/// Unmatched ones live in `NotAssessedSection` instead, so nothing appears
/// twice. Each row: severity dot, name, classification flags, evidence badge.
class FindingsListCard extends StatelessWidget {
  final List<IngredientFinding> findings;
  final String? title;
  const FindingsListCard({super.key, required this.findings, this.title});

  @override
  Widget build(BuildContext context) {
    if (findings.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return GlassCard(
      padding: EdgeInsets.all(18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${title ?? 'Recognised ingredients'} (${findings.length})',
            style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12.h),
          ...findings.map((f) => _FindingRow(finding: f, colors: colors)),
        ],
      ),
    );
  }
}

class _FindingRow extends StatelessWidget {
  final IngredientFinding finding;
  final AppThemeColors colors;
  const _FindingRow({required this.finding, required this.colors});

  @override
  Widget build(BuildContext context) {
    final dotColor = finding.severity.color(colors, matched: finding.matched);
    final tier = evidenceTierLabel(finding.evidenceTier);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 5.h),
            width: 8.r,
            height: 8.r,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finding.displayName,
                  style: TextStyle(color: Colors.white, fontSize: 13.5.sp, fontWeight: FontWeight.w600),
                ),
                if (finding.flags.isNotEmpty)
                  Text(
                    'Classified: ${finding.flags.join('; ')}',
                    style: TextStyle(color: colors.secondaryText, fontSize: 12.sp, height: 1.35),
                  ),
                if (tier != null) ...[
                  SizedBox(height: 4.h),
                  EvidenceTierBadge(label: tier, tier: finding.evidenceTier, colors: colors),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small pill naming the evidence behind a classification. Tier 4 (AI,
/// unverified) is drawn in neutral grey so unverified data never carries the
/// same visual weight as a government/IARC source.
class EvidenceTierBadge extends StatelessWidget {
  final String label;
  final int? tier;
  final AppThemeColors colors;
  const EvidenceTierBadge({super.key, required this.label, required this.tier, required this.colors});

  @override
  Widget build(BuildContext context) {
    final unverified = tier == 4;
    final color = unverified ? colors.secondaryText : colors.neonEmerald;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        'Evidence: $label',
        style: TextStyle(color: color, fontSize: 10.5.sp, fontWeight: FontWeight.w600),
      ),
    );
  }
}
