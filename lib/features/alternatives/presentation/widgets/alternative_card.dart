import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/alternative_product_entity.dart';
import 'alternative_style.dart';

const _ink = AltPalette.ink;

/// Share of the card height the light photo panel takes (down to the wave).
const kCardPhotoFraction = 0.44;

/// One wheel card, top to bottom: a light panel with the product photo, a
/// wave into the coloured part, the "AI Suggestion" chip, the brand (big) and
/// name, the approximate price (big, centred) with the size, and a full-width
/// "Avoids N flagged ingredients" pill. Dark text on a bright gradient.
///
/// The background and the price are two sibling [Hero]s (Heroes can't nest):
/// on tap the background grows into the detail screen (the photo panel
/// shrinks away during the flight) while the price flies to its new spot.
class AlternativeCard extends StatelessWidget {
  final AlternativeProductEntity item;
  final AltPalette palette;

  const AlternativeCard({super.key, required this.item, required this.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final waveY = box.maxHeight * kCardPhotoFraction;
        return Stack(
          children: [
            Positioned.fill(
              child: Hero(
                tag: altCardHeroTag(item.id),
                flightShuttleBuilder: altCardFlightShuttle(palette),
                child: AlternativeCardBackground(palette: palette, radius: 28.r, photoFraction: kCardPhotoFraction),
              ),
            ),
            // Photo inside the light panel (packs are mostly shot on white, so it blends in).
            Positioned(
              left: 20.w,
              right: 20.w,
              top: 12.h,
              height: waveY - 16.h,
              child: _CardPhoto(url: item.imageUrl),
            ),
            Positioned(
              left: 18.w,
              right: 18.w,
              top: waveY + box.maxHeight * 0.05,
              bottom: 16.h,
              child: _CardDetails(item: item),
            ),
          ],
        );
      },
    );
  }
}

class _CardPhoto extends StatelessWidget {
  final String? url;

  const _CardPhoto({this.url});

  @override
  Widget build(BuildContext context) {
    final icon = Center(child: Icon(Icons.inventory_2_outlined, color: _ink.withValues(alpha: 0.35), size: 46.r));
    if (url == null) return icon;
    return LayoutBuilder(
      builder: (context, box) => Image.network(
        url!,
        fit: BoxFit.contain,
        // Decode at display size, not the shop's 2000 px original.
        cacheHeight: (box.maxHeight * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, _, _) => icon,
        loadingBuilder: (_, child, progress) => progress == null ? child : icon,
      ),
    );
  }
}

class _CardDetails extends StatelessWidget {
  final AlternativeProductEntity item;

  const _CardDetails({required this.item});

  @override
  Widget build(BuildContext context) {
    final pill = item.avoidsLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AltAiChip(),
        SizedBox(height: 8.h),
        Text(
          item.brand,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: _ink, fontSize: 22.sp, fontWeight: FontWeight.w900, height: 1.1),
        ),
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: _ink.withValues(alpha: 0.55), fontSize: 13.sp, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Center(
          child: Hero(
            tag: altPriceHeroTag(item.id),
            child: AltPriceText(label: item.priceLabel, height: 40.h),
          ),
        ),
        if (item.size != null)
          Center(
            child: Text(
              item.size!,
              style: TextStyle(color: _ink.withValues(alpha: 0.55), fontSize: 11.sp, fontWeight: FontWeight.w700),
            ),
          ),
        const Spacer(),
        _WidePill(
          icon: pill != null ? Icons.block_rounded : Icons.lightbulb_outline_rounded,
          label: pill ?? item.whyBetter,
        ),
      ],
    );
  }
}

/// The card's background (also the detail screen's): the palette gradient, with
/// a light photo panel on top that ends in a wave and a white highlight line.
/// [photoFraction] 0 = no panel (the detail screen).
class AlternativeCardBackground extends StatelessWidget {
  final AltPalette palette;
  final double radius;
  final double photoFraction;

