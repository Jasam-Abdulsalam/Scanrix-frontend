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

/// "Better alternatives" for a scanned product: AI-suggested alternatives
/// (`POST /ai/alternatives`) on a rotating card wheel. Tapping the centred card
/// expands it into [AlternativeDetailPage].
///
/// Costs 1 weekly AI credit the first time anyone asks for this product; after
/// that the saved answer is free. Owns its own [AlternativesBloc] (one per screen).
class AlternativesPage extends StatelessWidget {
  final String barcode;
  final String? productName;

  const AlternativesPage({super.key, required this.barcode, this.productName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AlternativesBloc>()..add(AlternativesRequested(barcode)),
      child: _AlternativesView(barcode: barcode, productName: productName),
    );
  }
}

class _AlternativesView extends StatefulWidget {
  final String barcode;
  final String? productName;

  const _AlternativesView({required this.barcode, this.productName});

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
          final result = state is AlternativesLoaded ? state.result : null;
          final count = result?.alternatives.length ?? 0;
          final glow = count == 0 ? colors.neonEmerald : altPaletteAt(_active.clamp(0, count - 1)).glow;
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
                    _Header(productName: widget.productName, productType: result?.productType),
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
      AlternativesLoaded(:final result) when result.alternatives.isEmpty => const _Message(
          icon: Icons.search_off_rounded,
          title: 'No confident alternative found',
          body: "Our AI couldn't find a similar product it was sure is better. We'd rather show nothing than guess.",
        ),
      AlternativesLoaded(:final result) => Column(
          children: [
            // Hints above the carousel: the dial owns the bottom edge.
            _Hints(result: result),
            // Runs down to the bottom safe-area edge (the page's SafeArea),
            // where the dial's flat edge sits.
            Expanded(
              child: AlternativesCarousel(
                items: result.alternatives,
                originalPriceInr: result.originalPriceInr,
                onActiveChanged: (i) => setState(() => _active = i),
                onOpen: (item, palette) => openAlternativeDetail(
                  context,
                  item: item,
                  palette: palette,
                  disclaimer: result.disclaimer,
                  originalPriceInr: result.originalPriceInr,
                  originalName: widget.productName,
                ),
              ),
            ),
          ],
        ),
      AlternativesFailure() => _Message(
          icon: switch (state.kind) {
            AlternativesFailureKind.creditsExhausted => Icons.hourglass_bottom_rounded,
            AlternativesFailureKind.ingredientsMissing => Icons.document_scanner_outlined,
            _ => Icons.cloud_off_rounded,
          },
          title: state.kind == AlternativesFailureKind.creditsExhausted
              ? 'Out of AI credits'
              : "Couldn't load alternatives",
          body: state.resetsAt == null ? state.message : '${state.message} ${_resetsText(state.resetsAt!)}',
          actionLabel: state.canRetry ? 'Try again' : null,
          onAction: () => context.read<AlternativesBloc>().add(AlternativesRequested(widget.barcode)),
        ),
      _ => const _Loading(),
    };
  }
}

String _resetsText(DateTime resetsAt) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final t = resetsAt.toLocal();
  return 'New credits on ${days[t.weekday - 1]}, ${t.day} ${months[t.month - 1]}.';
}

/// "AI suggestions · check the label before buying" plus, when this request
/// used a credit, how many are left this week.
class _Hints extends StatelessWidget {
  final AlternativesResult result;

  const _Hints({required this.result});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final left = result.creditsRemaining;
    final credit = result.cached || left == null ? null : 'Used 1 AI credit · $left left this week';
    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: Center(
        child: Column(
          children: [
            Text(
              'AI suggestions · check the label before buying',
              style: TextStyle(color: colors.secondaryText, fontSize: 12.sp),
            ),
            if (credit != null)
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Text(credit, style: TextStyle(color: colors.secondaryText, fontSize: 11.sp)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? productName;
  final String? productType;

  const _Header({this.productName, this.productType});

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
                if (name.isNotEmpty || productType != null)
                  Text(
                    productType != null ? 'AI picks for this $productType' : 'Picks similar to $name',
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
          Text('AI is looking for better options…', style: TextStyle(color: colors.secondaryText, fontSize: 13.sp)),
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
