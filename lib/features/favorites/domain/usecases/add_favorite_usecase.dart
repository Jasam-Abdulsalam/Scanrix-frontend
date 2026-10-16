import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';

/// PUT /favorites/{barcode} : save a product (safe to repeat). Throws `ServerException` with
/// `code` `favorites_limit_reached` (409) at the cap, or 404 for an unknown barcode.
class AddFavoriteUseCase implements UseCase<void, String> {
  final ApiClient apiClient;

  AddFavoriteUseCase({required this.apiClient});

  @override
  Future<void> call(String barcode) async {
    await apiClient.put(ApiConstants.favorite(barcode));
  }
}
