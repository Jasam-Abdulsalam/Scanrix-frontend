import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/analyze_with_ai_usecase.dart';
import '../../domain/usecases/get_ai_credits_usecase.dart';
import 'ai_analysis_event.dart';
import 'ai_analysis_state.dart';

/// Drives the opt-in "Get AI verdict" block of one result screen.
///
/// `droppable()`: while an AI request is running, further
/// [AiAnalysisRequested] events (a double tap, an impatient user) are
/// DROPPED, not queued - so one tap can never become two paid AI calls.
/// (`restartable()` would cancel and restart the call, and `sequential()`
/// would run them one after another; both can still charge twice.)
class AiAnalysisBloc extends Bloc<AiAnalysisEvent, AiAnalysisState> {
  final AnalyzeWithAiUseCase analyzeWithAiUseCase;
  final GetAiCreditsUseCase getAiCreditsUseCase;

  AiAnalysisBloc({
    required this.analyzeWithAiUseCase,
    required this.getAiCreditsUseCase,
  }) : super(const AiAnalysisState()) {
    on<AiAnalysisRequested>(_onAnalysisRequested, transformer: droppable());
    on<AiCreditsRequested>(_onCreditsRequested, transformer: droppable());
  }

  Future<void> _onAnalysisRequested(
    AiAnalysisRequested event,
    Emitter<AiAnalysisState> emit,
  ) async {
    emit(state.copyWith(status: AiAnalysisStatus.loading, clearFailure: true));
    try {
      final analysis = await analyzeWithAiUseCase(event.request);
      final remaining = analysis.creditsRemaining;
      emit(state.copyWith(
        status: AiAnalysisStatus.loaded,
        analysis: analysis,
        credits: remaining != null ? state.credits?.copyWith(remaining: remaining) : null,
      ));
      if (remaining != null && state.credits == null) add(const AiCreditsRequested());
    } catch (e) {
      final failure = _failureFrom(e);
      emit(state.copyWith(
        status: AiAnalysisStatus.failure,
        failure: failure,
        // Out of credits: reflect it immediately instead of waiting for a refresh.
        credits: failure.kind == AiFailureKind.creditsExhausted ? state.credits?.copyWith(remaining: 0) : null,
      ));
    }
  }

  Future<void> _onCreditsRequested(
    AiCreditsRequested event,
    Emitter<AiAnalysisState> emit,
  ) async {
    try {
      emit(state.copyWith(credits: await getAiCreditsUseCase(const NoParams())));
    } catch (_) {
      // The balance is a nicety: a failed lookup must not disturb the screen.
    }
  }

  AiFailure _failureFrom(Object e) {
    if (e is NetworkException) return AiFailure(AiFailureKind.network, message: e.message);
    if (e is! ServerException) return AiFailure(AiFailureKind.other, message: e.toString());
    return switch ((e.statusCode, e.code)) {
      (422, 'ingredients_missing') => AiFailure(AiFailureKind.ingredientsMissing, message: e.message),
      (429, _) => AiFailure(
          AiFailureKind.creditsExhausted,
          message: e.message,
          resetsAt: DateTime.tryParse(e.details?['resets_at']?.toString() ?? ''),
        ),
      (503, _) => AiFailure(AiFailureKind.unavailable, message: e.message),
      (404, _) => AiFailure(AiFailureKind.notFound, message: e.message),
      _ => AiFailure(AiFailureKind.other, message: e.message),
    };
  }
}
