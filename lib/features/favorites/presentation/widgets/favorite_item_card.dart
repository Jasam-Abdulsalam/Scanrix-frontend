import 'package:flutter/material.dart';

import '../../../../core/utils/time_format.dart';
import '../../../products/presentation/widgets/product_row_card.dart';
import '../../domain/entities/favorite_entity.dart';

/// One saved product: the shared product row, with when it was saved and the product's stored verdict.
class FavoriteItemCard extends StatelessWidget {
  final FavoriteEntity item;
  final VoidCallback? onTap;

  const FavoriteItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) => ProductRowCard(
        imageUrl: item.imageUrl,
        brand: item.brand,
        name: item.name,
        subtitle: 'Saved ${formatShortTime(item.addedAt)}',
        verdict: item.verdict,
        onTap: onTap,
      );
}
