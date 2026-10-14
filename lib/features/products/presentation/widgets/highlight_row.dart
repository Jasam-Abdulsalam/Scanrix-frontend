import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';

class RowDivider extends StatelessWidget {
  final AppThemeColors colors;
  const RowDivider({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Divider(color: colors.divider, height: 1);
  }
}

/// One row inside the highlights card: leading icon in a tinted circle,
/// title + subtitle, trailing chevron. Tap is a no-op placeholder for now —
/// wire `onTap` up if each row should push to a detail page.
class HighlightRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final AppThemeColors colors;
  final VoidCallback? onTap;

  const HighlightRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42.r,
              height: 42.r,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.secondaryText, fontSize: 12.5.sp, height: 1.35),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Icon(Icons.chevron_right_rounded, color: colors.secondaryText.withValues(alpha: 0.6), size: 22.r),
            ),
          ],
        ),
      ),
    );
  }
}
