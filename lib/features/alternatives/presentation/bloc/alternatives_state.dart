import 'package:equatable/equatable.dart';

import '../../domain/entities/alternative_product_entity.dart';

abstract class AlternativesState extends Equatable {
  const AlternativesState();

  @override
  List<Object?> get props => [];
}

class AlternativesInitial extends AlternativesState {
  const AlternativesInitial();
}

class AlternativesLoading extends AlternativesState {
  const AlternativesLoading();
}

/// `result.alternatives` may be empty: the AI found nothing it was confident about.
class AlternativesLoaded extends AlternativesState {
  final AlternativesResult result;

  const AlternativesLoaded(this.result);

  @override
  List<Object?> get props => [result];
}

/// Why loading failed; the page picks the icon, title and whether to offer a retry.
enum AlternativesFailureKind {
  /// 429 `ai_credits_exhausted`: [AlternativesFailure.resetsAt] says when credits come back.
  creditsExhausted,

  /// 503 `ai_unavailable`: the user was NOT charged; worth retrying later.
  unavailable,

  /// 422 `ingredients_missing`: the product has no ingredient list.
  ingredientsMissing,

  network,
  other,
}

class AlternativesFailure extends AlternativesState {
  final AlternativesFailureKind kind;
  final String message;
  final DateTime? resetsAt;

  const AlternativesFailure(this.kind, this.message, {this.resetsAt});

  bool get canRetry => kind == AlternativesFailureKind.unavailable ||
      kind == AlternativesFailureKind.network ||
      kind == AlternativesFailureKind.other;

  @override
  List<Object?> get props => [kind, message, resetsAt];
}
