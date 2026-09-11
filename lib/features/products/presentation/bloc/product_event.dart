import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class ProductRequested extends ProductEvent {
  final String barcode;

  const ProductRequested(this.barcode);

  @override
  List<Object?> get props => [barcode];
}
