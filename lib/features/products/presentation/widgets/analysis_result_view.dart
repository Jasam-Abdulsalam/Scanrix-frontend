import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/ingredient_entity.dart';

/// Verdict → display color/label/icon. Shared by the barcode result page
/// (`ProductDetailPage`) and the ingredients-OCR result page
/// (`IngredientAnalysisResultPage`) so both flows render identically once
/// they have a verdict. Kept as a plain string extension (no BuildContext)
/// since it's used in places without one; `_amber`/`_red` below are the
/// same semantic shades used inside this file for FAIR/POOR and watch-out
/// states, so the two stay visually consistent even though this extension
/// can't pull `neonEmerald` from the current theme.
extension VerdictDisplay on String {
  Color get verdictColor => switch (this) {
        'safe' => const Color(0xFF25E28B),
        'caution' => _amber,
        'avoid' => _red,
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

/// Semantic warning/danger shades. Not part of `AppThemeColors` (which only
/// defines the emerald brand color), so these stay as fixed constants
/// shared by both theme modes rather than guessed theme tokens.
const _amber = Color(0xFFF2B33D);
const _red = Color(0xFFEF5B5B);

/// Score → the short badge word shown inside the gauge ("GOOD" / "FAIR" /
/// "POOR") and its color. Takes the current `AppThemeColors` so "GOOD"
/// always matches the theme's actual emerald (`neonEmerald`), not a
/// hardcoded shade — this is what makes the gauge repaint correctly if the
/// user switches between `darkGreen` and `blackishReference`.
typedef _ScoreBand = ({Color color, String label});

_ScoreBand _bandFor(int score, AppThemeColors colors) {
  if (score >= 70) return (color: colors.neonEmerald, label: 'GOOD');
  if (score >= 40) return (color: _amber, label: 'FAIR');
  return (color: _red, label: 'POOR');
}

/// Full analysis screen: app bar (back / favorite), product hero, circular
/// score gauge, one-line summary, up to three highlight rows (safety fit,
/// good ingredients, watch-outs), and the primary actions.
///
/// [productName] and [productImageUrl] are optional — the hero still
/// renders without them (placeholder icon, no name line) so this also
/// works for flows without a resolved product identity.
class AnalysisResultView extends StatelessWidget {
  final String verdict;
  final int? overallScore;
  final String? summary;
  final List<IngredientEntity> ingredients;
  final String? productName;
  final String? productImageUrl;
  final String? category;
  final String skinType;
  final VoidCallback? onBack;
  final VoidCallback? onFavorite;
  final VoidCallback? onViewAlternatives;
  final VoidCallback? onSeeFullAnalysis;
  final VoidCallback? onAddToRoutine;
  final bool isFavorite;

  const AnalysisResultView({
    super.key,
    required this.verdict,
    required this.overallScore,
    required this.summary,
    required this.ingredients,
    this.productName,
    this.productImageUrl,
    this.category,
    this.skinType = 'your skin',
    this.onBack,
    this.onFavorite,
    this.onViewAlternatives,
    this.onSeeFullAnalysis,
    this.onAddToRoutine,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final concerning = ingredients.where((i) => i.concerns.isNotEmpty).toList();
    final good = ingredients.where((i) => i.concerns.isEmpty).toList();
    // Fall back to a verdict-derived score so the gauge always has something
    // to draw, even before a numeric score is wired up end-to-end.
    final score = overallScore ??
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
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 40.h),
          children: [
            _TopBar(onBack: onBack, onFavorite: onFavorite, isFavorite: isFavorite, colors: colors),
            SizedBox(height: 8.h),
            // Always rendered — with graceful fallbacks for a missing image
            // or name — so this section is never silently skipped.
            _ProductHero(
              imageUrl: productImageUrl,
              name: productName,
              category: category,
              score: score,
              band: band,
              colors: colors,
            ),
            SizedBox(height: 20.h),
            if (summary != null && summary!.trim().isNotEmpty) ...[
              _SummaryPill(summary: summary!, colors: colors),
              SizedBox(height: 20.h),
            ],
            GlassCard(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              child: Column(
                children: [
                  _HighlightRow(
                    icon: Icons.eco_rounded,
                    iconColor: colors.neonEmerald,
                    title: 'Safe for $skinType',
                    subtitle: band.color == colors.neonEmerald
                        ? 'Non-comedogenic formula that won\'t clog pores.'
                        : 'Check ingredients below before regular use.',
                    colors: colors,
                  ),
                  _RowDivider(colors: colors),
                  _HighlightRow(
                    icon: Icons.science_rounded,
                    iconColor: colors.neonEmerald,
                    title: 'Good Ingredients',
                    subtitle: good.isNotEmpty
                        ? 'Contains ${good.take(3).map((i) => i.name).join(', ')}.'
                        : 'No standout beneficial ingredients found.',
                    colors: colors,
                  ),
                  if (concerning.isNotEmpty) ...[
                    _RowDivider(colors: colors),
                    _HighlightRow(
                      icon: Icons.warning_rounded,
                      iconColor: _amber,
                      title: 'Watch out',
                      subtitle:
                          'Contains ${concerning.first.name}${concerning.first.concerns.isNotEmpty ? ' which may ${concerning.first.concerns.first}' : ''}.',
                      colors: colors,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 24.h),
            _PrimaryButton(label: 'View Alternatives', onTap: onViewAlternatives, colors: colors),
            SizedBox(height: 12.h),
            _OutlinedButton(label: 'See Full Analysis', onTap: onSeeFullAnalysis, colors: colors),
            SizedBox(height: 16.h),
            Center(
              child: _AddToRoutineButton(onTap: onAddToRoutine, colors: colors),
            ),
            SizedBox(height: 12.h),
            if (ingredients.isNotEmpty) ...[
              SizedBox(height: 8.h),
              _IngredientListCard(ingredients: ingredients, colors: colors),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final AppThemeColors colors;

  const _TopBar({this.onBack, this.onFavorite, this.isFavorite = false, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CircleIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        _CircleIconButton(
          icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
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

  const _CircleIconButton({required this.icon, this.onTap, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: EdgeInsets.all(8.r),
        child: Icon(icon, color: color, size: 22.r),
      ),
    );
  }
}

/// Product image + name + category + circular gauge, laid out the way the
/// reference screen shows them: image on the left, text/gauge on the right.
class _ProductHero extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final String? category;
  final int score;
  final _ScoreBand band;
  final AppThemeColors colors;

  const _ProductHero({
    this.imageUrl,
    this.name,
    this.category,
    required this.score,
    required this.band,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: AspectRatio(
            aspectRatio: 0.75,
            child: _ProductImage(imageUrl: imageUrl, colors: colors),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: colors.iconContainerBg,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: colors.neonEmerald, size: 13.r),
                    SizedBox(width: 6.w),
                    Text(
                      'Analyzed Product',
                      style: TextStyle(color: colors.secondaryText, fontSize: 11.5.sp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              if (name != null)
                Text(
                  name!,
                  style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w800, height: 1.15),
                ),
              if (category != null) ...[
                SizedBox(height: 4.h),
                Text(
                  category!,
                  style: TextStyle(color: colors.neonEmerald, fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
              ],
              SizedBox(height: 14.h),
              Center(child: _ScoreGauge(score: score, band: band, colors: colors)),
            ],
          ),
        ),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8)),
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.neonEmerald),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.inventory_2_outlined, color: colors.secondaryText, size: 40.r),
              )
            else
              Icon(Icons.inventory_2_outlined, color: colors.secondaryText, size: 40.r),
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
                    colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
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

  const _ScoreGauge({required this.score, required this.band, required this.colors, this.size = 150});

  @override
  Widget build(BuildContext context) {
    final color = band.color;
    return SizedBox(
      width: size.r,
      height: size.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 30, spreadRadius: 2),
              ],
            ),
          ),
          CustomPaint(
            size: Size(size.r, size.r),
            painter: _GaugePainter(progress: (score.clamp(0, 100)) / 100, color: color, trackColor: colors.cardBorder),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(color: Colors.white, fontSize: 40.sp, fontWeight: FontWeight.w800, height: 1.0),
              ),
              SizedBox(height: 2.h),
              Text(
                band.label,
                style: TextStyle(color: color, fontSize: 14.sp, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  final Color trackColor;

  _GaugePainter({required this.progress, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi * progress,
        colors: [color.withValues(alpha: 0.5), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.trackColor != trackColor;
}

/// Rounded translucent pill holding the one-line AI summary, centered under
/// the gauge as in the reference screenshot.
class _SummaryPill extends StatelessWidget {
  final String summary;
  final AppThemeColors colors;
  const _SummaryPill({required this.summary, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Text(
        summary,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.secondaryText, fontSize: 14.sp, height: 1.4, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  final AppThemeColors colors;
  const _RowDivider({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Divider(color: colors.divider, height: 1);
  }
}

/// One row inside the highlights card: leading icon in a tinted circle,
/// title + subtitle, trailing chevron. Tap is a no-op placeholder for now —
/// wire `onTap` up if each row should push to a detail page.
class _HighlightRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final AppThemeColors colors;
  final VoidCallback? onTap;

  const _HighlightRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42.r,
              height: 42.r,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.secondaryText, fontSize: 12.5.sp, height: 1.35),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Icon(Icons.chevron_right_rounded, color: colors.secondaryText.withValues(alpha: 0.6), size: 22.r),
            ),
          ],
        ),
      ),
    );
  }
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
        padding: EdgeInsets.symmetric(vertical: 17.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [colors.neonEmerald, darker]),
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(color: colors.neonEmerald.withValues(alpha: 0.35), blurRadius: 20, offset: Offset(0, 8.h)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(color: colors.background, fontSize: 16.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(width: 6.w),
            Icon(Icons.chevron_right_rounded, color: colors.background, size: 20.r),
          ],
        ),
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppThemeColors colors;

  const _OutlinedButton({required this.label, this.onTap, required this.colors});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 17.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: colors.cardBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 15.5.sp, fontWeight: FontWeight.w700),
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
              child: Icon(Icons.add_rounded, color: colors.neonEmerald, size: 15.r),
            ),
            SizedBox(width: 8.w),
            Text(
              'Add to My Routine',
              style: TextStyle(color: colors.neonEmerald, fontSize: 14.5.sp, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kept from the original layout: the full scrollable ingredient list below
/// the fold, for anyone who taps "See Full Analysis" without a separate
/// route, or as a quick reference on this same page.
class _IngredientListCard extends StatelessWidget {
  final List<IngredientEntity> ingredients;
  final AppThemeColors colors;
  const _IngredientListCard({required this.ingredients, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingredients (${ingredients.length})',
            style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12.h),
          ...ingredients.map((i) => _IngredientRow(ingredient: i, colors: colors)),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final IngredientEntity ingredient;
  final AppThemeColors colors;
  const _IngredientRow({required this.ingredient, required this.colors});

  @override
  Widget build(BuildContext context) {
    final rating = ingredient.safetyRating;
    final dotColor = rating == null
        ? colors.secondaryText
        : rating >= 70
            ? colors.neonEmerald
            : rating >= 40
                ? _amber
                : _red;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 5.h),
            width: 8.r,
            height: 8.r,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: TextStyle(color: Colors.white, fontSize: 13.5.sp, fontWeight: FontWeight.w600),
                ),
                if (ingredient.purpose != null && ingredient.purpose!.isNotEmpty)
                  Text(
                    ingredient.purpose!,
                    style: TextStyle(color: colors.secondaryText, fontSize: 12.sp),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}