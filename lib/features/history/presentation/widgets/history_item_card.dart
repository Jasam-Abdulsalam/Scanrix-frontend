import 'package:flutter/material.dart';

import '../../../../core/utils/time_format.dart';
import '../../../products/presentation/widgets/product_row_card.dart';
import '../../domain/entities/scan_history_entity.dart';

/// One scan: the product row plus when it was scanned and the verdict it had at that time.
class HistoryItemCard extends StatelessWidget {
  final ScanHistoryEntity item;
  final VoidCallback? onTap;

  const HistoryItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return ProductRowCard(
      imageUrl: product?.imageUrl,
      brand: product?.brand,
      name: product?.name,
      subtitle: formatShortTime(item.scannedAt),
      verdict: item.verdict,
      onTap: onTap,
    );
  }
}
