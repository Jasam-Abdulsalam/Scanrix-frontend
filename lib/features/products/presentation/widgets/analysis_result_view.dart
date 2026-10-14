import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/entities/ingredient_entity.dart';
<<<<<<< Updated upstream
import '../pages/ingredients_page.dart';
import 'status_colors.dart';
=======
import '../../domain/entities/safety_engine_entity.dart';
import 'analysis_actions.dart';
import 'analysis_hero.dart';
import 'analysis_highlights_card.dart';
import 'findings_list_card.dart';
import 'legacy_ingredient_list_card.dart';
import 'not_assessed_section.dart';
import 'safety_disclaimer.dart';
import 'severity_style.dart';
>>>>>>> Stashed changes

/// Verdict → display color/label/icon. Shared by the barcode result page
/// (`ProductDetailPage`) and the ingredients-OCR result page
/// (`IngredientAnalysisResultPage`) so both flows render identically once
/// they have a verdict. Kept as a plain string extension (no BuildContext)
<<<<<<< Updated upstream
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
=======
/// since it's used in places without one; `kWarningAmber`/`kDangerRed`
/// (severity_style.dart) are the same shades used for FAIR/POOR and
/// watch-out states, so the two stay consistent even though this extension
/// can't pull `neonEmerald` from the current theme.
extension VerdictDisplay on String {
  Color get verdictColor => switch (this) {
        'safe' => const Color(0xFF25E28B),
        'caution' => kWarningAmber,
        'avoid' => kDangerRed,
        _ => const Color(0xFF8E9E96), // unknown / error
      };
>>>>>>> Stashed changes

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

<<<<<<< Updated upstream

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

=======
>>>>>>> Stashed changes
/// Full analysis screen: app bar (back / favorite), product hero, circular
/// score gauge, one-line summary, the highlights card, the primary actions,
/// then the detailed sections.
///
/// With a [safetyEngine] the detail sections are built from its findings
/// (recognised list, "Not assessed", disclaimer). Without one - an older
/// cached barcode result - it renders verdict/score/summary plus the legacy
/// [ingredients] list. [unknownIngredients] is the OCR response's top-level
/// list of names the database couldn't match.
///
/// [productName] and [productImageUrl] are optional - the hero still
/// renders without them (placeholder icon, no name line) so this also
/// works for flows without a resolved product identity.
class AnalysisResultView extends StatelessWidget {
  final String verdict;
  final int? overallScore;
  final String? summary;
  final SafetyEngine? safetyEngine;
  final List<String> unknownIngredients;
  final List<IngredientEntity> ingredients;
  final String? productName;
  final String? productImageUrl;
  final String? category;
<<<<<<< Updated upstream
  final String? brand;
  final String? quantity;
  final String skinType;
=======
>>>>>>> Stashed changes
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
    this.safetyEngine,
    this.unknownIngredients = const [],
    this.ingredients = const [],
    this.productName,
    this.productImageUrl,
    this.category,
<<<<<<< Updated upstream
    this.brand,
    this.quantity,
    this.skinType = 'your skin',
=======
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
    final concerning = ingredients.where((i) => i.concerns.isNotEmpty).toList();
    final isCosmetic = _isCosmetic(category);
=======
>>>>>>> Stashed changes
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
    final band = scoreBandFor(score, colors);

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
<<<<<<< Updated upstream
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
            child: ListView(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 40.h),
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
                        _HighlightRow(
                          icon: Icons.eco_rounded,
                          iconColor: concerning.isEmpty ? colors.neonEmerald : kWarnAmber,
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
                        _RowDivider(colors: colors),
                      ],
                      if (ingredients.isNotEmpty)
                        _HighlightRow(
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
                        if (ingredients.isNotEmpty) _RowDivider(colors: colors),
                        _HighlightRow(
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
                SizedBox(height: 24.h),
                _PrimaryButton(
                  label: 'View Alternatives',
                  onTap: onViewAlternatives,
                  colors: colors,
                ),
                SizedBox(height: 12.h),
                _OutlinedButton(
                  label: 'See Full Analysis',
                  onTap: onSeeFullAnalysis,
                  colors: colors,
                ),
                SizedBox(height: 16.h),
                Center(
                  child: _AddToRoutineButton(
                    onTap: onAddToRoutine,
                    colors: colors,
                  ),
                ),
              ],
            ),
          ),
        ],
