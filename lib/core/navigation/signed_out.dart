import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../features/favorites/presentation/bloc/favorites_event.dart';
import '../../features/history/presentation/bloc/scan_count_cubit.dart';
import '../../features/routine/presentation/bloc/routine_bloc.dart';
import '../../features/routine/presentation/bloc/routine_event.dart';
import '../../features/routine/reminders/reminders_cubit.dart';
import '../widgets/toast.dart';

/// The account is signed out (logout, deleted account or expired session):
/// forget its app-wide data so the next account never sees it, then replace
/// the whole stack with [LoginPage]. [notice], if given, is shown as a toast
/// on the login screen.
void goToLoginSignedOut(BuildContext context, {String? notice}) {
  context.read<FavoritesBloc>().add(const FavoritesReset());
  context.read<RoutineBloc>().add(const RoutineReset());
  context
      .read<RemindersCubit>()
      .cancelAll(); // no reminders for an account that's signed out
  context.read<ScanCountCubit>().reset();

  final route = MaterialPageRoute<void>(builder: (_) => const LoginPage());
  Navigator.of(context).pushAndRemoveUntil(route, (_) => false);
  if (notice != null) {
    // After the login page's first frame, from its own context: a toast added before the push
    // would sit under the new route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loginContext = route.subtreeContext;
      if (loginContext != null && loginContext.mounted) {
        showToast(
          loginContext,
          notice,
          icon: Icons.lock_clock_outlined,
          duration: const Duration(milliseconds: 2400),
        );
      }
    });
  }
}
