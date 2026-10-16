import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../products/presentation/widgets/analysis_result_view.dart' show VerdictDisplay;
import '../../domain/entities/scan_history_entity.dart';
import 'history_time.dart';

/// One scan: product image, brand over name, when it was scanned, and the
/// verdict it had at that time. Greyed out (not tappable) when the product no
/// longer exists.
class HistoryItemCard extends StatelessWidget {
  final ScanHistoryEntity item;
  final VoidCallback? onTap;

  const HistoryItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final product = item.product;
    final verdict = item.verdict ?? 'unknown';
    final brand = product?.brand?.trim() ?? '';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: GlassCard(
        borderRadius: 20.r,
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            _Thumb(url: ApiConstants.resolveMediaUrl(product?.imageUrl), colors: colors),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brand.isNotEmpty)
                    Text(
                      brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w800),
                    ),
                  Text(
                    product?.name ?? 'Product no longer available',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.sp, height: 1.25),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    formatScanTime(item.scannedAt),
                    style: TextStyle(color: colors.secondaryText, fontSize: 11.5.sp),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            _VerdictPill(verdict: verdict),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  final AppThemeColors colors;
  const _Thumb({required this.url, required this.colors});

  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(Icons.inventory_2_outlined, color: colors.secondaryText, size: 24.r);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: 62.r,
        height: 62.r,
        color: colors.iconContainerBg,
        alignment: Alignment.center,
        child: url == null
            ? placeholder
            : Image.network(url!, width: 62.r, height: 62.r, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder),
      ),
    );
  }
}

/// Short labels so a long one ("Unable To Determine") can't squeeze the product text.
String _shortLabel(String verdict) => switch (verdict) {
      'safe' => 'Safe',
      'caution' => 'Caution',
      'avoid' => 'Avoid',
      _ => 'Unknown',
    };

class _VerdictPill extends StatelessWidget {
  final String verdict;
  const _VerdictPill({required this.verdict});

  @override
  Widget build(BuildContext context) {
    final color = verdict.verdictColor;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(verdict.verdictIcon, color: color, size: 14.r),
          SizedBox(width: 5.w),
          Text(
            _shortLabel(verdict),
            style: TextStyle(color: Colors.white, fontSize: 11.5.sp, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
