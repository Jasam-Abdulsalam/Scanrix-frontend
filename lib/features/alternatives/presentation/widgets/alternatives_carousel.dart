import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/alternative_product_entity.dart';
import 'alternative_card.dart';
import 'alternative_style.dart';
import 'carousel_spring_physics.dart';
import 'dial_painter.dart';
import 'tap_ring_painter.dart';

/// Rotating wheel of alternative cards with a semicircle dial underneath.
///
/// The cards sit on a big circle whose centre (the pivot) is below the
/// screen. Swiping turns the wheel: side cards tilt and drop along the arc,
/// as if on a turning ring. The dial's ticks turn by the
/// same angle, so cards and ticks move together.
///
/// How it's put together (bottom to top in the Stack):
/// 1. The semicircle dial.
/// 2. The visible cards, painted by hand from the page offset so the centred
///    card is always on top.
/// 3. A transparent [PageView] that only handles the swipe, the snapping and
///    the taps.
/// 4. The tap ring, painted above everything with no clipping.
///
/// Everything per-frame is driven by `AnimatedBuilder`/`repaint` listeners on
/// the controllers, so scrolling never calls setState.
class AlternativesCarousel extends StatefulWidget {
  final List<AlternativeProductEntity> items;
  final int? originalScore;

  /// Opens the detail screen; the carousel waits for it to return before
  /// accepting another open.
  final Future<void> Function(AlternativeProductEntity item, AltPalette palette) onOpen;

  /// Called when a different card becomes the centred one (at the midpoint of
  /// a swipe, so the background can start changing right away).
  final ValueChanged<int>? onActiveChanged;

  const AlternativesCarousel({
    super.key,
    required this.items,
    required this.onOpen,
    this.originalScore,
    this.onActiveChanged,
  });

  @override
  State<AlternativesCarousel> createState() => _AlternativesCarouselState();
}

class _AlternativesCarouselState extends State<AlternativesCarousel> with TickerProviderStateMixin {
  /// Width of one swipe "page" as a fraction of the screen: how far you drag
  /// to turn the wheel by one card.
  static const _viewportFraction = 0.62;

  /// Wheel turn per card (rad), shared by the cards and the dial.
  static const _angleStep = 0.42;

  /// Wheel radius relative to the carousel width. Bigger = flatter arc.
  static const _wheelRadiusFactor = 1.05;

  /// Semicircle dial radius relative to the carousel width (0.5 = edge to edge).
  static const _dialRadiusFactor = 0.46;

  static const _scaleStep = 0.06;
  static const _minScale = 0.85;

  late final PageController _pc = PageController(viewportFraction: _viewportFraction);
  late final AnimationController _press = AnimationController(vsync: this);
  late final AnimationController _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  final _stackKey = GlobalKey();

  Offset? _tapPos;
  int? _pressedIndex;
  int _snapped = 0;
  bool _opening = false;

  @override
  void dispose() {
    _pc.dispose();
    _press.dispose();
    _ring.dispose();
    super.dispose();
  }

  double get _page =>
      _pc.hasClients && _pc.position.haveDimensions ? (_pc.page ?? 0) : _pc.initialPage.toDouble();

