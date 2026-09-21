import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scanrix_frontend/features/history/presentation/pages/history_page.dart';
import 'package:scanrix_frontend/features/profile/presentation/widgets/overview_card.dart';
import 'package:scanrix_frontend/features/profile/presentation/widgets/profile_dialogs.dart';
import 'package:scanrix_frontend/features/profile/presentation/widgets/profile_header.dart';
import 'package:scanrix_frontend/features/profile/presentation/widgets/settings.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: _handleAuthState,
      builder: (context, state) {
        final user = state is AuthCurrentUserLoaded
            ? state.user
            : (state is AuthProfileCompleteSuccess ? state.user : null);
        final isLoadingUser = user == null && state is AuthLoading;

        // MainShell's IndexedStack gives this tab tight constraints (full
        // tab-area size) regardless of content length, so a bare
        // SingleChildScrollView here is safe — no Positioned.fill needed
        // like the old per-page Scaffold+Stack layout required. No outer
        // SafeArea either: ProfileTopHeader's gradient banner is meant to
        // bleed to the very top behind the status bar, with its own inner
        // SafeArea around just the header's interactive content.
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(bottom: 120.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileTopHeader(
                user: user,
                isLoading: isLoadingUser,
                onEditTap: () => _openEditProfile(user),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Overview'),
                    SizedBox(height: 12.h),
                    _buildOverviewRow(),
                    SizedBox(height: 22.h),
                    _sectionTitle('Settings'),
                    SizedBox(height: 12.h),
                    _buildSettingsSection(user),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthUnauthenticated) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
    //   } else if (state is AuthFailure) {
    //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
    //   }
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildOverviewRow() {
    return Row(
      children: [
        Expanded(
          child: ProfileOverviewCard(
            count: '0',
            title: 'Scans',
            subtitle: 'Products analyzed',
            iconWidget: Icon(
              Icons.crop_free_rounded,
              color: context.colors.neonEmerald,
              size: 20.r,
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HistoryPage())),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ProfileOverviewCard(
            count: '0',
            title: 'Favorites',
            subtitle: 'Saved products',
            iconWidget: Icon(
              Icons.favorite_border_rounded,
              color: context.colors.neonEmerald,
              size: 18.r,
            ),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(UserEntity? user) {
    return SettingsContainer(
      children: [
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            final isDark = themeMode == ThemeMode.dark;
            return SettingsTile(
              icon: Icons.nightlight_round,
              title: 'Dark mode',
              subtitle: isDark
                  ? 'Dark Green with emerald green'
                  : 'Blackish with emerald green (Reference)',
              trailing: SettingsSwitch(
                value: isDark,
                onChanged: (val) => context.read<ThemeCubit>().setTheme(val),
              ),
            );
          },
        ),
        const SettingsDivider(),
        SettingsTile(
          icon: Icons.alarm_rounded,
          title: 'Reminders',
          subtitle: 'Get notified for your routine',
          trailing: SettingsSwitch(
            value: _reminders,
            onChanged: (val) => setState(() => _reminders = val),
          ),
        ),
        const SettingsDivider(),
        SettingsTile(
          icon: Icons.tune_rounded,
          title: 'Preference',
          subtitle: 'Customize your experience',
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: const Color(0xFF6B8074),
            size: 22.r,
          ),
          onTap: () {},
        ),
        const SettingsDivider(),
        SettingsTile(
          icon: Icons.badge_outlined,
          title: 'Account',
          subtitle: 'Manage your account',
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: const Color(0xFF6B8074),
            size: 22.r,
          ),
          onTap: () => showAccountSheet(
            context: context,
            user: user,
            onEditProfile: () => _openEditProfile(user),
            onLogout: () => confirmLogoutDialog(
              context,
              () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
            ),
            onDelete: () => confirmDeleteDialog(
              context,
              () => context.read<AuthBloc>().add(
                const AuthDeleteAccountRequested(),
              ),
            ),
          ),
        ),
      ],
    );
  
}
}