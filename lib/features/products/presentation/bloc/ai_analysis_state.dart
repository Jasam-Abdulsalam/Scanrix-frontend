import 'package:equatable/equatable.dart';

import '../../domain/entities/ai_analysis_entity.dart';

enum AiAnalysisStatus { idle, loading, loaded, failure }

/// Why an AI request failed; the UI picks the message from this.
enum AiFailureKind {
  /// 422 `ingredients_missing`: the product has no ingredient list.
  ingredientsMissing,

  /// 429 `ai_credits_exhausted`.
  creditsExhausted,

  /// 503 `ai_unavailable`: the user was NOT charged.
  unavailable,

  /// 404: product not found.
  notFound,
  network,
  other,
}

class AiFailure extends Equatable {
  final AiFailureKind kind;
  final String message;
  final DateTime? resetsAt;

  const AiFailure(this.kind, {this.message = '', this.resetsAt});

  @override
  List<Object?> get props => [kind, message, resetsAt];
}

/// One state object (not a class per state like the other Blocs) because the
/// credit balance must stay visible while idle, loading, loaded and failed.
class AiAnalysisState extends Equatable {
  final AiAnalysisStatus status;
  final AiAnalysis? analysis;
  final AiCredits? credits;
  final AiFailure? failure;

  const AiAnalysisState({
    this.status = AiAnalysisStatus.idle,
    this.analysis,
    this.credits,
    this.failure,
  });

  bool get isLoading => status == AiAnalysisStatus.loading;

  AiAnalysisState copyWith({
    AiAnalysisStatus? status,
    AiAnalysis? analysis,
    AiCredits? credits,
    AiFailure? failure,
    bool clearFailure = false,
  }) {
    return AiAnalysisState(
      status: status ?? this.status,
      analysis: analysis ?? this.analysis,
      credits: credits ?? this.credits,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, analysis, credits, failure];
}
