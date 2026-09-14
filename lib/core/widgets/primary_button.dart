import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
class PrimaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PrimaryButton({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(32.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 30.w,
            vertical: 15.h,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32.r),

            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF7CF2B0),
                Color(0xFF25E28B),
              ],
            ),

            boxShadow: [
              BoxShadow(
                color: AppColors.neonEmerald.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: AppColors.background,
              fontWeight: FontWeight.bold,
            ),
            child: IconTheme(
              data: IconThemeData(
                color: AppColors.background,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}