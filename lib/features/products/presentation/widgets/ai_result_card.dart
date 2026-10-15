import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/ai_analysis_entity.dart';
import 'status_colors.dart';

/// Display wording per AI verdict. Deliberately never "Safe": an AI estimate
/// can say "low concern", not that a product is safe.
extension AiVerdictStyle on AiVerdict {
  String get label => switch (this) {
        AiVerdict.good => 'Low concern',
        AiVerdict.caution => 'Use with caution',
        AiVerdict.avoid => 'Avoid',
        AiVerdict.unknown => 'Unable to determine',
      };

  IconData get icon => switch (this) {
        AiVerdict.good => Icons.check_circle_rounded,
        AiVerdict.caution => Icons.warning_rounded,
        AiVerdict.avoid => Icons.report_rounded,
        AiVerdict.unknown => Icons.help_outline_rounded,
      };

  Color color(AppThemeColors colors) => switch (this) {
        AiVerdict.good => colors.neonEmerald,
        AiVerdict.caution => kWarnAmber,
        AiVerdict.avoid => kDangerRed,
        AiVerdict.unknown => colors.secondaryText,
      };
}

/// The AI's answer, filling the same kind of content as our own result
/// (verdict, score, summary, concerns), under a permanent "unverified" label.
class AiResultCard extends StatelessWidget {
  final AiAnalysis analysis;

  const AiResultCard({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = analysis.verdict.color(colors);
    return GlassCard(
      padding: EdgeInsets.all(18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Chip(text: 'AI estimate · unverified', color: colors.secondaryText, icon: Icons.auto_awesome_rounded),
          SizedBox(height: 14.h),
          Row(
            children: [
              Icon(analysis.verdict.icon, color: accent, size: 26.r),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  analysis.verdict.label,
                  style: TextStyle(color: accent, fontSize: 18.sp, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${analysis.score}/100',
                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (analysis.summary.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              analysis.summary,
              style: TextStyle(color: colors.secondaryText, fontSize: 13.sp, height: 1.45),
            ),
          ],
          if (analysis.adjustedByDatabase) ...[
            SizedBox(height: 10.h),
            _Note(
              icon: Icons.shield_outlined,
              text: 'Lowered to match a hazard in our database.',
              color: kWarnAmber,
            ),
          ],
          if (analysis.concerns.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _SectionTitle('What may be a concern'),
            for (final c in analysis.concerns) _Bullet(title: c.ingredient, text: c.effect, color: kWarnAmber),
          ],
          if (analysis.positives.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _SectionTitle('Good points'),
            for (final p in analysis.positives) _Bullet(text: p, color: colors.neonEmerald),
          ],
          if (analysis.certainty != AiCertainty.wellKnown) ...[
            SizedBox(height: 12.h),
            _Note(
              icon: Icons.help_outline_rounded,
              text: 'The AI is not fully certain about some ingredients.',
              color: colors.secondaryText,
            ),
          ],
          SizedBox(height: 14.h),
          Text(
            analysis.disclaimer.isNotEmpty
                ? analysis.disclaimer
                : 'AI-generated estimate. It has not been verified and is not medical advice.',
            style: TextStyle(color: colors.secondaryText, fontSize: 11.sp, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _Chip({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13.r),
          SizedBox(width: 6.w),
          Text(text, style: TextStyle(color: color, fontSize: 11.5.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Note({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 15.r),
        SizedBox(width: 6.w),
        Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 12.sp, height: 1.35))),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 6.h),
        child: Text(text, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w700)),
      );
}

class _Bullet extends StatelessWidget {
  final String? title;
  final String text;
  final Color color;

  const _Bullet({this.title, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h),
            width: 7.r,
            height: 7.r,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                if (title != null)
                  TextSpan(text: '$title: ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                TextSpan(text: text, style: TextStyle(color: colors.secondaryText)),
              ]),
              style: TextStyle(fontSize: 12.5.sp, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
