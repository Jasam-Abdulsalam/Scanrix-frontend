import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';

/// DELETE /favorites/{barcode} : un-save a product (the backend answers 204 even if it was not saved).
class RemoveFavoriteUseCase implements UseCase<void, String> {
  final ApiClient apiClient;

  RemoveFavoriteUseCase({required this.apiClient});

  @override
  Future<void> call(String barcode) async {
    await apiClient.delete(ApiConstants.favorite(barcode));
  }
}
