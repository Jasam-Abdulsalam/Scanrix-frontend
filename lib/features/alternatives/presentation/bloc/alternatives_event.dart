import 'package:equatable/equatable.dart';

abstract class AlternativesEvent extends Equatable {
  const AlternativesEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or retry loading) the alternatives for the scanned [barcode].
class AlternativesRequested extends AlternativesEvent {
  final String barcode;

  const AlternativesRequested(this.barcode);

  @override
  List<Object?> get props => [barcode];
}
