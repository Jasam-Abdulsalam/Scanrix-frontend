import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';

/// Frosted-glass container: blurred backdrop, translucent dark fill, and a
/// faint emerald border. Base building block for glassmorphic surfaces
/// (cards, sheets) across the app.
///
/// [padding], [borderRadius] and [blurSigma] default to `.r`-scaled values
/// (see "Sizing / responsive units" in CLAUDE.md) — they're nullable rather
/// than const defaults because `.r` isn't a compile-time constant.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final double? blurSigma;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.fillColor,
    this.borderColor,
    this.blurSigma,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24.r);
    final sigma = blurSigma ?? 20.r;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          padding: padding ?? EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: fillColor ?? AppColors.glassFill.withValues(alpha: 0.48),
            borderRadius: radius,
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
