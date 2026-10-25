import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/ai_analysis_model.dart';
import '../entities/ai_analysis_entity.dart';

/// GET /ai/credits: how many AI credits the user has left this week.
class GetAiCreditsUseCase implements UseCase<AiCredits, NoParams> {
  final ApiClient apiClient;

  GetAiCreditsUseCase({required this.apiClient});

  @override
  Future<AiCredits> call(NoParams params) async {
    final data = await apiClient.get(ApiConstants.aiCredits);
    return AiCreditsModel.fromJson(data as Map<String, dynamic>);
  }
}
