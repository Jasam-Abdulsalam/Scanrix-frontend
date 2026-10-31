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

/// [items] may be empty: no better-scored product was found.
class AlternativesLoaded extends AlternativesState {
  final List<AlternativeProductEntity> items;

  const AlternativesLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class AlternativesFailure extends AlternativesState {
  final String message;

  const AlternativesFailure(this.message);

  @override
  List<Object?> get props => [message];
}
