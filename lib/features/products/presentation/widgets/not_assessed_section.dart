import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/glass_card.dart';

/// Ingredients the database could not assess (unmatched findings plus the
/// response's `unknown_ingredients`). Deliberately all-grey: absence of data
/// is not evidence of safety, so nothing here uses the emerald/"good" color.
class NotAssessedSection extends StatelessWidget {
  final List<String> names;
  const NotAssessedSection({super.key, required this.names});

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return GlassCard(
      padding: EdgeInsets.all(18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: colors.secondaryText, size: 18.r),
              SizedBox(width: 8.w),
              Text(
                'Not assessed (${names.length})',
                style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Not in our database, so we have no safety information on these - this is not a clean result.',
            style: TextStyle(color: colors.secondaryText, fontSize: 12.sp, height: 1.35),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [for (final n in names) _NamePill(name: n, colors: colors)],
          ),
        ],
      ),
    );
  }
}

class _NamePill extends StatelessWidget {
  final String name;
  final AppThemeColors colors;
  const _NamePill({required this.name, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: colors.iconContainerBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Text(name, style: TextStyle(color: colors.secondaryText, fontSize: 12.sp)),
    );
  }
}
