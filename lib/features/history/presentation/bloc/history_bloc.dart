import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/clear_history_usecase.dart';
import '../../domain/usecases/delete_history_entry_usecase.dart';
import '../../domain/usecases/get_scan_history_usecase.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetScanHistoryUseCase getScanHistoryUseCase;
  final DeleteHistoryEntryUseCase deleteHistoryEntryUseCase;
  final ClearHistoryUseCase clearHistoryUseCase;

  HistoryBloc({
    required this.getScanHistoryUseCase,
    required this.deleteHistoryEntryUseCase,
    required this.clearHistoryUseCase,
  }) : super(HistoryInitial()) {
    // droppable: a refresh while one is running adds nothing.
    on<HistoryRequested>(_onRequested, transformer: droppable());
    // sequential: deletes run one after another, so each optimistic update
    // starts from the result of the previous one.
    on<HistoryEntryDeleted>(_onDeleted, transformer: sequential());
    on<HistoryCleared>(_onCleared, transformer: sequential());
  }

  Future<void> _onRequested(HistoryRequested event, Emitter<HistoryState> emit) async {
    final keepList = event.silent && state is HistoryLoaded;
    if (!keepList) emit(HistoryLoading());
    try {
      emit(HistoryLoaded(await getScanHistoryUseCase(event.limit)));
    } catch (e) {
      // A failed silent refresh keeps the list the user already sees.
      if (keepList) return;
      emit(HistoryFailure(_messageFor(e)));
    }
  }

  /// Optimistic: the row disappears at once; if the server refuses, it comes back with a notice.
  Future<void> _onDeleted(HistoryEntryDeleted event, Emitter<HistoryState> emit) async {
    final current = state;
    if (current is! HistoryLoaded) return;
    emit(HistoryLoaded(current.items.where((i) => i.id != event.id).toList()));
    try {
      await deleteHistoryEntryUseCase(event.id);
    } catch (e) {
      emit(HistoryLoaded(current.items, notice: "Couldn't delete that scan. ${_messageFor(e)}"));
    }
  }

  Future<void> _onCleared(HistoryCleared event, Emitter<HistoryState> emit) async {
    final current = state;
    if (current is! HistoryLoaded || current.items.isEmpty) return;
    emit(const HistoryLoaded([]));
    try {
      await clearHistoryUseCase(const NoParams());
    } catch (e) {
      emit(HistoryLoaded(current.items, notice: "Couldn't clear history. ${_messageFor(e)}"));
    }
  }

  String _messageFor(Object e) =>
      e is NetworkException || e is ServerException ? e.toString() : 'Something went wrong. Please try again.';
}
