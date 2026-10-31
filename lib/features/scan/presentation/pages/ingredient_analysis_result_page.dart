import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../products/domain/entities/ai_analysis_entity.dart';
import '../../../products/presentation/widgets/ai_verdict_section.dart';
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

  /// The OCR text behind [analysis]; enables the opt-in AI verdict for it.
  final String ingredientsText;
  final String? productName;
  final String? productImageUrl;

  const IngredientAnalysisResultPage({
    super.key,
    required this.analysis,
    required this.category,
    this.ingredientsText = '',
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
        safetyEngine: analysis.safetyEngine,
        aiSection: ingredientsText.trim().length < 5
            ? null
            : AiVerdictSection(
                request: AiAnalysisRequest.text(ingredientsText, category: category.backendValue),
                engine: analysis.safetyEngine,
                verdict: analysis.verdict,
              ),
        // No fallbacks: without a real name/photo this is a label scan, and the
        // view shows "Label scan" instead of a fake product card.
        productName: productName,
        productImageUrl: productImageUrl,
        category: category.label,
        onBack: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
