import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../domain/entities/routine_entity.dart';

/// Overlapping round thumbnails of a routine's first products, in step order, with "+N" for the rest.
class RoutineThumbStack extends StatelessWidget {
  final List<RoutineItemEntity> items;
  final int maxShown;

  const RoutineThumbStack({super.key, required this.items, this.maxShown = 3});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    final size = 24.r;
    final step = size * 0.68; // how far each circle sits from the previous one
    final shown = items.take(maxShown).toList();
    final extra = items.length - shown.length;
    final count = shown.length + (extra > 0 ? 1 : 0);

    Widget circle(Widget child) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.iconContainerBg,
        border: Border.all(color: colors.surface, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: child,
    );

    final placeholder = Icon(
      Icons.inventory_2_outlined,
      color: colors.secondaryText,
      size: 12.r,
    );

    return Semantics(
      label: '${items.length} ${items.length == 1 ? 'product' : 'products'}',
      excludeSemantics: true,
      child: SizedBox(
        width: size + step * (count - 1),
        height: size,
        child: Stack(
          children: [
            for (var i = 0; i < shown.length; i++)
              Positioned(
                left: step * i,
                child: circle(_image(shown[i], placeholder)),
              ),
            if (extra > 0)
              Positioned(
                left: step * shown.length,
                child: circle(
                  Text(
                    '+$extra',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _image(RoutineItemEntity item, Widget placeholder) =>
      NetworkPhoto(url: item.imageUrl, placeholder: placeholder);
}
