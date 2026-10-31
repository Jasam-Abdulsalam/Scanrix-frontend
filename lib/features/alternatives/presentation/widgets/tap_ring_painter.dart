import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

/// The ring that bursts out from the tap point: thick and opaque at first,
/// then wider, thinner and fading out.
///
/// Repaints straight from [progress] (passed as `repaint`), so the ring
/// animates without rebuilding any widget.
class TapRingPainter extends CustomPainter {
  final Animation<double> progress;
  final Offset? Function() center;
  final double maxRadius;
  final double startStroke;
  final Color color;

  TapRingPainter({
    required this.progress,
    required this.center,
    required this.maxRadius,
    required this.startStroke,
    required this.color,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final c = center();
    final v = progress.value;
    if (c == null || v <= 0 || v >= 1) return;
    final t = Curves.easeOutCubic.transform(v);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = startStroke * (1 - t) + 1
      ..color = color.withValues(alpha: (1 - t).clamp(0, 1));
    canvas.drawCircle(c, maxRadius * t, paint);
  }

  @override
  bool shouldRepaint(TapRingPainter old) =>
      old.maxRadius != maxRadius || old.startStroke != startStroke || old.color != color;
}
