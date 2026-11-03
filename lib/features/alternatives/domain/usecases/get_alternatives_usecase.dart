import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/alternative_product_model.dart';
import '../entities/alternative_product_entity.dart';

/// POST /ai/alternatives: AI-suggested alternatives for a scanned product.
/// Costs 1 weekly AI credit unless an answer for this product already exists.
/// Throws `ServerException` with `code` `ingredients_missing` (422),
/// `ai_credits_exhausted` (429, `resets_at` in details) or `ai_unavailable`
/// (503, not charged); the Bloc maps those to UI messages.
class GetAlternativesUseCase implements UseCase<AlternativesResult, String> {
  final ApiClient apiClient;

  GetAlternativesUseCase({required this.apiClient});

  @override
  Future<AlternativesResult> call(String barcode) async {
    final data = await apiClient.post(ApiConstants.aiAlternatives, data: {'barcode': barcode});
    return AlternativesResultModel.fromJson(data as Map<String, dynamic>);
  }
}
