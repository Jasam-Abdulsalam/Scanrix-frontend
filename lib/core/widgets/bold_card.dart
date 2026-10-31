import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme_colors.dart';

// Building blocks of the bold-card language (.claude/skills/bold-card-ui):
// one solid brand-emerald accent block per screen, borderless dark cards, circular
// icon buttons, solid icon tiles, pill shapes.

/// The accent used as a solid fill (hero cards, primary pills, arrow buttons):
/// the theme's brand emerald, so it follows the active palette.
Color boldAccent(BuildContext context) => context.colors.neonEmerald;

/// Text and icons on top of [boldAccent] (and other bright fills).
const kOnAccent = Color(0xFF0B0F0C);

/// Borderless dark card fill: lifted just enough off the page background.
Color boldCardFill(AppThemeColors colors) => Color.alphaBlend(Colors.white.withValues(alpha: 0.05), colors.surface);

/// Borderless dark card with the large corner radius of this language.
class BoldCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const BoldCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(18.r),
      decoration: BoxDecoration(color: boldCardFill(context.colors), borderRadius: BorderRadius.circular(24.r)),
      child: child,
    );
  }
}

/// Solid circle holding one icon: the "icon button" shape of this language.
class CircleIcon extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final double? size;

  const CircleIcon({super.key, required this.icon, required this.background, required this.foreground, this.size});

  @override
  Widget build(BuildContext context) {
    final s = size ?? 40.r;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: foreground, size: s * 0.5),
    );
  }
}

/// Solid, lit-from-above icon tile like iOS Settings icons: a rounded square
/// (or circle) in the icon's color with a dark glyph. The brand colors are
/// bright, so the glyph is dark on them and white only on dark colors.
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double? size;
  final bool circle;

  const IconTile({super.key, required this.icon, required this.color, this.size, this.circle = false});

  @override
  Widget build(BuildContext context) {
    final s = size ?? 38.r;
    final glyph = ThemeData.estimateBrightnessForColor(color) == Brightness.light ? kOnAccent : Colors.white;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_shade(color, 0.08), _shade(color, -0.12)],
        ),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(s * 0.3),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: s * 0.35, offset: Offset(0, s * 0.08))],
      ),
      child: Icon(icon, color: glyph, size: s * 0.56),
    );
  }
}

/// Lighter (+) or darker (-) version of [c], in HSL lightness.
Color _shade(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

/// Shrinks slightly the instant it is pressed (feedback on touch-down, like
/// iOS). No scale when the system asks for reduced motion.
class Pressable extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const Pressable({super.key, required this.onTap, required this.child});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final scale = _down && !MediaQuery.disableAnimationsOf(context) ? 0.96 : 1.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Thick ring for a 0-100 score, drawn in [kOnAccent] for use on the accent
/// card. [fraction] (0..1) animates the fill and the counted-up number.
class AccentRing extends StatelessWidget {
  final double size;
  final int score;
  final double fraction;

  const AccentRing({super.key, required this.size, required this.score, this.fraction = 1});

  @override
  Widget build(BuildContext context) {
    final shown = (score.clamp(0, 100) * fraction).round();
    return Semantics(
      label: 'Score $score out of 100',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(fraction: score.clamp(0, 100) / 100 * fraction),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$shown',
                  style: TextStyle(
                    color: kOnAccent,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '/100',
                  style: TextStyle(color: kOnAccent.withValues(alpha: 0.6), fontSize: 10.sp, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;

  _RingPainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.11;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: (size.shortestSide - stroke) / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = kOnAccent.withValues(alpha: 0.12));
    if (fraction > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraction, false, paint..color = kOnAccent);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}

class StatColumnData {
  final IconData icon;
  final Color color;
  final int count;
  final String label;
  final VoidCallback? onTap;

  const StatColumnData({required this.icon, required this.color, required this.count, required this.label, this.onTap});
}

/// One dark card split into equal columns by thin vertical dividers: an icon
/// tile on top, a big count, a small label. A column with a count opens its
/// detail on tap; an empty one is dimmed and inert. With [progress] the
/// counts tick up from 0 during the screen's entrance.
class StatColumnsCard extends StatelessWidget {
  final List<StatColumnData> columns;
  final Animation<double>? progress;

  const StatColumnsCard({super.key, required this.columns, this.progress});

  @override
  Widget build(BuildContext context) {
    final divider = Colors.white.withValues(alpha: 0.08);
    return BoldCard(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 4.w),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < columns.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, thickness: 1, color: divider, indent: 6.h, endIndent: 6.h),
              Expanded(child: _StatColumn(data: columns[i], progress: progress)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final StatColumnData data;
  final Animation<double>? progress;

  const _StatColumn({required this.data, required this.progress});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = data.count > 0 && data.onTap != null;
    final countUp = progress == null
        ? const AlwaysStoppedAnimation<double>(1)
        : CurvedAnimation(parent: progress!, curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic));
    return Semantics(
      button: enabled,
      label: '${data.count} ${data.label}',
      excludeSemantics: true,
      child: Opacity(
        opacity: data.count > 0 ? 1 : 0.4,
        child: Pressable(
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  data.onTap!();
                }
              : null,
          child: Column(
            children: [
              IconTile(icon: data.icon, color: data.color, size: 32.r, circle: true),
              SizedBox(height: 10.h),
              AnimatedBuilder(
                animation: countUp,
                builder: (_, _) => Text(
                  '${(data.count * countUp.value).round()}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.secondaryText, fontSize: 12.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary call to action: an accent pill with the label and a dark arrow
/// circle on the right.
class AccentPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData icon;

  const AccentPillButton({super.key, required this.label, this.onTap, this.icon = Icons.arrow_forward_rounded});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Container(
        // Fixed height (not vertical padding) so pills placed side by side line up exactly.
        height: 54.r,
        padding: EdgeInsets.fromLTRB(24.w, 0, 6.w, 0),
        decoration: BoxDecoration(color: boldAccent(context), borderRadius: BorderRadius.circular(32.r)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: kOnAccent, fontSize: 15.sp, fontWeight: FontWeight.w800, letterSpacing: -0.2),
              ),
            ),
            SizedBox(width: 12.w),
            CircleIcon(icon: icon, background: kOnAccent, foreground: boldAccent(context), size: 42.r),
          ],
        ),
      ),
    );
  }
}

/// Single-line width of [text] in [style], scaled by the user's text size.
double measureText(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// Card outline with a small rounded notch cut into the middle of the top
/// edge (the "connector tab" of stacked cards in the reference designs).
/// Use with [ClipPath] around a solid card; corners match [radius].
class TopNotchClipper extends CustomClipper<Path> {
  final double radius;
  final double notchWidth;
  final double notchDepth;

  const TopNotchClipper({required this.radius, required this.notchWidth, required this.notchDepth});

  @override
  Path getClip(Size size) {
    final card = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    // A pill centered on the top edge: its lower half bites into the card.
    final notch = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(size.width / 2, 0), width: notchWidth, height: notchDepth * 2),
          Radius.circular(notchDepth),
        ),
      );
    return Path.combine(PathOperation.difference, card, notch);
  }

  @override
  bool shouldReclip(TopNotchClipper old) =>
      old.radius != radius || old.notchWidth != notchWidth || old.notchDepth != notchDepth;
}
