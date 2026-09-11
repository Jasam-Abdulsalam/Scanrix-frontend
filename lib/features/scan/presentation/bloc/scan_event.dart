import 'package:equatable/equatable.dart';

abstract class ScanEvent extends Equatable {
  const ScanEvent();

  @override
  List<Object?> get props => [];
}

class ScanBarcodeRequested extends ScanEvent {
  final String barcode;

  const ScanBarcodeRequested(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

class ScanAnalyzeTextRequested extends ScanEvent {
  final String ingredientsText;
  final String category;

  const ScanAnalyzeTextRequested({
    required this.ingredientsText,
    this.category = 'food',
  });

  @override
  List<Object?> get props => [ingredientsText, category];
}
