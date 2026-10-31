import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/usecases/get_alternatives_usecase.dart';
import 'alternatives_event.dart';
import 'alternatives_state.dart';

/// One per Alternatives screen (registered as a factory).
///
/// `droppable()`: a retry tapped while a request is running is ignored
/// rather than queued, so a double tap never fires two requests.
class AlternativesBloc extends Bloc<AlternativesEvent, AlternativesState> {
  final GetAlternativesUseCase getAlternativesUseCase;

  AlternativesBloc({required this.getAlternativesUseCase}) : super(const AlternativesInitial()) {
    on<AlternativesRequested>(_onRequested, transformer: droppable());
  }

  Future<void> _onRequested(AlternativesRequested event, Emitter<AlternativesState> emit) async {
    emit(const AlternativesLoading());
    try {
      emit(AlternativesLoaded(await getAlternativesUseCase(event.barcode)));
    } on NetworkException {
      emit(const AlternativesFailure('No connection. Check your internet and try again.'));
    } on ServerException catch (e) {
      emit(AlternativesFailure(e.message.isEmpty ? "Couldn't load alternatives." : e.message));
    } catch (_) {
      emit(const AlternativesFailure("Couldn't load alternatives."));
    }
  }
}
