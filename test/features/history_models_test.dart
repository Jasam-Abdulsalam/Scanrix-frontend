import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/features/history/data/models/scan_history_model.dart';
import 'package:scanrix_frontend/features/history/presentation/widgets/history_time.dart';

import 'history_test_support.dart';

void main() {
  group('ScanHistoryModel', () {
    test('parses the product summary', () {
      final m = ScanHistoryModel.fromJson(historyJson());
      expect(m.product?.barcode, 'b-h1');
      expect(m.product?.brand, 'Britannia');
      expect(m.verdict, 'caution');
    });

    test('product null (deleted product) is kept as null, row still parses', () {
      final json = historyJson()..['product'] = null;
      expect(ScanHistoryModel.fromJson(json).product, isNull);
    });

    test('a timestamp without zone is UTC (the backend sends it that way), not local', () {
      final m = ScanHistoryModel.fromJson(historyJson(scannedAt: '2026-10-16T08:41:00'));
      expect(m.scannedAt.toUtc(), DateTime.utc(2026, 10, 16, 8, 41));
      final withZ = ScanHistoryModel.fromJson(historyJson(scannedAt: '2026-10-16T08:41:00Z'));
      expect(withZ.scannedAt.toUtc(), DateTime.utc(2026, 10, 16, 8, 41));
      final offset = ScanHistoryModel.fromJson(historyJson(scannedAt: '2026-10-16T14:11:00+05:30'));
      expect(offset.scannedAt.toUtc(), DateTime.utc(2026, 10, 16, 8, 41));
    });
  });

  group('formatScanTime', () {
    final now = DateTime(2026, 10, 16, 15);
    test('today, yesterday, this year, other year', () {
      expect(formatScanTime(DateTime(2026, 10, 16, 14, 5), now: now), 'Today, 2:05 PM');
      expect(formatScanTime(DateTime(2026, 10, 15, 9, 0), now: now), 'Yesterday, 9:00 AM');
      expect(formatScanTime(DateTime(2026, 10, 12, 9), now: now), '12 Oct');
      expect(formatScanTime(DateTime(2025, 3, 1, 9), now: now), '1 Mar 2025');
    });
    test('midnight and noon use 12', () {
      expect(formatScanTime(DateTime(2026, 10, 16, 0, 7), now: now), 'Today, 12:07 AM');
      expect(formatScanTime(DateTime(2026, 10, 16, 12, 30), now: now), 'Today, 12:30 PM');
    });
  });
}
