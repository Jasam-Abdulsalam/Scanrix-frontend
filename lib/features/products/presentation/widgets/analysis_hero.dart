import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import 'severity_style.dart';

/// Score → the short badge word shown inside the gauge ("GOOD" / "FAIR" /
/// "POOR") and its color. Takes the current `AppThemeColors` so "GOOD"
/// always matches the theme's actual emerald (`neonEmerald`), not a
/// hardcoded shade — this is what makes the gauge repaint correctly if the
/// user switches between `darkGreen` and `blackishReference`.
typedef ScoreBand = ({Color color, String label});

ScoreBand scoreBandFor(int score, AppThemeColors colors) {
  if (score >= 70) return (color: colors.neonEmerald, label: 'GOOD');
  if (score >= 40) return (color: kWarningAmber, label: 'FAIR');
  return (color: kDangerRed, label: 'POOR');
}

/// Product image + name + category + circular gauge, laid out the way the
/// reference screen shows them: image on the left, text/gauge on the right.
class AnalysisHero extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final String? category;
  final int score;
  final ScoreBand band;
  final AppThemeColors colors;

  const AnalysisHero({
    this.imageUrl,
    this.name,
    this.category,
    required this.score,
    required this.band,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: AspectRatio(
            aspectRatio: 0.75,
            child: _ProductImage(imageUrl: imageUrl, colors: colors),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: colors.iconContainerBg,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: colors.neonEmerald, size: 13.r),
                    SizedBox(width: 6.w),
                    Text(
                      'Analyzed Product',
                      style: TextStyle(color: colors.secondaryText, fontSize: 11.5.sp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              if (name != null)
                Text(
                  name!,
                  style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w800, height: 1.15),
                ),
              if (category != null) ...[
                SizedBox(height: 4.h),
                Text(
                  category!,
                  style: TextStyle(color: colors.neonEmerald, fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
              ],
              SizedBox(height: 14.h),
              Center(child: _ScoreGauge(score: score, band: band, colors: colors)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Frames a product photo with a border, soft shadow, and a bottom
/// vignette — needed because these are often real phone snapshots (a hand
/// holding a pack on a tiled floor), not clean studio product shots, so a
/// plain unstyled `Image.network` looks like a stray screenshot rather than
/// an intentional part of the card. `BoxFit.cover` fills the frame (no
/// letterboxing bars), and loading/error states get the same placeholder
/// treatment as a missing image instead of Flutter's default spinner/red box.
class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final AppThemeColors colors;

  const _ProductImage({required this.imageUrl, required this.colors});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20.r);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: colors.iconContainerBg),
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 22.r,
                      height: 22.r,
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.neonEmerald),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.inventory_2_outlined, color: colors.secondaryText, size: 40.r),
              )
            else
              Icon(Icons.inventory_2_outlined, color: colors.secondaryText, size: 40.r),
            // Soft fade at the bottom so a busy real-world photo (floor,
            // hand, background clutter) settles into the card instead of
            // ending on a hard edge.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 48.h,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular progress ring with the numeric score and its band label
/// ("GOOD"/"FAIR"/"POOR") centered inside — the glowing ring from the
/// reference screenshot.
class _ScoreGauge extends StatelessWidget {
  final int score;
  final ScoreBand band;
  final AppThemeColors colors;
  final double size;

  const _ScoreGauge({required this.score, required this.band, required this.colors, this.size = 150});

  @override
  Widget build(BuildContext context) {
    final color = band.color;
    return SizedBox(
      width: size.r,
      height: size.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 30, spreadRadius: 2),
              ],
            ),
          ),
          CustomPaint(
            size: Size(size.r, size.r),
            painter: _GaugePainter(progress: (score.clamp(0, 100)) / 100, color: color, trackColor: colors.cardBorder),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(color: Colors.white, fontSize: 40.sp, fontWeight: FontWeight.w800, height: 1.0),
              ),
              SizedBox(height: 2.h),
              Text(
                band.label,
                style: TextStyle(color: color, fontSize: 14.sp, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  final Color trackColor;

  _GaugePainter({required this.progress, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi * progress,
        colors: [color.withValues(alpha: 0.5), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.trackColor != trackColor;
}
