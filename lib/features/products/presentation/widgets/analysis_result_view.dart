import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/bold_card.dart';
import '../../../../core/widgets/toast.dart';
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
/// same semantic shades used inside this file for watch-out states, so the
/// two stay visually consistent even though this extension can't pull
/// `neonEmerald` from the current theme.
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
    'safe' => 'No Known Concerns',
    'caution' => 'Use With Caution',
    'avoid' => 'Avoid',
    'error' => 'Analysis Failed',
    _ => 'Unable To Determine',
  };
}

/// Full analysis screen in the bold-card language (.claude/skills/bold-card-ui):
/// top bar, a dark product card (only when there is a product), the accent
/// verdict card with the score ring, the summary, the Watch out / Good /
/// Not assessed columns, the optional AI row, the disclaimer, and the pinned
/// actions.
///
/// With a [safetyEngine] the columns open the ingredient breakdown screen.
/// Without one - an older cached barcode result - the legacy per-ingredient
/// rows and [IngredientsPage] are used.
/// [aiSection] is the optional opt-in "AI verdict" block, shown beside (never
/// replacing) the database result.
///
/// A label scan (no [productName], [brand] or [productImageUrl]) has no
/// product card: the verdict card says "Label scan" instead.
class AnalysisResultView extends StatefulWidget {
  final String verdict;
  final int? overallScore;
  final String? summary;
  final SafetyEngine? safetyEngine;
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
  State<AnalysisResultView> createState() => _AnalysisResultViewState();
}

