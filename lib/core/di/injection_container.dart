import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../features/auth/domain/usecases/delete_account_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/google_login_usecase.dart';
import '../../features/auth/domain/usecases/google_signup_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/update_profile_usecase.dart';
import '../../features/auth/domain/usecases/upload_profile_photo_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/favorites/domain/usecases/add_favorite_usecase.dart';
import '../../features/favorites/domain/usecases/get_favorite_barcodes_usecase.dart';
import '../../features/favorites/domain/usecases/get_favorites_usecase.dart';
import '../../features/favorites/domain/usecases/remove_favorite_usecase.dart';
import '../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../features/history/domain/usecases/clear_history_usecase.dart';
import '../../features/history/domain/usecases/delete_history_entry_usecase.dart';
import '../../features/history/domain/usecases/get_scan_history_usecase.dart';
import '../../features/history/domain/usecases/get_scan_count_usecase.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';
import '../../features/history/presentation/bloc/scan_count_cubit.dart';
import '../../features/alternatives/domain/usecases/get_alternatives_usecase.dart';
import '../../features/alternatives/presentation/bloc/alternatives_bloc.dart';
import '../../features/natural_remedy/domain/usecases/get_natural_remedy_usecase.dart';
import '../../features/routine/domain/usecases/add_to_routine_usecase.dart';
import '../../features/routine/domain/usecases/get_routine_usecase.dart';
import '../../features/routine/domain/usecases/remove_from_routine_usecase.dart';
import '../../features/routine/domain/usecases/reorder_routine_usecase.dart';
import '../../features/routine/domain/usecases/set_routine_product_type_usecase.dart';
import '../../features/routine/presentation/bloc/routine_bloc.dart';
import '../../features/routine/reminders/reminder_scheduler.dart';
import '../../features/natural_remedy/presentation/bloc/natural_remedy_bloc.dart';
import '../../features/products/domain/usecases/analyze_with_ai_usecase.dart';
import '../../features/products/domain/usecases/get_ai_credits_usecase.dart';
import '../../features/products/domain/usecases/get_product_usecase.dart';
import '../../features/products/presentation/bloc/ai_analysis_bloc.dart';
import '../../features/products/presentation/bloc/product_bloc.dart';
import '../../features/scan/domain/usecases/analyze_text_usecase.dart';
import '../../features/scan/domain/usecases/scan_barcode_usecase.dart';
import '../../features/scan/presentation/bloc/scan_bloc.dart';
import '../constants/google_auth_config.dart';
import '../network/api_client.dart';
import '../network/dio_client.dart';
import '../storage/token_storage.dart';
import '../theme/theme_cubit.dart';

final sl = GetIt.instance;

/// The one dependency `ScanrixApp` needs for its first frame (its theme).
/// Called from `main()` before `runApp`, so the splash can show straight
/// away while [init] runs.
void registerEarly() {
  if (!sl.isRegistered<ThemeCubit>()) {
    sl.registerLazySingleton(() => ThemeCubit());
  }
}

