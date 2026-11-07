import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../products/domain/entities/ai_analysis_entity.dart';
import '../../data/models/natural_remedy_model.dart';
import '../entities/natural_remedy_entity.dart';

/// POST /ai/natural-remedy: homemade alternatives for a cosmetic. Takes the same
/// source as "Get AI verdict" (a barcode, or label text + category).
/// Costs 1 weekly AI credit unless an answer already exists. Throws
/// `ServerException` with `code` `not_cosmetic` / `ingredients_missing` (422),
/// `ai_credits_exhausted` (429) or `ai_unavailable` (503, not charged).
class GetNaturalRemedyUseCase implements UseCase<NaturalRemedyResult, AiAnalysisRequest> {
  final ApiClient apiClient;

  GetNaturalRemedyUseCase({required this.apiClient});

  @override
  Future<NaturalRemedyResult> call(AiAnalysisRequest request) async {
    final data = await apiClient.post(ApiConstants.aiNaturalRemedy, data: request.toJson());
    return NaturalRemedyResultModel.fromJson(data as Map<String, dynamic>);
  }
}