class _AnalysisResultViewState extends State<AnalysisResultView> with SingleTickerProviderStateMixin {
  /// Drives the staggered entrance, the score ring fill and the count-up.
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (_c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _hasProduct =>
      (widget.productName?.trim().isNotEmpty ?? false) ||
      (widget.brand?.trim().isNotEmpty ?? false) ||
      (widget.productImageUrl?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final w = widget;
    final isCosmetic = _isCosmetic(w.category);
    // Fall back to a verdict-derived score so the ring always has something
    // to draw, even before a numeric score is wired up end-to-end.
    final score =
        w.overallScore ??
        switch (w.verdict) {
          'safe' => 85,
          'caution' => 55,
          'avoid' => 20,
          _ => 50,
        };
    final summary = w.summary?.trim() ?? '';

    final sections = <Widget>[
      if (_hasProduct)
        _ProductCard(
          imageUrl: w.productImageUrl,
          name: w.productName,
          brand: w.brand,
          quantity: w.quantity,
          category: w.category,
        ),
      _VerdictCard(
        verdict: w.verdict,
        score: score,
        engine: w.safetyEngine,
        label: _hasProduct ? 'Database result' : (w.category == null ? 'Label scan' : 'Label scan · ${w.category}'),
        progress: _c,
      ),
      if (summary.isNotEmpty) _SummaryCard(text: summary),
      if (w.safetyEngine != null)
        AnalysisHighlightsCard(
          safetyEngine: w.safetyEngine,
          legacyIngredients: w.ingredients,
          progress: _c,
          onOpenTab: (tab) => _openBreakdown(context, tab),
        )
      else
        _LegacyRows(ingredients: w.ingredients, isCosmetic: isCosmetic, productName: w.productName, skinType: w.skinType),
      if (w.aiSection != null) w.aiSection!,
      if (w.safetyEngine != null) SafetyDisclaimer(text: w.safetyEngine!.disclaimer),
    ];

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        // Stack (not Column) so content scrolls *under* the faded action bar.
        child: Stack(
          children: [
            Positioned.fill(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 110.h),
                children: [
                  _TopBar(
                    title: _hasProduct ? null : 'Label scan',
                    onBack: w.onBack,
                    onFavorite: w.onFavorite,
                    isFavorite: w.isFavorite,
                  ),
                  SizedBox(height: 16.h),
                  for (var i = 0; i < sections.length; i++) ...[
                    if (i > 0) SizedBox(height: 12.h),
                    _Reveal(controller: _c, index: i, child: sections[i]),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomActions(
                onViewAlternatives: w.onViewAlternatives,
                onAddToRoutine: isCosmetic ? w.onAddToRoutine : null,
                showRoutine: isCosmetic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openBreakdown(BuildContext context, BreakdownTab tab) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IngredientsBreakdownPage(
          engine: widget.safetyEngine!,
          productName: widget.productName,
          initialTab: tab,
        ),
      ),
    );
  }
}

/// Staggered entrance: each section fades in and rises 12 px, a beat after
/// the previous one. Critically damped (ease-out, no overshoot).
class _Reveal extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _Reveal({required this.controller, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final start = math.min(index * 0.07, 0.5);
    final anim = CurvedAnimation(parent: controller, curve: Interval(start, start + 0.5, curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: Offset(0, 12.h * (1 - anim.value)), child: child),
      ),
      child: child,
    );
  }
}

/// Until a feature is built (no callback passed), its button still answers
/// a tap instead of doing nothing.
void _comingSoon(BuildContext context, String feature) {
  HapticFeedback.selectionClick();
  showToast(context, '$feature is coming soon', icon: Icons.schedule_rounded);
}

/// Pinned under the scrolling content so the main action is always visible.
class _BottomActions extends StatelessWidget {
  final VoidCallback? onViewAlternatives;
  final VoidCallback? onAddToRoutine;
  final bool showRoutine;

  const _BottomActions({this.onViewAlternatives, this.onAddToRoutine, required this.showRoutine});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
      padding: EdgeInsets.fromLTRB(16.w, 28.h, 16.w, 8.h),
      // Two equal pills side by side; if a label wouldn't fit in its half
      // (very large text), they stack instead, so no label is ever cut off.
      child: LayoutBuilder(
        builder: (context, box) {
          final alternatives = _ActionPill(
            label: 'Alternatives',
            semanticLabel: 'View alternatives',
            icon: Icons.arrow_forward_rounded,
            iconAfter: true,
            filled: true,
            onTap: onViewAlternatives ?? () => _comingSoon(context, 'Alternatives'),
          );
          if (!showRoutine) return alternatives;
          final routine = _ActionPill(
            label: 'Add to routine',
            semanticLabel: 'Add to My Routine',
            icon: Icons.add_rounded,
            filled: false,
            onTap: onAddToRoutine ?? () => _comingSoon(context, 'My Routine'),
          );
          final gap = 10.w;
          final half = (box.maxWidth - gap) / 2;
          final fits = routine.naturalWidth(context) <= half && alternatives.naturalWidth(context) <= half;
          return fits
              ? Row(children: [Expanded(child: routine), SizedBox(width: gap), Expanded(child: alternatives)])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [alternatives, SizedBox(height: 8.h), routine],
                );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String? title;
  final VoidCallback? onBack;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const _TopBar({this.title, this.onBack, this.onFavorite, this.isFavorite = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        Expanded(
          child: title == null
              ? const SizedBox.shrink()
              : Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700),
                ),
        ),
        // No handler = nothing to save (e.g. a label scan with no product): no heart.
        if (onFavorite != null)
          _RoundButton(
            icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            onTap: onFavorite,
            color: isFavorite ? boldAccent(context) : Colors.white,
          )
        else
          SizedBox(width: 42.r),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _RoundButton({required this.icon, this.onTap, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: CircleIcon(icon: icon, background: boldCardFill(context.colors), foreground: color, size: 42.r),
    );
  }
}

/// Dark product card: rounded photo on the left; brand (bold), product name,
/// then "quantity · category pill". When [brand] isn't given, the first word
/// of [name] is used as the brand.
class _ProductCard extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final String? brand;
  final String? quantity;
  final String? category;

  const _ProductCard({this.imageUrl, this.name, this.brand, this.quantity, this.category});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Backend can return an empty name/brand for products it couldn't
    // identify; show a placeholder instead of leaving a gap.
    final hasIdentity = (name?.trim().isNotEmpty ?? false) || (brand?.trim().isNotEmpty ?? false);
    final full = hasIdentity ? (name?.trim() ?? '') : 'Unidentified Product';
    final String line1;
    final String line2;
    if (brand != null && brand!.trim().isNotEmpty) {
      line1 = brand!.trim();
      // Avoid "Himalaya / Himalaya Neem Face Wash".
      line2 = full.toLowerCase().startsWith(line1.toLowerCase()) ? full.substring(line1.length).trim() : full;
    } else {
      final split = full.indexOf(' ');
      line1 = split == -1 ? full : full.substring(0, split);
      line2 = split == -1 ? '' : full.substring(split + 1);
    }
    final hasQty = quantity != null && quantity!.trim().isNotEmpty;

    return BoldCard(
      padding: EdgeInsets.all(12.r),
      child: Row(
        children: [
          _ProductImage(imageUrl: imageUrl, size: 92.r),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (line1.isNotEmpty)
                  Text(
                    line1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                if (line2.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    line2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14.sp, height: 1.3),
                  ),
                ],
                if (hasQty || category != null) ...[
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (hasQty) _Pill(text: quantity!.trim(), color: colors.secondaryText),
                      if (category != null) _Pill(text: category!, color: Colors.white),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(20.r)),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontSize: 12.sp, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Rounded product photo. These are often real phone snapshots, so
/// `BoxFit.cover` fills the frame (no letterboxing), and loading/error get
/// the same calm placeholder as a missing image.
class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const _ProductImage({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final placeholder = Icon(Icons.inventory_2_outlined, color: colors.secondaryText, size: size * 0.36);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        width: size,
        height: size,
        color: Colors.white.withValues(alpha: 0.06),
        alignment: Alignment.center,
        child: imageUrl == null
            ? placeholder
            : Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : SizedBox.square(
                        dimension: 20.r,
                        child: CircularProgressIndicator(strokeWidth: 2, color: boldAccent(context)),
                      ),
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

/// The one solid accent card: what it is (pill), the verdict in words and as
/// a status badge, how much of the label could be checked, and the score.
/// Status color only ever sits on black (badge, pill dot), never on the accent.
class _VerdictCard extends StatelessWidget {
  final String verdict;
  final int score;
  final SafetyEngine? engine;
  final String label;
  final Animation<double> progress;

  const _VerdictCard({
    required this.verdict,
    required this.score,
    required this.engine,
    required this.label,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = verdict == 'safe' ? colors.neonEmerald : verdict.verdictColor;
    final fill = CurvedAnimation(parent: progress, curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic));
    // Rounded notch in the top edge, like the stacked cards in the references.
    return ClipPath(
      clipper: TopNotchClipper(radius: 28.r, notchWidth: 56.w, notchDepth: 7.h),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 16.w, 20.h),
        decoration: BoxDecoration(color: boldAccent(context), borderRadius: BorderRadius.circular(28.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flexible: large text sizes shrink the pill instead of overflowing the row.
                Flexible(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(9.w, 5.h, 11.w, 5.h),
                    decoration: BoxDecoration(color: kOnAccent, borderRadius: BorderRadius.circular(20.r)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7.r,
                          height: 7.r,
                          decoration: BoxDecoration(color: status, shape: BoxShape.circle),
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                CircleIcon(icon: verdict.verdictIcon, background: kOnAccent, foreground: status, size: 38.r),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verdict.verdictLabel,
                        style: TextStyle(
                          color: kOnAccent,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.05,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _coverageLine(engine),
                        style: TextStyle(color: kOnAccent.withValues(alpha: 0.72), fontSize: 13.sp, height: 1.4),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 14.w),
                AnimatedBuilder(
                  animation: fill,
                  builder: (_, _) => AccentRing(size: 92.r, score: score, fraction: fill.value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// How much of the label the database could check: the caveat that
  /// matters most on a weak result, so it lives in the hero, not in fine print.
  static String _coverageLine(SafetyEngine? e) {
    if (e == null || e.totalCount == 0) return 'Based on available ingredient data.';
    final checked = '${e.recognisedCount} of ${e.totalCount} ingredients';
    return e.coverage < 0.7 ? 'Only $checked could be checked.' : '$checked checked.';
  }
}

class _SummaryCard extends StatelessWidget {
  final String text;

  const _SummaryCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return BoldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall assessment',
            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700, letterSpacing: -0.2),
          ),
          SizedBox(height: 8.h),
          Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontSize: 14.5.sp, height: 1.5)),
        ],
      ),
    );
  }
}

/// Older cached barcode results (no safety engine): per-ingredient rows in
/// one dark card, each opening [IngredientsPage].
class _LegacyRows extends StatelessWidget {
  final List<IngredientEntity> ingredients;
  final bool isCosmetic;
  final String? productName;
  final String skinType;

  const _LegacyRows({
    required this.ingredients,
    required this.isCosmetic,
    required this.productName,
    required this.skinType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final concerning = ingredients.where((i) => i.concerns.isNotEmpty).toList();
    void open({required bool flaggedOnly}) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IngredientsPage(
          ingredients: ingredients,
          productName: productName,
          skinType: skinType,
          initialFlaggedOnly: flaggedOnly,
        ),
      ),
    );
    final rows = <Widget>[
      // Skin fit only makes sense for cosmetics, and its text is derived
      // from the analysed ingredients (no canned claims).
      if (isCosmetic)
        HighlightRow(
          icon: Icons.eco_rounded,
          iconColor: concerning.isEmpty ? colors.neonEmerald : kWarnAmber,
          title: 'Skin compatibility',
          subtitle: concerning.isEmpty
              ? 'No concerns found for $skinType.'
              : '${concerning.length} ingredient${concerning.length == 1 ? '' : 's'} flagged for $skinType.',
          colors: colors,
          onTap: concerning.isEmpty ? null : () => open(flaggedOnly: true),
        ),
      if (ingredients.isNotEmpty)
        HighlightRow(
          icon: Icons.science_rounded,
          iconColor: colors.neonEmerald,
          title: 'Ingredients',
          subtitle:
              '${ingredients.length} ingredient${ingredients.length == 1 ? '' : 's'}'
              '${concerning.isEmpty ? '' : ' · ${concerning.length} flagged'}. Tap to view all.',
          colors: colors,
          onTap: () => open(flaggedOnly: false),
        ),
      if (concerning.isNotEmpty)
        HighlightRow(
          icon: Icons.warning_rounded,
          iconColor: kWarnAmber,
          title: 'Watch out',
          subtitle:
              'Contains ${concerning.first.name}${concerning.first.concerns.isNotEmpty ? ' which may ${concerning.first.concerns.first}' : ''}.',
          colors: colors,
          onTap: () => open(flaggedOnly: true),
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return BoldCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) RowDivider(colors: colors),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// Bottom action pill: [filled] = solid accent with dark text (main action),
/// otherwise dark with white text and an accent icon. Fixed height so two
/// pills side by side line up; content centered.
class _ActionPill extends StatelessWidget {
  final String label;
  final String semanticLabel;
  final IconData icon;
  final bool iconAfter;
  final bool filled;
  final VoidCallback onTap;

  const _ActionPill({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.filled,
    required this.onTap,
    this.iconAfter = false,
  });

  static double get _padding => 14.w;
  static double get _iconGap => 6.w;
  static double get _iconSize => 20.r;

  TextStyle _style(Color color) => TextStyle(color: color, fontSize: 14.5.sp, fontWeight: FontWeight.w700);

  /// Padding + icon + gap + label, at the user's text size.
  double naturalWidth(BuildContext context) =>
      _padding * 2 + _iconSize + _iconGap + measureText(context, label, _style(Colors.white));

  @override
  Widget build(BuildContext context) {
    final accent = boldAccent(context);
    final fg = filled ? kOnAccent : Colors.white;
    final iconWidget = Icon(icon, color: filled ? kOnAccent : accent, size: _iconSize);
    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        button: true,
        label: semanticLabel,
        excludeSemantics: true,
        child: Pressable(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            height: 54.r,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: _padding),
            decoration: BoxDecoration(
              color: filled ? accent : boldCardFill(context.colors),
              borderRadius: BorderRadius.circular(32.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!iconAfter) ...[iconWidget, SizedBox(width: _iconGap)],
                Flexible(
                  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _style(fg)),
                ),
                if (iconAfter) ...[SizedBox(width: _iconGap), iconWidget],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _isCosmetic(String? category) {
  final c = category?.toLowerCase() ?? '';
  return c.contains('cosmetic') || c.contains('skin') || c.contains('personal');
}
