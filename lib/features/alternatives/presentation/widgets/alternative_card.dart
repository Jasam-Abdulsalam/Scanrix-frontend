import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/alternative_product_entity.dart';
import 'alternative_style.dart';

const _ink = AltPalette.ink;

/// One wheel card: brand + name top-left, the product photo top-right, the
/// approximate price in the middle with the size under it, an "AI suggestion"
/// chip, then a footer with what it avoids and how its price compares.
/// Dark text on a bright radial gradient.
///
/// The gradient background and the price are two sibling [Hero]s (Heroes can't
/// nest), so on tap the card grows into the detail screen's background while
/// the price flies to its new spot.
class AlternativeCard extends StatelessWidget {
  final AlternativeProductEntity item;
  final AltPalette palette;
  final int? originalPriceInr;

  const AlternativeCard({super.key, required this.item, required this.palette, this.originalPriceInr});

  @override
  Widget build(BuildContext context) {
    final avoids = item.avoidsLabel;
    final compared = item.priceComparedTo(originalPriceInr);
    return Stack(
      children: [
        Positioned.fill(
          child: Hero(
            tag: altCardHeroTag(item.id),
            flightShuttleBuilder: altCardFlightShuttle(palette),
            child: AlternativeCardBackground(palette: palette, radius: 28.r),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(18.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _ink, fontSize: 16.sp, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _ink.withValues(alpha: 0.6),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  AltThumb(url: item.imageUrl, size: 56.r),
                ],
              ),
              const Spacer(),
              Center(
                child: Hero(
                  tag: altPriceHeroTag(item.id),
                  child: AltPriceText(label: item.priceLabel, height: 56.h),
                ),
              ),
              if (item.size != null)
                Center(
                  child: Text(
                    item.size!,
                    style: TextStyle(color: _ink.withValues(alpha: 0.55), fontSize: 12.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              SizedBox(height: 10.h),
              const Center(child: AltAiChip()),
              const Spacer(),
              Row(
                children: [
                  Flexible(
                    child: avoids != null
                        ? _FooterPill(icon: Icons.block_rounded, label: avoids)
                        : Text(
                            item.whyBetter,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: _ink.withValues(alpha: 0.65), fontSize: 11.sp),
                          ),
                  ),
                  if (compared != null) ...[
                    SizedBox(width: 8.w),
                    Text(
                      compared,
                      style: TextStyle(color: _ink, fontSize: 11.sp, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The gradient slab behind a card; also the detail screen's background.
class AlternativeCardBackground extends StatelessWidget {
  final AltPalette palette;
  final double radius;

  const AlternativeCardBackground({super.key, required this.palette, required this.radius});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: palette.gradient,
        boxShadow: radius == 0
            ? null
            : [BoxShadow(color: palette.edge.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 14))],
      ),
    );
  }
}

/// While the card flies to full screen, round corners ease to square (and back
/// on pop), instead of snapping at the end of the flight.
HeroFlightShuttleBuilder altCardFlightShuttle(AltPalette palette) {
  return (context, animation, direction, fromContext, toContext) {
    final start = 28.r;
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) => AlternativeCardBackground(
        palette: palette,
        radius: lerpDouble(start, 0, Curves.easeOut.transform(animation.value))!,
      ),
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
              'AI suggestion',
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

class _FooterPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FooterPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _ink, size: 13.r),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              label,
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
