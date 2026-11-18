import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scanrix_frontend/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:scanrix_frontend/features/favorites/presentation/bloc/favorites_event.dart';
import 'package:scanrix_frontend/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:scanrix_frontend/features/favorites/presentation/pages/favorites_page.dart';
import 'package:scanrix_frontend/features/history/presentation/bloc/scan_count_cubit.dart';
import 'package:scanrix_frontend/features/history/presentation/pages/history_page.dart';
import 'package:scanrix_frontend/features/profile/presentation/widgets/overview_card.dart';
import 'package:scanrix_frontend/features/profile/presentation/widgets/profile_dialogs.dart';
import 'package:scanrix_frontend/features/profile/presentation/widgets/profile_header.dart';
import 'package:scanrix_frontend/features/profile/presentation/widgets/settings.dart';

import '../../../../core/navigation/signed_out.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/toast.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/create_account_page.dart';
import '../../../routine/reminders/reminders_cubit.dart';

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
    context.read<FavoritesBloc>().add(
      const FavoritesBarcodesRequested(),
    ); // for the Favorites count
    context.read<ScanCountCubit>().refresh(); // for the Scans count
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
      // Forgets this account's app-wide data, then goes to the login screen.
      goToLoginSignedOut(context);
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
          child: BlocBuilder<ScanCountCubit, int?>(
            builder: (context, count) => ProfileOverviewCard(
              count: count?.toString() ?? '–',
              title: 'Scans',
              subtitle: 'Products analyzed',
              iconWidget: Icon(
                Icons.crop_free_rounded,
                color: context.colors.neonEmerald,
                size: 20.r,
              ),
              // History can be edited there: re-read the number when coming back.
              onTap: () => Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => const HistoryPage(standalone: true),
                    ),
                  )
                  .then((_) {
                    if (mounted) context.read<ScanCountCubit>().refresh();
                  }),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: BlocSelector<FavoritesBloc, FavoritesState, String>(
            selector: (s) => s.barcodesLoaded ? '${s.barcodes.length}' : '–',
            builder: (context, count) => ProfileOverviewCard(
              count: count,
              title: 'Favorites',
              subtitle: 'Saved products',
              iconWidget: Icon(
                Icons.favorite_border_rounded,
                color: context.colors.neonEmerald,
                size: 18.r,
              ),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const FavoritesPage())),
            ),
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
        // Same setting as the reminder card on the My Routine page (stored on this phone).
        BlocConsumer<RemindersCubit, RemindersState>(
          listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
          listener: (context, s) {
            if (ModalRoute.of(context)?.isCurrent ?? true) {
              showToast(
                context,
                s.notice!,
                icon: Icons.notifications_off_outlined,
              );
            }
          },
          builder: (context, reminders) => SettingsTile(
            icon: Icons.alarm_rounded,
            title: 'Reminders',
            subtitle: 'Get notified for your routine',
            trailing: SettingsSwitch(
              value: reminders.enabled,
              onChanged: (val) =>
                  context.read<RemindersCubit>().setEnabled(val),
            ),
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
