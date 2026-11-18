import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme_colors.dart';

/// The toast currently on screen, if any: a new toast replaces it instead of
/// stacking on top (e.g. "Added to your routine" followed by a failure).
OverlayEntry? _current;

/// Fire-and-forget glass toast: fades in, sits briefly, fades out on its
/// own — unlike [ScaffoldMessenger]'s `SnackBar`, it doesn't queue, doesn't
/// need a swipe to dismiss, and doesn't block the widgets underneath it.
/// Only one is shown at a time; a newer one replaces the older immediately.
void showToast(
  BuildContext context,
  String message, {
  IconData icon = Icons.info_outline_rounded,
  Duration duration = const Duration(milliseconds: 1600),
}) {
  final overlay = Overlay.of(context);
  _removeCurrent();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _ToastOverlay(
      message: message,
      icon: icon,
      duration: duration,
      onDismissed: () {
        if (identical(_current, entry)) _removeCurrent();
      },
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

void _removeCurrent() {
  final entry = _current;
  _current = null;
  if (entry != null && entry.mounted) entry.remove();
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismissed;

  const _ToastOverlay({
    required this.message,
    required this.icon,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _run();
  }

  Future<void> _run() async {
    await _ctrl.forward();
    await Future.delayed(widget.duration);
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Positioned(
      left: 24.w,
      right: 24.w,
      bottom: 140.h,
      child: IgnorePointer(
        // An overlay entry has no Material ancestor, so without this its Text
        // falls back to Flutter's yellow-double-underline "missing Material" style.
        child: Material(
          type: MaterialType.transparency,
          child: FadeTransition(
            opacity: _opacity,
            child: Align(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(30.r),
                      border: Border.all(
                        color: colors.cardBorder.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, color: Colors.white70, size: 16.r),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
