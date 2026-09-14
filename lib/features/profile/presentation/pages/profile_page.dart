import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/aurora_background.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
          );
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: AuroraBackground(
            child: Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 120.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──────────────────────────────────────
                        _PageHeader(),
                        SizedBox(height: 28.h),

                        // ── Avatar + name card ───────────────────────────
                        _AvatarCard(),
                        SizedBox(height: 24.h),

                        // ── Settings tiles ────────────────────────────────
                        _SectionLabel('Account'),
                        SizedBox(height: 10.h),
                        _SettingsTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Edit Profile',
                          onTap: () {},
                        ),
                        _SettingsTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          onTap: () {},
                        ),
                        SizedBox(height: 20.h),

                        _SectionLabel('General'),
                        SizedBox(height: 10.h),
                        _SettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          onTap: () {},
                        ),
                        _SettingsTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          onTap: () {},
                        ),
                        SizedBox(height: 32.h),

                        // ── Logout button ─────────────────────────────────
                        _LogoutButton(),
                        SizedBox(height: 12.h),

                        Center(
                          child: Text(
                            'Scanrix v1.0.0',
                            style: TextStyle(
                              color: AppColors.secondaryText.withValues(alpha: 0.5),
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Bottom nav ───────────────────────────────────────
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: BottomNavBar(currentIndex: 4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Text(
          'Profile',
          style: TextStyle(
            color: AppColors.neonEmerald,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Avatar card ─────────────────────────────────────────────────────────────

class _AvatarCard extends StatelessWidget {
  const _AvatarCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.07),
                AppColors.glassFill.withValues(alpha: 0.55),
              ],
            ),
            border: Border.all(
              color: AppColors.neonEmerald.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              // Avatar circle
              Container(
                width: 62.r,
                height: 62.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.neonEmerald.withValues(alpha: 0.35),
                      AppColors.forestGreen.withValues(alpha: 0.45),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.neonEmerald.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonEmerald.withValues(alpha: 0.22),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.white,
                  size: 30.r,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scanrix User',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        color: AppColors.neonEmerald.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppColors.neonEmerald.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Free Plan',
                        style: TextStyle(
                          color: AppColors.neonEmerald,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_outlined,
                color: AppColors.secondaryText,
                size: 18.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.secondaryText,
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─── Settings tile ────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                color: AppColors.glassFill.withValues(alpha: 0.45),
                border: Border.all(
                  color: AppColors.neonEmerald.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34.r,
                    height: 34.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonEmerald.withValues(alpha: 0.12),
                    ),
                    child: Icon(icon, color: AppColors.neonEmerald, size: 17.r),
                  ),
                  SizedBox(width: 14.w),
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.secondaryText,
                    size: 18.r,
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

// ─── Logout button ────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.glassFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: AppColors.neonEmerald.withValues(alpha: 0.2)),
        ),
        title: Text(
          'Sign Out',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 13.sp,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 14.sp),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: Text(
              'Sign Out',
              style: TextStyle(
                color: const Color(0xFFFF6B6B),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: () => _confirmLogout(context),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                const Color(0xFFFF4444).withValues(alpha: 0.10),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: const Color(0xFFFF6B6B),
                size: 20.r,
              ),
              SizedBox(width: 10.w),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: const Color(0xFFFF6B6B),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
