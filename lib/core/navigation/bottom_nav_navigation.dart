import 'package:flutter/material.dart';

import '../../features/scan/presentation/pages/scan_page.dart';

/// Shared `BottomNavBar.onScanPressed` handler — the floating center
/// button always pushes `ScanPage`, regardless of which tab it's on.
/// Tab switching itself is handled by `MainShell`, which owns the shared
/// `BottomNavBar` and keeps all four tabs alive in an `IndexedStack`
/// rather than pushing a fresh page per tap.
void handleScanPressed(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const ScanPage()));
}
