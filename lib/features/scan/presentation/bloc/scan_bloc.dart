import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/usecases/analyze_text_usecase.dart';
import '../../domain/usecases/scan_barcode_usecase.dart';
import 'scan_event.dart';
import 'scan_state.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  final ScanBarcodeUseCase scanBarcodeUseCase;
  final AnalyzeTextUseCase analyzeTextUseCase;

  ScanBloc({
    required this.scanBarcodeUseCase,
    required this.analyzeTextUseCase,
  }) : super(ScanInitial()) {
    on<ScanBarcodeRequested>(_onScanBarcodeRequested);
    on<ScanAnalyzeTextRequested>(_onScanAnalyzeTextRequested);
  }

  Future<void> _onScanBarcodeRequested(
    ScanBarcodeRequested event,
    Emitter<ScanState> emit,
  ) async {
    emit(ScanLoading());
    try {
      final result = await scanBarcodeUseCase(event.barcode);
      emit(ScanBarcodeSuccess(result));
    } catch (e) {
      emit(ScanFailure(
        e.toString(),
        statusCode: e is ServerException ? e.statusCode : null,
      ));
    }
  }

  Future<void> _onScanAnalyzeTextRequested(
    ScanAnalyzeTextRequested event,
    Emitter<ScanState> emit,
  ) async {
    emit(ScanLoading());
    try {
      final analysis = await analyzeTextUseCase(
        AnalyzeTextParams(
          ingredientsText: event.ingredientsText,
          category: event.category,
        ),
      );
      emit(ScanTextAnalysisSuccess(analysis));
    } catch (e) {
      emit(ScanFailure(e.toString()));
    }
  }
}
