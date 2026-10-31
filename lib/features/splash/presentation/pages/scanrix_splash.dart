// Scanrix animated splash — "Look and wave"
//
// Picks up seamlessly from the native (engine-start) splash, which shows only the
// leaf-eye, centred, at 136 x 136 dp on #142628. This widget's first frame is that
// exact picture, then:
//   0.00–1.25 s  the pupil glances left, right, and settles back
//   1.25–1.90 s  a wave of light runs across the six colour bands;
//                the leaf rises, "Scanrix" fades in, then the tagline
//   ~1.9 s       the glint sparkles
//   2.8 s        onFinished is called
//
// Needs: assets/splash/scanrix_wordmark.png and assets/splash/scanrix_tagline.png in pubspec.yaml.
// No packages needed for the animation itself.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/constants/hero_tags.dart';

class ScanrixSplash extends StatefulWidget {
  const ScanrixSplash({super.key, this.onFinished});

  /// Called once the animation has finished (go to your first real screen here).
  final VoidCallback? onFinished;

  /// Must match the native splash background colour.
  static const Color background = Color(0xFF142628);

  /// Must match the leaf size of the native splash image (scanrix_leaf.png is
  /// 544 px = 136 dp at 4x, which is what flutter_native_splash expects).
  static const double leafSize = 136;

  @override
  State<ScanrixSplash> createState() => _ScanrixSplashState();
}

class _ScanrixSplashState extends State<ScanrixSplash>
    with SingleTickerProviderStateMixin {
  static const double _totalSeconds = 2.8;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onFinished?.call();
    });
    // Load the name images first so they never pop in late. The leaf is drawn in
    // code, so it is on screen from the very first frame, matching the native splash.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        precacheImage(const AssetImage('assets/splash/scanrix_wordmark.png'), context),
        precacheImage(const AssetImage('assets/splash/scanrix_tagline.png'), context),
      ]);
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScanrixSplash.background,
      body: LayoutBuilder(builder: (context, box) {
        // Centre of the whole screen, the same point the native splash centres on.
        final cx = box.maxWidth / 2;
        final cy = box.maxHeight / 2;
        const leaf = ScanrixSplash.leafSize;
        final k = leaf / _Logo.leafBox.width; // logo px -> logical px

        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value * _totalSeconds;

            // The leaf starts centred, then rises to make room for the name.
            final up = _eio(_seg(t, 1.25, 1.7));
            final rise = _Logo.riseToFinal * k * up;
            final leafLeft = cx - leaf / 2;
            final leafTop = cy - leaf / 2 - rise;

            Rect place(Rect logoRect) => Rect.fromLTWH(
                  leafLeft + (logoRect.left - _Logo.leafBox.left) * k,
                  leafTop + (logoRect.top - _Logo.leafBox.top) * k,
                  logoRect.width * k,
                  logoRect.height * k,
                );

            final word = _eo(_seg(t, 1.4, 1.8));
            final tag = _eo(_seg(t, 1.65, 2.05));

            return Stack(children: [
              Positioned(
                left: leafLeft,
                top: leafTop,
                width: leaf,
                height: leaf,
                // Flies to the login page's logo (same tag) on the way out.
                // In flight it shows the login side's leaf image, which is
                // this painter's final frame.
                child: Hero(
                  tag: scanrixLogoHeroTag,
                  child: CustomPaint(painter: _LeafPainter(t)),
                ),
              ),
              // Name and tagline also fly to their places on the login page.
              Positioned.fromRect(
                rect: place(_Logo.wordRect),
                child: Hero(
                  tag: scanrixWordmarkHeroTag,
                  child: Opacity(
                    opacity: word,
                    child: Transform.translate(
                      offset: Offset(0, _lerp(30, 0, word) * k),
                      child: Image.asset('assets/splash/scanrix_wordmark.png'),
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: place(_Logo.tagRect),
                child: Hero(
                  tag: scanrixTaglineHeroTag,
                  child: Opacity(
                    opacity: tag,
                    child: Transform.translate(
                      offset: Offset(0, _lerp(22, 0, tag) * k),
                      child: Image.asset('assets/splash/scanrix_tagline.png'),
                    ),
                  ),
                ),
              ),
            ]);
          },
        );
      }),
    );
  }
}

/// Logo geometry, in the original 1372 x 1148 logo image's pixels.
class _Logo {
  /// The leaf's square bounding box (what scanrix_leaf.png is cropped to).
  static const Rect leafBox = Rect.fromLTWH(408, 62, 556, 556);
  static const Rect wordRect = Rect.fromLTWH(214, 689, 953, 181);
  static const Rect tagRect = Rect.fromLTWH(161, 920, 1049, 86);

  /// How far the leaf rises so leaf + name + tagline end up centred together.
  static const double riseToFinal = 189;

