import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/navigation/bottom_nav_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/aurora_background.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../../../../core/widgets/quick_action_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AuroraBackground(
          child: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const _Header(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 120.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _WelcomeSection(),
                            SizedBox(height: 44.h),
                            const _ScanHealthProductCard(),
                            SizedBox(height: 38.h),
                            const _SectionHeader(title: 'Quick Actions'),
                            SizedBox(height: 14.h),
                            Row(
                              children: [
                                const Expanded(
                                  child: QuickActionCard(
                                    
                                    title: 'My Routine',
                                    subtitle: 'Daily products',
                                    imageAsset: 'assets/images/routine.png',
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                const Expanded(
                                  child: QuickActionCard(
                                    icon: Icons.favorite_border_rounded,
                                    title: 'Saved Products',
                                    subtitle: 'Your collection',
                                    imageAsset: 'assets/images/product 2.png',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: BottomNavBar(
                    currentIndex: 0,
                    onTap: (index) =>
                        handleBottomNavTap(context, index, currentIndex: 0),
                    onScanPressed: () => handleScanPressed(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 4.h),
      child: Row(
        children: [
          Icon(Icons.eco_rounded, color: AppColors.neonEmerald, size: 22.r),
          SizedBox(width: 8.w),
          Text(
            'Scanrix',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const _CircleIconButton(
            icon: Icons.notifications_none_rounded,
            showBadge: true,
          ),
          SizedBox(width: 10.w),
          // Placeholder avatar — no user-photo field/backend wiring exists
          // yet, so this is a generic icon rather than a real profile image.
          const _CircleIconButton(icon: Icons.person_rounded),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final bool showBadge;

  const _CircleIconButton({required this.icon, this.showBadge = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 38.r,
          height: 38.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.glassFill.withValues(alpha: 0.6),
            border: Border.all(
              color: AppColors.neonEmerald.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(icon, color: AppColors.white, size: 18.r),
        ),
        if (showBadge)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 9.r,
              height: 9.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonEmerald,
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
            children: [
              const TextSpan(text: 'Welcome to '),
              TextSpan(
                text: 'Scanrix!',
                style: TextStyle(color: AppColors.neonEmerald),
              ),
            ],
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Ready to scan your first product?',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 13.sp),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Icon(
          Icons.chevron_right_rounded,
          color: AppColors.secondaryText,
          size: 20.r,
        ),
      ],
    );
  }
}

class _ScanHealthProductCard extends StatefulWidget {
  const _ScanHealthProductCard();

  @override
  State<_ScanHealthProductCard> createState() => _ScanHealthProductCardState();
}

class _ScanHealthProductCardState extends State<_ScanHealthProductCard>
    with SingleTickerProviderStateMixin {
  // -----------------------------------------------------------------
  // PRODUCT IMAGE POOL — add more images here any time
  // -----------------------------------------------------------------
  static const List<String> _productImages = [
    'assets/images/product.png',
    'assets/images/product 2.png',
  ];

  static const String _storageKey = 'product_showcase_index';
  static const _storage = FlutterSecureStorage();

  late int _imageIndex;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    // Slide-in controller: 650 ms, smooth deceleration curve
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _loadAndAdvanceIndex();
  }

  // Reads the stored index, picks the NEXT image, saves it, then plays animation.
  Future<void> _loadAndAdvanceIndex() async {
    final raw = await _storage.read(key: _storageKey);
    final previousIndex = int.tryParse(raw ?? '-1') ?? -1;
    // Advance to the next image in the pool
    _imageIndex = (previousIndex + 1) % _productImages.length;
    await _storage.write(key: _storageKey, value: '$_imageIndex');

    if (!mounted) return;
    setState(() => _ready = true);
    // Small delay so the card layout is painted before we animate
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (mounted) _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  String get _currentImage => _productImages[_imageIndex];

  @override
  Widget build(BuildContext context) {
    final radius = 24.r;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25E28B).withValues(alpha: 0.12),
            blurRadius: 36,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D281C),
                Color(0xFF081C13),
                Color(0xFF040E0A),
              ],
              stops: [0.0, 0.52, 1.0],
            ),
            border: Border.all(
              color: const Color(0xFF2B634A).withValues(alpha: 0.85),
              width: 1.2,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // -------------------------------------------------------
              // SOFT AMBIENT STUDIO LIGHT BEHIND PRODUCT
              // -------------------------------------------------------
              Positioned(
                right: -15.w,
                top: -20.h,
                bottom: -15.h,
                width: 180.w,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.2, -0.2),
                        radius: 0.85,
                        colors: [
                          const Color(0xFF1F5C3E).withValues(alpha: 0.65),
                          const Color(0xFF103623).withValues(alpha: 0.30),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // -------------------------------------------------------
              // PRODUCT BOTTLE IMAGE — slides in from right on each launch
              // -------------------------------------------------------
              Positioned(
                right: 0,
                top: 6.h,
                bottom: -4.h,
                width: 148.w,
                child: IgnorePointer(
                  child: _ready
                      ? FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Image.asset(
                              _currentImage,
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomRight,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/product.png',
                                fit: BoxFit.contain,
                                alignment: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              // -------------------------------------------------------
              // LEFT CONTENT (TAG, TITLE, DESCRIPTION, SCAN NOW CTA)
              // -------------------------------------------------------
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tag
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ViewfinderIcon(
                          size: 15.r,
                          color: AppColors.neonEmerald,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'SCAN HEALTH PRODUCT',
                          style: TextStyle(
                            color: AppColors.neonEmerald,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 14.h),

                    // Title
                    Text(
                      'Scan Health Product',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),

                    SizedBox(height: 10.h),

                    // Description (constrained so it never overlaps the product image)
                    SizedBox(
                      width: 158.w,
                      child: Text(
                        'Scan any health or skincare product to instantly '
                        'view ingredients and get a health score.',
                        style: TextStyle(
                          color: const Color(0xFF94B5A5),
                          fontSize: 12.sp,
                          height: 1.4,
                        ),
                      ),
                    ),

                    SizedBox(height: 18.h),

                    // Scan Now Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28.r),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF25E28B).withValues(alpha: 0.45),
                            blurRadius: 20,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28.r),
                          onTap: () => handleScanPressed(context),
                          child: Ink(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 11.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28.r),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF54F9A6),
                                  Color(0xFF21E387),
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ViewfinderIcon(
                                  size: 16.r,
                                  color: const Color(0xFF031409),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Scan Now',
                                  style: TextStyle(
                                    color: const Color(0xFF031409),
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewfinderIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _ViewfinderIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ViewfinderPainter(color: color),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  final Color color;

  const _ViewfinderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.12;
    final cornerLength = size.width * 0.30;
    final r = size.width * 0.10;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Top-left
    final tl = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(cornerLength, 0);
    canvas.drawPath(tl, paint);

    // Top-right
    final tr = Path()
      ..moveTo(w - cornerLength, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, cornerLength);
    canvas.drawPath(tr, paint);

    // Bottom-left
    final bl = Path()
      ..moveTo(0, h - cornerLength)
      ..lineTo(0, h - r)
      ..arcToPoint(Offset(r, h), radius: Radius.circular(r))
      ..lineTo(cornerLength, h);
    canvas.drawPath(bl, paint);

    // Bottom-right
    final br = Path()
      ..moveTo(w - cornerLength, h)
      ..lineTo(w - r, h)
      ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r))
      ..lineTo(w, h - cornerLength);
    canvas.drawPath(br, paint);

    // Center cross / dots
    final center = Offset(w / 2, h / 2);
    final dotR = strokeWidth * 0.85;
    canvas.drawCircle(center, dotR, dotPaint);

    final offset = w * 0.19;
    canvas.drawCircle(
        Offset(center.dx - offset, center.dy), dotR * 0.75, dotPaint);
    canvas.drawCircle(
        Offset(center.dx + offset, center.dy), dotR * 0.75, dotPaint);
    canvas.drawCircle(
        Offset(center.dx, center.dy - offset), dotR * 0.75, dotPaint);
    canvas.drawCircle(
        Offset(center.dx, center.dy + offset), dotR * 0.75, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) =>
      oldDelegate.color != color;
}
