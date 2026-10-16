import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/favorite_entity.dart';
import '../../domain/usecases/add_favorite_usecase.dart';
import '../../domain/usecases/get_favorite_barcodes_usecase.dart';
import '../../domain/usecases/get_favorites_usecase.dart';
import '../../domain/usecases/remove_favorite_usecase.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

/// App-wide (provided in app.dart): the set of saved barcodes behind every heart, plus the
/// paginated list for the Favorites screen. Saving/removing is optimistic and undone on failure.
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final GetFavoritesUseCase getFavoritesUseCase;
  final GetFavoriteBarcodesUseCase getFavoriteBarcodesUseCase;
  final AddFavoriteUseCase addFavoriteUseCase;
  final RemoveFavoriteUseCase removeFavoriteUseCase;

  /// Bumped whenever the list is replaced; a "load more" started earlier must not append to the new list.
  int _generation = 0;

  /// Barcodes whose add/remove request is still running. A barcodes response that was started
  /// earlier must not undo them (the server may not have processed them yet).
  final Set<String> _pendingAdds = {};
  final Set<String> _pendingRemoves = {};

  FavoritesBloc({
    required this.getFavoritesUseCase,
    required this.getFavoriteBarcodesUseCase,
    required this.addFavoriteUseCase,
    required this.removeFavoriteUseCase,
  }) : super(const FavoritesState()) {
    on<FavoritesBarcodesRequested>(_onBarcodes, transformer: droppable());
    on<FavoritesListRequested>(_onList, transformer: droppable());
    on<FavoritesLoadMore>(_onLoadMore, transformer: droppable());
    // sequential: each optimistic change starts from the result of the previous one.
    on<FavoriteAdded>(_onAdded, transformer: sequential());
    on<FavoriteRemoved>(_onRemoved, transformer: sequential());
    on<FavoritesReset>((_, emit) {
      _generation++;
      _pendingAdds.clear();
      _pendingRemoves.clear();
      emit(const FavoritesState());
    });
  }

  Future<void> _onBarcodes(FavoritesBarcodesRequested event, Emitter<FavoritesState> emit) async {
    try {
      final saved = await getFavoriteBarcodesUseCase(const NoParams());
      final merged = {...saved, ..._pendingAdds}..removeAll(_pendingRemoves);
      emit(state.copyWith(barcodes: merged, barcodesLoaded: true));
    } catch (_) {
      // Hearts stay as they are; the next request retries. Nothing to tell the user.
    }
  }

  Future<void> _onList(FavoritesListRequested event, Emitter<FavoritesState> emit) async {
    final keepList = event.silent && state.listStatus == FavoritesListStatus.loaded;
    if (!keepList) emit(state.copyWith(listStatus: FavoritesListStatus.loading));
    _generation++;
    try {
      final page = await getFavoritesUseCase(FavoritesPageParams(limit: event.limit));
      emit(state.copyWith(
        listStatus: FavoritesListStatus.loaded,
        items: page.items,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        hasMore: page.hasMore,
        loadingMore: false,
        loadMoreFailed: false,
      ));
    } catch (e) {
      if (keepList) return; // a failed silent refresh keeps what the user sees
      emit(state.copyWith(listStatus: FavoritesListStatus.failure, failureMessage: _messageFor(e)));
    }
  }

  Future<void> _onLoadMore(FavoritesLoadMore event, Emitter<FavoritesState> emit) async {
    final current = state;
    if (current.listStatus != FavoritesListStatus.loaded || !current.hasMore || current.nextCursor == null) return;
    final generation = _generation;
    emit(current.copyWith(loadingMore: true, loadMoreFailed: false));
    try {
      final page = await getFavoritesUseCase(FavoritesPageParams(limit: event.limit, cursor: current.nextCursor));
      if (generation != _generation) return;
      final seen = {for (final i in state.items) i.id};
      emit(state.copyWith(
        items: [...state.items, ...page.items.where((i) => !seen.contains(i.id))],
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } catch (_) {
      if (generation != _generation) return;
      emit(state.copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }

  Future<void> _onAdded(FavoriteAdded event, Emitter<FavoritesState> emit) async {
    _pendingAdds.add(event.barcode);
    _pendingRemoves.remove(event.barcode);
    emit(state.copyWith(barcodes: {...state.barcodes, event.barcode}));
    try {
      await addFavoriteUseCase(event.barcode);
    } catch (e) {
      emit(state.copyWith(
        barcodes: {...state.barcodes}..remove(event.barcode),
        notice: "Couldn't save this product. ${_messageFor(e)}",
      ));
    } finally {
      _pendingAdds.remove(event.barcode);
    }
  }

  Future<void> _onRemoved(FavoriteRemoved event, Emitter<FavoritesState> emit) async {
    final index = state.items.indexWhere((i) => i.barcode == event.barcode);
    final FavoriteEntity? removed = index == -1 ? null : state.items[index];
    _pendingRemoves.add(event.barcode);
    _pendingAdds.remove(event.barcode);
    emit(state.copyWith(
      barcodes: {...state.barcodes}..remove(event.barcode),
      items: state.items.where((i) => i.barcode != event.barcode).toList(),
    ));
    try {
      await removeFavoriteUseCase(event.barcode);
    } catch (e) {
      final items = [...state.items];
      if (removed != null) items.insert(index.clamp(0, items.length), removed);
      emit(state.copyWith(
        barcodes: {...state.barcodes, event.barcode},
        items: items,
        notice: "Couldn't remove this product. ${_messageFor(e)}",
      ));
    } finally {
      _pendingRemoves.remove(event.barcode);
    }
  }

  String _messageFor(Object e) =>
      e is NetworkException || e is ServerException ? e.toString() : 'Something went wrong. Please try again.';
}