  const AlternativeCardBackground({super.key, required this.palette, required this.radius, this.photoFraction = 0});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: radius == 0
            ? null
            // Soft coloured glow around the card rather than a drop shadow under it.
            : [BoxShadow(color: palette.mid.withValues(alpha: 0.35), blurRadius: 36, spreadRadius: -6, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(painter: _CardBackgroundPainter(palette, photoFraction), child: const SizedBox.expand()),
      ),
    );
  }
}

class _CardBackgroundPainter extends CustomPainter {
  final AltPalette palette;
  final double photoFraction;

  _CardBackgroundPainter(this.palette, this.photoFraction);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Glow centred in the coloured part (lower when there is a photo panel).
    final glowCenter = Alignment(0, -1 + 2 * (photoFraction + (1 - photoFraction) * 0.45));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: glowCenter,
          radius: 0.9,
          colors: [palette.center, palette.mid, palette.edge],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
    if (photoFraction <= 0.001) return;

    final wave = _wave(size, size.height * photoFraction, size.height * 0.035);
    final panel = Path.from(wave)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(
      panel,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFEFEFEC)],
        ).createShader(rect),
    );
    canvas.drawPath(
      wave,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.height * 0.018
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  /// An S-shaped wave across the card: a little high on the left, dipping
  /// past the middle, rising towards the right edge.
  Path _wave(Size s, double y, double a) => Path()
    ..moveTo(0, y - a * 0.2)
    ..cubicTo(s.width * 0.22, y - a * 1.3, s.width * 0.38, y + a * 1.2, s.width * 0.6, y + a * 1.1)
    ..cubicTo(s.width * 0.8, y + a * 1.0, s.width * 0.9, y - a * 0.5, s.width, y - a * 1.2);

  @override
  bool shouldRepaint(_CardBackgroundPainter old) => old.palette != palette || old.photoFraction != photoFraction;
}

/// While the card flies to full screen, the corners ease to square and the
/// photo panel shrinks away (and back on pop), instead of snapping at the end.
HeroFlightShuttleBuilder altCardFlightShuttle(AltPalette palette) {
  return (context, animation, direction, fromContext, toContext) {
    final start = 28.r;
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        final t = Curves.easeOut.transform(animation.value);
        return AlternativeCardBackground(
          palette: palette,
          radius: lerpDouble(start, 0, t)!,
          photoFraction: lerpDouble(kCardPhotoFraction, 0, t)!,
        );
      },
    );
  };
}

/// "≈ ₹349" (or "Price unknown"), scaled to fit [height] so the Hero flight
/// between the small card and the big detail header stays smooth.
class AltPriceText extends StatelessWidget {
  final String? label;
  final double height;

  const AltPriceText({super.key, required this.label, required this.height});

  @override
  Widget build(BuildContext context) {
    // Material: Text inside a Hero flight otherwise shows the debug underline.
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        height: height,
        child: FittedBox(
          child: Text(
            label ?? 'Price unknown',
            style: TextStyle(
              color: label == null ? _ink.withValues(alpha: 0.5) : _ink,
              fontSize: label == null ? 22.sp : 48.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Always shown: these come from the AI, not from Scanrix's database.
/// White pill with a sparkle, as in the design.
class AltAiChip extends StatelessWidget {
  const AltAiChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, color: _ink, size: 13.r),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              'AI Suggestion',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _ink, fontSize: 11.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// The product photo on a white rounded tile (packs are usually shot on white),
/// or the product icon when there is no photo or it fails to load.
class AltThumb extends StatelessWidget {
  final String? url;
  final double size;

  const AltThumb({super.key, this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.inventory_2_outlined, color: _ink.withValues(alpha: 0.7), size: size * 0.45);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: url == null ? Colors.white.withValues(alpha: 0.55) : Colors.white,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: url == null
          ? icon
          : Image.network(
              url!,
              fit: BoxFit.contain,
              // Decode at display size, not the shop's 2000 px original.
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
              errorBuilder: (_, _, _) => icon,
              loadingBuilder: (_, child, progress) => progress == null ? child : Center(child: icon),
            ),
    );
  }
}

/// Full-width translucent pill at the bottom of the card.
class _WidePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WidePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _ink, size: 15.r),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _ink, fontSize: 12.sp, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
