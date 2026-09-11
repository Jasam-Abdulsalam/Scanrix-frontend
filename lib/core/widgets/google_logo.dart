import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Dependency-free approximation of the Google "G" mark, drawn with
/// [CustomPainter] so the "Continue with Google" button doesn't need an
/// image asset or an icon-font package for a one-off glyph.
///
/// [size] defaults to a `.r`-scaled value (see "Sizing / responsive units"
/// in CLAUDE.md) — nullable rather than a const default since `.r` isn't a
/// compile-time constant.
class GoogleLogo extends StatelessWidget {
  final double? size;

  const GoogleLogo({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    final s = size ?? 20.r;
    return SizedBox(
      width: s,
      height: s,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.22;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint arcPaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, -0.35, 1.55, false, arcPaint(const Color(0xFF4285F4)));
    canvas.drawArc(rect, 1.2, 1.15, false, arcPaint(const Color(0xFF34A853)));
    canvas.drawArc(rect, 2.35, 0.95, false, arcPaint(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, 3.3, 1.55, false, arcPaint(const Color(0xFFEA4335)));

    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - strokeWidth / 2,
        radius + strokeWidth / 2,
        strokeWidth,
      ),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
