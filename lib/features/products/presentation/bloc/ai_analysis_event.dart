import 'package:equatable/equatable.dart';

import '../../domain/entities/ai_analysis_entity.dart';

abstract class AiAnalysisEvent extends Equatable {
  const AiAnalysisEvent();

  @override
  List<Object?> get props => [];
}

/// The user tapped "Get AI verdict".
class AiAnalysisRequested extends AiAnalysisEvent {
  final AiAnalysisRequest request;

  const AiAnalysisRequested(this.request);

  @override
  List<Object?> get props => [request];
}

/// Refresh the weekly credit balance.
class AiCreditsRequested extends AiAnalysisEvent {
  const AiCreditsRequested();
}
