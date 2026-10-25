import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';

/// GET /favorites/barcodes : every saved barcode (bounded by the backend's per-user cap).
class GetFavoriteBarcodesUseCase implements UseCase<Set<String>, NoParams> {
  final ApiClient apiClient;

  GetFavoriteBarcodesUseCase({required this.apiClient});

  @override
  Future<Set<String>> call(NoParams params) async {
    final data = await apiClient.get(ApiConstants.favoriteBarcodes) as Map<String, dynamic>;
    return {for (final b in data['barcodes'] as List) b as String};
  }
}
