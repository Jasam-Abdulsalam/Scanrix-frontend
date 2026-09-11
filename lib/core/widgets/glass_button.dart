import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Frosted-glass pill button — used for secondary CTAs like
/// "Continue with Google" that should feel premium but sit visually quieter
/// than the solid-emerald primary CTA.
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.borderRadius = const BorderRadius.all(Radius.circular(40)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: AppColors.glassFill.withValues(alpha: 0.55),
          child: InkWell(
            onTap: onPressed,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(color: AppColors.mutedGreen.withValues(alpha: 0.45)),
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
