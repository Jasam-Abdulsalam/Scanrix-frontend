import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import 'scan_category.dart';

class CategorySelectionOverlay extends StatefulWidget {
  final bool visible;
  final ValueChanged<ScanCategory> onCategorySelected;

  const CategorySelectionOverlay({
    super.key,
    required this.visible,
    required this.onCategorySelected,
  });

  @override
  State<CategorySelectionOverlay> createState() =>
      _CategorySelectionOverlayState();
}

class _CategorySelectionOverlayState extends State<CategorySelectionOverlay> {
  ScanCategory? _pressed;

  void _handleTap(ScanCategory category) {
    HapticFeedback.lightImpact();
    setState(() => _pressed = category);
    widget.onCategorySelected(category);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),

            Positioned(
              top: 120.h,
              left: 0,
              right: 0,
              child: Center(child: _TitlePill()),
            ),

            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategoryColumn(
                    category: ScanCategory.cosmetics,
                    delayMs: 100,
                    isPressed: _pressed == ScanCategory.cosmetics,
                    onTap: () => _handleTap(ScanCategory.cosmetics),
                  ),
                  SizedBox(width: 16.w),
                  _CategoryColumn(
                    category: ScanCategory.food,
                    delayMs: 250,
                    isPressed: _pressed == ScanCategory.food,
                    onTap: () => _handleTap(ScanCategory.food),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitlePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * -12), child: child),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(40.r),
              border: Border.all(
                color: colors.cardBorder.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Text(
              'Select Product Category to Scan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card + its glass label pill underneath
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryColumn extends StatefulWidget {
  final ScanCategory category;
  final int delayMs;
  final bool isPressed;
  final VoidCallback onTap;

  const _CategoryColumn({
    required this.category,
    required this.delayMs,
    required this.isPressed,
    required this.onTap,
  });

  @override
  State<_CategoryColumn> createState() => _CategoryColumnState();
}

class _CategoryColumnState extends State<_CategoryColumn> {
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _entered ? 1 : 0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(scale: 0.7 + (0.3 * t.clamp(0, 1)), child: child),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CategoryCard(
            category: widget.category,
            isPressed: widget.isPressed,
            onTap: widget.onTap,
          ),
          SizedBox(height: 10.h),
          _CategoryLabelPill(category: widget.category),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card — image cover only, arrow bottom-right, no text inside
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final ScanCategory category;
  final bool isPressed;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isPressed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = category.gradient;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 165.w,
          height: 200.h,
          padding: EdgeInsets.all(1.6.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: category.glowColor
                    .withValues(alpha: isPressed ? 0.55 : 0.22),
                blurRadius: isPressed ? 24 : 16,
                spreadRadius: isPressed ? 1 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: const Color(0xFF0B0B0D)),

                Positioned.fill(
                  child: Image.asset(
                    category.assetPath,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),

                // Faint bottom scrim so the arrow button stays legible
                // against a busy image, even with no text now.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.7, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                ),

                // Arrow button — same position/style as before, bottom-right
                Positioned(
                  right: 10.w,
                  bottom: 12.h,
                  child: Container(
                    width: 30.r,
                    height: 30.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color: category.glowColor.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 15.r,
                    ),
                  ),
                ),

                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass label pill shown below the card
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryLabelPill extends StatelessWidget {
  final ScanCategory category;
  const _CategoryLabelPill({required this.category});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: category.glowColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Text(
            category.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}