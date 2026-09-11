import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
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
                      color: AppColors.glassFill.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(40.r),
                      border: Border.all(
                        color: AppColors.neonEmerald.withValues(alpha: 0.16),
                      ),
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
    final color = selected ? AppColors.neonEmerald : AppColors.secondaryText;

    return InkWell(
      onTap: onTap,
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
    );
  }
}
