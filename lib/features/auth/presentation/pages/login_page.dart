import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/hero_tags.dart';
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

const _skincareShot = 'assets/images/Eco Skincare Tube with Ingredients UI.png';
const _groceriesShot = 'assets/images/Ingredients Scan_ Snacks and Dairy.png';

/// Decorative product shots on the login page, shown one after another.
/// Public so the splash can precache them and they never pop in late.
const loginProductImages = [_skincareShot, _groceriesShot];

/// Width the product shots are drawn at. The PNGs have wide transparent
/// margins, so they're drawn larger than the products look.
double get _productImageWidth => 390.r;

/// The decoded image for a product shot, at the size the login page shows
/// it. The splash precaches exactly this, so it's a cache hit here.
ImageProvider loginProductImageProvider(BuildContext context, String image) =>
    ResizeImage(
      AssetImage(image),
      width: (_productImageWidth * MediaQuery.devicePixelRatioOf(context))
          .round(),
    );

/// Where each shot's rock rests, in its 1312 x 1199 PNG's pixels (measured
/// from the image's alpha): the bottom edge and the horizontal span.
/// [scale] evens out how big the shots look: the groceries one fills more
/// of its frame, so it's drawn smaller.
const _rocks = {
  _skincareShot: (bottom: 1146.0, centreX: 724.0, width: 889.0, scale: 1.0),
  _groceriesShot: (bottom: 1160.0, centreX: 700.0, width: 940.0, scale: 0.85),
};

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
              child: Stack(
                children: [
                  const Positioned.fill(child: _BackgroundLeaves()),
                  SafeArea(
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
                                  SizedBox(height: 12.h),
                                  // Hero landing spots (leaf + name fly in from
                                  // the splash), so these don't slide in.
                                  const _Header(),
                                  SizedBox(height: 8.h),
                                  _Hero(textTheme: textTheme),
                                  // At least this much air before the button,
                                  // more on taller screens.
                                  SizedBox(height: 40.h),
                                  const Spacer(),
                                  _FadeSlideIn(
                                    delay: const Duration(milliseconds: 180),
                                    child: _GoogleButton(
                                      isLoading: isLoading,
                                      onPressed: () =>
                                          _continueWithGoogle(context),
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Blurred leaves at the edges of the page: depth behind the content
/// without competing with it.
class _BackgroundLeaves extends StatelessWidget {
  const _BackgroundLeaves();

  static const _leaf = 'assets/images/leaf bg.png';

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // Heavily blurred, so a small decode is plenty.
    Widget leaf(double width, double blur, double opacity, double turns) =>
        Opacity(
          opacity: opacity,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: RotationTransition(
              turns: AlwaysStoppedAnimation(turns),
              child: Image.asset(
                _leaf,
                width: width,
                excludeFromSemantics: true,
                cacheWidth: (width * dpr / 2).round(),
              ),
            ),
          ),
        );

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Left edge, beside the product.
          Positioned(
            left: -120.r,
            top: 250.h,
            child: leaf(230.r, 7, 0.45, 0.12),
          ),
          // Top-right corner.
          Positioned(
            right: -110.r,
            top: -40.h,
            child: leaf(220.r, 12, 0.3, -0.35),
          ),
        ],
      ),
    );
  }
}

