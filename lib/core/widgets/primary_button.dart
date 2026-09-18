import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Visual-only "disabled" dimming, independent of [onTap] being null.
  /// [onTap] on its own gives no visual feedback when null — the button
  /// looks identical whether tappable or not — so a caller that wants
  /// taps to still land (e.g. to show "why this is disabled" feedback)
  /// can pass a non-null [onTap] while setting [enabled] to false.
  final bool enabled;

  const PrimaryButton({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32.r),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32.r),

              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7CF2B0), Color(0xFF25E28B)],
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
                data: IconThemeData(color: AppColors.background),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
