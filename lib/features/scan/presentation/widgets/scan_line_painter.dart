import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Draws a neon vertical scan line that sweeps top→bottom across [rect].
/// [progress] ∈ [0, 1] controls the line's Y position within the rect.
/// [lineColor] is the main line colour (defaults to vivid blue matching ref image).
class ScanLinePainter extends CustomPainter {
  final double progress;
  final Color lineColor;
  final Color glowColor;

  const ScanLinePainter({
    required this.progress,
    this.lineColor = const Color(0xFF4F7EFF),
    this.glowColor = const Color(0xFF3D6BFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;

    // ── Outer diffuse glow (wide, soft)
    final outerGlowPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, y - 24),
        Offset(0, y + 8),
        [
          glowColor.withValues(alpha: 0.0),
          glowColor.withValues(alpha: 0.18),
          glowColor.withValues(alpha: 0.0),
        ],
        [0.0, 0.6, 1.0],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(Rect.fromLTWH(0, y - 24, size.width, 32), outerGlowPaint);

    // ── Core line (crisp, narrow)
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    // ── Bright centre highlight (very thin, white-ish core)
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), corePaint);

    // ── Trailing gradient below the line
    final trailPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, y),
        Offset(0, y + 60),
        [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.0),
        ],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width, 60),
      trailPaint,
    );
  }

  @override
  bool shouldRepaint(ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.lineColor != lineColor;
}
