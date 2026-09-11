import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';

/// Solid-emerald primary CTA — the strongest visual accent on a screen.
/// Pair with [GlassButton] for secondary actions.
class PrimaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const PrimaryButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(40.r);

    return Material(
      color: AppColors.neonEmerald,
      borderRadius: radius,
      shadowColor: AppColors.neonEmerald.withValues(alpha: 0.5),
      elevation: 8,
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: Container(
          padding: padding ?? EdgeInsets.symmetric(vertical: 14.h),
          alignment: Alignment.center,
          child: IconTheme.merge(
            data: const IconThemeData(color: AppColors.background),
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                color: AppColors.background,
                fontWeight: FontWeight.bold,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
