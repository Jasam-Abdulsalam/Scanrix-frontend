import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AuroraBackground extends StatelessWidget {
  final Widget child;

  const AuroraBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ------------------------------------------------------------
        // 1. Deep dark base
        // ------------------------------------------------------------
        Container(
          color: AppColors.background,
        ),

        // ------------------------------------------------------------
        // 2. Large upper-right yellow/green ambient glow
        // ------------------------------------------------------------
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
                  stops: const [
                    0.0,
                    0.28,
                    0.55,
                    1.0,
                  ],
                ),
              ),
            ),
          ),
        ),

        // ------------------------------------------------------------
        // 3. Broad emerald atmosphere across the upper/middle area
        // ------------------------------------------------------------
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.15, -0.15),
                  radius: 1.25,
                  colors: [
                    AppColors.neonEmerald.withValues(alpha: 0.12),
                    AppColors.neonEmerald.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const [
                    0.0,
                    0.42,
                    1.0,
                  ],
                ),
              ),
            ),
          ),
        ),

        // ------------------------------------------------------------
        // 4. Very subtle lower-right green reflection
        // ------------------------------------------------------------
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.95, 0.45),
                  radius: 0.9,
                  colors: [
                    AppColors.neonEmerald.withValues(alpha: 0.07),
                    AppColors.neonEmerald.withValues(alpha: 0.025),
                    Colors.transparent,
                  ],
                  stops: const [
                    0.0,
                    0.45,
                    1.0,
                  ],
                ),
              ),
            ),
          ),
        ),

        // ------------------------------------------------------------
        // 5. Soft dark falloff toward the bottom
        // ------------------------------------------------------------
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.12),
                    AppColors.background.withValues(alpha: 0.42),
                  ],
                  stops: const [
                    0.45,
                    0.75,
                    1.0,
                  ],
                ),
              ),
            ),
          ),
        ),

        // ------------------------------------------------------------
        // App content
        // ------------------------------------------------------------
        child,
      ],
    );
  }
}