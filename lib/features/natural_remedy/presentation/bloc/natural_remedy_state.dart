import 'package:equatable/equatable.dart';

import '../../domain/entities/natural_remedy_entity.dart';

sealed class NaturalRemedyState extends Equatable {
  const NaturalRemedyState();

  @override
  List<Object?> get props => [];
}

class NaturalRemedyLoading extends NaturalRemedyState {
  const NaturalRemedyLoading();
}

/// `result.remedies` may be empty: then `result.noRemedyReason` says why.
class NaturalRemedyLoaded extends NaturalRemedyState {
  final NaturalRemedyResult result;

  const NaturalRemedyLoaded(this.result);

  @override
  List<Object?> get props => [result];
}

enum NaturalRemedyFailureKind {
  /// 429: [NaturalRemedyFailure.resetsAt] says when credits come back.
  creditsExhausted,

  /// 503: the user was NOT charged; worth retrying later.
  unavailable,
  ingredientsMissing,

  /// 422 `not_cosmetic` (the app only offers it for cosmetics, so rare).
  notCosmetic,
  network,
  other,
}

class NaturalRemedyFailure extends NaturalRemedyState {
  final NaturalRemedyFailureKind kind;
  final String message;
  final DateTime? resetsAt;

  const NaturalRemedyFailure(this.kind, this.message, {this.resetsAt});

  bool get canRetry => switch (kind) {
        NaturalRemedyFailureKind.unavailable || NaturalRemedyFailureKind.network || NaturalRemedyFailureKind.other => true,
        _ => false,
      };

  @override
  List<Object?> get props => [kind, message, resetsAt];
}
