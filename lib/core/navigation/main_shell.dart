import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/history/presentation/pages/history_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../widgets/aurora_background.dart';
import '../widgets/bottom_nav_bar.dart';
import 'bottom_nav_navigation.dart';

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
    _navIndexNotifier = ValueNotifier(_navIndex);
    _tabs = [
      HomePage(activeTabIndex: _navIndexNotifier),
      const HistoryPage(),
      const SearchPage(),
      const ProfilePage(),
    ];
  }

  @override
  void dispose() {
    _navIndexNotifier.dispose();
    super.dispose();
  }

  // BottomNavBar indices (0/1/3/4) -> position in `_tabs`.
  int get _tabIndex => switch (_navIndex) {
    0 => 0,
    1 => 1,
    3 => 2,
    4 => 3,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AuroraBackground(
          child: Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(index: _tabIndex, children: _tabs),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: BottomNavBar(
                    currentIndex: _navIndex,
                    onTap: (index) {
                      setState(() => _navIndex = index);
                      _navIndexNotifier.value = index;
                    },
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
