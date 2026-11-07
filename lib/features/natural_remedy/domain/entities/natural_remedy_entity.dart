import 'package:equatable/equatable.dart';

/// One kitchen ingredient of a remedy, e.g. besan · 2 tsp.
class RemedyIngredient extends Equatable {
  final String item;
  final String amount;

  const RemedyIngredient({required this.item, required this.amount});

  @override
  List<Object?> get props => [item, amount];
}

/// A simple homemade alternative to the scanned cosmetic (AI suggestion,
/// already filtered by the backend's safety rules).
class NaturalRemedyEntity extends Equatable {
  final String name;
  final String replaces;
  final List<RemedyIngredient> ingredients;
  final List<String> steps;
  final String? howOften;
  final String? keepsFor;
  final String? why;
  final String? caution;

  const NaturalRemedyEntity({
    required this.name,
    required this.replaces,
    required this.ingredients,
    required this.steps,
    this.howOften,
    this.keepsFor,
    this.why,
    this.caution,
  });

  @override
  List<Object?> get props => [name, replaces, ingredients, steps, howOften, keepsFor, why, caution];
}

class NaturalRemedyResult extends Equatable {
  final String productType;

  /// May be empty: then [noRemedyReason] says why (e.g. sunscreen).
  final List<NaturalRemedyEntity> remedies;
  final String? noRemedyReason;

  /// True = a saved answer (free); false = this request used 1 AI credit.
  final bool cached;
  final int? creditsRemaining;
  final String disclaimer;
  final String patchTestNote;

  const NaturalRemedyResult({
    required this.productType,
    this.remedies = const [],
    this.noRemedyReason,
    this.cached = false,
    this.creditsRemaining,
    required this.disclaimer,
    required this.patchTestNote,
  });

  @override
  List<Object?> get props => [productType, remedies, noRemedyReason, cached, creditsRemaining, disclaimer, patchTestNote];
}
