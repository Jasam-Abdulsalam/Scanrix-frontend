import 'package:equatable/equatable.dart';

import '../../domain/entities/routine_entity.dart';

enum RoutineStatus { initial, loading, loaded, failure }

class RoutineState extends Equatable {
  final RoutineStatus status;
  final RoutineEntity routine;
  final String? failureMessage;

  /// One-shot message for a toast (a change that failed and was undone).
  final String? notice;

  const RoutineState({
    this.status = RoutineStatus.initial,
    this.routine = RoutineEntity.empty,
    this.failureMessage,
    this.notice,
  });

  RoutineState copyWith({
    RoutineStatus? status,
    RoutineEntity? routine,
    String? failureMessage,
    String? notice,
  }) => RoutineState(
    status: status ?? this.status,
    routine: routine ?? this.routine,
    failureMessage: failureMessage ?? this.failureMessage,
    notice: notice, // always replaced: a copy never repeats the previous notice
  );

  @override
  List<Object?> get props => [status, routine, failureMessage, notice];
}
