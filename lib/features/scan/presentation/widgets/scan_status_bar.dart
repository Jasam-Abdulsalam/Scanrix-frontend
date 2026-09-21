import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import 'scan_mode.dart';

class ScanStatusBar extends StatelessWidget {
  final bool flashOn;
  final ScanMode mode;
  final ValueChanged<ScanMode> onModeChanged;
  final VoidCallback onBack;
  final VoidCallback onFlashToggle;

  const ScanStatusBar({
    super.key,
    required this.flashOn,
    required this.mode,
    required this.onModeChanged,
    required this.onBack,
    required this.onFlashToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CircleIconBtn(
              icon: Icons.chevron_left_rounded,
              onTap: onBack,
            ),
            Flexible(
              child: _ScanModeToggle(mode: mode, onChanged: onModeChanged),
            ),
            _CircleIconBtn(
              icon: flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              onTap: onFlashToggle,
              highlight: flashOn,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barcode | Ingredients segmented pill
// ─────────────────────────────────────────────────────────────────────────────
class _ScanModeToggle extends StatelessWidget {
  final ScanMode mode;
  final ValueChanged<ScanMode> onChanged;

  const _ScanModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(30.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: colors.cardBorder.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: ScanMode.values
                .map(
                  (m) => Flexible(
                    child: _ModeSegment(
                      mode: m,
                      active: m == mode,
                      onTap: () => onChanged(m),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final ScanMode mode;
  final bool active;
  final VoidCallback onTap;

  const _ModeSegment({
    required this.mode,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26.r),
          color: active ? colors.neonEmerald.withValues(alpha: 0.14) : null,
          border: active
              ? Border.all(color: colors.neonEmerald.withValues(alpha: 0.7))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mode.icon,
              size: 15.r,
              color: active ? colors.neonEmerald : Colors.white54,
            ),
            SizedBox(width: 5.w),
            Flexible(
              child: Text(
                mode.label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white54,
                  fontSize: 12.sp,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;

  const _CircleIconBtn({
    required this.icon,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: highlight
                  ? colors.neonEmerald.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
              border: Border.all(
                color: highlight
                    ? colors.neonEmerald.withValues(alpha: 0.6)
                    : colors.cardBorder.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: highlight ? colors.neonEmerald : Colors.white,
              size: 18.r,
            ),
          ),
        ),
      ),
    );
  }
}
