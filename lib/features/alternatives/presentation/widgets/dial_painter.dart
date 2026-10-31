import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The semicircular dial under the cards (a half-disc, flat along the bottom).
/// Its ticks turn by the same [angleStep] per page as the card wheel, so they
/// move in step with the cards. One long tick per card, [ticksPerCard] - 1
/// short ticks between, and a fixed indicator at the top.
///
/// Repaints straight from the controller (passed as `repaint`): no widget
/// rebuild per scroll frame.
class DialPainter extends CustomPainter {
  final PageController controller;
  final int itemCount;
  final Offset center;
  final double radius;
  final double angleStep;
  final Color discColor;
  final Color tickColor;
  final Color indicatorColor;
  final double tickWidth;
  final double shortTick;
  final double longTick;
  final double rimInset;

  static const int ticksPerCard = 5;

  DialPainter({
    required this.controller,
    required this.itemCount,
    required this.center,
    required this.radius,
    required this.angleStep,
    required this.discColor,
    required this.tickColor,
    required this.indicatorColor,
    required this.tickWidth,
    required this.shortTick,
    required this.longTick,
    required this.rimInset,
  }) : super(repaint: controller);

  double get _page {
    if (controller.hasClients && controller.position.haveDimensions) return controller.page ?? 0;
    return controller.initialPage.toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (itemCount == 0 || radius <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Half-disc: the top half of the circle, flat along the bottom.
    final half = Path()
      ..moveTo(center.dx - radius, center.dy)
      ..arcTo(rect, math.pi, math.pi, false)
      ..close();
    canvas.drawPath(
      half,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [discColor.withValues(alpha: 0.14), discColor.withValues(alpha: 0.02)],
        ).createShader(Rect.fromLTRB(rect.left, rect.top, rect.right, center.dy)),
    );
    // Rim along the curved edge only.
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tickWidth
        ..color = discColor.withValues(alpha: 0.22),
    );

    final tickStep = angleStep / ticksPerCard;
    final rotation = -_page * angleStep;
    final tickRadius = radius - rimInset;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = tickWidth;
    final visible = math.pi / 2; // the whole curved edge of the half-disc

    const pad = ticksPerCard * 3;
    final lastCard = (itemCount - 1) * ticksPerCard;
    for (var k = -pad; k <= lastCard + pad; k++) {
      final angle = k * tickStep + rotation; // 0 rad = straight up
      if (angle.abs() > visible) continue;
      final isCard = k % ticksPerCard == 0 && k >= 0 && k <= lastCard;
      final len = isCard ? longTick : shortTick;
      final fade = 1 - angle.abs() / visible;
      paint.color = tickColor.withValues(alpha: (isCard ? 0.85 : 0.3) * fade);
      final dir = Offset(math.sin(angle), -math.cos(angle));
      canvas.drawLine(center + dir * tickRadius, center + dir * (tickRadius - len), paint);
    }

    // Fixed indicator: a thin line across the rim at the top.
    final top = center.dy - radius;
    canvas.drawLine(
      Offset(center.dx, top - longTick * 0.35),
      Offset(center.dx, top + rimInset + longTick),
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = tickWidth * 1.6
        ..color = indicatorColor,
    );
  }

  @override
  bool shouldRepaint(DialPainter old) =>
      old.controller != controller ||
      old.itemCount != itemCount ||
      old.center != center ||
      old.radius != radius ||
      old.angleStep != angleStep ||
      old.discColor != discColor ||
      old.tickColor != tickColor ||
      old.indicatorColor != indicatorColor ||
      old.tickWidth != tickWidth ||
      old.shortTick != shortTick ||
      old.longTick != longTick ||
      old.rimInset != rimInset;
}
