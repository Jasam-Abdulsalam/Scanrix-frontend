import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/ingredient_entity.dart';
import '../../domain/entities/safety_engine_entity.dart';
import '../pages/ingredients_breakdown_page.dart';
import '../pages/ingredients_page.dart';
import 'analysis_highlights_card.dart';
import 'highlight_row.dart';
import 'safety_disclaimer.dart';
import 'status_colors.dart';

/// Verdict → display color/label/icon. Shared by the barcode result page
/// (`ProductDetailPage`) and the ingredients-OCR result page
/// (`IngredientAnalysisResultPage`) so both flows render identically once
/// they have a verdict. Kept as a plain string extension (no BuildContext)
/// since it's used in places without one; `kWarnAmber`/`kDangerRed` below are the
/// same semantic shades used inside this file for FAIR/POOR and watch-out
/// states, so the two stay visually consistent even though this extension
/// can't pull `neonEmerald` from the current theme.
extension VerdictDisplay on String {
  Color get verdictColor => switch (this) {
    'safe' => const Color(0xFF25E28B),
    'caution' => kWarnAmber,
    'avoid' => kDangerRed,
    _ => const Color(0xFF8E9E96), // unknown / error
  };

  IconData get verdictIcon => switch (this) {
    'safe' => Icons.check_circle_rounded,
    'caution' => Icons.warning_rounded,
    'avoid' => Icons.dangerous_rounded,
    'error' => Icons.error_outline_rounded,
    _ => Icons.help_outline_rounded,
  };

  String get verdictLabel => switch (this) {
    'safe' => 'Safe',
    'caution' => 'Use With Caution',
    'avoid' => 'Avoid',
    'error' => 'Analysis Failed',
    _ => 'Unable To Determine',
  };
}

/// Score → the short badge word shown inside the gauge ("GOOD" / "FAIR" /
/// "POOR") and its color. Takes the current `AppThemeColors` so "GOOD"
/// always matches the theme's actual emerald (`neonEmerald`), not a
/// hardcoded shade — this is what makes the gauge repaint correctly if the
/// user switches between `darkGreen` and `blackishReference`.
typedef _ScoreBand = ({Color color, String label});

_ScoreBand _bandFor(int score, AppThemeColors colors) {
  if (score >= 70) return (color: colors.neonEmerald, label: 'GOOD');
  if (score >= 40) return (color: kWarnAmber, label: 'FAIR');
  return (color: kDangerRed, label: 'POOR');
}

/// Full analysis screen: app bar (back / favorite), product hero, circular
/// score gauge, one-line summary, up to three highlight rows (safety fit,
/// good ingredients, watch-outs), and the primary actions.
///
/// With a [safetyEngine] the highlight rows and the detail sections below
/// the buttons (recognised list, "Not assessed", disclaimer) are built from
/// its findings. Without one - an older cached barcode result - the legacy
/// per-ingredient rows and [IngredientsPage] are used. [unknownIngredients] is
/// the OCR response's top-level list of names the database couldn't match.
/// [aiSection] is the optional opt-in "AI verdict" block, shown beside (never
/// replacing) the database result.
///
/// [productName] and [productImageUrl] are optional — the hero still
/// renders without them (placeholder icon, no name line) so this also
/// works for flows without a resolved product identity.
class AnalysisResultView extends StatelessWidget {
  final String verdict;
  final int? overallScore;
  final String? summary;
  final SafetyEngine? safetyEngine;
  final List<String> unknownIngredients;
  final Widget? aiSection;
  final List<IngredientEntity> ingredients;
  final String? productName;
  final String? productImageUrl;
  final String? category;
  final String? brand;
  final String? quantity;
  final String skinType;
  final VoidCallback? onBack;
  final VoidCallback? onFavorite;
  final VoidCallback? onViewAlternatives;
  final VoidCallback? onAddToRoutine;
  final bool isFavorite;

