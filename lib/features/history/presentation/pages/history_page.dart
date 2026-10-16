import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/aurora_background.dart';
import '../../../../core/widgets/toast.dart';
import '../../../products/presentation/pages/product_detail_page.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';
import '../../../../core/widgets/paged_list_view.dart';
import '../history_paging.dart';
import '../widgets/history_item_card.dart';

/// Scan history. Newest first; swipe a row left to delete it, "Clear all" empties the list.
///
/// No Scaffold of its own when used as a tab (`MainShell` provides it). Pass
/// [standalone] for a direct push (e.g. Profile's "Scan History" row), which
/// adds a Scaffold, the background and a back button.
class HistoryPage extends StatefulWidget {
  final bool standalone;
  const HistoryPage({super.key, this.standalone = false});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not initState: the page size needs MediaQuery (the screen height).
    if (_requested) return;
    _requested = true;
    context.read<HistoryBloc>().add(HistoryRequested(limit: productListPageSize(context)));
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      bottom: false,
      child: BlocConsumer<HistoryBloc, HistoryState>(
        listener: (context, state) {
          if (state is HistoryLoaded && state.notice != null) {
            showToast(context, state.notice!, icon: Icons.error_outline_rounded);
          }
        },
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              standalone: widget.standalone,
              canClear: state is HistoryLoaded && state.items.isNotEmpty,
            ),
            Expanded(
              // As a tab the floating nav bar overlays the bottom: end the list
              // above it instead of letting rows scroll underneath.
              child: Padding(
                padding: EdgeInsets.only(bottom: widget.standalone ? 0 : _navReserve(context)),
                child: _FadeBottom(child: _Content(state: state)),
              ),
            ),
          ],
        ),
      ),
    );
    if (!widget.standalone) return body;
    return Scaffold(backgroundColor: Colors.transparent, body: AuroraBackground(child: body));
  }
}

/// Room the floating `BottomNavBar` takes: its 78 + 12 padding, the scan
/// button that pokes above it, and the system bottom inset.
double _navReserve(BuildContext context) => 92.h + MediaQuery.paddingOf(context).bottom;

/// Soft fade on the list's bottom edge so rows dissolve instead of being cut off.
class _FadeBottom extends StatelessWidget {
  final Widget child;
  const _FadeBottom({required this.child});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Colors.white, Colors.transparent],
        stops: [0, 0.94, 1],
      ).createShader(rect),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  final bool standalone;
  final bool canClear;
  const _Header({required this.standalone, required this.canClear});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(standalone ? 8.w : 20.w, 12.h, 12.w, 8.h),
      child: Row(
        children: [
          if (standalone)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          Expanded(
            child: Text(
              'History',
              style: TextStyle(color: Colors.white, fontSize: 26.sp, fontWeight: FontWeight.w800),
            ),
          ),
          if (canClear)
            TextButton(
              onPressed: () => _confirmClear(context),
              child: Text('Clear all', style: TextStyle(color: colors.secondaryText, fontSize: 13.sp)),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final bloc = context.read<HistoryBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('All your scans will be removed from this list. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear all')),
        ],
      ),
    );
    if (ok == true) bloc.add(const HistoryCleared());
  }
}

class _Content extends StatelessWidget {
  final HistoryState state;
  const _Content({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = state;
    if (s is HistoryLoaded) {
      return RefreshIndicator(
        color: colors.neonEmerald,
        onRefresh: () async =>
            context.read<HistoryBloc>().add(HistoryRequested(limit: productListPageSize(context), silent: true)),
        child: s.items.isEmpty ? const _Empty() : _List(state: s),
      );
    }
    if (s is HistoryFailure) return _Failure(message: s.message);
    return Center(child: CircularProgressIndicator(color: colors.neonEmerald));
  }
}

class _List extends StatelessWidget {
  final HistoryLoaded state;
  const _List({required this.state});

  @override
  Widget build(BuildContext context) {
    final items = state.items;
    return PagedListView(
      itemCount: items.length,
      hasMore: state.hasMore,
      loadingMore: state.loadingMore,
      loadMoreFailed: state.loadMoreFailed,
      onLoadMore: () => context.read<HistoryBloc>().add(HistoryLoadMore(limit: productListPageSize(context))),
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
      itemBuilder: (context, i) {
        final item = items[i];
        final barcode = item.product?.barcode;
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => context.read<HistoryBloc>().add(HistoryEntryDeleted(item.id)),
          background: const _DeleteBackground(),
          child: HistoryItemCard(
            item: item,
            onTap: barcode == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => ProductDetailPage(barcode: barcode)),
                    ),
          ),
        );
      },
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 24.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEF5B5B).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26.r),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // A scrollable so pull-to-refresh still works on an empty list.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 120.h),
        Icon(Icons.history_rounded, color: colors.secondaryText, size: 56.r),
        SizedBox(height: 14.h),
        Center(
          child: Text('No scans yet', style: TextStyle(color: Colors.white, fontSize: 17.sp, fontWeight: FontWeight.w700)),
        ),
        SizedBox(height: 6.h),
        Center(
          child: Text(
            'Products you scan will show up here.',
            style: TextStyle(color: colors.secondaryText, fontSize: 13.sp),
          ),
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  final String message;
  const _Failure({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryText, fontSize: 13.5.sp, height: 1.4),
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: () => context.read<HistoryBloc>().add(HistoryRequested(limit: productListPageSize(context))),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
