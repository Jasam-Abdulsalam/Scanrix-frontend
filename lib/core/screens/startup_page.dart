import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:scanrix_frontend/core/di/injection_container.dart' as di;
import 'package:scanrix_frontend/core/error/exceptions.dart';
import 'package:scanrix_frontend/core/navigation/main_shell.dart';
import 'package:scanrix_frontend/core/network/api_client.dart';
import 'package:scanrix_frontend/core/usecase/usecase.dart';
import 'package:scanrix_frontend/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:scanrix_frontend/features/auth/presentation/pages/create_account_page.dart';
import 'package:scanrix_frontend/features/auth/presentation/pages/login_page.dart';


class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  // Controls whether the Lottie animation has finished.
  bool animationFinished = false;

  // Controls whether authentication / user initialization has finished.
  bool initializationFinished = false;

  // The screen we should navigate to after both are finished.
  Widget? destination;

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  // ------------------------------------------------------------
  // INITIALIZATION
  // ------------------------------------------------------------

  Future<void> _initialize() async {
    destination = await _resolveInitialPage();

    initializationFinished = true;

    _tryNavigate();
  }

  // ------------------------------------------------------------
  // ANIMATION COMPLETE
  // ------------------------------------------------------------

  void _onAnimationFinished() {
    animationFinished = true;

    _tryNavigate();
  }

  // ------------------------------------------------------------
  // NAVIGATION CHECK
  // ------------------------------------------------------------

  void _tryNavigate() {
    if (!animationFinished) return;
    if (!initializationFinished) return;
    if (destination == null) return;
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => destination!,
      ),
    );
  }

  // ------------------------------------------------------------
  // DETERMINE INITIAL SCREEN
  // ------------------------------------------------------------

  Future<Widget> _resolveInitialPage() async {
    final apiClient = di.sl<ApiClient>();

    if (!apiClient.isAuthenticated) {
      return const LoginPage();
    }

    try {
      final user = await di.sl<GetCurrentUserUseCase>()(
        const NoParams(),
      );

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
        await apiClient.clearToken();
        return const LoginPage();
      }

      return const MainShell();
    } catch (_) {
      return const MainShell();
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D0A),
      body: Center(
        child: Lottie.asset(
          'assets/animations/scanrix_splash.json',

          width: 180,
          height: 180,

          repeat: false,

          // THIS is called when Lottie finishes.
          onLoaded: (composition) {
            // Don't use a fixed delay.
            // Let Lottie tell us exactly when it finishes.
          },
        ),
      ),
    );
  }
}