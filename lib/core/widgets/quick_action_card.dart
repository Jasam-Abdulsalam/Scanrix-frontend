import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_colors.dart';

class QuickActionCard extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String subtitle;
  final String? imageAsset;
  final VoidCallback? onTap;

  const QuickActionCard({
    super.key,
     this.icon,
    required this.title,
    required this.subtitle,
    this.imageAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: colors.surface,
        border: Border.all(color: colors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (imageAsset != null) ...[
              // Soft ambient emerald glow behind the asset
              Positioned(
                right: -10.w,
                bottom: -10.h,
                width: 100.w,
                height: 100.h,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.neonEmerald.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Right-side 3D illustration asset
              Positioned(
                right: -4.w,
                bottom: -8.h,
                width: 100.w,
                height: 100.h,
                child: IgnorePointer(
                  child: Image.asset(
                    imageAsset!,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                  ),
                ),
              ),
            ],
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Container(
                      //   width: 36.r,
                      //   height: 36.r,
                      //   decoration: BoxDecoration(
                      //     shape: BoxShape.circle,
                      //     color: AppColors.neonEmerald.withValues(alpha: 0.14),
                      //     boxShadow: [
                      //       BoxShadow(
                      //         color: AppColors.neonEmerald.withValues(alpha: 0.25),
                      //         blurRadius: 10,
                      //       ),
                      //     ],
                      //   ),
                      //   child: Icon(icon, color: AppColors.neonEmerald, size: 18.r),
                      // ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.secondaryText,
                        size: 18.r,
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}