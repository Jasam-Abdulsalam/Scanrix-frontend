import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme_colors.dart';

/// Central floating scan CTA that sits above [BottomNavBar] — solid
/// emerald, with a controlled (not full-neon) glow.
class FloatingScanButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double? size;

  const FloatingScanButton({super.key, this.onPressed, this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final diameter = size ?? 60.r;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.neonEmerald,
        boxShadow: [
          BoxShadow(
            color: colors.neonEmerald.withValues(alpha: 0.45),
            blurRadius: 20.r,
            spreadRadius: 2.r,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(
            Icons.qr_code_scanner_rounded,
            color: colors.background,
            size: diameter * 0.42,
          ),
        ),
      ),
    );
  }
}
