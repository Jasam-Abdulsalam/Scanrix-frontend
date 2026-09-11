import 'package:equatable/equatable.dart';

import '../../../products/domain/entities/ingredient_entity.dart';

/// Mirrors the AI analysis shape returned by `POST /scan/analyze-text`
/// (`app/services/ai_service.py`'s waterfall - Groq -> Gemini -> fallback -
/// under the `"analysis"` key of the response).
class TextAnalysisEntity extends Equatable {
  final int overallScore;
  final String verdict;
  final List<IngredientEntity> ingredients;
  final String? summary;

  const TextAnalysisEntity({
    required this.overallScore,
    required this.verdict,
    required this.ingredients,
    this.summary,
  });

  @override
  List<Object?> get props => [overallScore, verdict, ingredients, summary];
}
