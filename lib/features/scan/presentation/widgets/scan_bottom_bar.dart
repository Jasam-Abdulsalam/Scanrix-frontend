import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme_colors.dart';
import 'scan_category.dart';

/// Bottom glassmorphic action bar with:
///   [Import Picture] · [Camera capture button] · [Category dropdown]
class ScanBottomBar extends StatelessWidget {
  final VoidCallback? onCameraTap;
  final ValueChanged<String>? onImageImported; // barcode value from gallery
  final ScanCategory category;
  final ValueChanged<ScanCategory> onCategoryChanged;

  const ScanBottomBar({
    super.key,
    this.onCameraTap,
    this.onImageImported,
    required this.category,
    required this.onCategoryChanged,
  });

  Future<void> _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    // In a real app, decode the barcode from the picked image here using
    // `mobile_scanner`'s analyzeImage. For now, show a snackbar placeholder.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: _ToastWidget(
            message: 'Processing image…',
            icon: Icons.image_search_rounded,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 12.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: 68.h,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.50),
                borderRadius: BorderRadius.circular(36.r),
                border: Border.all(
                  color: colors.cardBorder.withValues(alpha: 0.55),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ── Import Picture
                  Expanded(
                    child: _BottomBarAction(
                      icon: Icons.photo_library_rounded,
                      label: 'Import Picture',
                      iconColor: colors.neonEmerald,
                      onTap: () => _pickFromGallery(context),
                    ),
                  ),

                  // ── Camera centre button
                  _CameraCentreButton(onTap: onCameraTap),

                  // ── Category dropdown
                  Expanded(
                    child: Center(
                      child: _CategoryDropdownPill(
                        category: category,
                        onChanged: onCategoryChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Individual action item
class _BottomBarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;

  const _BottomBarAction({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: iconColor, size: 18.r),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 10.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Glowing centre camera button
class _CameraCentreButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _CameraCentreButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58.r,
        height: 58.r,
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B5EFF), Color(0xFF4F7EFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F7EFF).withValues(alpha: 0.55),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          Icons.camera_alt_rounded,
          color: Colors.white,
          size: 26.r,
        ),
      ),
    );
  }
}

// ── Category dropdown pill (replaces the old "Import File" slot)
class _CategoryDropdownPill extends StatelessWidget {
  final ScanCategory category;
  final ValueChanged<ScanCategory> onChanged;

  const _CategoryDropdownPill({
    required this.category,
    required this.onChanged,
  });

  Future<void> _openMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final position = RelativeRect.fromLTRB(
      topLeft.dx,
      topLeft.dy - 8.h - (ScanCategory.values.length * 40.h),
      overlay.size.width - topLeft.dx - box.size.width,
      overlay.size.height - topLeft.dy,
    );

    final selected = await showMenu<ScanCategory>(
      context: context,
      position: position,
      color: Colors.black.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      items: ScanCategory.values
          .map(
            (c) => PopupMenuItem<ScanCategory>(
              value: c,
              child: Row(
                children: [
                  Text(c.emoji, style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 10.w),
                  Text(
                    c.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight:
                          c == category ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );

    if (selected != null && selected != category) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openMenu(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color: category.glowColor.withValues(alpha: 0.7),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: TextStyle(fontSize: 14.sp)),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                category.label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white70,
              size: 16.r,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small toast widget for snackbars
class _ToastWidget extends StatelessWidget {
  final String message;
  final IconData icon;

  const _ToastWidget({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white70, size: 16.r),
              SizedBox(width: 8.w),
              Text(
                message,
                style: TextStyle(color: Colors.white, fontSize: 13.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
