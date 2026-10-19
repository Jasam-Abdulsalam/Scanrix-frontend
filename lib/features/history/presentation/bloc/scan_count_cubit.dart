import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_scan_count_usecase.dart';

/// The Profile "Scans" number. State is null until the first load; a failed
/// refresh keeps the last known value instead of blanking it.
class ScanCountCubit extends Cubit<int?> {
  final GetScanCountUseCase getScanCountUseCase;

  ScanCountCubit({required this.getScanCountUseCase}) : super(null);

  Future<void> refresh() async {
    try {
      emit(await getScanCountUseCase(const NoParams()));
    } catch (_) {
      // keep the previous value
    }
  }

  /// On logout, so the next account never sees this one's number.
  void reset() => emit(null);
}
