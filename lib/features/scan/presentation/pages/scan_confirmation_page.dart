import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/pages/product_detail_page.dart';
import '../../domain/entities/scan_result_entity.dart';
import '../widgets/scan_category.dart';

/// Shown after `POST /scan/` resolves successfully (and no category
/// mismatch was flagged) — lets the user confirm the identified product
/// before moving on to the (possibly still-analyzing) result screen.
/// "Not this product" and "Rescan" are functionally identical: both just
/// pop back to the live camera on `ScanPage`, which resumes scanning.
class ScanConfirmationPage extends StatelessWidget {
  final ScanResultEntity result;

  const ScanConfirmationPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final product = result.product;
    final category = ScanCategoryX.fromBackendLabel(product.category);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleIconBtn(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _RescanPill(onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                children: [
                  _ProductImage(imageUrl: product.imageUrl, category: category),
                  SizedBox(height: 16.h),
                  Center(
                    child: _StatusPill(
                      icon: Icons.check_circle_rounded,
                      label: 'Product Identified',
                      color: colors.neonEmerald,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This is the closest match based on the scanned barcode.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.secondaryText, fontSize: 12.5.sp),
                  ),
                  SizedBox(height: 20.h),
                  _ProductInfoCard(product: product, category: category),
                  SizedBox(height: 16.h),
                  _ConfirmCard(
                    onNotThisProduct: () => Navigator.of(context).pop(),
                    onContinue: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailPage(
                            barcode: product.barcode,
                            initialProduct: product,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16.h),
                  _BarcodeFooter(barcode: product.barcode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final ScanCategory? category;
  const _ProductImage({required this.imageUrl, required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fallbackAsset = (category ?? ScanCategory.food).assetPath;

    // Fade every frame in instead of popping straight from blank to loaded —
    // covers both the network-image and the asset-fallback path.
    Widget fadeIn(Widget child, int? frame, bool wasSynchronouslyLoaded) {
      if (wasSynchronouslyLoaded) return child;
      return AnimatedOpacity(
        opacity: frame == null ? 0 : 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: child,
      );
    }

    return Center(
      child: Container(
        width: 220.w,
        height: 260.h,
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              colors.neonEmerald.withValues(alpha: 0.14),
              Colors.transparent,
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            // Fills the gap while a network image is still loading, instead
            // of an empty/transparent flash.
            color: colors.surface,
            child: imageUrl == null
                ? Image.asset(
                    fallbackAsset,
                    fit: BoxFit.cover,
                    frameBuilder: (context, child, frame, wasSync) =>
                        fadeIn(child, frame, wasSync),
                  )
                : Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    frameBuilder: (context, child, frame, wasSync) =>
                        fadeIn(child, frame, wasSync),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 28.r,
                          height: 28.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(colors.neonEmerald),
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) =>
                        Image.asset(fallbackAsset, fit: BoxFit.cover),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ProductInfoCard extends StatelessWidget {
  final ProductEntity product;
  final ScanCategory? category;
  const _ProductInfoCard({required this.product, required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolvedCategory = category ?? ScanCategory.food;
    final subtitleParts = [
      product.brand,
      if (product.quantity != null && product.quantity!.isNotEmpty)
        product.quantity!,
    ];
    final tags = product.tags;

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: resolvedCategory.gradient),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(resolvedCategory.emoji, style: TextStyle(fontSize: 12.sp)),
                SizedBox(width: 4.w),
                Text(
                  resolvedCategory.label,
                  style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            product.name,
            style: TextStyle(color: Colors.white, fontSize: 19.sp, fontWeight: FontWeight.w700, height: 1.25),
          ),
          SizedBox(height: 6.h),
          Text(
            subtitleParts.join('  •  '),
            style: TextStyle(color: colors.secondaryText, fontSize: 13.sp),
          ),
          if (tags.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: tags
                  .map((t) => _TagChip(label: t))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: colors.iconContainerBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Text(
        label,
        style: TextStyle(color: colors.secondaryText, fontSize: 11.5.sp, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  final VoidCallback onNotThisProduct;
  final VoidCallback onContinue;
  const _ConfirmCard({required this.onNotThisProduct, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: colors.neonEmerald, size: 16.r),
              SizedBox(width: 8.w),
              Text(
                'Is this the correct product?',
                style: TextStyle(color: Colors.white, fontSize: 14.5.sp, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Please confirm before we analyze the ingredients.',
            style: TextStyle(color: colors.secondaryText, fontSize: 12.5.sp, height: 1.4),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onNotThisProduct,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.cardBorder),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                  ),
                  child: Text(
                    'Not this product',
                    style: TextStyle(color: colors.secondaryText, fontSize: 13.sp),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: PrimaryButton(
                  onTap: onContinue,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Continue'),
                      SizedBox(width: 6.w),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarcodeFooter extends StatelessWidget {
  final String barcode;
  const _BarcodeFooter({required this.barcode});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        children: [
          Icon(Icons.qr_code_scanner_rounded, color: colors.secondaryText, size: 20.r),
          SizedBox(height: 6.h),
          Text(
            'Scanned Barcode',
            style: TextStyle(color: colors.secondaryText, fontSize: 11.sp),
          ),
          Text(
            barcode,
            style: TextStyle(color: Colors.white70, fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatusPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16.r),
          SizedBox(width: 6.w),
          Text(label, style: TextStyle(color: color, fontSize: 12.5.sp, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RescanPill extends StatelessWidget {
  final VoidCallback onTap;
  const _RescanPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: colors.iconContainerBg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, color: Colors.white, size: 16.r),
            SizedBox(width: 6.w),
            const Text('Rescan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: colors.iconContainerBg,
          shape: BoxShape.circle,
          border: Border.all(color: colors.cardBorder),
        ),
        child: Icon(icon, color: Colors.white, size: 20.r),
      ),
    );
  }
}
