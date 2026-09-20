import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';

/// Top status pill shown above the viewfinder.
/// Shows back button, animated "Scanning…XX%" label, and flash toggle.
class ScanStatusBar extends StatefulWidget {
  final bool isScanning;
  final bool flashOn;
  final VoidCallback onBack;
  final VoidCallback onFlashToggle;

  const ScanStatusBar({
    super.key,
    required this.isScanning,
    required this.flashOn,
    required this.onBack,
    required this.onFlashToggle,
  });

  @override
  State<ScanStatusBar> createState() => _ScanStatusBarState();
}

class _ScanStatusBarState extends State<ScanStatusBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _percentCtrl;
  late Animation<double> _percentAnim;

  @override
  void initState() {
    super.initState();
    _percentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _percentAnim = Tween<double>(begin: 0, end: 75).animate(
      CurvedAnimation(parent: _percentCtrl, curve: Curves.easeOut),
    );
    if (widget.isScanning) _percentCtrl.forward();
  }

  @override
  void didUpdateWidget(ScanStatusBar old) {
    super.didUpdateWidget(old);
    if (widget.isScanning && !old.isScanning) {
      _percentCtrl.forward(from: 0);
    } else if (!widget.isScanning) {
      _percentCtrl.stop();
    }
  }

  @override
  void dispose() {
    _percentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            _CircleIconBtn(
              icon: Icons.chevron_left_rounded,
              onTap: widget.onBack,
            ),

            // Status pill
            AnimatedBuilder(
              animation: _percentAnim,
              builder: (context, _) {
                final pct = widget.isScanning
                    ? _percentAnim.value.toInt()
                    : 100;
                final label = widget.isScanning
                    ? 'Scanning … $pct%'
                    : 'Detected!';
                return ClipRRect(
                  borderRadius: BorderRadius.circular(40.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(40.r),
                        border: Border.all(
                          color: colors.cardBorder.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isScanning) ...[
                            SizedBox(
                              width: 10.r,
                              height: 10.r,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colors.neonEmerald,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ] else ...[
                            Icon(
                              Icons.check_circle_rounded,
                              color: colors.neonEmerald,
                              size: 12.r,
                            ),
                            SizedBox(width: 6.w),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Flash toggle
            _CircleIconBtn(
              icon: widget.flashOn
                  ? Icons.flash_on_rounded
                  : Icons.flash_off_rounded,
              onTap: widget.onFlashToggle,
              highlight: widget.flashOn,
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
