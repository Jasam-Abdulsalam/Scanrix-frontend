import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/error/exceptions.dart';
import 'package:scanrix_frontend/features/history/domain/entities/scan_history_entity.dart';
import 'package:scanrix_frontend/features/history/presentation/bloc/history_bloc.dart';
import 'package:scanrix_frontend/features/history/presentation/bloc/history_event.dart';
import 'package:scanrix_frontend/features/history/presentation/bloc/history_state.dart';

import 'history_test_support.dart';

HistoryBloc _bloc(FakeGetHistory get, {FakeDeleteEntry? del, FakeClear? clear}) => HistoryBloc(
      getScanHistoryUseCase: get,
      deleteHistoryEntryUseCase: del ?? FakeDeleteEntry(),
      clearHistoryUseCase: clear ?? FakeClear(),
    );

Future<HistoryLoaded> _loaded(HistoryBloc b) =>
    b.stream.firstWhere((s) => s is HistoryLoaded).then((s) => s as HistoryLoaded).timeout(const Duration(seconds: 2));

Future<void> _load(HistoryBloc b) async {
  b.add(const HistoryRequested());
  await _loaded(b);
}

List<ScanHistoryEntity> _many(int n) => [for (var i = 0; i < n; i++) entry('r$i')];

void main() {
  group('pagination', () {
    test('first page asks for the given size and exposes the cursor', () async {
      final get = FakeGetHistory(_many(7));
      final b = _bloc(get);
      b.add(const HistoryRequested(limit: 3));
      final s = await _loaded(b);
      expect(s.items.map((e) => e.id), ['r0', 'r1', 'r2']);
      expect(s.hasMore, isTrue);
      expect(get.requests.single.limit, 3);
      expect(get.requests.single.cursor, isNull);
      await b.close();
    });

    test('load more appends the next page with the cursor, until there is no more', () async {
      final get = FakeGetHistory(_many(7));
      final b = _bloc(get);
      b.add(const HistoryRequested(limit: 3));
      await _loaded(b);
      b.add(const HistoryLoadMore(limit: 3));
      await b.stream.firstWhere((s) => s is HistoryLoaded && s.items.length == 6);
      b.add(const HistoryLoadMore(limit: 3));
      final last = await b.stream.firstWhere((s) => s is HistoryLoaded && s.items.length == 7) as HistoryLoaded;
      expect(last.items.map((e) => e.id), [for (var i = 0; i < 7; i++) 'r$i']);
      expect(last.hasMore, isFalse);
      expect(get.requests.map((r) => r.cursor), [null, 'c3', 'c6']);
      b.add(const HistoryLoadMore(limit: 3)); // nothing left: no request
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(get.requests, hasLength(3));
      await b.close();
    });

    test('droppable: rapid scroll events fetch ONE next page', () async {
      final get = FakeGetHistory(_many(9));
      final b = _bloc(get);
      b.add(const HistoryRequested(limit: 3));
      await _loaded(b);
      get.gate = Completer<void>();
      b
        ..add(const HistoryLoadMore(limit: 3))
        ..add(const HistoryLoadMore(limit: 3))
        ..add(const HistoryLoadMore(limit: 3));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      get.gate!.complete();
      await b.stream.firstWhere((s) => s is HistoryLoaded && s.items.length == 6);
      expect(get.requests.where((r) => r.cursor != null), hasLength(1));
      await b.close();
    });

    test('a failed next page keeps the list, flags the failure, and a retry works', () async {
      final get = FakeGetHistory(_many(6))..errorOnCursor = networkDown;
      final b = _bloc(get);
      b.add(const HistoryRequested(limit: 3));
      await _loaded(b);
      b.add(const HistoryLoadMore(limit: 3));
      final failed = await b.stream.firstWhere((s) => s is HistoryLoaded && s.loadMoreFailed) as HistoryLoaded;
      expect(failed.items, hasLength(3));
      expect(failed.loadingMore, isFalse);
      get.errorOnCursor = null;
      b.add(const HistoryLoadMore(limit: 3));
      final ok = await b.stream.firstWhere((s) => s is HistoryLoaded && s.items.length == 6) as HistoryLoaded;
      expect(ok.loadMoreFailed, isFalse);
      await b.close();
    });

    test('a refresh while the next page is loading discards that stale page', () async {
      final get = FakeGetHistory(_many(9));
      final b = _bloc(get);
      b.add(const HistoryRequested(limit: 3));
      await _loaded(b);
      get.gate = Completer<void>();
      b.add(const HistoryLoadMore(limit: 3)); // stuck at the gate
      await Future<void>.delayed(const Duration(milliseconds: 20));
      get.items = _many(3).map((e) => entry('new-${e.id}')).toList(); // the list changed server-side
      b.add(const HistoryRequested(limit: 3, silent: true)); // runs in parallel with the stuck load-more
      await Future<void>.delayed(const Duration(milliseconds: 20));
      get.gate!.complete();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final s = b.state as HistoryLoaded;
      expect(s.items.every((e) => e.id.startsWith('new-')), isTrue, reason: 'stale page must not be appended');
      await b.close();
    });

    test('rows that moved between pages are not shown twice', () async {
      final get = FakeGetHistory([entry('a'), entry('b'), entry('c')]);
      final b = _bloc(get);
      b.add(const HistoryRequested(limit: 2));
      await _loaded(b);
      get.items = [entry('b'), entry('b'), entry('c')]; // page 2 repeats 'b'
      b.add(const HistoryLoadMore(limit: 2));
      final s = await b.stream.firstWhere((s) => s is HistoryLoaded && !s.hasMore) as HistoryLoaded;
      expect(s.items.map((e) => e.id).toSet().length, s.items.length);
      await b.close();
    });
  });

  test('request: loading, then the list', () async {
    final b = _bloc(FakeGetHistory([entry('a'), entry('b')]));
    final states = <Type>[];
    b.stream.listen((s) => states.add(s.runtimeType));
    b.add(const HistoryRequested());
    final loaded = await _loaded(b);
    expect(loaded.items.map((e) => e.id), ['a', 'b']);
    expect(states, [HistoryLoading, HistoryLoaded]);
    await b.close();
  });

  test('failure shows the message; a silent refresh failure keeps the list', () async {
    final get = FakeGetHistory([entry('a')]);
    final b = _bloc(get);
    await _load(b);
    get.error = networkDown;
    b.add(const HistoryRequested(silent: true));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(b.state, isA<HistoryLoaded>()); // list stays

    final failing = _bloc(FakeGetHistory([], error: const ServerException(message: 'boom')));
    failing.add(const HistoryRequested());
    final f = await failing.stream.firstWhere((s) => s is HistoryFailure);
    expect((f as HistoryFailure).message, 'boom');
    await b.close();
    await failing.close();
  });

  test('delete is optimistic: row is gone immediately and the API is called', () async {
    final del = FakeDeleteEntry();
    final b = _bloc(FakeGetHistory([entry('a'), entry('b')]), del: del);
    await _load(b);
    b.add(const HistoryEntryDeleted('a'));
    final after = await _loaded(b);
    expect(after.items.map((e) => e.id), ['b']);
    await Future<void>.delayed(Duration.zero);
    expect(del.deleted, ['a']);
    await b.close();
  });

  test('delete that fails comes back with a notice', () async {
    final b = _bloc(FakeGetHistory([entry('a')]), del: FakeDeleteEntry(error: networkDown));
    await _load(b);
    b.add(const HistoryEntryDeleted('a'));
    final restored = await b.stream.firstWhere((s) => s is HistoryLoaded && s.notice != null);
    expect((restored as HistoryLoaded).items.map((e) => e.id), ['a']);
    expect(restored.notice, contains("Couldn't delete"));
    await b.close();
  });

  test('clear all empties the list; failure restores it with a notice', () async {
    final clear = FakeClear();
    final b = _bloc(FakeGetHistory([entry('a'), entry('b')]), clear: clear);
    await _load(b);
    b.add(const HistoryCleared());
    expect((await _loaded(b)).items, isEmpty);
    await Future<void>.delayed(Duration.zero);
    expect(clear.calls, 1);
    await b.close();

    final bad = _bloc(FakeGetHistory([entry('a')]), clear: FakeClear(error: networkDown));
    await _load(bad);
    bad.add(const HistoryCleared());
    final restored = await bad.stream.firstWhere((s) => s is HistoryLoaded && s.notice != null);
    expect((restored as HistoryLoaded).items, hasLength(1));
    await bad.close();
  });
}
