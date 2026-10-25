import 'package:equatable/equatable.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

/// Loads which barcodes are saved (fills the hearts). Cheap; safe to send often.
class FavoritesBarcodesRequested extends FavoritesEvent {
  const FavoritesBarcodesRequested();
}

/// Loads the first page of the list. [silent] keeps the current rows while refreshing.
class FavoritesListRequested extends FavoritesEvent {
  final int limit;
  final bool silent;

  const FavoritesListRequested({this.limit = 20, this.silent = false});

  @override
  List<Object?> get props => [limit, silent];
}

class FavoritesLoadMore extends FavoritesEvent {
  final int limit;

  const FavoritesLoadMore({this.limit = 20});

  @override
  List<Object?> get props => [limit];
}

class FavoriteAdded extends FavoritesEvent {
  final String barcode;

  const FavoriteAdded(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

class FavoriteRemoved extends FavoritesEvent {
  final String barcode;

  const FavoriteRemoved(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

/// Forget everything (logout), so the next account never sees this one's saved products.
class FavoritesReset extends FavoritesEvent {
  const FavoritesReset();
}
