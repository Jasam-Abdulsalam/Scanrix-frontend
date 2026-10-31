import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/error/exceptions.dart';
import '../../../../core/navigation/main_shell.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/get_current_user_usecase.dart';
import '../../../auth/presentation/pages/create_account_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'scanrix_splash.dart';

/// First route on launch. Shows [ScanrixSplash] from the first frame and,
/// while it plays, does the startup work (.env, DI, start-page check).
///
/// When both are done it replaces itself with the start page (so Back
/// can't return here) using a fade, during which the splash leaf flies
/// into the login page's logo (shared hero tag). If the animation ends
/// first, its last frame stays up until the start page is known.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final Future<Widget> _startPage = _startUp();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode the login page's large product shots while the splash plays.
    for (final image in loginProductImages) {
      precacheImage(loginProductImageProvider(context, image), context);
    }
  }

  static Future<Widget> _startUp() async {
    await dotenv.load();
    await di.init();
    return _resolveInitialPage();
  }

  Future<void> _onSplashFinished() async {
    final startPage = await _startPage;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, _, _) => startPage,
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScanrixSplash(onFinished: _onSplashFinished);
  }
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
        signOutOnBack: true,
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