  Future<void> _onTap(int index, TapUpDetails details) async {
    if (_opening) return;
    // Side card: turn the wheel to it first; a second tap opens it.
    if ((index - _page).abs() > 0.5) {
      HapticFeedback.selectionClick();
      await _pc.animateToPage(index, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
      return;
    }

    final item = widget.items[index];
    final palette = altPaletteAt(index);
    _opening = true;
    try {
      if (MediaQuery.disableAnimationsOf(context)) {
        await widget.onOpen(item, palette);
        return;
      }
      final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
      _tapPos = box?.globalToLocal(details.globalPosition);
      _pressedIndex = index;
      HapticFeedback.lightImpact();

      _ring.forward(from: 0);
      await _press.animateTo(1, duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
      // Spring back while the ring is still expanding, then open.
      _press.animateBack(0, duration: const Duration(milliseconds: 500), curve: Curves.elasticOut);
      await Future<void>.delayed(const Duration(milliseconds: 160));
      if (!mounted) return;
      await widget.onOpen(item, palette);
    } finally {
      if (mounted) {
        _press.value = 0;
        _pressedIndex = null;
      }
      _opening = false;
    }
  }

  bool _onScrollEnd(ScrollEndNotification n) {
    final p = _page.round();
    if (p != _snapped) {
      _snapped = p;
      HapticFeedback.selectionClick();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final height = box.maxHeight;
        final gap = 20.h;

        // Semicircle dial pinned to the bottom: its flat edge sits on the
        // bottom of this box, which the page keeps inside the bottom safe
        // area. On short screens it gives up height so the cards still fit.
        final dialRadius = math.max(0.0, math.min(width * _dialRadiusFactor, height * 0.32));
        final dialCenter = Offset(width / 2, height);
        final dialTop = height - dialRadius;

        // Cards centred in the space above the dial.
        final cardWidth = width * 0.58;
        final cardHeight = math.max(0.0, math.min(cardWidth * 1.3, dialTop - gap * 2));
        final cardCenterY = dialTop / 2;

        final wheelRadius = width * _wheelRadiusFactor;
        final pivot = Offset(width / 2, cardCenterY + wheelRadius);

        return Stack(
          key: _stackKey,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: DialPainter(
                  controller: _pc,
                  itemCount: widget.items.length,
                  center: dialCenter,
                  radius: dialRadius,
                  angleStep: _angleStep,
                  discColor: Colors.white,
                  tickColor: Colors.white,
                  indicatorColor: const Color(0xFFFF4D4D),
                  tickWidth: 1.6.r,
                  shortTick: 7.h,
                  longTick: 14.h,
                  rimInset: 10.h,
                ),
              ),
            ),
            AnimatedBuilder(
              animation: Listenable.merge([_pc, _press]),
              builder: (context, _) => Stack(
                clipBehavior: Clip.none,
                children: _buildCards(pivot, wheelRadius, cardWidth, cardHeight),
              ),
            ),
            NotificationListener<ScrollEndNotification>(
              onNotification: _onScrollEnd,
              child: PageView.builder(
                controller: _pc,
                physics: const CarouselSpringPhysics(),
                itemCount: widget.items.length,
                onPageChanged: widget.onActiveChanged,
                itemBuilder: (context, i) => Semantics(
                  button: true,
                  label: '${widget.items[i].brand} ${widget.items[i].name}, '
                      'score ${widget.items[i].overallScore ?? 'unknown'}. Tap to view details.',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => _onTap(i, d),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: TapRingPainter(
                    progress: _ring,
                    center: () => _tapPos,
                    maxRadius: 60.r,
                    startStroke: 14.r,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildCards(Offset pivot, double wheelRadius, double cardWidth, double cardHeight) {
    final page = _page;
    // Far cards first, centred card last = on top.
    final order = List<int>.generate(widget.items.length, (i) => i)
      ..removeWhere((i) => (i - page).abs() > 2.2)
      ..sort((a, b) => (b - page).abs().compareTo((a - page).abs()));

    return [
      for (final i in order) _wheelCard(i, i - page, pivot, wheelRadius, cardWidth, cardHeight),
    ];
  }

  Widget _wheelCard(int index, double delta, Offset pivot, double wheelRadius, double cardWidth, double cardHeight) {
    final angle = delta * _angleStep;
    // Point on the wheel at this angle (0 = straight up from the pivot).
    final center = pivot + Offset(math.sin(angle), -math.cos(angle)) * wheelRadius;

    var scale = math.max(_minScale, 1 - delta.abs() * _scaleStep);
    if (index == _pressedIndex) scale *= 1 - 0.04 * _press.value;
    // Neighbours stay fully visible; cards further out fade away.
    final opacity = (1 - (delta.abs() - 1).clamp(0.0, 1.0)).toDouble();

    final transform = Matrix4.identity()
      ..rotateZ(angle)
      ..scaleByDouble(scale, scale, 1, 1);

    return Positioned(
      key: ValueKey(widget.items[index].barcode),
      left: center.dx - cardWidth / 2,
      top: center.dy - cardHeight / 2,
      width: cardWidth,
      height: cardHeight,
      child: Opacity(
        opacity: opacity,
        child: Transform(
          alignment: Alignment.center,
          transform: transform,
          child: RepaintBoundary(
            child: AlternativeCard(
              item: widget.items[index],
              palette: altPaletteAt(index),
              originalScore: widget.originalScore,
            ),
          ),
        ),
      ),
    );
  }
}
