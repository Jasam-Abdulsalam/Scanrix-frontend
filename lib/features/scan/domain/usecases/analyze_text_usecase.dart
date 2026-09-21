import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/text_analysis_model.dart';
import '../entities/text_analysis_entity.dart';

/// POST /scan/analyze-text (`app/api/v1/endpoints/scan.py`) - the OCR path.
/// Skips the DB and external product lookups, hits the AI synchronously,
/// returns the analysis inline (nothing persisted server-side).
class AnalyzeTextUseCase implements UseCase<TextAnalysisEntity, AnalyzeTextParams> {
  final ApiClient apiClient;

  AnalyzeTextUseCase({required this.apiClient});

  @override
  Future<TextAnalysisEntity> call(AnalyzeTextParams params) async {
    final data = await apiClient.post(
      ApiConstants.analyzeText,
      data: {
        'ingredients_text': params.ingredientsText,
        'category': params.category,
      },
    );
    final map = data as Map<String, dynamic>;
    return TextAnalysisModel.fromJson(map['analysis'] as Map<String, dynamic>);
  }
}

class AnalyzeTextParams {
  final String ingredientsText;
  final String category;

  const AnalyzeTextParams({
    required this.ingredientsText,
    this.category = 'food',
  });
}
