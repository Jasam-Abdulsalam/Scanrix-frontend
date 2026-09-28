import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import 'package:scanrix_frontend/core/widgets/reveal_text.dart';
import 'package:scanrix_frontend/core/di/injection_container.dart' as di;
import 'package:scanrix_frontend/core/error/exceptions.dart';
import 'package:scanrix_frontend/core/navigation/main_shell.dart';
import 'package:scanrix_frontend/core/network/api_client.dart';
import 'package:scanrix_frontend/core/usecase/usecase.dart';
import 'package:scanrix_frontend/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:scanrix_frontend/features/auth/presentation/pages/create_account_page.dart';
import 'package:scanrix_frontend/features/auth/presentation/pages/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  bool animationFinished = false;
  bool initializationFinished = false;

  Widget? destination;

  @override
  void initState() {
    super.initState();

    // Hide status bar + nav bar so the splash truly covers the whole screen.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _animationController = AnimationController(vsync: this);

    _initialize();
  }

  // ------------------------------------------------------------
  // APP INITIALIZATION
  // ------------------------------------------------------------

  Future<void> _initialize() async {
    destination = await _resolveInitialPage();
    initializationFinished = true;
    _tryNavigate();
  }

  // ------------------------------------------------------------
  // LOTTIE ANIMATION
  // ------------------------------------------------------------

  void _onAnimationFinished() {
    animationFinished = true;
    _tryNavigate();
  }

  // ------------------------------------------------------------
  // NAVIGATION
  // ------------------------------------------------------------

  void _tryNavigate() {
    if (!animationFinished) return;
    if (!initializationFinished) return;
    if (destination == null) return;
    if (!mounted) return;

    // Restore normal system UI before leaving the splash.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination!),
    );
  }

  // ------------------------------------------------------------
  // DETERMINE INITIAL PAGE
  // ------------------------------------------------------------

  Future<Widget> _resolveInitialPage() async {
    final apiClient = di.sl<ApiClient>();

    if (!apiClient.isAuthenticated) {
      return const LoginPage();
    }

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
        await apiClient.clearToken();
        return const LoginPage();
      }
      return const MainShell();
    } catch (_) {
      return const MainShell();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D0A),
      extendBodyBehindAppBar: true,
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Constrained + BoxFit.contain so it scales proportionally
            // to the composition's own aspect ratio (430x932) instead
            // of stretching/overflowing to fill the device screen.
            FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 430,
                height: 932,
                child: Lottie.asset(
                  'assets/lottie/scanrix.lottie',
                  delegates: LottieDelegates(
                    text: (initialText) {
                    
                      return initialText;
                    },
                  ),
                  controller: _animationController,
                  repeat: false,
                  onLoaded: (composition) {
                    _animationController
                      ..duration = composition.duration
                      ..forward();

                    _animationController.addStatusListener((status) {
                      if (status == AnimationStatus.completed) {
                        _onAnimationFinished();
                      }
                    });
                  },
                ),
              ),
            ),

            // "Scanrix" text overlay — appears, holds, fades out in sync
            // with the dot's expand-to-cover-screen animation.
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, _) {
                return TextRevealFade(
  text: 'Scanrix',
  timelineProgress: _animationController.value,

  // Keep reveal speed unchanged
  appearStart: 0.25,
  appearEnd: 0.28,

  // Faster fade-out
  disappearStart: 0.30,
  disappearEnd: 0.35,

  baseStyle: const TextStyle(
    fontFamily: 'Audiowide',
    fontSize: 30,
  ),
  endColor: const Color(0xFF010E0E),
);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Safety net in case the widget gets disposed some other way
    // (e.g. hot reload) without _tryNavigate running.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    super.dispose();
  }
}