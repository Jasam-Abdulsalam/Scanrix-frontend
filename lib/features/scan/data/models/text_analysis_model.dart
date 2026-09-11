import '../../../products/data/models/ingredient_model.dart';
import '../../domain/entities/text_analysis_entity.dart';

class TextAnalysisModel extends TextAnalysisEntity {
  const TextAnalysisModel({
    required super.overallScore,
    required super.verdict,
    required super.ingredients,
    super.summary,
  });

  factory TextAnalysisModel.fromJson(Map<String, dynamic> json) {
    return TextAnalysisModel(
      overallScore: json['overall_score'] as int,
      verdict: json['verdict'] as String,
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => IngredientModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] as String?,
    );
  }
}
