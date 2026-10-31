import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../products/presentation/widgets/analysis_result_view.dart' show VerdictDisplay;
import '../../domain/entities/alternative_product_entity.dart';
import 'alternative_style.dart';

const _ink = AltPalette.ink;

/// One wheel card: brand + name top-left, thumbnail top-right, the big score
/// in the middle, then the verdict and a footer with the score gain over the
/// scanned product and the price. Dark text on a bright radial gradient.
///
/// The gradient background and the score are two sibling [Hero]s (Heroes can't
/// nest), so on tap the card grows into the detail screen's background while
/// the score flies to its new spot.
class AlternativeCard extends StatelessWidget {
  final AlternativeProductEntity item;
  final AltPalette palette;
  final int? originalScore;

  const AlternativeCard({super.key, required this.item, required this.palette, this.originalScore});

  @override
  Widget build(BuildContext context) {
    final gain = item.scoreGainOver(originalScore);
    final price = item.priceLabel;
    return Stack(
      children: [
        Positioned.fill(
          child: Hero(
            tag: altCardHeroTag(item.barcode),
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
                  AltThumb(url: item.imageUrl, size: 38.r),
                ],
              ),
              const Spacer(),
              Center(
                child: Hero(
                  tag: altScoreHeroTag(item.barcode),
                  child: AltScoreText(score: item.overallScore, height: 72.h),
                ),
              ),
              SizedBox(height: 8.h),
              Center(child: AltVerdictChip(verdict: item.verdict)),
              const Spacer(),
              Row(
                children: [
                  if (gain != null)
                    Flexible(child: _FooterPill(icon: Icons.trending_up_rounded, label: '+$gain vs. yours'))
                  else
                    Flexible(
                      child: Text(
                        item.concernLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _ink.withValues(alpha: 0.6), fontSize: 11.sp),
                      ),
                    ),
                  if (price != null) ...[
                    const Spacer(),
                    Text(
                      price,
                      style: TextStyle(color: _ink, fontSize: 13.sp, fontWeight: FontWeight.w700),
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

/// "92 /100", scaled to fit [height] so the Hero flight between the small card
/// and the big detail header stays smooth.
class AltScoreText extends StatelessWidget {
  final int? score;
  final double height;

  const AltScoreText({super.key, required this.score, required this.height});

  @override
  Widget build(BuildContext context) {
    // Material: Text inside a Hero flight otherwise shows the debug underline.
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        height: height,
        child: FittedBox(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                score?.toString() ?? '--',
                style: TextStyle(color: _ink, fontSize: 64.sp, fontWeight: FontWeight.w900, height: 1),
              ),
              Text(
                '/100',
                style: TextStyle(color: _ink.withValues(alpha: 0.5), fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AltVerdictChip extends StatelessWidget {
  final String verdict;

  const AltVerdictChip({super.key, required this.verdict});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        // Near-white chip: the verdict colour reads on every palette.
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(verdict.verdictIcon, color: _verdictInk(verdict), size: 14.r),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              verdict.verdictLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _ink, fontSize: 11.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  /// Darker shades of the verdict colours: the neon ones wash out on white.
  static Color _verdictInk(String verdict) => switch (verdict) {
        'safe' => const Color(0xFF0E9F62),
        'caution' => const Color(0xFFC77F00),
        'avoid' => const Color(0xFFD13A3A),
        _ => verdict.verdictColor,
      };
}

class AltThumb extends StatelessWidget {
  final String? url;
  final double size;

  const AltThumb({super.key, required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConstants.resolveMediaUrl(url);
    final placeholder = Icon(Icons.inventory_2_outlined, color: _ink.withValues(alpha: 0.7), size: size * 0.5);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.55), shape: BoxShape.circle),
      child: resolved == null
          ? placeholder
          : Image.network(resolved, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder),
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
