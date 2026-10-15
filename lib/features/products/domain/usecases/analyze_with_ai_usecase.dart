import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/ai_analysis_model.dart';
import '../entities/ai_analysis_entity.dart';

/// POST /ai/analyze-product: the opt-in "Get AI verdict". Costs 1 AI credit
/// unless the answer already exists. Throws `ServerException` with `code`
/// `ingredients_missing` (422), `ai_credits_exhausted` (429) or
/// `ai_unavailable` (503); the Bloc maps those to UI states.
class AnalyzeWithAiUseCase implements UseCase<AiAnalysis, AiAnalysisRequest> {
  final ApiClient apiClient;

  AnalyzeWithAiUseCase({required this.apiClient});

  @override
  Future<AiAnalysis> call(AiAnalysisRequest params) async {
    final data = await apiClient.post(ApiConstants.aiAnalyzeProduct, data: params.toJson());
    return AiAnalysisModel.fromJson(data as Map<String, dynamic>);
  }
}
