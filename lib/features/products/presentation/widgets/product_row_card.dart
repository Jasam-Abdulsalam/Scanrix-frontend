import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import 'analysis_result_view.dart' show VerdictDisplay;

/// One product row (used by History and Favorites): image, brand over name, a small subtitle
/// line (e.g. when it was scanned) and a short verdict pill. [name] null means the product no
/// longer exists: a placeholder is shown (the caller also leaves [onTap] null).
class ProductRowCard extends StatelessWidget {
  final String? imageUrl;
  final String? brand;
  final String? name;
  final String subtitle;
  final String? verdict;
  final VoidCallback? onTap;

  const ProductRowCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.imageUrl,
    this.brand,
    this.verdict,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brandText = brand?.trim() ?? '';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: GlassCard(
        borderRadius: 20.r,
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            _Thumb(url: ApiConstants.resolveMediaUrl(imageUrl), colors: colors),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brandText.isNotEmpty)
                    Text(
                      brandText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w800),
                    ),
                  Text(
                    name ?? 'Product no longer available',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.sp, height: 1.25),
                  ),
                  SizedBox(height: 6.h),
                  Text(subtitle, style: TextStyle(color: colors.secondaryText, fontSize: 11.5.sp)),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            _VerdictPill(verdict: verdict ?? 'unknown'),
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
      'safe' => 'No flags',
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
