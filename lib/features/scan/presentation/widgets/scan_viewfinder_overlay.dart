import 'package:flutter/material.dart';

import 'scan_line_painter.dart';

/// Full-screen overlay drawn above the [MobileScanner] camera feed.
///
/// Renders:
/// - Dark vignette around the viewfinder cut-out
/// - Corner bracket frame (white/emerald accent)
/// - Pulsing emerald glow border around the frame
/// - Animated horizontal blue scanning line sweeping top→bottom
class ScanViewfinderOverlay extends StatefulWidget {
  /// Fraction of screen width the viewfinder occupies.
  final double frameWidthFraction;

  /// Height of the viewfinder as a fraction of its width (aspect ratio).
  final double frameAspectRatio;

  /// Whether the scan line should be animating (false = camera frozen).
  final bool isScanning;

  /// Vertical centre offset of the viewfinder (0 = true centre).
  final double verticalOffset;

  const ScanViewfinderOverlay({
    super.key,
    this.frameWidthFraction = 0.72,
    this.frameAspectRatio = 0.72,
    this.isScanning = true,
    this.verticalOffset = -0.06,
  });

  @override
  State<ScanViewfinderOverlay> createState() => _ScanViewfinderOverlayState();
}

class _ScanViewfinderOverlayState extends State<ScanViewfinderOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _scanLineCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ScanViewfinderOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_scanLineCtrl.isAnimating) {
      _scanLineCtrl.repeat();
    } else if (!widget.isScanning && _scanLineCtrl.isAnimating) {
      _scanLineCtrl.stop();
    }
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight;

        final frameW = screenW * widget.frameWidthFraction;
        final frameH = frameW / widget.frameAspectRatio;

        final left = (screenW - frameW) / 2;
        final top = (screenH - frameH) / 2 + (screenH * widget.verticalOffset);
        final frameRect = Rect.fromLTWH(left, top, frameW, frameH);

        return AnimatedBuilder(
          animation: Listenable.merge([_scanLineCtrl, _pulseAnim]),
          builder: (context, _) {
            return Stack(
              children: [
                // ── Vignette + cutout
                CustomPaint(
                  size: Size(screenW, screenH),
                  painter: _VignettePainter(frameRect: frameRect),
                ),
                // ── Corner brackets
                CustomPaint(
                  size: Size(screenW, screenH),
                  painter: _CornerBracketPainter(
                    frameRect: frameRect,
                    glowAlpha: _pulseAnim.value,
                  ),
                ),
                // ── Scan line (only while scanning)
                if (widget.isScanning)
                  Positioned(
                    left: frameRect.left + 1,
                    top: frameRect.top + 1,
                    width: frameRect.width - 2,
                    height: frameRect.height - 2,
                    child: ClipRect(
                      child: CustomPaint(
                        painter: ScanLinePainter(
                          progress: _scanLineCtrl.value,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vignette + transparent cutout
// ─────────────────────────────────────────────────────────────────────────────
class _VignettePainter extends CustomPainter {
  final Rect frameRect;
  _VignettePainter({required this.frameRect});

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Outer dark overlay
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.62);
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(20)));
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, bgPaint);

    // Subtle inner edge glow on the cutout
    final glowPaint = Paint()
      ..color = const Color(0xFF4F7EFF).withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(20)),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_VignettePainter old) => old.frameRect != frameRect;
}

// ─────────────────────────────────────────────────────────────────────────────
// Corner brackets + pulsing emerald border glow
// ─────────────────────────────────────────────────────────────────────────────
class _CornerBracketPainter extends CustomPainter {
  final Rect frameRect;
  final double glowAlpha;

  _CornerBracketPainter({required this.frameRect, required this.glowAlpha});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeW = 3.2;
    const cornerR = 16.0;
    const neonBlue = Color(0xFF4F7EFF);
    const neonEmerald = Color(0xFF00D58C);

    // ── Pulsing outer glow border around entire frame
    final glowPaint = Paint()
      ..color = neonBlue.withValues(alpha: glowAlpha * 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(20)),
      glowPaint,
    );

    // ── White frame outline (very subtle)
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(20)),
      borderPaint,
    );

    // ── Corner brackets
    final bracketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final glowBracketPaint = Paint()
      ..color = neonEmerald.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW + 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final corners = [
      // top-left
      _Corner(
        frameRect.topLeft + const Offset(cornerR, 0),
        frameRect.topLeft,
        frameRect.topLeft + const Offset(0, cornerR),
      ),
      // top-right
      _Corner(
        frameRect.topRight + const Offset(-cornerR, 0),
        frameRect.topRight,
        frameRect.topRight + const Offset(0, cornerR),
      ),
      // bottom-left
      _Corner(
        frameRect.bottomLeft + const Offset(0, -cornerR),
        frameRect.bottomLeft,
        frameRect.bottomLeft + const Offset(cornerR, 0),
      ),
      // bottom-right
      _Corner(
        frameRect.bottomRight + const Offset(0, -cornerR),
        frameRect.bottomRight,
        frameRect.bottomRight + const Offset(-cornerR, 0),
      ),
    ];

    for (final c in corners) {
      final path = Path()
        ..moveTo(c.start.dx, c.start.dy)
        ..lineTo(c.corner.dx, c.corner.dy)
        ..lineTo(c.end.dx, c.end.dy);

      // glow layer first
      canvas.drawPath(path, glowBracketPaint);
      // crisp white on top
      canvas.drawPath(path, bracketPaint);
    }
  }

  @override
  bool shouldRepaint(_CornerBracketPainter old) =>
      old.frameRect != frameRect || old.glowAlpha != glowAlpha;
}

class _Corner {
  final Offset start;
  final Offset corner;
  final Offset end;
  const _Corner(this.start, this.corner, this.end);
}
