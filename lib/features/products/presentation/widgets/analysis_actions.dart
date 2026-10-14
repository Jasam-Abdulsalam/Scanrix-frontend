import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';

class AnalysisPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppThemeColors colors;

  const AnalysisPrimaryButton({super.key, required this.label, this.onTap, required this.colors});

  @override
  Widget build(BuildContext context) {
    final darker = Color.lerp(colors.neonEmerald, Colors.black, 0.25)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 17.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [colors.neonEmerald, darker]),
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(color: colors.neonEmerald.withValues(alpha: 0.35), blurRadius: 20, offset: Offset(0, 8.h)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(color: colors.background, fontSize: 16.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(width: 6.w),
            Icon(Icons.chevron_right_rounded, color: colors.background, size: 20.r),
          ],
        ),
      ),
    );
  }
}

class AnalysisOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppThemeColors colors;

  const AnalysisOutlinedButton({super.key, required this.label, this.onTap, required this.colors});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 17.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: colors.cardBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 15.5.sp, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class AddToRoutineButton extends StatelessWidget {
  final VoidCallback? onTap;
  final AppThemeColors colors;
  const AddToRoutineButton({super.key, this.onTap, required this.colors});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22.r,
              height: 22.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.neonEmerald),
              ),
              child: Icon(Icons.add_rounded, color: colors.neonEmerald, size: 15.r),
            ),
            SizedBox(width: 8.w),
            Text(
              'Add to My Routine',
              style: TextStyle(color: colors.neonEmerald, fontSize: 14.5.sp, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