/// Registers every use case and Bloc with the service locator. Call once
/// at startup (the splash page does this while its animation plays).
///
/// TODO: once the rest of auth/products/scan/history are wired up, inject
/// `sl<ApiClient>()` into those use cases' constructors too — call through
/// `ApiClient`, not `DioClient` directly (only `GoogleLoginUseCase` does
/// this so far — see CLAUDE.md "Google Sign-In").
Future<void> init() async {
  registerEarly();
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
      googleSignupUseCase: sl(),
      updateProfileUseCase: sl(),
      uploadProfilePhotoUseCase: sl(),
      getCurrentUserUseCase: sl(),
      deleteAccountUseCase: sl(),
      apiClient: sl(),
    ),
  );
  sl.registerLazySingleton(() => LoginUseCase());
  sl.registerLazySingleton(() => RegisterUseCase());
  sl.registerLazySingleton(() => GoogleLoginUseCase(apiClient: sl()));
  sl.registerLazySingleton(() => GoogleSignupUseCase(apiClient: sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(apiClient: sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(apiClient: sl()));
  sl.registerLazySingleton(() => UploadProfilePhotoUseCase(apiClient: sl()));
  sl.registerLazySingleton(() => DeleteAccountUseCase(apiClient: sl()));

  // ---------------- Products ----------------
  sl.registerFactory(() => ProductBloc(getProductUseCase: sl()));
  sl.registerLazySingleton(() => GetProductUseCase(apiClient: sl()));
  // Opt-in "Get AI verdict": one bloc per result screen (factory), shared use cases.
  sl.registerFactory(
    () => AiAnalysisBloc(analyzeWithAiUseCase: sl(), getAiCreditsUseCase: sl()),
  );
  sl.registerLazySingleton(() => AnalyzeWithAiUseCase(apiClient: sl()));
  sl.registerLazySingleton(() => GetAiCreditsUseCase(apiClient: sl()));

  // ---------------- Alternatives ----------------
  // One bloc per Alternatives screen (factory), shared use case. AI-suggested
  // alternatives: POST /ai/alternatives, 1 weekly credit unless already saved.
  sl.registerFactory(() => AlternativesBloc(getAlternativesUseCase: sl()));
  sl.registerLazySingleton(() => GetAlternativesUseCase(apiClient: sl()));

  // ---------------- Natural remedy ----------------
  // Homemade swaps for cosmetics: POST /ai/natural-remedy, 1 weekly credit
  // unless already saved. One bloc per remedy screen.
  sl.registerFactory(() => NaturalRemedyBloc(getNaturalRemedyUseCase: sl()));
  sl.registerLazySingleton(() => GetNaturalRemedyUseCase(apiClient: sl()));

  // ---------------- Scan ----------------
  sl.registerFactory(
    () => ScanBloc(scanBarcodeUseCase: sl(), analyzeTextUseCase: sl()),
  );
  sl.registerLazySingleton(() => ScanBarcodeUseCase(apiClient: sl()));
  sl.registerLazySingleton(() => AnalyzeTextUseCase(apiClient: sl()));

  // ---------------- History ----------------
  sl.registerFactory(
    () => HistoryBloc(
      getScanHistoryUseCase: sl(),
      deleteHistoryEntryUseCase: sl(),
      clearHistoryUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetScanHistoryUseCase(apiClient: sl()));
  sl.registerLazySingleton(() => DeleteHistoryEntryUseCase(apiClient: sl()));
  sl.registerLazySingleton(() => ClearHistoryUseCase(apiClient: sl()));
  sl.registerFactory(() => ScanCountCubit(getScanCountUseCase: sl()));
  sl.registerLazySingleton(() => GetScanCountUseCase(apiClient: sl()));

  // ---------------- Favorites (saved products) ----------------
  sl.registerFactory(
    () => FavoritesBloc(
      getFavoritesUseCase: sl(),
      getFavoriteBarcodesUseCase: sl(),
      addFavoriteUseCase: sl(),
      removeFavoriteUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetFavoritesUseCase(apiClient: sl()));
  sl.registerLazySingleton(() => GetFavoriteBarcodesUseCase(apiClient: sl()));
  sl.registerLazySingleton(() => AddFavoriteUseCase(apiClient: sl()));
  sl.registerLazySingleton(() => RemoveFavoriteUseCase(apiClient: sl()));

  // ---------------- My Routine ----------------
  // App-wide bloc (provided once in app.dart). Reminders: RemindersCubit is built in app.dart because it
  // needs that same RoutineBloc instance; the scheduler (real phone notifications) is shared.
  sl.registerFactory(
    () => RoutineBloc(
      getRoutineUseCase: sl(),
      addToRoutineUseCase: sl(),
      removeFromRoutineUseCase: sl(),
      reorderRoutineUseCase: sl(),
      setProductTypeUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetRoutineUseCase(apiClient: sl()));
  sl.registerLazySingleton(() => AddToRoutineUseCase(apiClient: sl()));
  sl.registerLazySingleton(() => RemoveFromRoutineUseCase(apiClient: sl()));
  sl.registerLazySingleton(() => ReorderRoutineUseCase(apiClient: sl()));
  sl.registerLazySingleton(() => SetRoutineProductTypeUseCase(apiClient: sl()));
  sl.registerLazySingleton<ReminderScheduler>(() => LocalReminderScheduler());
}
