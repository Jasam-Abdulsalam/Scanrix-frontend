import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import 'routine_step_params.dart';

/// PUT /routine/{slot}/{barcode} : add as the last step (safe to repeat). Throws `ServerException`
/// with `code` `not_cosmetic` (422) or `routine_slot_full` (409), or 404 for an unknown barcode.
class AddToRoutineUseCase implements UseCase<void, RoutineStepParams> {
  final ApiClient apiClient;

  AddToRoutineUseCase({required this.apiClient});

  @override
  Future<void> call(RoutineStepParams p) async {
    await apiClient.put(ApiConstants.routineStep(p.slot.apiValue, p.barcode));
  }
}
