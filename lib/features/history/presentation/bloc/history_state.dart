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

  /// One-shot message for the UI (e.g. a delete that failed and was undone).
  final String? notice;

  const HistoryLoaded(this.items, {this.notice});

  @override
  List<Object?> get props => [items, notice];
}

class HistoryFailure extends HistoryState {
  final String message;

  const HistoryFailure(this.message);

  @override
  List<Object?> get props => [message];
}
