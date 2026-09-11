import 'package:get_it/get_it.dart';

import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/history/domain/usecases/get_scan_history_usecase.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';
import '../../features/products/domain/usecases/get_product_usecase.dart';
import '../../features/products/presentation/bloc/product_bloc.dart';
import '../../features/scan/domain/usecases/analyze_text_usecase.dart';
import '../../features/scan/domain/usecases/scan_barcode_usecase.dart';
import '../../features/scan/presentation/bloc/scan_bloc.dart';

final sl = GetIt.instance;

/// Registers every use case and Bloc with the service locator. Call once
/// from `main()`, before `runApp`.
///
/// TODO: once Dio is added, register the shared client here first (e.g.
/// `sl.registerLazySingleton(() => DioClient())`) and inject it into each
/// use case's constructor below.
Future<void> init() async {
  // ---------------- Auth ----------------
  sl.registerFactory(
    () => AuthBloc(loginUseCase: sl(), registerUseCase: sl()),
  );
  sl.registerLazySingleton(() => LoginUseCase());
  sl.registerLazySingleton(() => RegisterUseCase());

  // ---------------- Products ----------------
  sl.registerFactory(
    () => ProductBloc(getProductUseCase: sl()),
  );
  sl.registerLazySingleton(() => GetProductUseCase());

  // ---------------- Scan ----------------
  sl.registerFactory(
    () => ScanBloc(scanBarcodeUseCase: sl(), analyzeTextUseCase: sl()),
  );
  sl.registerLazySingleton(() => ScanBarcodeUseCase());
  sl.registerLazySingleton(() => AnalyzeTextUseCase());

  // ---------------- History ----------------
  sl.registerFactory(
    () => HistoryBloc(getScanHistoryUseCase: sl()),
  );
  sl.registerLazySingleton(() => GetScanHistoryUseCase());
}
