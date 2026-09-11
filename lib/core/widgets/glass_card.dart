import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Frosted-glass container: blurred backdrop, translucent dark fill, and a
/// faint emerald border. Base building block for glassmorphic surfaces
/// (cards, sheets) across the app.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final double blurSigma;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.fillColor,
    this.borderColor,
    this.blurSigma = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fillColor ?? AppColors.glassFill.withValues(alpha: 0.48),
            borderRadius: borderRadius,
            border: Border.all(
              color: borderColor ?? AppColors.glassBorder.withValues(alpha: 0.16),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
