import 'package:equatable/equatable.dart';

import '../../domain/entities/scan_result_entity.dart';
import '../../domain/entities/text_analysis_entity.dart';

abstract class ScanState extends Equatable {
  const ScanState();

  @override
  List<Object?> get props => [];
}

class ScanInitial extends ScanState {}

class ScanLoading extends ScanState {}

class ScanBarcodeSuccess extends ScanState {
  final ScanResultEntity result;

  const ScanBarcodeSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class ScanTextAnalysisSuccess extends ScanState {
  final TextAnalysisEntity analysis;

  const ScanTextAnalysisSuccess(this.analysis);

  @override
  List<Object?> get props => [analysis];
}

class ScanFailure extends ScanState {
  final String message;
  final int? statusCode;

  const ScanFailure(this.message, {this.statusCode});

  /// True when the barcode simply isn't in any database (vs. a network/server
  /// error) — `POST /scan/` returns 404 for this specifically.
  bool get isNotFound => statusCode == 404;

  @override
  List<Object?> get props => [message, statusCode];
}
