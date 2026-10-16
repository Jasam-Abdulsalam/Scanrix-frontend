import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

/// Frosted-glass card: blurred translucent fill, gradient border sheen,
/// and a soft outer glow — matches the target's "glass panel" look
/// instead of a flat solid rectangle.
class GlassCard extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;
  final double? borderRadius;

  /// Optional accent that replaces the default emerald in the sheen, border
  /// and glow. Null keeps the standard look.
  final Color? tint;

  const GlassCard({
    super.key,
    required this.padding,
    required this.child,
    this.borderRadius,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 24.r;
    final accent = tint ?? AppColors.neonEmerald;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint != null ? accent.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.06),
                  AppColors.glassFill.withValues(alpha: 0.55),
                ],
              ),
              border: Border.all(
                color: accent.withValues(alpha: tint != null ? 0.45 : 0.20),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}