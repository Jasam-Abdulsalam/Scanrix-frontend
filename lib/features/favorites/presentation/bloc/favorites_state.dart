import 'package:equatable/equatable.dart';

import '../../domain/entities/favorite_entity.dart';

enum FavoritesListStatus { initial, loading, loaded, failure }

/// One state for the whole feature: [barcodes] feeds every heart in the app, the rest is the list screen.
class FavoritesState extends Equatable {
  final Set<String> barcodes;
  final bool barcodesLoaded;

  final FavoritesListStatus listStatus;
  final List<FavoriteEntity> items;
  final String? nextCursor;
  final bool hasMore;
  final bool loadingMore;
  final bool loadMoreFailed;
  final String? failureMessage;

  /// One-shot message for the UI (e.g. a save that failed and was undone).
  final String? notice;

  const FavoritesState({
    this.barcodes = const {},
    this.barcodesLoaded = false,
    this.listStatus = FavoritesListStatus.initial,
    this.items = const [],
    this.nextCursor,
    this.hasMore = false,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.failureMessage,
    this.notice,
  });

  FavoritesState copyWith({
    Set<String>? barcodes,
    bool? barcodesLoaded,
    FavoritesListStatus? listStatus,
    List<FavoriteEntity>? items,
    String? nextCursor,
    bool clearCursor = false,
    bool? hasMore,
    bool? loadingMore,
    bool? loadMoreFailed,
    String? failureMessage,
    String? notice,
  }) =>
      FavoritesState(
        barcodes: barcodes ?? this.barcodes,
        barcodesLoaded: barcodesLoaded ?? this.barcodesLoaded,
        listStatus: listStatus ?? this.listStatus,
        items: items ?? this.items,
        nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
        failureMessage: failureMessage ?? this.failureMessage,
        notice: notice, // always replaced: a copy never repeats the previous notice
      );

  @override
  List<Object?> get props => [
        barcodes,
        barcodesLoaded,
        listStatus,
        items,
        nextCursor,
        hasMore,
        loadingMore,
        loadMoreFailed,
        failureMessage,
        notice,
      ];
}
