import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import 'scan_line_painter.dart';

/// Pop-up card that animates the detected barcode into the centre of screen.
///
/// Animation sequence:
///   1. Card scales + fades in  (ElasticOut, 700ms)
///   2. Scan line sweeps top→bottom  (600ms)
///   3. Success tick draws  (400ms)
///   4. Brief pause  (300ms)
///   5. [onComplete] fires with the barcode value
class BarcodePopupCard extends StatefulWidget {
  final String barcodeValue;
  final String? barcodeFormat;
  final VoidCallback onComplete;
  final VoidCallback onDismiss;

  const BarcodePopupCard({
    super.key,
    required this.barcodeValue,
    this.barcodeFormat,
    required this.onComplete,
    required this.onDismiss,
  });

  @override
  State<BarcodePopupCard> createState() => _BarcodePopupCardState();
}

class _BarcodePopupCardState extends State<BarcodePopupCard>
    with TickerProviderStateMixin {
  // Phase 1: card entrance
  late final AnimationController _entranceCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  // Phase 2: scan line
  late final AnimationController _scanLineCtrl;

  // Phase 3: success tick
  late final AnimationController _tickCtrl;
  late final Animation<double> _tickAnim;

  // Phase tracking (mutable state)
  bool _showScanLine = false;
  bool _showTick = false;


  @override
  void initState() {
    super.initState();

    // ── Entrance animation
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // ── Scan line
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // ── Tick
    _tickCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _tickAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tickCtrl, curve: Curves.easeOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    // 1. Card entrance
    await _entranceCtrl.forward();

    // 2. Scan line
    if (!mounted) return;
    setState(() => _showScanLine = true);
    await _scanLineCtrl.forward();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 80));

    // 3. Success tick
    if (!mounted) return;
    setState(() {
      _showScanLine = false;
      _showTick = true;
    });
    await _tickCtrl.forward();

    // 4. Pause then complete
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _scanLineCtrl.dispose();
    _tickCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      // tap outside card → dismiss
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // absorb taps on card itself
            child: AnimatedBuilder(
              animation: _entranceCtrl,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: child,
                  ),
                );
              },
              child: _buildCard(colors),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(AppThemeColors colors) {
    final cardW = 280.w;
    final cardH = 180.h;

    return Container(
      width: cardW,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: colors.neonEmerald.withValues(alpha: 0.18),
            blurRadius: 40,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
              border: Border.all(
                color: colors.neonEmerald.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                // ── Main card content
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 22.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Format label
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color:
                                  colors.neonEmerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: colors.neonEmerald
                                    .withValues(alpha: 0.30),
                              ),
                            ),
                            child: Text(
                              widget.barcodeFormat ?? 'BARCODE',
                              style: TextStyle(
                                color: colors.neonEmerald,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // Barcode graphic
                      _BarcodeGraphic(width: cardW - 48.w, height: cardH),

                      SizedBox(height: 14.h),

                      // Barcode value text
                      Text(
                        widget.barcodeValue,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Barcode detected — processing…',
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scan line overlay
                if (_showScanLine)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.r),
                      child: AnimatedBuilder(
                        animation: _scanLineCtrl,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: ScanLinePainter(
                              progress: _scanLineCtrl.value,
                              lineColor: colors.neonEmerald,
                              glowColor: colors.neonEmerald,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // ── Success tick overlay
                if (_showTick)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _tickAnim,
                      builder: (context, _) {
                        return Opacity(
                          opacity: _tickAnim.value,
                          child: Center(
                            child: _SuccessTick(
                              color: colors.neonEmerald,
                              progress: _tickAnim.value,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barcode graphic (decorative bars)
// ─────────────────────────────────────────────────────────────────────────────
class _BarcodeGraphic extends StatelessWidget {
  final double width;
  final double height;
  const _BarcodeGraphic({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 50.h,
      child: CustomPaint(
        painter: _BarcodeBarsPainter(),
      ),
    );
  }
}

class _BarcodeBarsPainter extends CustomPainter {
  static const _pattern = [
    3, 1, 2, 1, 4, 1, 2, 3, 1, 2, 1, 3, 2, 1, 3, 1, 2, 4, 1, 2,
    1, 3, 2, 1, 2, 1, 4, 2, 1, 3, 1, 2, 1, 3, 2, 1, 2, 1, 4, 1
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final totalUnits = _pattern.fold<int>(0, (a, b) => a + b);
    final unitW = size.width / totalUnits;

    double x = 0;
    bool isBar = true;
    for (final units in _pattern) {
      if (isBar) {
        final barW = units * unitW;
        final paint = Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTWH(x, 0, barW, size.height), paint);
      }
      x += units * unitW;
      isBar = !isBar;
    }
  }

  @override
  bool shouldRepaint(_BarcodeBarsPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated success check-mark
// ─────────────────────────────────────────────────────────────────────────────
class _SuccessTick extends StatelessWidget {
  final Color color;
  final double progress; // 0..1

  const _SuccessTick({required this.color, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72.r,
      height: 72.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _TickPainter(progress: progress, color: color),
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _TickPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Tick path: short segment then long segment
    final p1 = Offset(cx - 14, cy);
    final p2 = Offset(cx - 4, cy + 10);
    final p3 = Offset(cx + 14, cy - 10);

    final totalLen = (p2 - p1).distance + (p3 - p2).distance;
    final drawn = totalLen * progress;

    final path = Path();
    double remaining = drawn;

    final seg1Len = (p2 - p1).distance;
    if (remaining <= seg1Len) {
      final t = remaining / seg1Len;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
    } else {
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      remaining -= seg1Len;
      final seg2Len = (p3 - p2).distance;
      final t = (remaining / seg2Len).clamp(0.0, 1.0);
      path.moveTo(p2.dx, p2.dy);
      path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.progress != progress;
}