  const AnalysisResultView({
    super.key,
    required this.verdict,
    required this.overallScore,
    required this.summary,
    this.safetyEngine,
    this.unknownIngredients = const [],
    this.aiSection,
    this.ingredients = const [],
    this.productName,
    this.productImageUrl,
    this.category,
    this.brand,
    this.quantity,
    this.skinType = 'your skin',
    this.onBack,
    this.onFavorite,
    this.onViewAlternatives,
    this.onAddToRoutine,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final concerning = ingredients.where((i) => i.concerns.isNotEmpty).toList();
    final isCosmetic = _isCosmetic(category);
    // Fall back to a verdict-derived score so the gauge always has something
    // to draw, even before a numeric score is wired up end-to-end.
    final score =
        overallScore ??
        switch (verdict) {
          'safe' => 85,
          'caution' => 55,
          'avoid' => 20,
          _ => 50,
        };
    final band = _bandFor(score, colors);

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        gradient: RadialGradient(
          center: const Alignment(0.9, -0.9),
          radius: 1.3,
          colors: colors.headerGradient,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative leaf, top-right, behind the content.
          Positioned(
            top: 0,
            right: 0,
            width: 230.w,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.4,
                child: Image.asset(
                  'assets/images/plant.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SafeArea(
            // Stack (not Column) so content scrolls *under* the faded action bar.
            child: Stack(
              children: [
                Positioned.fill(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 130.h),
                    children: [
                      _TopBar(
                        onBack: onBack,
                        onFavorite: onFavorite,
                        isFavorite: isFavorite,
                        colors: colors,
                      ),
                      SizedBox(height: 16.h),
                      // Always rendered — with graceful fallbacks for a missing image
                      // or name — so this section is never silently skipped.
                      _ProductHero(
                        imageUrl: productImageUrl,
                        name: productName,
                        brand: brand,
                        quantity: quantity,
                        category: category,
                        colors: colors,
                      ),
                      SizedBox(height: 24.h),
                      _AssessmentCard(
                        score: score,
                        band: band,
                        summary: summary,
                        colors: colors,
                      ),
                      SizedBox(height: 20.h),
                      if (safetyEngine != null)
                        AnalysisHighlightsCard(
                          safetyEngine: safetyEngine,
                          legacyIngredients: ingredients,
                          unknownIngredients: unknownIngredients,
                    onOpenTab: (tab) => _openBreakdown(context, tab),
                        )
                      else
                        GlassCard(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 6.h,
                          ),
                          child: Column(
                            children: [
                              // Skin fit only makes sense for cosmetics, and its text
                              // is derived from the analysed ingredients (no canned claims).
                              if (isCosmetic) ...[
                                HighlightRow(
                                  icon: Icons.eco_rounded,
                                  iconColor: concerning.isEmpty
                                      ? colors.neonEmerald
                                      : kWarnAmber,
                                  title: 'Skin compatibility',
                                  subtitle: concerning.isEmpty
                                      ? 'No concerns found for $skinType.'
                                      : '${concerning.length} ingredient${concerning.length == 1 ? '' : 's'} flagged for $skinType.',
                                  colors: colors,
                                  onTap: concerning.isEmpty
                                      ? null
                                      : () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => IngredientsPage(
                                              ingredients: ingredients,
                                              productName: productName,
                                              skinType: skinType,
                                              initialFlaggedOnly: true,
                                            ),
                                          ),
                                        ),
                                ),
                                RowDivider(colors: colors),
                              ],
                              if (ingredients.isNotEmpty)
                                HighlightRow(
                                  icon: Icons.science_rounded,
                                  iconColor: colors.neonEmerald,
                                  title: 'Ingredients',
                                  subtitle:
                                      '${ingredients.length} ingredient${ingredients.length == 1 ? '' : 's'}'
                                      '${concerning.isEmpty ? '' : ' · ${concerning.length} flagged'}. Tap to view all.',
                                  colors: colors,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => IngredientsPage(
                                        ingredients: ingredients,
                                        productName: productName,
                                        skinType: skinType,
                                        initialFlaggedOnly: false,
                                      ),
                                    ),
                                  ),
                                ),
                              if (concerning.isNotEmpty) ...[
                                if (ingredients.isNotEmpty)
                                  RowDivider(colors: colors),
                                HighlightRow(
                                  icon: Icons.warning_rounded,
                                  iconColor: kWarnAmber,
                                  title: 'Watch out',
                                  subtitle:
                                      'Contains ${concerning.first.name}${concerning.first.concerns.isNotEmpty ? ' which may ${concerning.first.concerns.first}' : ''}.',
                                  colors: colors,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => IngredientsPage(
                                        ingredients: ingredients,
                                        productName: productName,
                                        skinType: skinType,
                                        initialFlaggedOnly: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (aiSection != null) ...[
                        SizedBox(height: 16.h),
                        aiSection!,
                      ],
                      if (safetyEngine != null) ...[
                        SizedBox(height: 16.h),
                        SafetyDisclaimer(text: safetyEngine!.disclaimer),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _BottomActions(
                    onViewAlternatives: onViewAlternatives,
                    onAddToRoutine: isCosmetic ? onAddToRoutine : null,
                    showRoutine: isCosmetic,
                    colors: colors,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openBreakdown(BuildContext context, BreakdownTab tab) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IngredientsBreakdownPage(
          engine: safetyEngine!,
          unknownIngredients: unknownIngredients,
          productName: productName,
          initialTab: tab,
        ),
      ),
    );
  }
}

/// Pinned under the scrolling content so the main action is always visible.
class _BottomActions extends StatelessWidget {
  final VoidCallback? onViewAlternatives;
  final VoidCallback? onAddToRoutine;
  final bool showRoutine;
  final AppThemeColors colors;

  const _BottomActions({
    this.onViewAlternatives,
    this.onAddToRoutine,
    required this.showRoutine,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Top fade: content dissolves into the bar instead of being cut off.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.background.withValues(alpha: 0), colors.background.withValues(alpha: 0.95)],
          stops: const [0, 0.35],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PrimaryButton(
            label: 'View Alternatives',
            onTap: onViewAlternatives,
            colors: colors,
          ),
          if (showRoutine) ...[
            SizedBox(height: 6.h),
            _AddToRoutineButton(onTap: onAddToRoutine, colors: colors),
          ],
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final AppThemeColors colors;

  const _TopBar({
    this.onBack,
    this.onFavorite,
    this.isFavorite = false,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
        ),
        _CircleIconButton(
          icon: isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          onTap: onFavorite,
          color: isFavorite ? colors.neonEmerald : Colors.white,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _CircleIconButton({
    required this.icon,
    this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 42.r,
        height: 42.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.iconContainerBg,
          border: Border.all(color: colors.cardBorder),
        ),
        child: Icon(icon, color: color, size: 18.r),
      ),
    );
  }
}

/// Product image on the left; "Analyzed Product" chip, brand (bold) over
/// product name (lighter), then "quantity • category chip" on the right.
/// When [brand] isn't given, the first word of [name] is used as the brand.
class _ProductHero extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final String? brand;
  final String? quantity;
  final String? category;
  final AppThemeColors colors;

  const _ProductHero({
    this.imageUrl,
    this.name,
    this.brand,
    this.quantity,
    this.category,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    // Backend can return an empty name/brand for products it couldn't
    // identify; show a placeholder instead of leaving a gap under the chip.
    final hasIdentity =
        (name?.trim().isNotEmpty ?? false) ||
        (brand?.trim().isNotEmpty ?? false);
    final full = hasIdentity ? (name?.trim() ?? '') : 'Unidentified Product';
    final String line1;
    final String line2;
    if (brand != null && brand!.trim().isNotEmpty) {
      line1 = brand!.trim();
      // Avoid "Himalaya / Himalaya Neem Face Wash".
      line2 = full.toLowerCase().startsWith(line1.toLowerCase())
          ? full.substring(line1.length).trim()
          : full;
    } else {
      final split = full.indexOf(' ');
      line1 = split == -1 ? full : full.substring(0, split);
      line2 = split == -1 ? '' : full.substring(split + 1);
    }
    final hasQty = quantity != null && quantity!.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 150.w,
          height: 190.h,
          child: _ProductImage(imageUrl: imageUrl, colors: colors),
        ),
        SizedBox(width: 18.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: colors.neonEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: colors.neonEmerald,
                      size: 13.r,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Analyzed Product',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              if (line1.isNotEmpty)
                Text(
                  line1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              if (line2.isNotEmpty)
                Text(
                  line2,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              if (hasQty || category != null) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    if (hasQty)
                      Text(
                        quantity!,
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (hasQty && category != null) ...[
                      SizedBox(width: 8.w),
                      Container(
                        width: 4.r,
                        height: 4.r,
                        decoration: BoxDecoration(
                          color: colors.secondaryText,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    if (category != null)
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: colors.neonEmerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: colors.neonEmerald.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            category!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.neonEmerald,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Wide glass card: score ring on the left, "Overall Assessment" text in the
/// middle, decorative leaf tile on the right.
class _AssessmentCard extends StatelessWidget {
  final int score;
  final _ScoreBand band;
  final String? summary;
  final AppThemeColors colors;

  const _AssessmentCard({
    required this.score,
    required this.band,
    required this.summary,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final text = (summary != null && summary!.trim().isNotEmpty)
        ? summary!
        : 'Based on available ingredient data.';
    final gaugeSize = 130.r;
    // The glass card sits behind the ring: it starts at the ring's centre
    // line (left padding = half the ring) so the ring overlaps its left edge.
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Padding(
          padding: EdgeInsets.only(left: gaugeSize / 2),
          child: GlassCard(
            padding: EdgeInsets.zero,
            // The leaf is a Positioned backdrop (not a Row child), so it takes
            // no layout space: the card's height comes only from the text,
            // and long text can't be squeezed or stretch the card because of
            // the icon. GlassCard clips it to the rounded card shape.
            child: Stack(
              children: [
                Positioned(
                  top: 16.h,
                  bottom: 16.h,
                  right: 8.w,
                  width: 70.w,
                  child: Opacity(
                    opacity: 0.5,
                    child: Image.asset(
                      'assets/images/glowing leaf.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    gaugeSize / 2 + 16.w,
                    22.h,
                    44.w,
                    22.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Assessment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        text,
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 12.5.sp,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _ScoreGauge(score: score, band: band, colors: colors, size: 130),
      ],
    );
  }
}

/// Frames a product photo with a border, soft shadow, and a bottom
/// vignette — needed because these are often real phone snapshots (a hand
/// holding a pack on a tiled floor), not clean studio product shots, so a
/// plain unstyled `Image.network` looks like a stray screenshot rather than
/// an intentional part of the card. `BoxFit.cover` fills the frame (no
/// letterboxing bars), and loading/error states get the same placeholder
/// treatment as a missing image instead of Flutter's default spinner/red box.
class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final AppThemeColors colors;

  const _ProductImage({required this.imageUrl, required this.colors});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20.r);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: colors.iconContainerBg),
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 22.r,
                      height: 22.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.neonEmerald,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.inventory_2_outlined,
                  color: colors.secondaryText,
                  size: 40.r,
                ),
              )
            else
              Icon(
                Icons.inventory_2_outlined,
                color: colors.secondaryText,
                size: 40.r,
              ),
            // Soft fade at the bottom so a busy real-world photo (floor,
            // hand, background clutter) settles into the card instead of
            // ending on a hard edge.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 48.h,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular progress ring with the numeric score and its band label
/// ("GOOD"/"FAIR"/"POOR") centered inside — the glowing ring from the
/// reference screenshot.
class _ScoreGauge extends StatelessWidget {
  final int score;
  final _ScoreBand band;
  final AppThemeColors colors;
  final double size;

  const _ScoreGauge({
    required this.score,
    required this.band,
    required this.colors,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final color = band.color;
    final diameter = size.r;
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Very subtle glow around the ring.
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 16),
              ],
            ),
          ),
          // Opaque fill only *inside* the stroke, so the card doesn't show
          // through the ring and nothing dark rims its outer edge.
          Container(
            width: diameter - diameter * 0.09 * 2,
            height: diameter - diameter * 0.09 * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.background,
            ),
          ),
          CustomPaint(
            size: Size(diameter, diameter),
            painter: _GaugePainter(
              progress: score.clamp(0, 100) / 100,
              color: color,
              trackColor: Colors.white.withValues(alpha: 0.08),
              strokeWidth: diameter * 0.09,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                band.label,
                style: TextStyle(
                  color: color,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '/ 100',
                style: TextStyle(color: colors.secondaryText, fontSize: 11.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ring starting at 12 o'clock, sweeping clockwise by `progress` of a full
/// turn, with round caps. Solid color (no sweep shader) so the arc's color
/// can't drift out of sync with its start angle.
class _GaugePainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _GaugePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final base = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, base..color = trackColor);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        base..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppThemeColors colors;

  const _PrimaryButton({required this.label, this.onTap, required this.colors});

  @override
  Widget build(BuildContext context) {
    final darker = Color.lerp(colors.neonEmerald, Colors.black, 0.25)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 13.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [colors.neonEmerald, darker]),
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: colors.neonEmerald.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: colors.background,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.background,
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddToRoutineButton extends StatelessWidget {
  final VoidCallback? onTap;
  final AppThemeColors colors;
  const _AddToRoutineButton({this.onTap, required this.colors});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22.r,
              height: 22.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.neonEmerald),
              ),
              child: Icon(
                Icons.add_rounded,
                color: colors.neonEmerald,
                size: 15.r,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'Add to My Routine',
              style: TextStyle(
                color: colors.neonEmerald,
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isCosmetic(String? category) {
  final c = category?.toLowerCase() ?? '';
  return c.contains('cosmetic') || c.contains('skin') || c.contains('personal');
}
