import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import 'scan_category.dart';

/// Shows the glassmorphic "wrong category" toast with a switch action.
void showCategoryMismatchSnackbar(
  BuildContext context, {
  required ScanCategory detectedCategory,
  required VoidCallback onSwitch,
}) {
  final colors = context.colors;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: const Duration(seconds: 5),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      padding: EdgeInsets.zero,
      content: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: colors.cardBorder.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(detectedCategory.emoji, style: TextStyle(fontSize: 20.sp)),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'This looks like a ${detectedCategory.label} product. Switch category?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5.sp,
                      height: 1.3,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () {
                    messenger.hideCurrentSnackBar();
                    onSwitch();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: detectedCategory.gradient),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Text(
                      'Switch to ${detectedCategory.label}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}