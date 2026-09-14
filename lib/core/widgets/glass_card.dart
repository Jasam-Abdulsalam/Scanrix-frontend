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

  const GlassCard({
    super.key,
    required this.padding,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 24.r;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonEmerald.withValues(alpha: 0.06),
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
                  Colors.white.withValues(alpha: 0.06),
                  AppColors.glassFill.withValues(alpha: 0.55),
                ],
              ),
              border: Border.all(
                color: AppColors.neonEmerald.withValues(alpha: 0.20),
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