import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';

/// Frosted-glass pill button — used for secondary CTAs like
/// "Continue with Google" that should feel premium but sit visually quieter
/// than the solid-emerald primary CTA.
///
/// [padding], [borderRadius] and [gradient] default to `.h`/`.r`-scaled or
/// runtime-computed values (see "Sizing / responsive units" in CLAUDE.md) —
/// nullable rather than const defaults because those aren't compile-time
/// constants.
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final Color? borderColor;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.borderRadius,
    this.gradient,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(40.r);
    final fillGradient = gradient ??
        RadialGradient(
          center: Alignment.center,
          radius: 1.3,
          colors: [
            AppColors.mutedGreen.withValues(alpha: 0.6),
            AppColors.glassFill.withValues(alpha: 0.75),
          ],
        );

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.r, sigmaY: 16.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              padding: padding ?? EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                gradient: fillGradient,
                borderRadius: radius,
                border: Border.all(
                  color: borderColor ?? AppColors.neonEmerald.withValues(alpha: 0.4),
                ),
              ),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
