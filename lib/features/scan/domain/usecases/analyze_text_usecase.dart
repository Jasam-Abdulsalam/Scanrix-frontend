import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/text_analysis_model.dart';
import '../entities/text_analysis_entity.dart';

/// POST /scan/analyze-text (`app/api/v1/endpoints/scan.py`) - the OCR path.
/// Runs the database-first safety engine synchronously and returns the result
/// inline at the top level of the response (nothing persisted server-side).
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
    return TextAnalysisModel.fromJson(data as Map<String, dynamic>);
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
