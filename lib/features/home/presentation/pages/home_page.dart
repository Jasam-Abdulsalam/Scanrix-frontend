import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/aurora_background.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/quick_action_card.dart';

/// Static UI for now — no navigation wired (destination pages are still
/// placeholders). See CLAUDE.md "Home page" for what's stubbed.
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
                            SizedBox(height: 24.h),
                            const _ScanHealthProductCard(),
                            SizedBox(height: 28.h),
                         
                            SizedBox(height: 28.h),
                            const _SectionHeader(title: 'Quick Actions'),
                            SizedBox(height: 14.h),
                            Row(
                              children: [
                                const Expanded(
                                  child: QuickActionCard(
                                    icon: Icons.assignment_outlined,
                                    title: 'My Routine',
                                    subtitle: 'Daily products',
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                const Expanded(
                                  child: QuickActionCard(
                                    icon: Icons.favorite_border_rounded,
                                    title: 'Saved Products',
                                    subtitle: 'Your collection',
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
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(top: false, child: BottomNavBar(currentIndex: 0)),
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
class _ScanHealthProductCard extends StatelessWidget {
  const _ScanHealthProductCard();

  @override
  Widget build(BuildContext context) {
    final radius = 25.r;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25E28B).withValues(alpha: 0.10),
            blurRadius: 35,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            // ---------------------------------------------------------
            // CARD BACKGROUND
            // ---------------------------------------------------------
            Container(
              padding: EdgeInsets.fromLTRB(
                20.w,
                20.h,
                20.w,
                20.h,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF183A2B).withValues(alpha: 0.72),
                    const Color(0xFF0D2118).withValues(alpha: 0.82),
                    const Color(0xFF07120D).withValues(alpha: 0.88),
                  ],
                  stops: const [
                    0.0,
                    0.48,
                    1.0,
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.48),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ---------------------------------------------------
                  // LABEL
                  // ---------------------------------------------------
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.crop_free_rounded,
                        color: AppColors.neonEmerald,
                        size: 18.r,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'SCAN HEALTH PRODUCT',
                        style: TextStyle(
                          color: AppColors.neonEmerald,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // ---------------------------------------------------
                  // TITLE
                  // ---------------------------------------------------
                  Text(
                    'Scan Health Product',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // ---------------------------------------------------
                  // DESCRIPTION
                  // ---------------------------------------------------
                  SizedBox(
                    width: 0.78.sw,
                    child: Text(
                      'Scan any health or skincare product to instantly '
                      'view ingredients and get a health score.',
                      style: TextStyle(
                        color: const Color(0xFFA5C3B7),
                        fontSize: 13.sp,
                        height: 1.45,
                      ),
                    ),
                  ),

                  SizedBox(height: 18.h),

                  // ---------------------------------------------------
                  // BUTTON
                  // ---------------------------------------------------
                  PrimaryButton(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.crop_free_rounded,
                          size: 18.r,
                        ),
                        SizedBox(width: 9.w),
                        Text(
                          'Scan Now',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---------------------------------------------------------
            // SOFT INTERNAL GREEN GLOW
            // ---------------------------------------------------------
            Positioned(
              right: -80.w,
              bottom: -90.h,
              child: IgnorePointer(
                child: Container(
                  width: 220.r,
                  height: 220.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.neonEmerald.withValues(alpha: 0.16),
                        AppColors.neonEmerald.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ---------------------------------------------------------
            // GLASS BUBBLES
          
          ],
        ),
      ),
    );
  }

  Widget _glassBubble(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.30),
            AppColors.neonEmerald.withValues(alpha: 0.18),
            AppColors.forestGreen.withValues(alpha: 0.22),
            const Color(0xFF07150E).withValues(alpha: 0.30),
          ],
          stops: const [
            0.0,
            0.18,
            0.58,
            1.0,
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonEmerald.withValues(alpha: 0.20),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(3, 5),
          ),
        ],
      ),
    );
  }
}