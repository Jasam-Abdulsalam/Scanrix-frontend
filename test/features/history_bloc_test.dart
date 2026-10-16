import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/error/exceptions.dart';
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

void main() {
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
