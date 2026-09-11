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

  const ScanFailure(this.message);

  @override
  List<Object?> get props => [message];
}
