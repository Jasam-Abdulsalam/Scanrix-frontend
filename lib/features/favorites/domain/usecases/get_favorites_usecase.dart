import 'package:equatable/equatable.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/page_result.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/favorite_model.dart';
import '../entities/favorite_entity.dart';

class FavoritesPageParams extends Equatable {
  final int limit;
  final String? cursor;

  const FavoritesPageParams({required this.limit, this.cursor});

  @override
  List<Object?> get props => [limit, cursor];
}

/// GET /favorites/?limit=&cursor= : one page of saved products, newest saved first.
class GetFavoritesUseCase implements UseCase<PageResult<FavoriteEntity>, FavoritesPageParams> {
  final ApiClient apiClient;

  GetFavoritesUseCase({required this.apiClient});

  @override
  Future<PageResult<FavoriteEntity>> call(FavoritesPageParams params) async {
    final data = await apiClient.get(
      ApiConstants.favorites,
      queryParameters: {'limit': params.limit, if (params.cursor != null) 'cursor': params.cursor},
    );
    return PageResult.fromJson(data as Map<String, dynamic>, FavoriteModel.fromJson);
  }
}
