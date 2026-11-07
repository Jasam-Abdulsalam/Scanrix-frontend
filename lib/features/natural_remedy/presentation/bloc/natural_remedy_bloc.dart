import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/usecases/get_natural_remedy_usecase.dart';
import 'natural_remedy_event.dart';
import 'natural_remedy_state.dart';

/// One per remedy screen (registered as a factory).
///
/// `droppable()`: a retry tapped while a request is running is ignored rather
/// than queued, so a double tap can never become two paid AI calls.
class NaturalRemedyBloc extends Bloc<NaturalRemedyRequested, NaturalRemedyState> {
  final GetNaturalRemedyUseCase getNaturalRemedyUseCase;

  NaturalRemedyBloc({required this.getNaturalRemedyUseCase}) : super(const NaturalRemedyLoading()) {
    on<NaturalRemedyRequested>(_onRequested, transformer: droppable());
  }

  Future<void> _onRequested(NaturalRemedyRequested event, Emitter<NaturalRemedyState> emit) async {
    emit(const NaturalRemedyLoading());
    try {
      emit(NaturalRemedyLoaded(await getNaturalRemedyUseCase(event.request)));
    } catch (e) {
      emit(_failureFrom(e));
    }
  }

  NaturalRemedyFailure _failureFrom(Object e) {
    const fallback = "Couldn't load a natural option.";
    if (e is NetworkException) {
      return const NaturalRemedyFailure(
          NaturalRemedyFailureKind.network, 'No connection. Check your internet and try again.');
    }
    if (e is! ServerException) return const NaturalRemedyFailure(NaturalRemedyFailureKind.other, fallback);
    return switch ((e.statusCode, e.code)) {
      (429, _) => NaturalRemedyFailure(
          NaturalRemedyFailureKind.creditsExhausted,
          "You've used this week's AI credits.",
          resetsAt: DateTime.tryParse(e.details?['resets_at']?.toString() ?? ''),
        ),
      (503, _) => const NaturalRemedyFailure(NaturalRemedyFailureKind.unavailable,
          'AI suggestions are not available right now. You were not charged. Try again later.'),
      (422, 'not_cosmetic') => const NaturalRemedyFailure(
          NaturalRemedyFailureKind.notCosmetic, 'Natural options are only available for cosmetics.'),
      (422, 'ingredients_missing') => const NaturalRemedyFailure(NaturalRemedyFailureKind.ingredientsMissing,
          "This product has no ingredient list yet. Scan its ingredients label first."),
      _ => NaturalRemedyFailure(NaturalRemedyFailureKind.other, e.message.isEmpty ? fallback : e.message),
    };
  }
}