/// Top-left brand row: small leaf + "Scanrix". Both are hero landing spots
/// for the splash's leaf and name.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Same image as the splash leaf's final frame, so the flying leaf
        // lands without a visible swap.
        Hero(
          tag: scanrixLogoHeroTag,
          child: Image.asset(
            excludeFromSemantics: true,
            'assets/splash/scanrix_leaf.png',
            width: 44.r,
            height: 44.r,
            filterQuality: FilterQuality.high,
          ),
        ),
        SizedBox(width: 12.w),
        _flyingText(
          scanrixWordmarkHeroTag,
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontFamily: 'Audiowide',
                fontSize: 24.sp,
                letterSpacing: 1,
                height: 1.1,
              ),
              children: const [
                TextSpan(
                  text: 'Scan',
                  style: TextStyle(color: AppColors.white),
                ),
                TextSpan(
                  text: 'rix',
                  style: TextStyle(color: _logoMint),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Product shot, then headline and tagline below it. Stacked rather than
/// overlapping, so nothing competes for the same space.
class _Hero extends StatelessWidget {
  final TextTheme textTheme;

  const _Hero({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    final imageWidth = _productImageWidth;
    final imageHeight = 330.r;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: imageHeight,
          width: double.infinity,
          child: _FadeSlideIn(
            delay: const Duration(milliseconds: 150),
            // Nudged right of centre, like the product sits in the frame.
            child: Transform.translate(
              offset: Offset(16.r, 0),
              // Fades the bottom of the whole group (product, glow, rock
              // shadow) into the page, so the rock blends into the
              // background instead of ending on a hard edge.
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0.0, 0.72, 1.0],
                ).createShader(bounds),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Soft mint glow behind the product.
                    Container(
                      width: 300.r,
                      height: 300.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _logoMint.withValues(alpha: 0.14),
                            _logoTeal.withValues(alpha: 0.04),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: _ProductCarousel(
                        imageWidth: imageWidth,
                        imageHeight: imageHeight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 28.h),
        _FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: Text.rich(
            TextSpan(
              style: textTheme.displaySmall?.copyWith(
                color: AppColors.white,
                fontSize: 34.sp,
                fontWeight: FontWeight.w700,
                height: 1.12,
                // Large text reads better tracked slightly tighter.
                letterSpacing: -0.6,
              ),
              children: const [
                TextSpan(text: 'Know what’s in\n'),
                TextSpan(
                  text: 'your products.',
                  style: TextStyle(color: _logoMint),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10.h),
        // Hero landing spot for the splash tagline.
        _flyingText(
          scanrixTaglineHeroTag,
          Text(
            'Smarter choices for a healthier you.',
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.secondaryText,
              fontSize: 17.sp,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// The product shots, one at a time. Every few seconds the current one
/// swooshes out to the left while the next slides in from the right; both
/// move together, so it reads as one motion. Under Reduce Motion they just
/// cross-fade.
class _ProductCarousel extends StatefulWidget {
  final double imageWidth;
  final double imageHeight;

  const _ProductCarousel({required this.imageWidth, required this.imageHeight});

  @override
  State<_ProductCarousel> createState() => _ProductCarouselState();
}

class _ProductCarouselState extends State<_ProductCarousel>
    with SingleTickerProviderStateMixin {
  /// How long each shot stays before the next one comes in.
  static const _hold = Duration(milliseconds: 1500);

  late final AnimationController _swap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _swap,
    curve: Curves.easeInOutCubic,
  );
  Timer? _timer;
  int _index = 0;

  int get _next => (_index + 1) % loginProductImages.length;

  @override
  void initState() {
    super.initState();
    _swap.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      setState(() => _index = _next);
      _swap.reset();
      _scheduleNext();
    });
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(_hold, () {
      if (mounted) _swap.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _swap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Far enough that the outgoing shot has faded before leaving the screen.
    final travel = MediaQuery.sizeOf(context).width * 0.6;

    Widget layer(String image, {required bool incoming}) {
      final t = _t.value;
      final p = incoming ? 1 - t : t; // 0 = in place, 1 = fully away
      return Opacity(
        opacity: incoming ? t : 1 - t,
        child: reduceMotion
            ? _ProductShot(
                image: image,
                imageWidth: widget.imageWidth,
                imageHeight: widget.imageHeight,
              )
            : Transform.translate(
                offset: Offset((incoming ? travel : -travel) * p, 0),
                child: Transform.scale(
                  scale: 1 - 0.08 * p,
                  child: _ProductShot(
                    image: image,
                    imageWidth: widget.imageWidth,
                    imageHeight: widget.imageHeight,
                  ),
                ),
              ),
      );
    }

    return AnimatedBuilder(
      animation: _swap,
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          layer(loginProductImages[_index], incoming: false),
          if (_swap.isAnimating)
            layer(loginProductImages[_next], incoming: true),
        ],
      ),
    );
  }
}

/// One product shot with its rock's contact shadow.
class _ProductShot extends StatelessWidget {
  final String image;
  final double imageWidth;
  final double imageHeight;

  const _ProductShot({
    required this.image,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    final rock = _rocks[image]!;
    // Scale around the rock's resting point, so a smaller shot still sits
    // on the same ground line (and its shadow shrinks with it).
    return Transform.scale(
      scale: rock.scale,
      alignment: Alignment(0, rock.bottom / _RockShadow._imageH * 2 - 1),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Contact shadow under the rock, behind the image, so the product
          // sits on the page instead of floating.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _RockShadow(image: image, imageHeight: imageHeight),
          ),
          OverflowBox(
            maxWidth: imageWidth,
            maxHeight: imageHeight,
            child: Image(
              image: loginProductImageProvider(context, image),
              excludeFromSemantics: true,
              fit: BoxFit.contain,
              width: imageWidth,
              height: imageHeight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft oval shadow where a shot's rock meets the ground, placed from that
/// image's measured rock ([_rocks]). The image is fitted by height into
/// [imageHeight] and centred, so its pixel positions map to the offsets
/// below.
class _RockShadow extends StatelessWidget {
  final String image;
  final double imageHeight;

  const _RockShadow({required this.image, required this.imageHeight});

  static const _imageW = 1312.0, _imageH = 1199.0;

  @override
  Widget build(BuildContext context) {
    final rock = _rocks[image]!;
    final scale = imageHeight / _imageH;
    final shownWidth = _imageW * scale;
    final width = rock.width * scale;
    final dx = (rock.centreX / _imageW - 0.5) * shownWidth;
    final bottom = rock.bottom * scale;

    // Two layers: a wide, very soft ambient shadow and a tighter, darker
    // core right at the contact line, the way real contact shadows fall off.
    Widget oval(
      double w,
      double h,
      double alpha,
      double sigmaX,
      double sigmaY,
    ) => ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: alpha),
          borderRadius: BorderRadius.all(Radius.elliptical(w / 2, h / 2)),
        ),
      ),
    );

    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: SizedBox(
          height: bottom + 24.r,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: bottom - 10.r,
                child: oval(width * 1.05, 22.r, 0.45, 14.r, 7.r),
              ),
              Positioned(
                top: bottom - 6.r,
                child: oval(width * 0.78, 10.r, 0.55, 6.r, 3.r),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero landing spot for text flying in from the splash.
Widget _flyingText(String tag, Widget text) =>
    Hero(tag: tag, flightShuttleBuilder: _crossfadeShuttle, child: text);

/// In flight, cross-fades the splash's version (an image, often a different
/// shape, e.g. one line vs two) into this page's text, each scaled to the
/// flying box, instead of snapping to the new shape at take-off.
Widget _crossfadeShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final from = (fromHeroContext.widget as Hero).child;
  final to = (toHeroContext.widget as Hero).child;
  final fadeIn = CurvedAnimation(
    parent: animation,
    curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
  );
  return Material(
    type: MaterialType.transparency,
    child: Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: ReverseAnimation(fadeIn),
          child: FittedBox(fit: BoxFit.contain, child: from),
        ),
        FadeTransition(
          opacity: fadeIn,
          child: FittedBox(fit: BoxFit.contain, child: to),
        ),
      ],
    ),
  );
}

/// Solid white Google button — the one action on this page, so it should
/// be the brightest thing on it.
class _GoogleButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final TextTheme textTheme;

  const _GoogleButton({
    required this.isLoading,
    required this.onPressed,
    required this.textTheme,
  });

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(32.r);
    final enabled = !widget.isLoading;
    // Shrinks on finger-down, not on release.
    return AnimatedScale(
      scale: _pressed && enabled ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: AppColors.white,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            onTap: enabled ? widget.onPressed : null,
            onTapDown: enabled ? (_) => _setPressed(true) : null,
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: SizedBox(
              // Fixed height so the label → spinner swap can't resize it.
              height: 56.h,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: widget.isLoading
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 22.r,
                          height: 22.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.background,
                          ),
                        )
                      : Row(
                          key: const ValueKey('label'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GoogleLogo(size: 20.r),
                            SizedBox(width: 12.w),
                            Text(
                              'Continue with Google',
                              style: widget.textTheme.titleMedium?.copyWith(
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
        ),
      ),
    );
  }
}

/// Fades and slides [child] up once, after [delay]. Under Reduce Motion it
/// only fades.
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
    duration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(_curve);

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
    final fade = FadeTransition(opacity: _curve, child: widget.child);
    if (MediaQuery.disableAnimationsOf(context)) return fade;
    return SlideTransition(position: _slide, child: fade);
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
