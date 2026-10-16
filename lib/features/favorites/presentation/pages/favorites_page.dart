import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/aurora_background.dart';
import '../../../../core/widgets/paged_list_view.dart';
import '../../../../core/widgets/toast.dart';
import '../../../history/presentation/history_paging.dart';
import '../../../products/presentation/pages/product_detail_page.dart';
import '../bloc/favorites_bloc.dart';
import '../bloc/favorites_event.dart';
import '../bloc/favorites_state.dart';
import '../widgets/favorite_item_card.dart';

/// Saved products, newest saved first. Swipe a row left to remove it; tap to open the product.
/// Pushed as its own route (Profile "Favorites" card, Home "Saved Products" card).
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not initState: the page size needs MediaQuery (the screen height).
    if (_requested) return;
    _requested = true;
    context.read<FavoritesBloc>().add(FavoritesListRequested(limit: productListPageSize(context)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: BlocConsumer<FavoritesBloc, FavoritesState>(
            listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
            // Only the screen on top shows it (the product page underneath listens too).
            listener: (context, state) {
              if (ModalRoute.of(context)?.isCurrent ?? true) {
                showToast(context, state.notice!, icon: Icons.error_outline_rounded);
              }
            },
            builder: (context, state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Header(),
                Expanded(child: _Content(state: state)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 12.h, 12.w, 8.h),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              'Saved products',
              style: TextStyle(color: Colors.white, fontSize: 26.sp, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final FavoritesState state;
  const _Content({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    switch (state.listStatus) {
      case FavoritesListStatus.loaded:
        return RefreshIndicator(
          color: colors.neonEmerald,
          onRefresh: () async => context
              .read<FavoritesBloc>()
              .add(FavoritesListRequested(limit: productListPageSize(context), silent: true)),
          child: state.items.isEmpty ? const _Empty() : _List(state: state),
        );
      case FavoritesListStatus.failure:
        return _Failure(message: state.failureMessage ?? 'Something went wrong. Please try again.');
      case FavoritesListStatus.initial:
      case FavoritesListStatus.loading:
        return Center(child: CircularProgressIndicator(color: colors.neonEmerald));
    }
  }
}

class _List extends StatelessWidget {
  final FavoritesState state;
  const _List({required this.state});

  @override
  Widget build(BuildContext context) {
    final items = state.items;
    return PagedListView(
      itemCount: items.length,
      hasMore: state.hasMore,
      loadingMore: state.loadingMore,
      loadMoreFailed: state.loadMoreFailed,
      onLoadMore: () => context.read<FavoritesBloc>().add(FavoritesLoadMore(limit: productListPageSize(context))),
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
      itemBuilder: (context, i) {
        final item = items[i];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => context.read<FavoritesBloc>().add(FavoriteRemoved(item.barcode)),
          background: const _RemoveBackground(),
          child: FavoriteItemCard(
            item: item,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => ProductDetailPage(barcode: item.barcode)),
            ),
          ),
        );
      },
    );
  }
}

class _RemoveBackground extends StatelessWidget {
  const _RemoveBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 24.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEF5B5B).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Icon(Icons.heart_broken_outlined, color: Colors.white, size: 26.r),
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
        Icon(Icons.favorite_border_rounded, color: colors.secondaryText, size: 56.r),
        SizedBox(height: 14.h),
        Center(
          child: Text(
            'No saved products yet',
            style: TextStyle(color: Colors.white, fontSize: 17.sp, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(height: 6.h),
        Center(
          child: Text(
            'Tap the heart on a product to keep it here.',
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
              onPressed: () =>
                  context.read<FavoritesBloc>().add(FavoritesListRequested(limit: productListPageSize(context))),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
