import 'package:flutter/material.dart';

/// Search tab content — rendered inside `MainShell`'s `IndexedStack`, which
/// owns the Scaffold shared by all tabs.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Search page - TODO'));
  }
}
