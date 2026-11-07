import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/bold_card.dart';
import '../../domain/entities/ai_analysis_entity.dart';
import 'ai_verdict_style.dart';

// The AI verdict screen's own identity: violet → blue, on dark. The solid
// emerald hero card belongs to the database result, so the AI estimate never
// looks like the same thing. Status colours (green / amber / red) still mean
// what they mean everywhere; only the "AI" chrome is violet.

const kAiViolet = Color(0xFFA78BFA);
const kAiBlue = Color(0xFF60A5FA);
const kAiGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kAiViolet, kAiBlue],
);

/// The AI verdict hero: dark card with a violet → blue gradient border and a
/// soft glow, a ✨ "AI estimate · unverified" chip, the verdict in its status
/// colour, and the score as a big number in a thin gradient arc.
class AiGlowHeroCard extends StatelessWidget {
  final AiAnalysis analysis;

  /// 0..1: fills the arc and counts the number up.
  final Animation<double> progress;

  const AiGlowHeroCard({super.key, required this.analysis, required this.progress});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = analysis.verdict.color(colors);
    final radius = 28.r;
    final border = 1.5.r;
    final fill = CurvedAnimation(parent: progress, curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic));
    return Container(
      // Gradient "border": the outer box paints the gradient, the inner one covers all but the edge.
      padding: EdgeInsets.all(border),
      decoration: BoxDecoration(
        gradient: kAiGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: kAiViolet.withValues(alpha: 0.28), blurRadius: 32, spreadRadius: -6, offset: const Offset(-6, 8)),
          BoxShadow(color: kAiBlue.withValues(alpha: 0.22), blurRadius: 32, spreadRadius: -6, offset: const Offset(6, 10)),
        ],
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 16.w, 20.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius - border),
          // Dark, with a faint violet wash from the top-left corner.
          gradient: RadialGradient(
            center: const Alignment(-1, -1),
            radius: 1.4,
            colors: [Color.alphaBlend(kAiViolet.withValues(alpha: 0.14), colors.surface), colors.surface],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AiChip(label: 'AI estimate · unverified'),
            SizedBox(height: 16.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(analysis.verdict.icon, color: status, size: 20.r),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              analysis.verdict.label,
                              style: TextStyle(
                                color: status,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.7,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        analysis.verdict.meaning,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 13.sp, height: 1.4),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 14.w),
                AnimatedBuilder(
                  animation: fill,
                  builder: (_, _) => AiScoreArc(size: 92.r, score: analysis.score, fraction: fill.value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pill with a sparkle: marks something as AI-made.
class AiChip extends StatelessWidget {
  final String label;

  const AiChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 5.h, 11.w, 5.h),
      decoration: BoxDecoration(
        color: kAiViolet.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (r) => kAiGradient.createShader(r),
            child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 13.r),
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: kAiViolet, fontSize: 11.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Big score number inside a thin violet → blue arc (open at the bottom, like
/// a gauge). Different shape from the database's thick ring on purpose.
class AiScoreArc extends StatelessWidget {
  final double size;
  final int? score;
  final double fraction;

  const AiScoreArc({super.key, required this.size, required this.score, this.fraction = 1});

  @override
  Widget build(BuildContext context) {
    final s = score?.clamp(0, 100);
    final shown = s == null ? '–' : '${(s * fraction).round()}';
    return Semantics(
      label: s == null ? 'No score' : 'AI score $s out of 100',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _ArcPainter(
            fraction: (s ?? 0) / 100 * fraction,
            track: Colors.white.withValues(alpha: 0.08),
            stroke: size * 0.065,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  shown,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'AI score',
                  style: TextStyle(color: kAiViolet.withValues(alpha: 0.85), fontSize: 10.sp, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double fraction;
  final Color track;
  final double stroke;

  _ArcPainter({required this.fraction, required this.track, required this.stroke});

  // 270° gauge, gap at the bottom.
  static const _start = math.pi * 0.75;
  static const _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2 + 1);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _start, _sweep, false, base..color = track);
    if (fraction <= 0) return;
    final value = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: _start,
        endAngle: _start + _sweep,
        colors: [kAiViolet, kAiBlue],
        transform: GradientRotation(0),
      ).createShader(rect);
    canvas.drawArc(rect, _start, _sweep * fraction.clamp(0.0, 1.0), false, value);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.fraction != fraction || old.track != track || old.stroke != stroke;
}

/// Violet "Try again" pill for the AI screen (the database screens keep green).
class AiPillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const AiPillButton({super.key, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(22.w, 6.h, 6.w, 6.h),
        decoration: BoxDecoration(gradient: kAiGradient, borderRadius: BorderRadius.circular(30.r)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: kOnAccent, fontSize: 14.sp, fontWeight: FontWeight.w700)),
            SizedBox(width: 12.w),
            CircleIcon(icon: icon, background: kOnAccent, foreground: kAiViolet, size: 36.r),
          ],
        ),
      ),
    );
  }
}

/// Dark card with a faint violet edge and wash: the small AI cards on the
/// result screen ("Get AI verdict", the folded answer row), so AI looks the
/// same wherever it appears.
class AiCardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AiCardShell({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: padding ?? EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: kAiViolet.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.alphaBlend(kAiViolet.withValues(alpha: 0.10), boldCardFill(colors)), boldCardFill(colors)],
        ),
      ),
      child: child,
    );
  }
}
