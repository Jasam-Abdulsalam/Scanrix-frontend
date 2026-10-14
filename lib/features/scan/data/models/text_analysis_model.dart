import '../../../products/data/models/safety_engine_model.dart';
import '../../domain/entities/text_analysis_entity.dart';

class TextAnalysisModel extends TextAnalysisEntity {
  const TextAnalysisModel({
    super.overallScore,
    required super.verdict,
    super.summary,
    super.unknownIngredients,
    super.safetyEngine,
  });

  /// Takes the response body as-is (top-level keys, no `"analysis"` wrapper).
  factory TextAnalysisModel.fromJson(Map<String, dynamic> json) {
    final unknown = json['unknown_ingredients'];
    return TextAnalysisModel(
      overallScore: (json['overall_score'] as num?)?.toInt(),
      // Missing verdict renders as "Unable To Determine", never as safe.
      verdict: json['verdict'] as String? ?? 'unknown',
      summary: json['summary'] as String?,
      unknownIngredients: unknown is List ? unknown.whereType<String>().toList() : const [],
      safetyEngine: SafetyEngineModel.tryParse(json['safety_engine']),
    );
  }
}
