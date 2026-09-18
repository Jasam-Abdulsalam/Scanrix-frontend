import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scanrix_frontend/features/history/presentation/pages/history_page.dart';

import '../../../../core/navigation/bottom_nav_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/aurora_background.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/create_account_page.dart';
import '../../../auth/presentation/pages/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthCurrentUserRequested());
  }

  void _openEditProfile(UserEntity? user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateAccountPage(
          initialName: user?.name,
          photoUrl: user?.photoUrl,
          email: user?.email,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        // AuthBloc is shared app-wide, so this also briefly sees loading/
        // failure states from unrelated auth actions — only update the
        // displayed user when we actually have one.
        final user = state is AuthCurrentUserLoaded
            ? state.user
            : (state is AuthProfileCompleteSuccess ? state.user : null);
        final isLoadingUser = user == null && state is AuthLoading;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: AuroraBackground(
              child: Stack(
                children: [
                  // Positioned.fill pins this to the full screen height
                  // regardless of content length — a bare SingleChildScrollView
                  // here would size itself to its own content instead, which
                  // shrinks the Stack (and drags the Positioned bottom nav up
                  // with it) whenever the content gets shorter.
                  Positioned.fill(
                    child: SafeArea(
                      bottom: false,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: 120.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ── Top bar + centered hero ───────────────────
                            Padding(
                              padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 0),
                              child: _TopBar(
                                onEditTap: () => _openEditProfile(user),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            _ProfileHero(
                              user: user,
                              isLoading: isLoadingUser,
                              onEditTap: () => _openEditProfile(user),
                            ),
                            SizedBox(height: 28.h),

                            // ── Settings list (single sheet) ───────────────
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: _SettingsSheet(
                                rows: [
                                  _SettingsRowData(
                                    icon: Icons.history_rounded,
                                    title: 'Scan History',
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const HistoryPage(),
                                      ),
                                    ),
                                  ),
                                  // _SettingsRowData(
                                  //   icon: Icons.notifications_none_rounded,
                                  //   title: 'Notifications',
                                  //   onTap: () {},
                                  // ),
                                  _SettingsRowData(
                                    icon: Icons.privacy_tip_outlined,
                                    title: 'Privacy Policy',
                                    onTap: () {},
                                  ),
                                  // _SettingsRowData(
                                  //   icon: Icons.description_outlined,
                                  //   title: 'Terms & Conditions',
                                  //   onTap: () {},
                                  // ),
                                  // _SettingsRowData(
                                  //   icon: Icons.help_outline_rounded,
                                  //   title: 'Help & Support',
                                  //   onTap: () {},
                                  // ),
                                ],
                              ),
                            ),
                            SizedBox(height: 28.h),

                            // ── Logout / Delete account ─────────────────────
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Column(
                                children: [
                                  _LogoutButton(),
                                  SizedBox(height: 12.h),
                                  _DeleteAccountButton(),
                                  SizedBox(height: 12.h),
                                  Center(
                                    child: Text(
                                      'Scanrix v1.0.0',
                                      style: TextStyle(
                                        color: AppColors.secondaryText
                                            .withValues(alpha: 0.5),
                                        fontSize: 11.sp,
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
                  ),

                  // ── Bottom nav ─────────────────────────────────────
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: BottomNavBar(
                        currentIndex: 4,
                        onTap: (index) =>
                            handleBottomNavTap(context, index, currentIndex: 4),
                        onScanPressed: () => handleScanPressed(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onEditTap;
  const _TopBar({required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
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
            InkWell(
              onTap: onEditTap,
              borderRadius: BorderRadius.circular(18.r),
              child: Container(
                width: 34.r,
                height: 34.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.glassFill.withValues(alpha: 0.5),
                  border: Border.all(
                    color: AppColors.neonEmerald.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: AppColors.neonEmerald,
                  size: 16.r,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Text(
          'My Profile',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ─── Centered avatar/name hero ────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final UserEntity? user;
  final bool isLoading;
  final VoidCallback onEditTap;

  const _ProfileHero({
    required this.user,
    required this.isLoading,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? (isLoading ? 'Loading…' : 'Scanrix User');
    final email = user?.email;

    return Column(
      children: [
        _Avatar(photoUrl: user?.photoUrl, onEditTap: onEditTap),
        SizedBox(height: 14.h),
        Text(
          name,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 19.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (email != null) ...[
          SizedBox(height: 4.h),
          Text(
            email,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.secondaryText, fontSize: 13.sp),
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final VoidCallback onEditTap;

  const _Avatar({required this.photoUrl, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    final size = 92.r;
    return GestureDetector(
      onTap: onEditTap,
      child: SizedBox(
        width: size + 10.r,
        height: size + 10.r,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
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
                    blurRadius: 18,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl != null
                  ? Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderIcon(),
                    )
                  : _placeholderIcon(),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 30.r,
                height: 30.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonEmerald,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: 14.r,
                  color: AppColors.background,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Icon(Icons.person_rounded, color: AppColors.white, size: 38.r);
  }
}

// ─── Settings sheet (single continuous list) ──────────────────────────────────

class _SettingsRowData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsRowData({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class _SettingsSheet extends StatelessWidget {
  final List<_SettingsRowData> rows;
  const _SettingsSheet({required this.rows});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: AppColors.glassFill.withValues(alpha: 0.45),
            border: Border.all(
              color: AppColors.neonEmerald.withValues(alpha: 0.14),
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                _SettingsRow(data: rows[i]),
                if (i != rows.length - 1)
                  Divider(
                    height: 1,
                    indent: 64.w,
                    color: AppColors.neonEmerald.withValues(alpha: 0.1),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final _SettingsRowData data;
  const _SettingsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              width: 34.r,
              height: 34.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonEmerald.withValues(alpha: 0.12),
              ),
              child: Icon(data.icon, color: AppColors.neonEmerald, size: 17.r),
            ),
            SizedBox(width: 14.w),
            Text(
              data.title,
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

// ─── Delete account button ─────────────────────────────────────────────────

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton();

  void _confirmDelete(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.glassFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
          ),
        ),
        title: Text(
          'Delete Account',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This permanently deletes your account, scan history, and all '
          'associated data. This cannot be undone.',
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
              authBloc.add(const AuthDeleteAccountRequested());
            },
            child: Text(
              'Delete Account',
              style: TextStyle(
                color: const Color(0xFFFF4444),
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
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
        onTap: () => _confirmDelete(context),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: const Color(0xFFFF4444).withValues(alpha: 0.12),
            border: Border.all(
              color: const Color(0xFFFF4444).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: const Color(0xFFFF4444),
                size: 20.r,
              ),
              SizedBox(width: 10.w),
              Text(
                'Delete Account',
                style: TextStyle(
                  color: const Color(0xFFFF4444),
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
