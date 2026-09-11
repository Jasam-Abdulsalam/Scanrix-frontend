import 'package:equatable/equatable.dart';

import '../../domain/entities/scan_history_entity.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<ScanHistoryEntity> items;

  const HistoryLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class HistoryFailure extends HistoryState {
  final String message;

  const HistoryFailure(this.message);

  @override
  List<Object?> get props => [message];
}
