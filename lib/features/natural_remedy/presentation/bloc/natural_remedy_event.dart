import 'package:equatable/equatable.dart';

import '../../../products/domain/entities/ai_analysis_entity.dart';

/// Load (or retry loading) the remedy for this barcode / label text.
class NaturalRemedyRequested extends Equatable {
  final AiAnalysisRequest request;

  const NaturalRemedyRequested(this.request);

  @override
  List<Object?> get props => [request];
}
