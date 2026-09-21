import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme_colors.dart';
import 'floating_scan_button.dart';

/// Floating glassmorphic bottom nav (Home/History/Scan/Search/Profile) with
/// a [FloatingScanButton] centered above it. [onTap]/[onScanPressed] are
/// nullable so this can be dropped in as static UI before navigation exists.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final VoidCallback? onScanPressed;

  const BottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.onScanPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
      child: SizedBox(
        height: 78.h,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 64.h,
                    decoration: BoxDecoration(
                      color: colors.navFill.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(40.r),
                      border: Border.all(
                        color: colors.cardBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _NavItem(
                            icon: Icons.home_rounded,
                            label: 'Home',
                            selected: currentIndex == 0,
                            onTap: () => onTap?.call(0),
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            icon: Icons.access_time_rounded,
                            label: 'History',
                            selected: currentIndex == 1,
                            onTap: () => onTap?.call(1),
                          ),
                        ),
                        SizedBox(width: 64.r),
                        Expanded(
                          child: _NavItem(
                            icon: Icons.search_rounded,
                            label: 'Search',
                            selected: currentIndex == 3,
                            onTap: () => onTap?.call(3),
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            icon: Icons.person_outline_rounded,
                            label: 'Profile',
                            selected: currentIndex == 4,
                            onTap: () => onTap?.call(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 34.h,
              child: FloatingScanButton(onPressed: onScanPressed),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.neonEmerald : colors.secondaryText;

    return InkWell(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Spotlight: a bright strip "shining" down from the top edge of
          // the pill, lighting up a soft rounded patch behind the active
          // item only. Cross-fades so it visually hands off between items
          // as `selected` moves.
          Positioned(
            top: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: selected ? 1 : 0,
              child: Column(
                children: [
                  Container(
                    width: 22.w,
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: AppColors.neonEmerald,
                      borderRadius: BorderRadius.circular(2.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonEmerald.withValues(alpha: 0.8),
                          blurRadius: 8.r,
                          spreadRadius: 1.r,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44.r,
                    height: 44.r,
                    margin: EdgeInsets.only(top: 4.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.neonEmerald.withValues(alpha: 0.28),
                          AppColors.neonEmerald.withValues(alpha: 0.0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.background.withValues(alpha: 0.4),
                          blurRadius: 10.r,
                          offset: Offset(0, 6.h),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 11.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20.r),
                SizedBox(height: 2.h),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.sp,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
