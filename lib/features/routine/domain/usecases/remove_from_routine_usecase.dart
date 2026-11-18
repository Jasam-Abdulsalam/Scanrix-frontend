import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import 'routine_step_params.dart';

/// DELETE /routine/{slot}/{barcode} : remove a step (safe to repeat).
class RemoveFromRoutineUseCase implements UseCase<void, RoutineStepParams> {
  final ApiClient apiClient;

  RemoveFromRoutineUseCase({required this.apiClient});

  @override
  Future<void> call(RoutineStepParams p) async {
    await apiClient.delete(
      ApiConstants.routineStep(p.slot.apiValue, p.barcode),
    );
  }
}
