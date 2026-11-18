import 'package:equatable/equatable.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/routine_entity.dart';

class ReorderParams extends Equatable {
  final RoutineSlot slot;
  final List<String> barcodes;

  const ReorderParams(this.slot, this.barcodes);

  @override
  List<Object?> get props => [slot, barcodes];
}

/// PUT /routine/{slot} {barcodes} : new step order. Throws `ServerException` with `code`
/// `order_mismatch` (422) when the slot changed meanwhile (the bloc reloads).
class ReorderRoutineUseCase implements UseCase<void, ReorderParams> {
  final ApiClient apiClient;

  ReorderRoutineUseCase({required this.apiClient});

  @override
  Future<void> call(ReorderParams p) async {
    await apiClient.put(
      ApiConstants.routineSlot(p.slot.apiValue),
      data: {'barcodes': p.barcodes},
    );
  }
}
