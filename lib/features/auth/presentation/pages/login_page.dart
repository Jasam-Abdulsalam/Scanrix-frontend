import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/navigation/main_shell.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/aurora_background.dart';
import '../../../../core/widgets/google_logo.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'create_account_page.dart';

/// Logo colours (see brand/scanrix-logo-kit/SCANRIX-LOGO-GUIDE.md).
const _logoMint = Color(0xFF39F5C5);
const _logoTeal = Color(0xFF2CC1D2);

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _continueWithGoogle(BuildContext context) {
    context.read<AuthBloc>().add(const AuthGoogleLoginRequested());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocConsumer<AuthBloc, AuthState>(
          // Stay quiet while CreateAccountPage (pushed on top) is showing,
          // so its failures and success aren't handled twice.
          listenWhen: (_, _) => ModalRoute.of(context)?.isCurrent ?? true,
          listener: (context, state) {
            if (state is AuthGoogleSignupRequired) {
              // Pushed, not replaced: Back returns here to pick another
              // Google account. Nothing exists on the server yet.
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateAccountPage(
                    initialName: state.signup.displayName,
                    photoUrl: state.signup.photoUrl,
                    email: state.signup.email,
                    pendingSignup: state.signup,
                  ),
                ),
              );
            } else if (state is AuthFailure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is AuthLoginSuccess) {
              // Keyed off profileCompleted (persisted server-side), not
              // isNewUser — isNewUser is only ever true on the exact
              // request that creates the account, so it can't detect
              // "signed in again, still hasn't finished onboarding".
              if (!state.token.profileCompleted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => CreateAccountPage(
                      initialName: state.token.displayName,
                      photoUrl: state.token.photoUrl,
                      email: state.token.email,
                      // Replaced, so nothing is below it: Back logs out.
                      signOutOnBack: true,
                    ),
                  ),
                );
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainShell()),
                );
              }
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return AuroraBackground(
              child: SafeArea(
                // Scrolls only on very short screens; otherwise the Spacers
                // spread the content over the full height.
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            children: [
                              const Spacer(flex: 3),
                              const _FadeSlideIn(child: _ScanningLogo()),
                              SizedBox(height: 8.h),
                              _FadeSlideIn(
                                delay: const Duration(milliseconds: 150),
                                child: _Wordmark(textTheme: textTheme),
                              ),
                              const Spacer(flex: 2),
                              _FadeSlideIn(
                                delay: const Duration(milliseconds: 300),
                                child: _Highlights(textTheme: textTheme),
                              ),
                              const Spacer(flex: 2),
                              _FadeSlideIn(
                                delay: const Duration(milliseconds: 450),
                                child: _GoogleButton(
                                  isLoading: isLoading,
                                  onPressed: () => _continueWithGoogle(context),
                                  textTheme: textTheme,
                                ),
                              ),
                              SizedBox(height: 20.h),
                              _TermsFooter(textTheme: textTheme),
                              SizedBox(height: 16.h),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The leaf-eye symbol with a soft glow and slow "scanning" pulse rings.
class _ScanningLogo extends StatefulWidget {
  const _ScanningLogo();

  @override
  State<_ScanningLogo> createState() => _ScanningLogoState();
}

class _ScanningLogoState extends State<_ScanningLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = 230.r;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _HaloPainter(_pulse)),
            ),
          ),
          Image.asset(
            'assets/logo/symbol.png',
            width: size * 0.56,
            height: size * 0.56,
            filterQuality: FilterQuality.high,
          ),
        ],
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  final Animation<double> progress;

  _HaloPainter(this.progress) : super(repaint: progress);

  static const _rings = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;

    // Soft teal glow behind the leaf.
    canvas.drawCircle(
      center,
      maxR * 0.62,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _logoTeal.withValues(alpha: 0.30),
            _logoMint.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: maxR * 0.62)),
    );

    // Rings that grow outwards and fade, evenly staggered.
    for (var i = 0; i < _rings; i++) {
      final t = (progress.value + i / _rings) % 1.0;
      final radius = maxR * (0.40 + 0.58 * t);
      final opacity = math.sin(t * math.pi) * 0.45;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _logoMint.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_HaloPainter oldDelegate) => false;
}

