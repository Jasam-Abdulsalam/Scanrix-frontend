import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/primary_button.dart';

/// Shown when `POST /scan/` returns 404 — the barcode isn't in any
/// database (own DB, Open Food Facts, or Open Beauty Facts). Pops `true`
/// when the user chooses to switch to Ingredients mode instead, so the
/// caller (`ScanPage`) can react.
class ProductNotFoundPage extends StatelessWidget {
  const ProductNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96.r,
                height: 96.r,
                decoration: BoxDecoration(
                  color: colors.neonEmerald.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  color: colors.secondaryText,
                  size: 46.r,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Product Not Found',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'We couldn\'t find this barcode in any database. You can still '
                'get a safety analysis by scanning the ingredients list on the '
                'label instead.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 14.sp,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),
              PrimaryButton(
                onTap: () => Navigator.of(context).pop(true),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Scan Ingredients Instead'),
                    SizedBox(width: 8.w),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Go Back',
                  style: TextStyle(color: colors.secondaryText, fontSize: 13.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
