import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';

/// Full-screen "AI is working" state: an orb that draws ingredient dots into
/// its core, plus status lines that step forward (once, no looping back) so
/// a 10-30 s wait feels like progress rather than a stuck spinner.
///
/// With reduced motion on (`MediaQuery.disableAnimations`), the orb is drawn
/// still and only the text changes.
class AiThinkingView extends StatefulWidget {
  const AiThinkingView({super.key});

  static const steps = [
    'Reading the ingredient list',
    'Looking up what each one does',
    'Checking for known risks',
    'Writing a plain summary',
  ];

  @override
  State<AiThinkingView> createState() => _AiThinkingViewState();
}

class _AiThinkingViewState extends State<AiThinkingView> {
  static const _stepEvery = Duration(milliseconds: 2600);
  int _step = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_stepEvery, (t) {
      if (_step >= AiThinkingView.steps.length - 1) return t.cancel();
      setState(() => _step++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AiThinkingOrb(size: 168.r),
            SizedBox(height: 36.h),
            SizedBox(
              height: 26.h,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  '${AiThinkingView.steps[_step]}…',
                  key: ValueKey(_step),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'This usually takes 10 to 30 seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryText, fontSize: 13.sp, height: 1.4),
            ),
            SizedBox(height: 20.h),
            _StepDots(count: AiThinkingView.steps.length, current: _step, color: colors.neonEmerald),
          ],
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int count;
  final int current;
  final Color color;

  const _StepDots({required this.count, required this.current, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.symmetric(horizontal: 3.w),
            width: i == current ? 18.r : 6.r,
            height: 6.r,
            decoration: BoxDecoration(
              color: i <= current ? color : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),
      ],
    );
  }
}

/// The animated orb on its own. One 8 s controller drives everything; every
/// motion completes a whole number of cycles per loop so the repeat has no seam.
class AiThinkingOrb extends StatefulWidget {
  final double size;

  const AiThinkingOrb({super.key, required this.size});

  @override
  State<AiThinkingOrb> createState() => _AiThinkingOrbState();
}

class _AiThinkingOrbState extends State<AiThinkingOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 8));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 0.12;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(painter: _OrbPainter(_c, context.colors.neonEmerald)),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final Animation<double> t;
  final Color accent;

  _OrbPainter(this.t, this.accent) : super(repaint: t);

  static const _particles = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final v = t.value;
    const tau = math.pi * 2;

    // Soft halo behind everything.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          accent.withValues(alpha: 0.18),
          accent.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Two thin rings turning in opposite directions (2 revs / -1 rev per loop).
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final r1 = r * 0.62;
    canvas.drawCircle(c, r1, ring..strokeWidth = 1.0..color = Colors.white.withValues(alpha: 0.07));
    canvas.drawArc(Rect.fromCircle(center: c, radius: r1), v * tau * 2, 1.3,
        false, ring..strokeWidth = 2.2..color = accent.withValues(alpha: 0.85));
    final r2 = r * 0.86;
    canvas.drawCircle(c, r2, ring..strokeWidth = 1.0..color = Colors.white.withValues(alpha: 0.05));
    for (var k = 0; k < 2; k++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r2), -v * tau + k * math.pi, 0.7,
          false, ring..strokeWidth = 1.6..color = accent.withValues(alpha: 0.45));
    }

    // Ingredient dots drifting from the outer ring into the core (2 trips per loop each).
    final dot = Paint();
    for (var i = 0; i < _particles; i++) {
      final p = (v * 2 + i / _particles) % 1.0;
      final angle = i * tau / _particles + p * 0.9;
      final dist = r * (0.92 - 0.62 * Curves.easeIn.transform(p));
      final pos = c + Offset(math.cos(angle), math.sin(angle)) * dist;
      dot.color = accent.withValues(alpha: 0.9 * math.sin(math.pi * p));
      canvas.drawCircle(pos, r * 0.025 * (1 - 0.5 * p), dot);
    }

    // Breathing core (4 breaths per loop = one every 2 s).
    final breath = 0.5 + 0.5 * math.sin(v * tau * 4);
    final coreR = r * (0.24 + 0.03 * breath);
    canvas.drawCircle(
      c,
      coreR * 1.9,
      Paint()
        ..shader = RadialGradient(colors: [
          accent.withValues(alpha: 0.25 + 0.15 * breath),
          accent.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: c, radius: coreR * 1.9)),
    );
    canvas.drawCircle(
      c,
      coreR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: [Color.lerp(accent, Colors.white, 0.55)!, accent, Color.lerp(accent, Colors.black, 0.45)!],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: coreR)),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.accent != accent;
}
