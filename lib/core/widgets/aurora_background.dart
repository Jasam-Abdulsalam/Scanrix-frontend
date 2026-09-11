import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen atmospheric backdrop: a dark vertical gradient (olive-green
/// top fading through forest green into near-black) with large, softly
/// blurred emerald glow circles layered on top.
///
/// Reusable across screens so the same "premium" atmosphere (first used on
/// the login screen) can be dropped behind any page.
class AuroraBackground extends StatelessWidget {
  final Widget? child;

  const AuroraBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.oliveGreen,
                Color(0xFF263A2C),
                AppColors.background,
              ],
              stops: [0.0, 0.32, 0.85],
            ),
          ),
        ),
        Positioned(
          top: -140,
          right: -100,
          child: _Glow(diameter: 420, color: AppColors.neonEmerald.withValues(alpha: 0.30)),
        ),
        Positioned(
          top: 60,
          left: -160,
          child: _Glow(diameter: 320, color: AppColors.forestGreen.withValues(alpha: 0.28)),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  final double diameter;
  final Color color;

  const _Glow({required this.diameter, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
