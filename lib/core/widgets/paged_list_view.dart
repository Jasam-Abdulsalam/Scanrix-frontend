import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme_colors.dart';

/// A vertical list that asks for the next page near its end (infinite scroll).
///
/// Calls [onLoadMore] when fewer than [loadMoreThreshold] pixels remain, and also right after a
/// build when the content is too short to scroll but [hasMore] is true (otherwise a tall screen
/// could get stuck on page 1). The caller must ignore repeat calls while a load is running
/// (`droppable()` on the event). Shows a spinner while [loadingMore] and a retry row after a failure.
class PagedListView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool hasMore;
  final bool loadingMore;
  final bool loadMoreFailed;
  final VoidCallback onLoadMore;
  final EdgeInsets padding;
  final double separatorHeight;
  final double loadMoreThreshold;

  const PagedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.hasMore,
    required this.loadingMore,
    required this.loadMoreFailed,
    required this.onLoadMore,
    required this.padding,
    this.separatorHeight = 12,
    this.loadMoreThreshold = 300,
  });

  @override
  State<PagedListView> createState() => _PagedListViewState();
}

class _PagedListViewState extends State<PagedListView> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!widget.hasMore || widget.loadingMore || widget.loadMoreFailed || !_controller.hasClients) return;
    if (_controller.position.extentAfter < widget.loadMoreThreshold) widget.onLoadMore();
  }

  @override
  Widget build(BuildContext context) {
    // Content shorter than the screen never scrolls, so check once the frame is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeLoadMore();
    });
    final colors = context.colors;
    final hasFooter = widget.loadingMore || widget.loadMoreFailed;
    return ListView.separated(
      controller: _controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: widget.padding,
      itemCount: widget.itemCount + (hasFooter ? 1 : 0),
      separatorBuilder: (_, _) => SizedBox(height: widget.separatorHeight.h),
      itemBuilder: (context, i) {
        if (i < widget.itemCount) return widget.itemBuilder(context, i);
        if (widget.loadMoreFailed) {
          return Center(
            child: TextButton(onPressed: widget.onLoadMore, child: const Text("Couldn't load more. Tap to retry")),
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Center(
            child: SizedBox(
              width: 22.r,
              height: 22.r,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: colors.neonEmerald),
            ),
          ),
        );
      },
    );
  }
}
