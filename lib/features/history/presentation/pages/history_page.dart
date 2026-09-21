import 'package:flutter/material.dart';

/// History tab content — no Scaffold of its own; rendered either inside
/// `MainShell`'s `IndexedStack` (tab flow) or wrapped in a bare `Scaffold`
/// by a direct-push call site (e.g. `ProfilePage`'s "Scan History" row).
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('History page - TODO'));
  }
}
