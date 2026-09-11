import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_scan_history_usecase.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetScanHistoryUseCase getScanHistoryUseCase;

  HistoryBloc({required this.getScanHistoryUseCase}) : super(HistoryInitial()) {
    on<HistoryRequested>(_onHistoryRequested);
  }

  Future<void> _onHistoryRequested(
    HistoryRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    try {
      final items = await getScanHistoryUseCase(event.limit);
      emit(HistoryLoaded(items));
    } catch (e) {
      emit(HistoryFailure(e.toString()));
    }
  }
}
