import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/ingredient_entity.dart';
import '../widgets/status_colors.dart';

enum _Filter { all, flagged, safe }

/// Full-screen ingredient breakdown: summary counts, filter chips, and the
/// list grouped so flagged ingredients come first. Pure presentation — all
/// data comes in through the constructor; the filter is local UI state.
class IngredientsPage extends StatefulWidget {
  final List<IngredientEntity> ingredients;
  final String? productName;
  final String skinType;
  final bool initialFlaggedOnly;

  const IngredientsPage({
    super.key,
    required this.ingredients,
    this.productName,
    this.skinType = 'your skin',
    this.initialFlaggedOnly = false,
  });

  @override
  State<IngredientsPage> createState() => _IngredientsPageState();
}

class _IngredientsPageState extends State<IngredientsPage> {
  late _Filter _filter = widget.initialFlaggedOnly ? _Filter.flagged : _Filter.all;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final all = widget.ingredients;
    final flagged = all.where((i) => i.isFlagged).toList();
    final safe = all.where((i) => !i.isFlagged).toList();

    final showFlagged = _filter != _Filter.safe && flagged.isNotEmpty;
    final showSafe = _filter != _Filter.flagged && safe.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.9, -0.9),
            radius: 1.3,
            colors: colors.headerGradient,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
            children: [
              _Header(productName: widget.productName, colors: colors),
              SizedBox(height: 20.h),
              Row(
                children: [
                  _StatTile(label: 'Total', value: all.length, color: Colors.white, colors: colors),
                  SizedBox(width: 10.w),
                  _StatTile(label: 'Safe', value: safe.length, color: colors.neonEmerald, colors: colors),
                  SizedBox(width: 10.w),
                  _StatTile(label: 'Flagged', value: flagged.length, color: kWarnAmber, colors: colors),
                ],
              ),
              SizedBox(height: 20.h),
              Wrap(
                spacing: 8.w,
                children: [
                  for (final (f, label) in [
                    (_Filter.all, 'All'),
                    (_Filter.flagged, 'Flagged'),
                    (_Filter.safe, 'Safe'),
                  ])
                    _FilterChip(
                      label: label,
                      selected: _filter == f,
                      colors: colors,
                      onTap: () => setState(() => _filter = f),
                    ),
                ],
              ),
              SizedBox(height: 20.h),
              if (all.isEmpty)
                _EmptyNote(text: 'No ingredient data available for this product.', colors: colors)
              else if (!showFlagged && !showSafe)
                _EmptyNote(
                  text: _filter == _Filter.flagged
                      ? 'No flagged ingredients for ${widget.skinType}.'
                      : 'No ingredients in this group.',
                  colors: colors,
                )
              else ...[
                if (showFlagged) ...[
                  _SectionHeader(title: 'Watch out', count: flagged.length, color: kWarnAmber),
                  SizedBox(height: 10.h),
                  for (final i in flagged) _IngredientTile(ingredient: i, colors: colors),
                ],
                if (showFlagged && showSafe) SizedBox(height: 12.h),
                if (showSafe) ...[
                  _SectionHeader(title: 'Looks fine', count: safe.length, color: colors.neonEmerald),
                  SizedBox(height: 10.h),
                  for (final i in safe) _IngredientTile(ingredient: i, colors: colors),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? productName;
  final AppThemeColors colors;
  const _Header({required this.productName, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          customBorder: const CircleBorder(),
          child: Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.iconContainerBg,
              border: Border.all(color: colors.cardBorder),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18.r),
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingredients',
                style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w800),
              ),
              if (productName != null && productName!.trim().isNotEmpty)
                Text(
                  productName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.secondaryText, fontSize: 13.sp),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final AppThemeColors colors;
  const _StatTile({required this.label, required this.value, required this.color, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        borderRadius: 18.r,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(color: color, fontSize: 24.sp, fontWeight: FontWeight.w800, height: 1.1),
            ),
            SizedBox(height: 2.h),
            Text(label, style: TextStyle(color: colors.secondaryText, fontSize: 12.sp)),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? colors.neonEmerald : colors.iconContainerBg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: selected ? colors.neonEmerald : colors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.background : Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _SectionHeader({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8.r, height: 8.r, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 8.w),
        Text(
          '$title · $count',
          style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final IngredientEntity ingredient;
  final AppThemeColors colors;
  const _IngredientTile({required this.ingredient, required this.colors});

  @override
  Widget build(BuildContext context) {
    final rating = ingredient.safetyRating;
    final ratingColor = ingredientRatingColor(rating, colors);
    final hasPurpose = ingredient.purpose != null && ingredient.purpose!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: GlassCard(
        borderRadius: 18.r,
        padding: EdgeInsets.all(14.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        ingredient.name,
                        style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700),
                      ),
                      if (ingredient.isNatural)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: colors.neonEmerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            'Natural',
                            style: TextStyle(color: colors.neonEmerald, fontSize: 10.5.sp, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  if (hasPurpose) ...[
                    SizedBox(height: 4.h),
                    Text(
                      ingredient.purpose!,
                      style: TextStyle(color: colors.secondaryText, fontSize: 12.5.sp, height: 1.35),
                    ),
                  ],
                  if (ingredient.isFlagged) ...[
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: [
                        for (final c in ingredient.concerns)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: kWarnAmber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: kWarnAmber.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              c,
                              style: TextStyle(color: kWarnAmber, fontSize: 11.5.sp, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (rating != null) ...[
              SizedBox(width: 12.w),
              Column(
                children: [
                  Text(
                    '$rating',
                    style: TextStyle(color: ratingColor, fontSize: 18.sp, fontWeight: FontWeight.w800, height: 1.1),
                  ),
                  Text('/100', style: TextStyle(color: colors.secondaryText, fontSize: 10.sp)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String text;
  final AppThemeColors colors;
  const _EmptyNote({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.secondaryText, fontSize: 14.sp),
        ),
      ),
    );
  }
}
