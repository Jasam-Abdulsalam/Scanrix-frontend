import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';

class AuroraBackground extends StatelessWidget {
  final Widget child;

  const AuroraBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (colors.isBlackishReference) {
      // ------------------------------------------------------------
      // Reference Image Theme: Sleek Matte Blackish + Emerald Accent
      // ------------------------------------------------------------
      return Stack(
        children: [
          Container(color: colors.background),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.85, -0.85),
                    radius: 1.15,
                    colors: [
                      colors.neonEmerald.withValues(alpha: 0.12),
                      colors.neonEmerald.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.15, -0.20),
                    radius: 1.25,
                    colors: [
                      colors.neonEmerald.withValues(alpha: 0.09),
                      colors.neonEmerald.withValues(alpha: 0.02),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      colors.background.withValues(alpha: 0.35),
                      colors.background.withValues(alpha: 0.75),
                    ],
                    stops: const [0.45, 0.75, 1.0],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      );
    }

    // ------------------------------------------------------------
    // Original Scanrix Theme: Dark Green + Emerald Green Base
    // ------------------------------------------------------------
    return Stack(
      children: [
        Container(color: colors.background),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.85, -0.85),
                  radius: 1.15,
                  colors: [
                    const Color(0xFF9ACB5A).withValues(alpha: 0.38),
                    const Color(0xFF6FA84F).withValues(alpha: 0.24),
                    const Color(0xFF2E6B43).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.28, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.15, -0.15),
                  radius: 1.25,
                  colors: [
                    colors.neonEmerald.withValues(alpha: 0.12),
                    colors.neonEmerald.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colors.background.withValues(alpha: 0.12),
                    colors.background.withValues(alpha: 0.42),
                  ],
                  stops: const [0.45, 0.75, 1.0],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}