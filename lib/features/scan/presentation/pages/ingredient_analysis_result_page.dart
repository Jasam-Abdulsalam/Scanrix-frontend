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
  final String? productName;
  final String? productImageUrl;

  const IngredientAnalysisResultPage({
    super.key,
    required this.analysis,
    required this.category,
    this.productName,
    this.productImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: AnalysisResultView(
        verdict: analysis.verdict,
        overallScore: analysis.overallScore,
        summary: analysis.summary,
        ingredients: analysis.ingredients,
        productName: productName ?? 'Scanned ${category.label}',
        productImageUrl: productImageUrl ?? category.assetPath,
        category: category.label,
        onBack: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
