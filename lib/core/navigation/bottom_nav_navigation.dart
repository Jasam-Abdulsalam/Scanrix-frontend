import 'package:flutter/material.dart';

import '../../features/history/presentation/pages/history_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/scan/presentation/pages/scan_page.dart';
import '../../features/search/presentation/pages/search_page.dart';

/// Maps a `BottomNavBar` index to its destination page. Simple push
/// navigation per tab (see CLAUDE.md's home-page notes) rather than a
/// persistent `IndexedStack` tab shell — each tab tap pushes a fresh page,
/// so switching tabs repeatedly grows the navigation stack. That's the
/// documented tradeoff of this simpler approach, not a bug.
Widget bottomNavPageFor(int index) {
  switch (index) {
    case 0:
      return const HomePage();
    case 1:
      return const HistoryPage();
    case 3:
      return const SearchPage();
    case 4:
      return const ProfilePage();
    default:
      throw ArgumentError('No page for bottom nav index $index');
  }
}

/// Shared `BottomNavBar.onTap` handler: pushes the destination page for
/// [index] unless it's the page already showing ([currentIndex]).
void handleBottomNavTap(
  BuildContext context,
  int index, {
  required int currentIndex,
}) {
  if (index == currentIndex) return;
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => bottomNavPageFor(index)));
}

/// Shared `BottomNavBar.onScanPressed` handler — the floating center
/// button always pushes `ScanPage`, regardless of which tab it's on.
void handleScanPressed(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const ScanPage()));
}
