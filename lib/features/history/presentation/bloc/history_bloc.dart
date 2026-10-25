import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/models/page_result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/scan_history_entity.dart';
import '../../domain/usecases/clear_history_usecase.dart';
import '../../domain/usecases/delete_history_entry_usecase.dart';
import '../../domain/usecases/get_scan_history_usecase.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetScanHistoryUseCase getScanHistoryUseCase;
  final DeleteHistoryEntryUseCase deleteHistoryEntryUseCase;
  final ClearHistoryUseCase clearHistoryUseCase;

  /// Bumped whenever the list is replaced (refresh, clear). A "load more" that was started
  /// before that must not append its (now stale) page to the new list.
  int _generation = 0;

  HistoryBloc({
    required this.getScanHistoryUseCase,
    required this.deleteHistoryEntryUseCase,
    required this.clearHistoryUseCase,
  }) : super(HistoryInitial()) {
    // droppable: a refresh / next-page request while one is running adds nothing.
    on<HistoryRequested>(_onRequested, transformer: droppable());
    on<HistoryLoadMore>(_onLoadMore, transformer: droppable());
    // sequential: deletes run one after another, so each optimistic update
    // starts from the result of the previous one.
    on<HistoryEntryDeleted>(_onDeleted, transformer: sequential());
    on<HistoryCleared>(_onCleared, transformer: sequential());
  }

  Future<void> _onRequested(HistoryRequested event, Emitter<HistoryState> emit) async {
    final keepList = event.silent && state is HistoryLoaded;
    if (!keepList) emit(HistoryLoading());
    _generation++;
    try {
      final page = await getScanHistoryUseCase(HistoryPageParams(limit: event.limit));
      emit(_fromPage(page));
    } catch (e) {
      // A failed silent refresh keeps the list the user already sees.
      if (keepList) return;
      emit(HistoryFailure(_messageFor(e)));
    }
  }

  Future<void> _onLoadMore(HistoryLoadMore event, Emitter<HistoryState> emit) async {
    final current = state;
    if (current is! HistoryLoaded || !current.hasMore || current.nextCursor == null) return;
    final generation = _generation;
    emit(current.copyWith(loadingMore: true, loadMoreFailed: false));
    try {
      final page = await getScanHistoryUseCase(HistoryPageParams(limit: event.limit, cursor: current.nextCursor));
      if (generation != _generation) return; // the list was replaced meanwhile
      final latest = state is HistoryLoaded ? state as HistoryLoaded : current;
      emit(_fromPage(page, before: latest.items));
    } catch (_) {
      if (generation != _generation) return;
      final latest = state is HistoryLoaded ? state as HistoryLoaded : current;
      emit(latest.copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }

  /// Optimistic: the row disappears at once; if the server refuses, it comes back with a notice.
  Future<void> _onDeleted(HistoryEntryDeleted event, Emitter<HistoryState> emit) async {
    final current = state;
    if (current is! HistoryLoaded) return;
    emit(current.copyWith(items: current.items.where((i) => i.id != event.id).toList()));
    try {
      await deleteHistoryEntryUseCase(event.id);
    } catch (e) {
      final now = state is HistoryLoaded ? state as HistoryLoaded : current;
      final restored = [...now.items, ...current.items.where((i) => i.id == event.id)]
        ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      emit(now.copyWith(items: restored, notice: "Couldn't delete that scan. ${_messageFor(e)}"));
    }
  }

  Future<void> _onCleared(HistoryCleared event, Emitter<HistoryState> emit) async {
    final current = state;
    if (current is! HistoryLoaded || current.items.isEmpty) return;
    _generation++;
    emit(const HistoryLoaded([]));
    try {
      await clearHistoryUseCase(const NoParams());
    } catch (e) {
      emit(current.copyWith(notice: "Couldn't clear history. ${_messageFor(e)}"));
    }
  }

  HistoryLoaded _fromPage(PageResult<ScanHistoryEntity> page, {List<ScanHistoryEntity> before = const []}) {
    final seen = {for (final i in before) i.id};
    return HistoryLoaded(
      [...before, ...page.items.where((i) => !seen.contains(i.id))], // drop repeats if rows shifted
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  String _messageFor(Object e) =>
      e is NetworkException || e is ServerException ? e.toString() : 'Something went wrong. Please try again.';
}
