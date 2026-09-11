import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../features/auth/domain/usecases/google_login_usecase.dart';
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
import '../constants/google_auth_config.dart';
import '../network/api_client.dart';
import '../network/dio_client.dart';
import '../storage/token_storage.dart';

final sl = GetIt.instance;

/// Registers every use case and Bloc with the service locator. Call once
/// from `main()`, before `runApp`.
///
/// TODO: once the rest of auth/products/scan/history are wired up, inject
/// `sl<ApiClient>()` into those use cases' constructors too — call through
/// `ApiClient`, not `DioClient` directly (only `GoogleLoginUseCase` does
/// this so far — see CLAUDE.md "Google Sign-In").
Future<void> init() async {
  sl.registerLazySingleton(() => TokenStorage());
  sl.registerLazySingleton(() => DioClient(tokenStorage: sl()));
  sl.registerLazySingleton(() => ApiClient(dioClient: sl()));
  // Load any token persisted from a previous session before anything else
  // makes a request.
  await sl<ApiClient>().loadPersistedToken();

  // `GoogleSignIn.instance.initialize()` must be awaited exactly once,
  // before any other GoogleSignIn method is called.
  await GoogleSignIn.instance.initialize(
    serverClientId: GoogleAuthConfig.webClientId,
  );

  // ---------------- Auth ----------------
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      googleLoginUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => LoginUseCase());
  sl.registerLazySingleton(() => RegisterUseCase());
  sl.registerLazySingleton(() => GoogleLoginUseCase(apiClient: sl()));

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