  static const Offset eye = Offset(692, 334);
  static const double pupilR = 117;
  static const Offset glint = Offset(760, 322);
  static const double glintR = 20;
  static const Color pupil = Color(0xFF0C1D14);

  static Path upper() => Path()
    ..moveTo(940, 66)
    ..cubicTo(800, 62, 660, 90, 560, 150)
    ..cubicTo(450, 220, 405, 320, 408, 450)
    ..cubicTo(409, 500, 414, 545, 422, 583)
    ..close();

  static Path lower() => Path()
    ..moveTo(960, 86)
    ..cubicTo(968, 200, 958, 300, 930, 360)
    ..cubicTo(890, 470, 820, 560, 700, 600)
    ..cubicTo(620, 625, 520, 618, 442, 604)
    ..close();

  static const bands = <_Band>[
    _Band(Rect.fromLTWH(380, 40, 204, 580), Color(0xFF14A89A), true),
    _Band(Rect.fromLTWH(583, 40, 170, 580), Color(0xFF0F9488), true),
    _Band(Rect.fromLTWH(752, 40, 230, 580), Color(0xFF0B7F78), true),
    _Band(Rect.fromLTWH(420, 60, 570, 214), Color(0xFF7DF5DC), false),
    _Band(Rect.fromLTWH(420, 273, 570, 170), Color(0xFF39F5C5), false),
    _Band(Rect.fromLTWH(420, 442, 570, 200), Color(0xFF2CC1D2), false),
  ];

  /// Wave order: bottom-left tip to top-right tip (indexes into [bands]).
  static const waveOrder = [0, 5, 1, 4, 2, 3];
}

class _Band {
  const _Band(this.rect, this.color, this.isUpper);
  final Rect rect;
  final Color color;
  final bool isUpper;
}

class _LeafPainter extends CustomPainter {
  _LeafPainter(this.t);
  final double t; // seconds since start

  static final Path _upper = _Logo.upper();
  static final Path _lower = _Logo.lower();

  @override
  void paint(Canvas canvas, Size size) {
    // Map the leaf's logo-pixel box onto this widget's box.
    final k = size.width / _Logo.leafBox.width;
    canvas.scale(k);
    canvas.translate(-_Logo.leafBox.left, -_Logo.leafBox.top);

    // Colour wave: each band brightens and lifts a touch as the wave passes.
    final bump = List<double>.filled(6, 0);
    for (var i = 0; i < 6; i++) {
      final t0 = 1.25 + i * 0.09;
      bump[_Logo.waveOrder[i]] =
          _eo(_seg(t, t0, t0 + 0.14)) * (1 - _ei(_seg(t, t0 + 0.14, t0 + 0.42)));
    }
    for (var i = 0; i < 6; i++) {
      final b = _Logo.bands[i];
      canvas.save();
      final c = b.rect.center;
      final s = 1 + 0.025 * bump[i];
      canvas.translate(c.dx, c.dy);
      canvas.scale(s);
      canvas.translate(-c.dx, -c.dy);
      canvas.clipPath(b.isUpper ? _upper : _lower);
      canvas.drawRect(b.rect, Paint()..color = _brighten(b.color, 1 + 0.45 * bump[i]));
      canvas.restore();
    }

    // Look around: left, right, back to centre with a small settle.
    final l = _eio(_seg(t, 0.2, 0.38));
    final r = _eio(_seg(t, 0.62, 0.82));
    final back = _eob(_seg(t, 1.0, 1.25), 1.6);
    final dx = _lerp(_lerp(_lerp(0, -34, l), 34, r), 0, back);
    final dy = _lerp(_lerp(_lerp(0, -6, l), -6, r), 0, back);
    final eye = _Logo.eye.translate(dx, dy);
    canvas.drawCircle(eye, _Logo.pupilR, Paint()..color = _Logo.pupil);

    // Glint sparkles as the wave ends.
    final g = _eo(_seg(t, 1.85, 1.98)) * (1 - _eo(_seg(t, 1.98, 2.3)));
    canvas.drawCircle(
      _Logo.glint.translate(dx, dy),
      _Logo.glintR * (1 + 0.7 * g),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_LeafPainter old) => old.t != t;
}

// ---- helpers (same curves as the preview) ----

/// Like CSS brightness(): multiplies each channel, capped at 255.
Color _brighten(Color c, double f) {
  int ch(double v) => (v * 255.0 * f).round().clamp(0, 255);
  return Color.fromARGB(255, ch(c.r), ch(c.g), ch(c.b));
}

double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
double _lerp(double a, double b, double p) => a + (b - a) * p;
double _eo(double x) => 1 - math.pow(1 - x, 3).toDouble();
double _ei(double x) => x * x * x;
double _eio(double x) =>
    x < 0.5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3).toDouble() / 2;
double _eob(double x, [double s = 1.4]) {
  final y = x - 1;
  return 1 + (s + 1) * y * y * y + s * y * y;
}
