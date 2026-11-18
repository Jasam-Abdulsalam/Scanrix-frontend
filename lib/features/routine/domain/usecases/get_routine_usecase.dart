import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/routine_model.dart';
import '../entities/routine_entity.dart';

/// GET /routine/ : the whole routine (bounded, not paginated).
class GetRoutineUseCase implements UseCase<RoutineEntity, NoParams> {
  final ApiClient apiClient;

  GetRoutineUseCase({required this.apiClient});

  @override
  Future<RoutineEntity> call(NoParams params) async {
    final data = await apiClient.get(ApiConstants.routine);
    return RoutineModel.fromJson(data as Map<String, dynamic>);
  }
}