class _Wordmark extends StatelessWidget {
  final TextTheme textTheme;

  const _Wordmark({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    final brandStyle = TextStyle(
      fontFamily: 'Audiowide',
      fontSize: 38.sp,
      letterSpacing: 1.5,
      height: 1.1,
    );
    return Column(
      children: [
        Text.rich(
          TextSpan(
            style: brandStyle,
            children: const [
              TextSpan(text: 'Scan', style: TextStyle(color: AppColors.white)),
              TextSpan(text: 'rix', style: TextStyle(color: _logoMint)),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          'Smarter choices for a healthier you.',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: AppColors.secondaryText,
            fontSize: 15.sp,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// Three steps side by side: a glowing round icon over a two-line label,
/// split by thin vertical lines.
class _Highlights extends StatelessWidget {
  final TextTheme textTheme;

  const _Highlights({required this.textTheme});

  // null icon = the scan-frame icon drawn by _IconBadge.
  static const _items = [
    (null, 'Scan\nProducts'),
    (Icons.eco_outlined, 'Understand\nIngredients'),
    (Icons.verified_user_outlined, 'Make\nHealthier Choices'),
  ];

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.white.withValues(alpha: 0.08),
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  _IconBadge(icon: _items[i].$1),
                  SizedBox(height: 12.h),
                  Text(
                    _items[i].$2,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.88),
                      fontSize: 13.sp,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  /// Null draws a scan frame (corner brackets with a line through it).
  final IconData? icon;

  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56.r,
      height: 56.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _logoMint.withValues(alpha: 0.14),
            AppColors.iconContainerBg,
          ],
        ),
        border: Border.all(color: _logoMint.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: _logoMint.withValues(alpha: 0.10),
            blurRadius: 18.r,
          ),
        ],
      ),
      child: icon != null
          ? Icon(icon, color: _logoMint, size: 24.r)
          : Center(
              child: SizedBox.square(
                dimension: 22.r,
                child: const CustomPaint(painter: _ScanFramePainter()),
              ),
            ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final arm = w * 0.3;
    final paint = Paint()
      ..color = _logoMint
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;
    // Four corner brackets.
    for (final (x, y, dx, dy) in [
      (0.0, 0.0, 1.0, 1.0),
      (w, 0.0, -1.0, 1.0),
      (0.0, w, 1.0, -1.0),
      (w, w, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y + dy * arm)
          ..lineTo(x, y)
          ..lineTo(x + dx * arm, y),
        paint,
      );
    }
    // Scan line.
    canvas.drawLine(Offset(w * 0.22, w / 2), Offset(w * 0.78, w / 2), paint);
  }

  @override
  bool shouldRepaint(_ScanFramePainter oldDelegate) => false;
}

/// Solid white Google button — the one action on this page, so it should
/// be the brightest thing on it.
class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final TextTheme textTheme;

  const _GoogleButton({
    required this.isLoading,
    required this.onPressed,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(32.r);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: _logoMint.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22.r,
                      height: 22.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.background,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GoogleLogo(size: 20.r),
                        SizedBox(width: 12.w),
                        Text(
                          'Continue with Google',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.background,
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades and slides [child] up once, after [delay].
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeSlideIn({required this.child, this.delay = Duration.zero});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

class _TermsFooter extends StatelessWidget {
  final TextTheme textTheme;

  const _TermsFooter({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    final baseStyle = textTheme.bodySmall?.copyWith(
      color: AppColors.secondaryText,
    );
    final linkStyle = baseStyle?.copyWith(
      color: AppColors.neonEmerald,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.neonEmerald,
    );

    return Center(
      child: Text.rich(
        TextSpan(
          style: baseStyle,
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(text: 'Terms of Service', style: linkStyle),
            const TextSpan(text: ' and '),
            TextSpan(text: 'Privacy Policy', style: linkStyle),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
