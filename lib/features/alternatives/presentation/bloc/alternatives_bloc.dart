import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/usecases/get_alternatives_usecase.dart';
import 'alternatives_event.dart';
import 'alternatives_state.dart';

/// One per Alternatives screen (registered as a factory).
///
/// `droppable()`: a retry tapped while a request is running is ignored rather
/// than queued, so a double tap can never become two paid AI calls.
class AlternativesBloc extends Bloc<AlternativesEvent, AlternativesState> {
  final GetAlternativesUseCase getAlternativesUseCase;

  AlternativesBloc({required this.getAlternativesUseCase}) : super(const AlternativesInitial()) {
    on<AlternativesRequested>(_onRequested, transformer: droppable());
  }

  Future<void> _onRequested(AlternativesRequested event, Emitter<AlternativesState> emit) async {
    emit(const AlternativesLoading());
    try {
      emit(AlternativesLoaded(await getAlternativesUseCase(event.barcode)));
    } catch (e) {
      emit(_failureFrom(e));
    }
  }

  AlternativesFailure _failureFrom(Object e) {
    if (e is NetworkException) {
      return const AlternativesFailure(
          AlternativesFailureKind.network, 'No connection. Check your internet and try again.');
    }
    if (e is! ServerException) {
      return const AlternativesFailure(AlternativesFailureKind.other, "Couldn't load alternatives.");
    }
    return switch ((e.statusCode, e.code)) {
      (429, _) => AlternativesFailure(
          AlternativesFailureKind.creditsExhausted,
          "You've used this week's AI credits.",
          resetsAt: DateTime.tryParse(e.details?['resets_at']?.toString() ?? ''),
        ),
      (503, _) => const AlternativesFailure(AlternativesFailureKind.unavailable,
          'AI suggestions are not available right now. You were not charged. Try again later.'),
      (422, 'ingredients_missing') => const AlternativesFailure(AlternativesFailureKind.ingredientsMissing,
          'This product has no ingredient list yet, so we can\'t suggest alternatives. Scan its ingredients label.'),
      _ => AlternativesFailure(
          AlternativesFailureKind.other, e.message.isEmpty ? "Couldn't load alternatives." : e.message),
    };
  }
}
