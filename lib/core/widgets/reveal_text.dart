import 'package:flutter/material.dart';

/// Reveals [text] as a single unit, then fades it back out later in the
/// same timeline — e.g. text appears after a dot passes, stays solid,
/// then disappears as the dot expands to fill the screen.
class TextRevealFade extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final double timelineProgress; // 0.0 to 1.0, the whole animation's progress
  final double appearStart;
  final double appearEnd;
  final double disappearStart;
  final double disappearEnd;
  final Color startColor;
  final Color endColor;
  final double startOpacity;

  const TextRevealFade({
    super.key,
    required this.text,
    required this.baseStyle,
    required this.timelineProgress,
    required this.appearStart,
    required this.appearEnd,
    required this.disappearStart,
    required this.disappearEnd,
    this.startColor = const Color(0xFFF2F2F2),
    required this.endColor,
    this.startOpacity = 0.00,
  });

  double _easeOut(double t) => 1 - (1 - t) * (1 - t) * (1 - t);

  @override
  Widget build(BuildContext context) {
    final t = timelineProgress;

    double opacity;
    double colorMix;

    if (t < appearStart) {
      opacity = startOpacity;
      colorMix = 0.0;
    } else if (t < appearEnd) {
      final local = ((t - appearStart) / (appearEnd - appearStart)).clamp(0.0, 1.0);
      final eased = _easeOut(local);
      opacity = startOpacity + (1.0 - startOpacity) * eased;
      colorMix = eased;
    } else if (t < disappearStart) {
      opacity = 1.0;
      colorMix = 1.0;
    } else if (t < disappearEnd) {
      final local = ((t - disappearStart) / (disappearEnd - disappearStart)).clamp(0.0, 1.0);
      opacity = 1.0 - local; // straight fade out
      colorMix = 1.0;
    } else {
      opacity = 0.0;
      colorMix = 1.0;
    }

    final color = Color.lerp(startColor, endColor, colorMix)!;

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Text(text, style: baseStyle.copyWith(color: color)),
    );
  }
}