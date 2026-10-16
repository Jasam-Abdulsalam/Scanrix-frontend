import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the list. [silent] keeps the current list on screen while
/// refreshing (tab re-selected, pull-to-refresh) instead of a spinner.
class HistoryRequested extends HistoryEvent {
  final int limit;
  final bool silent;

  const HistoryRequested({this.limit = 50, this.silent = false});

  @override
  List<Object?> get props => [limit, silent];
}

class HistoryEntryDeleted extends HistoryEvent {
  final String id;

  const HistoryEntryDeleted(this.id);

  @override
  List<Object?> get props => [id];
}

class HistoryCleared extends HistoryEvent {
  const HistoryCleared();
}
