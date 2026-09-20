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
  bool _darkMode = true;
  bool _reminders = false;

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

  void _showAccountSheet(BuildContext context, UserEntity? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 32.h),
        decoration: BoxDecoration(
          color: const Color(0xFF0C1D14),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          border: Border.all(
            color: AppColors.neonEmerald.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Account Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            if (user?.email != null) ...[
              Text(
                'Email',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                user!.email,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16.h),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonEmerald.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: AppColors.neonEmerald,
                  size: 18.r,
                ),
              ),
              title: Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.secondaryText,
                size: 20.r,
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _openEditProfile(user);
              },
            ),
            Divider(
              color: Colors.white.withValues(alpha: 0.08),
              height: 20.h,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF4444).withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: const Color(0xFFFF4444),
                  size: 18.r,
                ),
              ),
              title: Text(
                'Delete Account',
                style: TextStyle(
                  color: const Color(0xFFFF4444),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.secondaryText,
                size: 20.r,
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0C1D14),
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

  void _confirmDelete(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0C1D14),
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
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: 120.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Top Curved Header ───────────────────────
                          _TopCurvedHeader(
                            user: user,
                            isLoading: isLoadingUser,
                            onEditTap: () => _openEditProfile(user),
                          ),

                          // ── Overview Section ────────────────────────
                          Padding(
                            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Overview',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                SizedBox(height: 14.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _OverviewCard(
                                        count: '0',
                                        label: 'scans',
                                        iconWidget: _ScanIconWidget(),
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const HistoryPage(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 14.w),
                                    Expanded(
                                      child: _OverviewCard(
                                        count: '0',
                                        label: 'Favorites',
                                        iconWidget: Icon(
                                          Icons.favorite_border_rounded,
                                          color: Colors.white.withValues(
                                            alpha: 0.75,
                                          ),
                                          size: 20.r,
                                        ),
                                        onTap: () {},
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 18.h),

                                // ── Settings Card ───────────────────────
                                _SettingsContainer(
                                  children: [
                                    _SettingsTile(
                                      icon: Icons.nightlight_round,
                                      title: 'Dark mode',
                                      trailing: _CustomSwitch(
                                        value: _darkMode,
                                        onChanged: (val) {
                                          setState(() => _darkMode = val);
                                        },
                                      ),
                                    ),
                                    _SettingsDivider(),
                                    _SettingsTile(
                                      icon: Icons.alarm_rounded,
                                      title: 'Reminders',
                                      trailing: _CustomSwitch(
                                        value: _reminders,
                                        onChanged: (val) {
                                          setState(() => _reminders = val);
                                        },
                                      ),
                                    ),
                                    _SettingsDivider(),
                                    _SettingsTile(
                                      icon: Icons.tune_rounded,
                                      title: 'Preference',
                                      trailing: Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        size: 22.r,
                                      ),
                                      onTap: () {},
                                    ),
                                    _SettingsDivider(),
                                    _SettingsTile(
                                      icon: Icons.badge_outlined,
                                      title: 'Account',
                                      trailing: Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        size: 22.r,
                                      ),
                                      onTap: () =>
                                          _showAccountSheet(context, user),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24.h),

                                // ── Log out Button ──────────────────────
                                _LogOutPillButton(
                                  onTap: () => _confirmLogout(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Bottom nav ──────────────────────────────────────
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

// ─── Top Curved Header ────────────────────────────────────────────────────────

class _TopCurvedHeader extends StatelessWidget {
  final UserEntity? user;
  final bool isLoading;
  final VoidCallback onEditTap;

  const _TopCurvedHeader({
    required this.user,
    required this.isLoading,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = (user != null && user!.name.isNotEmpty)
        ? user!.name
        : (isLoading ? 'Loading…' : 'Jasam');

    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(38.r)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF10281C),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(38.r)),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background wave painter: full header cover, low opacity
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'assets/images/painter.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            // Header content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row with Edit button
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: onEditTap,
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          width: 36.r,
                          height: 36.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.35),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 17.r,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // Central glowing avatar
                    _AvatarWithGlowRing(
                      photoUrl: user?.photoUrl,
                      onTap: onEditTap,
                    ),
                    SizedBox(height: 14.h),

                    // User name
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Central Avatar with Glassy Halo ──────────────────────────────────────────

class _AvatarWithGlowRing extends StatelessWidget {
  final String? photoUrl;
  final VoidCallback onTap;

  const _AvatarWithGlowRing({required this.photoUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final outerSize = 104.r;
    final innerSize = 72.r;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: outerSize,
        height: outerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF132F21),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.30),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonEmerald.withValues(alpha: 0.12),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF3A4D43),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: photoUrl != null && photoUrl!.isNotEmpty
              ? Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _silhouetteIcon(innerSize),
                )
              : _silhouetteIcon(innerSize),
        ),
      ),
    );
  }

  Widget _silhouetteIcon(double size) {
    return Icon(
      Icons.person_rounded,
      color: Colors.white.withValues(alpha: 0.45),
      size: size * 0.62,
    );
  }
}

// ─── Overview Metric Card ─────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  final String count;
  final String label;
  final Widget iconWidget;
  final VoidCallback onTap;

  const _OverviewCard({
    required this.count,
    required this.label,
    required this.iconWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A2B).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count,
              style: TextStyle(
                color: Colors.white,
                fontSize: 30.sp,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                iconWidget,
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Custom Scan Bracket Barcode Icon ─────────────────────────────────────────

class _ScanIconWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.document_scanner_outlined,
      color: Colors.white.withValues(alpha: 0.75),
      size: 20.r,
    );
  }
}

// ─── Settings Container & Tiles ──────────────────────────────────────────────

class _SettingsContainer extends StatelessWidget {
  final List<Widget> children;

  const _SettingsContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F261B).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.7),
              size: 22.r,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.07),
    );
  }
}

// ─── Custom Toggle Switch ────────────────────────────────────────────────────

class _CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CustomSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44.w,
        height: 25.h,
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13.r),
          color: value ? const Color(0xFF38463D) : const Color(0xFF132319),
          border: Border.all(
            color: value
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.12),
            width: 1.2,
          ),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18.r,
          height: 18.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value ? const Color(0xFF86978C) : const Color(0xFF38473D),
          ),
        ),
      ),
    );
  }
}

// ─── Log Out Pill Button ─────────────────────────────────────────────────────

class _LogOutPillButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogOutPillButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFE53935),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          'Log out',
          style: TextStyle(
            color: const Color(0xFFE53935),
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
