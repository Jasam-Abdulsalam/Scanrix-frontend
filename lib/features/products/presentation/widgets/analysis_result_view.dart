import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/ingredient_entity.dart';

/// Verdict → display color/label/icon. Shared by the barcode result page
/// (`ProductDetailPage`) and the ingredients-OCR result page
/// (`IngredientAnalysisResultPage`) so both flows render identically once
/// they have a verdict.
extension VerdictDisplay on String {
  Color get verdictColor => switch (this) {
        'safe' => const Color(0xFF25E28B),
        'caution' => const Color(0xFFF2B33D),
        'avoid' => const Color(0xFFEF5B5B),
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

/// Presentational result body: verdict badge, score, AI summary (when
/// present), full ingredient list, and a "things to watch out for" section
/// derived from flagged ingredients — this stands in for named
/// "alternative product" suggestions, which need product identity neither
/// flow reliably has.
class AnalysisResultView extends StatelessWidget {
  final String verdict;
  final int? overallScore;
  final String? summary;
  final List<IngredientEntity> ingredients;

  const AnalysisResultView({
    super.key,
    required this.verdict,
    required this.overallScore,
    required this.summary,
    required this.ingredients,
  });

  @override
  Widget build(BuildContext context) {
    final concerning = ingredients.where((i) => i.concerns.isNotEmpty).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 40.h),
      children: [
        _VerdictHeader(verdict: verdict, overallScore: overallScore),
        if (summary != null && summary!.trim().isNotEmpty) ...[
          SizedBox(height: 16.h),
          _SummaryCard(summary: summary!),
        ],
        if (concerning.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _WatchOutForCard(ingredients: concerning),
        ],
        SizedBox(height: 16.h),
        _IngredientListCard(ingredients: ingredients),
      ],
    );
  }
}

class _VerdictHeader extends StatelessWidget {
  final String verdict;
  final int? overallScore;

  const _VerdictHeader({required this.verdict, required this.overallScore});

  @override
  Widget build(BuildContext context) {
    final color = verdict.verdictColor;
    return GlassCard(
      padding: EdgeInsets.all(20.r),
      child: Row(
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(verdict.verdictIcon, color: color, size: 30.r),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verdict.verdictLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (overallScore != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Overall score: $overallScore/100',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13.sp,
                    ),
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

class _SummaryCard extends StatelessWidget {
  final String summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(18.r),
      child: Text(
        summary,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14.sp, height: 1.4),
      ),
    );
  }
}

class _WatchOutForCard extends StatelessWidget {
  final List<IngredientEntity> ingredients;
  const _WatchOutForCard({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Things to watch out for',
            style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4.h),
          Text(
            'No specific alternative product — look for options without these:',
            style: TextStyle(color: Colors.white54, fontSize: 12.sp),
          ),
          SizedBox(height: 12.h),
          ...ingredients.map(
            (i) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 6.r, color: Colors.white38),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.white70, fontSize: 13.sp, height: 1.4),
                        children: [
                          TextSpan(
                            text: '${i.name}: ',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          TextSpan(text: i.concerns.join(', ')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientListCard extends StatelessWidget {
  final List<IngredientEntity> ingredients;
  const _IngredientListCard({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    if (ingredients.isEmpty) {
      return GlassCard(
        padding: EdgeInsets.all(18.r),
        child: Text(
          'No ingredient list available for this item.',
          style: TextStyle(color: Colors.white54, fontSize: 13.sp),
        ),
      );
    }
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
          ...ingredients.map((i) => _IngredientRow(ingredient: i)),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final IngredientEntity ingredient;
  const _IngredientRow({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final rating = ingredient.safetyRating;
    final dotColor = rating == null
        ? Colors.white38
        : rating >= 70
            ? const Color(0xFF25E28B)
            : rating >= 40
                ? const Color(0xFFF2B33D)
                : const Color(0xFFEF5B5B);

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
                    style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
