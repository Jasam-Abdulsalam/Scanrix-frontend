import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/models/page_result.dart';
import 'package:scanrix_frontend/core/utils/page_size.dart';

void main() {
  group('pageSizeForViewport (two screens of rows, clamped)', () {
    test('a phone gets about two screens', () {
      expect(pageSizeForViewport(viewportHeight: 800, rowExtent: 98), 18); // ceil(8.16)=9 rows -> 18
    });
    test('a taller screen asks for more, a short one never below the minimum', () {
      expect(pageSizeForViewport(viewportHeight: 1200, rowExtent: 98), 26);
      expect(pageSizeForViewport(viewportHeight: 200, rowExtent: 98), 10);
    });
    test('huge screens are capped, bad inputs fall back to the minimum', () {
      expect(pageSizeForViewport(viewportHeight: 5000, rowExtent: 98), 50);
      expect(pageSizeForViewport(viewportHeight: 0, rowExtent: 98), 10);
      expect(pageSizeForViewport(viewportHeight: 800, rowExtent: 0), 10);
    });
  });

  group('PageResult.fromJson', () {
    int parse(Map<String, dynamic> j) => j['n'] as int;

    test('reads items and cursor', () {
      final p = PageResult<int>.fromJson({
        'items': [{'n': 1}, {'n': 2}],
        'next_cursor': 'abc',
        'has_more': true,
      }, parse);
      expect(p.items, [1, 2]);
      expect(p.nextCursor, 'abc');
      expect(p.hasMore, isTrue);
    });

    test('last page: no cursor, no more', () {
      final p = PageResult<int>.fromJson({'items': [], 'next_cursor': null, 'has_more': false}, parse);
      expect(p.hasMore, isFalse);
      expect(p.nextCursor, isNull);
    });

    test('has_more without a cursor is not trusted (it could never be continued)', () {
      final p = PageResult<int>.fromJson({'items': [], 'has_more': true}, parse);
      expect(p.hasMore, isFalse);
    });
  });
}
