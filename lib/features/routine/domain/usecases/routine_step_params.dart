import 'package:equatable/equatable.dart';

import '../entities/routine_entity.dart';

class RoutineStepParams extends Equatable {
  final RoutineSlot slot;
  final String barcode;

  const RoutineStepParams(this.slot, this.barcode);

  @override
  List<Object?> get props => [slot, barcode];
}
