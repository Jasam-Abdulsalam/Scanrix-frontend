import 'package:equatable/equatable.dart';

/// Mirrors the dict shape from `app/models/history.py::history_helper`,
/// returned by `GET /history/`.
class ScanHistoryEntity extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final String? verdict;
  final int? personalizedScore;
  final DateTime scannedAt;

  const ScanHistoryEntity({
    required this.id,
    required this.userId,
    required this.productId,
    this.verdict,
    this.personalizedScore,
    required this.scannedAt,
  });

  @override
  List<Object?> get props =>
      [id, userId, productId, verdict, personalizedScore, scannedAt];
}