=======
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 40.h),
          children: [
            _TopBar(onBack: onBack, onFavorite: onFavorite, isFavorite: isFavorite, colors: colors),
            SizedBox(height: 8.h),
            // Always rendered - with graceful fallbacks for a missing image
            // or name - so this section is never silently skipped.
            AnalysisHero(
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
            AnalysisHighlightsCard(safetyEngine: safetyEngine, legacyIngredients: ingredients),
            SizedBox(height: 24.h),
            AnalysisPrimaryButton(label: 'View Alternatives', onTap: onViewAlternatives, colors: colors),
            SizedBox(height: 12.h),
            AnalysisOutlinedButton(label: 'See Full Analysis', onTap: onSeeFullAnalysis, colors: colors),
            SizedBox(height: 16.h),
            Center(child: AddToRoutineButton(onTap: onAddToRoutine, colors: colors)),
            SizedBox(height: 20.h),
            ...(_details(colors)),
          ],
        ),
>>>>>>> Stashed changes
      ),
    );
  }

  List<Widget> _details(AppThemeColors colors) {
    final engine = safetyEngine;
    if (engine == null) {
      return [
        if (ingredients.isNotEmpty) LegacyIngredientListCard(ingredients: ingredients, colors: colors),
      ];
    }
    final recognised = engine.findings.where((f) => !f.isNotAssessed).toList();
    final notAssessed = NotAssessedSection.merge(
      engine.notAssessed.map((f) => f.rawName),
      unknownIngredients,
    );
    return [
      FindingsListCard(findings: recognised),
      if (notAssessed.isNotEmpty) ...[
        SizedBox(height: 16.h),
        NotAssessedSection(names: notAssessed),
      ],
      SizedBox(height: 20.h),
      SafetyDisclaimer(text: engine.disclaimer),
    ];
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

<<<<<<< Updated upstream
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
    final hasIdentity = (name?.trim().isNotEmpty ?? false) || (brand?.trim().isNotEmpty ?? false);
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
                    Icon(Icons.auto_awesome_rounded, color: colors.neonEmerald, size: 13.r),
                    SizedBox(width: 6.w),
                    Text(
                      'Analyzed Product',
                      style: TextStyle(color: Colors.white, fontSize: 11.5.sp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              if (line1.isNotEmpty)
                Text(
                  line1,
                  style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.w800, height: 1.1),
                ),
              if (line2.isNotEmpty)
                Text(
                  line2,
                  style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w600, height: 1.25),
                ),
              if (hasQty || category != null) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    if (hasQty)
                      Text(
                        quantity!,
                        style: TextStyle(color: colors.secondaryText, fontSize: 14.sp, fontWeight: FontWeight.w500),
                      ),
                    if (hasQty && category != null) ...[
                      SizedBox(width: 8.w),
                      Container(
                        width: 4.r,
                        height: 4.r,
                        decoration: BoxDecoration(color: colors.secondaryText, shape: BoxShape.circle),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    if (category != null)
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: colors.neonEmerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: colors.neonEmerald.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            category!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.neonEmerald, fontSize: 12.sp, fontWeight: FontWeight.w600),
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
                  padding: EdgeInsets.fromLTRB(gaugeSize / 2 + 16.w, 22.h, 44.w, 22.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Assessment',
                        style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        text,
                        style: TextStyle(color: colors.secondaryText, fontSize: 12.5.sp, height: 1.4),
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

  const _ScoreGauge({required this.score, required this.band, required this.colors, this.size = 150});

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
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 16)],
            ),
          ),
          // Opaque fill only *inside* the stroke, so the card doesn't show
          // through the ring and nothing dark rims its outer edge.
          Container(
            width: diameter - diameter * 0.09 * 2,
            height: diameter - diameter * 0.09 * 2,
            decoration: BoxDecoration(shape: BoxShape.circle, color: colors.background),
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
                style: TextStyle(color: Colors.white, fontSize: 34.sp, fontWeight: FontWeight.w800, height: 1.0),
              ),
              SizedBox(height: 2.h),
              Text(
                band.label,
                style: TextStyle(color: color, fontSize: 14.sp, fontWeight: FontWeight.w700, letterSpacing: 0.5),
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
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, base..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
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
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 12.5.sp,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Icon(
                Icons.chevron_right_rounded,
                color: colors.secondaryText.withValues(alpha: 0.6),
                size: 22.r,
              ),
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

class _OutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppThemeColors colors;

  const _OutlinedButton({
    required this.label,
    this.onTap,
    required this.colors,
  });

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
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.5.sp,
            fontWeight: FontWeight.w700,
          ),
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
=======
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
>>>>>>> Stashed changes
