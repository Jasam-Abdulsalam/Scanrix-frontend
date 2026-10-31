import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/mock/mock_alternatives.dart';
import '../../data/models/alternative_product_model.dart';
import '../entities/alternative_product_entity.dart';

/// GET /products/{barcode}/alternatives: better-scored products similar to
/// the scanned one.
///
/// TODO(backend): the endpoint doesn't exist yet, so this returns
/// [mockAlternativesResponse] after a short fake delay (so the loading state
/// is visible while designing). To integrate, replace the body with:
///
/// ```dart
/// final data = await apiClient.get(ApiConstants.productAlternatives(params));
/// return AlternativeProductModel.listFromJson(data);
/// ```
///
/// then delete `data/mock/mock_alternatives.dart`. Nothing in the bloc or UI
/// needs to change.
class GetAlternativesUseCase implements UseCase<List<AlternativeProductEntity>, String> {
  final ApiClient apiClient;

  /// Fake latency for the mock; zero in tests.
  final Duration mockDelay;

  GetAlternativesUseCase({required this.apiClient, this.mockDelay = const Duration(milliseconds: 700)});

  @override
  Future<List<AlternativeProductEntity>> call(String barcode) async {
    await Future<void>.delayed(mockDelay);
    // The scanned product itself is never its own alternative.
    return AlternativeProductModel.listFromJson(mockAlternativesResponse).where((a) => a.barcode != barcode).toList();
  }
}
