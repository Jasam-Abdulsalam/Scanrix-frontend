import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/bold_card.dart';
import '../../domain/entities/alternative_product_entity.dart';
import '../bloc/alternatives_bloc.dart';
import '../bloc/alternatives_event.dart';
import '../bloc/alternatives_state.dart';
import '../widgets/alternative_style.dart';
import '../widgets/alternatives_carousel.dart';
import 'alternative_detail_page.dart';

/// "Better alternatives" for a scanned product: a 3D coverflow of
/// better-scored products. Tapping the centred card expands it into
/// [AlternativeDetailPage].
///
/// Owns its own [AlternativesBloc] (one per screen).
class AlternativesPage extends StatelessWidget {
  final String barcode;
  final String? productName;
  final int? originalScore;

  const AlternativesPage({super.key, required this.barcode, this.productName, this.originalScore});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AlternativesBloc>()..add(AlternativesRequested(barcode)),
      child: _AlternativesView(barcode: barcode, productName: productName, originalScore: originalScore),
    );
  }
}

class _AlternativesView extends StatefulWidget {
  final String barcode;
  final String? productName;
  final int? originalScore;

  const _AlternativesView({required this.barcode, this.productName, this.originalScore});

  @override
  State<_AlternativesView> createState() => _AlternativesViewState();
}

class _AlternativesViewState extends State<_AlternativesView> {
  /// Only changes when a different card becomes centred, never per frame.
  int _active = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: BlocBuilder<AlternativesBloc, AlternativesState>(
        builder: (context, state) {
          final items = state is AlternativesLoaded ? state.items : const <AlternativeProductEntity>[];
          final glow = items.isEmpty ? colors.neonEmerald : altPaletteAt(_active.clamp(0, items.length - 1)).glow;
          return Stack(
            children: [
              // Soft tint of the centred card, cross-fading as you swipe.
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.35),
                      radius: 1.1,
                      colors: [glow.withValues(alpha: 0.28), colors.background],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(productName: widget.productName),
                    Expanded(child: _body(context, state)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, AlternativesState state) {
    return switch (state) {
      AlternativesLoaded(:final items) when items.isEmpty => const _Message(
          icon: Icons.search_off_rounded,
          title: 'No better-scored alternatives yet',
          body: "We couldn't find a similar product that scores higher. Check back as our catalogue grows.",
        ),
      AlternativesLoaded(:final items) => Column(
          children: [
            // Hint above the carousel: the dial owns the bottom edge.
            Padding(
              padding: EdgeInsets.only(top: 14.h),
              child: Center(
                child: Text(
                  'Swipe to compare · tap a card for details',
                  style: TextStyle(color: context.colors.secondaryText, fontSize: 12.sp),
                ),
              ),
            ),
            // Runs down to the bottom safe-area edge (the page's SafeArea),
            // where the dial's flat edge sits.
            Expanded(
              child: AlternativesCarousel(
                items: items,
                originalScore: widget.originalScore,
                onActiveChanged: (i) => setState(() => _active = i),
                onOpen: (item, palette) => openAlternativeDetail(
                  context,
                  item: item,
                  palette: palette,
                  originalScore: widget.originalScore,
                  originalName: widget.productName,
                ),
              ),
            ),
          ],
        ),
      AlternativesFailure(:final message) => _Message(
          icon: Icons.cloud_off_rounded,
          title: "Couldn't load alternatives",
          body: message,
          actionLabel: 'Try again',
          onAction: () => context.read<AlternativesBloc>().add(AlternativesRequested(widget.barcode)),
        ),
      _ => const _Loading(),
    };
  }
}

class _Header extends StatelessWidget {
  final String? productName;

  const _Header({this.productName});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = productName?.trim() ?? '';
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      child: Row(
        children: [
          Pressable(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).maybePop();
            },
            child: CircleIcon(
              icon: Icons.arrow_back_ios_new_rounded,
              background: boldCardFill(colors),
              foreground: Colors.white,
              size: 42.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Better alternatives',
                  style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w800),
                ),
                if (name.isNotEmpty)
                  Text(
                    'Higher-scoring picks similar to $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.secondaryText, fontSize: 12.sp),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colors.neonEmerald),
          SizedBox(height: 16.h),
          Text('Finding better options…', style: TextStyle(color: colors.secondaryText, fontSize: 13.sp)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({required this.icon, required this.title, required this.body, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 36.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.secondaryText, size: 44.r),
            SizedBox(height: 14.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6.h),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryText, fontSize: 13.sp, height: 1.4),
            ),
            if (actionLabel != null) ...[
              SizedBox(height: 18.h),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!, style: TextStyle(color: colors.neonEmerald, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
