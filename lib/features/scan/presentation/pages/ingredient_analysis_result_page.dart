import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../products/presentation/widgets/analysis_result_view.dart';
import '../../domain/entities/text_analysis_entity.dart';
import '../widgets/scan_category.dart';

/// Result screen for the ingredients-OCR flow. Unlike the barcode flow,
/// `POST /scan/analyze-text` resolves synchronously — this page is fed an
/// already-final [TextAnalysisEntity] directly, no polling, no bloc. There's
/// no product identity here (no barcode/name/image), so the header is
/// deliberately lighter than `ProductDetailPage`'s.
class IngredientAnalysisResultPage extends StatelessWidget {
  final TextAnalysisEntity analysis;
  final ScanCategory category;

  const IngredientAnalysisResultPage({
    super.key,
    required this.analysis,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: TextStyle(fontSize: 16.sp)),
            SizedBox(width: 8.w),
            Text(
              'Scanned Ingredients',
              style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: AnalysisResultView(
        verdict: analysis.verdict,
        overallScore: analysis.overallScore,
        summary: analysis.summary,
        ingredients: analysis.ingredients,
      ),
    );
  }
}
