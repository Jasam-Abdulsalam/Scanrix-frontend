import 'dart:async';

import 'package:scanrix_frontend/core/models/page_result.dart';
import 'package:scanrix_frontend/core/network/api_client.dart';
import 'package:scanrix_frontend/core/usecase/usecase.dart';
import 'package:scanrix_frontend/features/favorites/domain/entities/favorite_entity.dart';
import 'package:scanrix_frontend/features/favorites/domain/usecases/add_favorite_usecase.dart';
import 'package:scanrix_frontend/features/favorites/domain/usecases/get_favorite_barcodes_usecase.dart';
import 'package:scanrix_frontend/features/favorites/domain/usecases/get_favorites_usecase.dart';
import 'package:scanrix_frontend/features/favorites/domain/usecases/remove_favorite_usecase.dart';
import 'package:scanrix_frontend/features/favorites/presentation/bloc/favorites_bloc.dart';

Map<String, dynamic> favoriteJson({String id = 'f1', String barcode = 'b1', String addedAt = '2026-10-16T08:41:00'}) => {
      'id': id,
      'barcode': barcode,
      'name': 'Milk Bikis',
      'brand': 'Britannia',
      'category': 'food',
      'image_url': null,
      'verdict': 'safe',
      'overall_score': 80,
      'added_at': addedAt,
    };

FavoriteEntity fav(String n) => FavoriteEntity(
      id: 'id$n',
      barcode: 'b$n',
      name: 'Product $n',
      brand: 'Brand',
      verdict: 'safe',
      addedAt: DateTime(2026, 10, 16, 9),
    );

/// Serves [items] page by page; the cursor is "c<next index>".
class FakeGetFavorites implements GetFavoritesUseCase {
  List<FavoriteEntity> items;
  Object? error;
  Object? errorOnCursor;
  final List<FavoritesPageParams> requests = [];
  Completer<void>? gate; // only "load more" requests wait

  FakeGetFavorites(this.items, {this.error});

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<PageResult<FavoriteEntity>> call(FavoritesPageParams params) async {
    requests.add(params);
    final snapshot = List<FavoriteEntity>.of(items);
    final gateNow = params.cursor != null ? gate : null;
    if (gateNow != null) await gateNow.future;
    if (error != null) throw error!;
    if (params.cursor != null && errorOnCursor != null) throw errorOnCursor!;
    final start = params.cursor == null ? 0 : int.parse(params.cursor!.substring(1));
    final end = (start + params.limit).clamp(0, snapshot.length);
    final more = end < snapshot.length;
    return PageResult(items: snapshot.sublist(start, end), nextCursor: more ? 'c$end' : null, hasMore: more);
  }
}

class FakeGetBarcodes implements GetFavoriteBarcodesUseCase {
  Set<String> barcodes;
  Object? error;
  Completer<void>? gate;
  int calls = 0;
  FakeGetBarcodes(this.barcodes);

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<Set<String>> call(NoParams params) async {
    calls++;
    final snapshot = {...barcodes}; // the server's answer at request time
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    return snapshot;
  }
}

class FakeAdd implements AddFavoriteUseCase {
  final List<String> added = [];
  Object? error;
  Completer<void>? gate;
  FakeAdd({this.error});

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<void> call(String barcode) async {
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    added.add(barcode);
  }
}

class FakeRemove implements RemoveFavoriteUseCase {
  final List<String> removed = [];
  Object? error;
  FakeRemove({this.error});

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<void> call(String barcode) async {
    if (error != null) throw error!;
    removed.add(barcode);
  }
}

class FavFakes {
  final FakeGetFavorites list;
  final FakeGetBarcodes barcodes;
  final FakeAdd add;
  final FakeRemove remove;
  FavFakes({
    List<FavoriteEntity> items = const [],
    Set<String> saved = const {},
    Object? listError,
    Object? addError,
    Object? removeError,
  })  : list = FakeGetFavorites(items, error: listError),
        barcodes = FakeGetBarcodes(saved),
        add = FakeAdd(error: addError),
        remove = FakeRemove(error: removeError);

  FavoritesBloc bloc() => FavoritesBloc(
        getFavoritesUseCase: list,
        getFavoriteBarcodesUseCase: barcodes,
        addFavoriteUseCase: add,
        removeFavoriteUseCase: remove,
      );
}
