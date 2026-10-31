import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/bold_card.dart';

class RowDivider extends StatelessWidget {
  final AppThemeColors colors;
  const RowDivider({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    // Starts after the leading icon tile, like an iOS grouped list.
    return Divider(color: Colors.white.withValues(alpha: 0.07), height: 1, thickness: 1, indent: 52.w);
  }
}

/// One row inside the highlights card: solid icon tile, title + subtitle,
/// trailing chevron when it opens something. Shrinks slightly on press.
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
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(icon: icon, color: iconColor),
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
            if (onTap != null) ...[
              SizedBox(width: 8.w),
              Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Icon(Icons.chevron_right_rounded, color: colors.secondaryText, size: 22.r),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
