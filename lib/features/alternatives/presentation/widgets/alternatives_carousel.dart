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
/// The cards are spokes of a wheel turning around the dial's centre, a
/// quarter turn apart. At rest only the centred card is on screen. On a swipe
/// the current card swings out and down past one bottom corner while the next
/// one swings up from the other corner and turns upright in the middle. The
/// dial's ticks turn with the swipe.
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

  /// Dial turn per card (rad).
  static const _dialStep = 0.42;

  /// Semicircle dial radius relative to the carousel width (0.5 = edge to edge).
  static const _dialRadiusFactor = 0.46;

  /// Centred card width relative to the carousel width.
  static const _cardWidthFactor = 0.66;

  /// Wheel turn per card (rad): a quarter turn, so the cards are spokes 90°
  /// apart. At rest the neighbours are off screen; halfway through a swap
  /// both cards are down in the bottom corners.
  static const _cardStep = math.pi / 2;

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
        final cardWidth = width * _cardWidthFactor;
        final cardHeight = math.max(0.0, math.min(cardWidth * 1.3, dialTop - gap * 2));
        final cardCenterY = dialTop / 2;

        // The cards are spokes turning around the dial's centre.
        final wheel = _Wheel(pivot: dialCenter, radius: math.max(1.0, dialCenter.dy - cardCenterY));

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
                  angleStep: _dialStep,
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
                children: _buildCards(wheel, cardWidth, cardHeight),
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

  List<Widget> _buildCards(_Wheel wheel, double cardWidth, double cardHeight) {
    final page = _page;
    // Only the centred card and the ones swinging in/out are on screen.
    // Far cards first, centred card last = on top; the two swap order at the
    // halfway point, when both are down in the bottom corners.
    final order = List<int>.generate(widget.items.length, (i) => i)
      ..removeWhere((i) => (i - page).abs() >= 1.5)
      ..sort((a, b) => (b - page).abs().compareTo((a - page).abs()));

    return [
      for (final i in order) _wheelCard(i, i - page, wheel, cardWidth, cardHeight),
    ];
  }

  Widget _wheelCard(int index, double delta, _Wheel wheel, double cardWidth, double cardHeight) {
    // Spoke angle: 0 = straight up from the pivot, positive = clockwise.
    // The next card waits a quarter turn to the right and the wheel turns
    // counter-clockwise to bring it up.
    final angle = delta * _cardStep;
    final center = wheel.pivot + Offset(math.sin(angle), -math.cos(angle)) * wheel.radius;

    // Same size all the way round, like the reference; only the tap press
    // shrinks the card.
    final scale = index == _pressedIndex ? 1 - 0.04 * _press.value : 1.0;
    // Fades only past a quarter turn, where it is off screen anyway.
    final opacity = (1 - (delta.abs() - 1) / 0.5).clamp(0.0, 1.0);

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

/// Where the card wheel turns: around [pivot] (the dial's centre) at
/// [radius] (pivot to the centred card's centre).
class _Wheel {
  final Offset pivot;
  final double radius;

  const _Wheel({required this.pivot, required this.radius});
}
