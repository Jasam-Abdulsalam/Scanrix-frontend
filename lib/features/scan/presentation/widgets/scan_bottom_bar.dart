import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme_colors.dart';

/// Bottom glassmorphic action bar with:
///   [Import Picture] · [Camera capture button] · [Import File]
class ScanBottomBar extends StatelessWidget {
  final VoidCallback? onCameraTap;
  final ValueChanged<String>? onImageImported; // barcode value from gallery

  const ScanBottomBar({
    super.key,
    this.onCameraTap,
    this.onImageImported,
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

                  // ── Import File
                  Expanded(
                    child: _BottomBarAction(
                      icon: Icons.attach_file_rounded,
                      label: 'Import File',
                      iconColor: const Color(0xFFAA72FF),
                      onTap: () => _pickFromGallery(context),
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
        padding: EdgeInsets.symmetric(vertical: 8.h),
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
