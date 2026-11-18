import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../features/favorites/presentation/bloc/favorites_event.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';
import '../../features/history/presentation/bloc/history_event.dart';
import '../../features/history/presentation/bloc/scan_count_cubit.dart';
import '../../features/history/presentation/history_paging.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/routine/presentation/bloc/routine_bloc.dart';
import '../../features/routine/presentation/bloc/routine_event.dart';
import '../../features/routine/reminders/reminders_cubit.dart';
import '../../features/routine/domain/entities/routine_entity.dart';
import '../../features/routine/presentation/pages/routine_page.dart';
import '../widgets/aurora_background.dart';
import '../widgets/bottom_nav_bar.dart';
import 'bottom_nav_navigation.dart';
import 'signed_out.dart';
import 'tab_scope.dart';

/// Top-level tab shell: the single owner of the Scaffold, aurora
/// background, and [BottomNavBar] shared by the four tabs. Keeps all four
/// tab pages alive in an [IndexedStack] so switching tabs just toggles
/// which one is painted, instead of the previous approach — each tab
/// having its own embedded `BottomNavBar` and `Navigator.push`ing a fresh
/// page per tap, which rebuilt the destination from scratch and grew the
/// nav stack every time.
class MainShell extends StatefulWidget {
  /// A `BottomNavBar` index (0/1/3/4 — 2 is the floating scan button's
  /// slot) to land on. Defaults to the Home tab.
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _navIndex;

  // Mirrors _navIndex so a tab's content can react to *becoming active
  // again* (e.g. HomePage's showcase card advancing its image each visit)
  // without needing IndexedStack to rebuild it from scratch — that
  // rebuild-from-scratch is exactly what IndexedStack exists to avoid.
  late final ValueNotifier<int> _navIndexNotifier;

  // Slot the Routine tab shows. Owned here so Home's "Today" card can open the tab on it.
  final _routineSlot = ValueNotifier(RoutineSlot.forTime(DateTime.now()));

  // Built once and kept alive for the shell's lifetime — IndexedStack only
  // preserves each child's state across index switches while the same
  // widget instances stay in the tree. Not `const` since HomePage needs
  // this instance's _navIndexNotifier; each tab is still only ever
  // instantiated once.
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialIndex;
    // Signed in (and DI is ready): start the reminders first, so they are listening when the routine
    // loads, then load the routine (feeds "In routine" and the reminder text).
    context.read<RemindersCubit>();
    context.read<RoutineBloc>().add(const RoutineRequested(silent: true));
    _navIndexNotifier = ValueNotifier(_navIndex);
    _tabs = [
      HomePage(activeTabIndex: _navIndexNotifier, onOpenRoutine: _openRoutine),
      const HistoryPage(),
      RoutinePage(slot: _routineSlot),
      const ProfilePage(),
    ];
  }

  @override
  void dispose() {
    _navIndexNotifier.dispose();
    _routineSlot.dispose();
    super.dispose();
  }

  /// Home's "Today" card: the Routine tab on [slot].
  void _openRoutine(RoutineSlot slot) {
    _routineSlot.value = slot;
    _selectTab(3);
  }

  // BottomNavBar indices (0/1/3/4) -> position in `_tabs`.
  int get _tabIndex => switch (_navIndex) {
    0 => 0,
    1 => 1,
    3 => 2,
    4 => 3,
    _ => 0,
  };

  void _selectTab(int index) {
    setState(() => _navIndex = index);
    _navIndexNotifier.value = index;
    // The tabs stay alive in the IndexedStack, so their data can be stale
    // (e.g. after a scan): refresh the selected one.
    if (index == 4) {
      context.read<ScanCountCubit>().refresh();
      context.read<FavoritesBloc>().add(const FavoritesBarcodesRequested());
    }
    if (index == 1) {
      context.read<HistoryBloc>().add(
        HistoryRequested(limit: productListPageSize(context), silent: true),
      );
    }
    if (index == 3) {
      context.read<RoutineBloc>().add(const RoutineRequested(silent: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Any signed-in screen sits on top of this shell, so this one listener covers them all: a
    // request rejected with 401 (expired or invalid token) signs out and goes to the login screen.
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, state) => state is AuthSessionExpired,
      listener: (context, _) => goToLoginSignedOut(
        context,
        notice: 'Your session has expired. Please sign in again.',
      ),
      child: _buildShell(context),
    );
  }

  Widget _buildShell(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AuroraBackground(
          child: Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      TabScope(active: i == _tabIndex, child: _tabs[i]),
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
                    currentIndex: _navIndex,
                    onTap: _selectTab,
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
