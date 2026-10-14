import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/ingredient_entity.dart';
import 'severity_style.dart';

/// Pre-safety-engine ingredient list (AI purpose/rating per ingredient). Only
/// used when a product has no `safetyEngine` (older cached barcode result).
class LegacyIngredientListCard extends StatelessWidget {
  final List<IngredientEntity> ingredients;
  final AppThemeColors colors;
  const LegacyIngredientListCard({super.key, required this.ingredients, required this.colors});

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
                ? kWarningAmber
                : kDangerRed;

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
