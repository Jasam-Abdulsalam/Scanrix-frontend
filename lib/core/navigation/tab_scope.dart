import 'package:flutter/widgets.dart';

/// Marks whether a `MainShell` tab is the one on screen. The tabs all stay alive in an `IndexedStack`,
/// so a listener on a hidden tab still fires; [canShowToastHere] lets it skip its toast.
class TabScope extends InheritedWidget {
  final bool active;

  const TabScope({super.key, required this.active, required super.child});

  /// True outside a tab (a pushed page) or on the visible tab.
  static bool isActive(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TabScope>()?.active ?? true;

  @override
  bool updateShouldNotify(TabScope oldWidget) => oldWidget.active != active;
}

/// True when this widget is on screen: its route is on top and, inside `MainShell`, its tab is selected.
bool canShowToastHere(BuildContext context) =>
    (ModalRoute.of(context)?.isCurrent ?? true) && TabScope.isActive(context);
