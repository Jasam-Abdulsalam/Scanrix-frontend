import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the first page. [limit] is the page size (the page derives it from the screen height).
/// [silent] keeps the current list on screen while refreshing instead of a spinner.
class HistoryRequested extends HistoryEvent {
  final int limit;
  final bool silent;

  const HistoryRequested({this.limit = 20, this.silent = false});

  @override
  List<Object?> get props => [limit, silent];
}

/// Loads the page after the last one shown (infinite scroll).
class HistoryLoadMore extends HistoryEvent {
  final int limit;

  const HistoryLoadMore({this.limit = 20});

  @override
  List<Object?> get props => [limit];
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
