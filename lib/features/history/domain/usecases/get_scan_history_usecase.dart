import 'package:equatable/equatable.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/page_result.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/scan_history_model.dart';
import '../entities/scan_history_entity.dart';

class HistoryPageParams extends Equatable {
  final int limit;
  final String? cursor;

  const HistoryPageParams({required this.limit, this.cursor});

  @override
  List<Object?> get props => [limit, cursor];
}

/// GET /history/?limit=&cursor= : one page, newest first, each entry with a product summary.
class GetScanHistoryUseCase implements UseCase<PageResult<ScanHistoryEntity>, HistoryPageParams> {
  final ApiClient apiClient;

  GetScanHistoryUseCase({required this.apiClient});

  @override
  Future<PageResult<ScanHistoryEntity>> call(HistoryPageParams params) async {
    final data = await apiClient.get(
      ApiConstants.history,
      queryParameters: {'limit': params.limit, if (params.cursor != null) 'cursor': params.cursor},
    );
    return PageResult.fromJson(data as Map<String, dynamic>, ScanHistoryModel.fromJson);
  }
}
