import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:scanrix_frontend/core/screens/splash_screen.dart';

import 'app.dart';
import 'core/di/injection_container.dart' as di;
import 'core/error/exceptions.dart';
import 'core/navigation/main_shell.dart';
import 'core/network/api_client.dart';
import 'core/usecase/usecase.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/presentation/pages/create_account_page.dart';
import 'features/auth/presentation/pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await di.init();
  runApp(ScanrixApp(home: await SplashScreen()));
}

/// A persisted token alone isn't enough to know where to land: it only
/// says the user is *authenticated*, not whether they finished the
/// profile-completion step (`CreateAccountPage`) — that's server state
/// (`UserEntity.profileCompleted`), fetched fresh here since it can change
/// between app opens (see the "profile_completed" discussion — the
/// one-shot `AuthTokenEntity.isNewUser` can't answer this on a later
/// launch).
Future<Widget> _resolveInitialPage() async {
  final apiClient = di.sl<ApiClient>();
  if (!apiClient.isAuthenticated) return const LoginPage();

  try {
    final user = await di.sl<GetCurrentUserUseCase>()(const NoParams());
    if (!user.profileCompleted) {
      return CreateAccountPage(
        initialName: user.name,
        photoUrl: user.photoUrl,
        email: user.email,
      );
    }
    return const MainShell();
  } on ServerException catch (e) {
    if (e.statusCode == 401) {
      // The token really is invalid/expired — the backend said so.
      await apiClient.clearToken();
      return const LoginPage();
    }
    // Some other backend error (5xx, etc.) doesn't mean the token is bad —
    // don't sign the user out over it. Whatever screen needs fresh user
    // data will just refetch it later.
    return const MainShell();
  } catch (_) {
    // Network unreachable, timeout, backend not up yet, etc. — same
    // reasoning: "couldn't reach the server right now" isn't "not logged
    // in", so don't clear a perfectly valid token over it.
    return const MainShell();
  }
}
