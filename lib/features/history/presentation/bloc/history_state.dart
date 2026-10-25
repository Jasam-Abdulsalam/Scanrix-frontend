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

  /// Cursor for the next page; null when there is none.
  final String? nextCursor;
  final bool hasMore;
  final bool loadingMore;
  final bool loadMoreFailed;

  /// One-shot message for the UI (e.g. a delete that failed and was undone).
  final String? notice;

  const HistoryLoaded(
    this.items, {
    this.nextCursor,
    this.hasMore = false,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.notice,
  });

  HistoryLoaded copyWith({
    List<ScanHistoryEntity>? items,
    String? nextCursor,
    bool? hasMore,
    bool? loadingMore,
    bool? loadMoreFailed,
    String? notice,
  }) =>
      HistoryLoaded(
        items ?? this.items,
        nextCursor: nextCursor ?? this.nextCursor,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
        notice: notice,
      );

  @override
  List<Object?> get props => [items, nextCursor, hasMore, loadingMore, loadMoreFailed, notice];
}

class HistoryFailure extends HistoryState {
  final String message;

  const HistoryFailure(this.message);

  @override
  List<Object?> get props => [message];
}
