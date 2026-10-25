import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/error/exceptions.dart';
import 'package:scanrix_frontend/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:scanrix_frontend/features/favorites/presentation/bloc/favorites_event.dart';
import 'package:scanrix_frontend/features/favorites/presentation/bloc/favorites_state.dart';

import 'favorites_test_support.dart';
import 'history_test_support.dart' show networkDown;

Future<FavoritesState> _until(FavoritesBloc b, bool Function(FavoritesState) test) =>
    b.stream.firstWhere(test).timeout(const Duration(seconds: 2));

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 40));

void main() {
  group('hearts (saved barcodes)', () {
    test('loads the saved barcodes', () async {
      final f = FavFakes(saved: {'b1', 'b2'});
      final b = f.bloc()..add(const FavoritesBarcodesRequested());
      final s = await _until(b, (s) => s.barcodesLoaded);
      expect(s.barcodes, {'b1', 'b2'});
      await b.close();
    });

    test('add is optimistic: the heart fills at once and the API is called', () async {
      final f = FavFakes();
      final b = f.bloc();
      b.add(const FavoriteAdded('b1'));
      final s = await _until(b, (s) => s.barcodes.contains('b1'));
      expect(s.notice, isNull);
      await _settle();
      expect(f.add.added, ['b1']);
      await b.close();
    });

    test('a failed add empties the heart again and says why (server message kept)', () async {
      final f = FavFakes(addError: const ServerException(message: 'You have reached the limit.', statusCode: 409));
      final b = f.bloc();
      b.add(const FavoriteAdded('b1'));
      final s = await _until(b, (s) => s.notice != null);
      expect(s.barcodes, isEmpty);
      expect(s.notice, contains('You have reached the limit.'));
      await b.close();
    });

    test('remove is optimistic and takes the row out of the list too', () async {
      final f = FavFakes(items: [fav('1'), fav('2')], saved: {'b1', 'b2'});
      final b = f.bloc();
      b.add(const FavoritesBarcodesRequested());
      b.add(const FavoritesListRequested(limit: 10));
      await _until(b, (s) => s.listStatus == FavoritesListStatus.loaded && s.barcodesLoaded);
      b.add(const FavoriteRemoved('b1'));
      final s = await _until(b, (s) => !s.barcodes.contains('b1'));
      expect(s.items.map((i) => i.barcode), ['b2']);
      await _settle();
      expect(f.remove.removed, ['b1']);
      await b.close();
    });

    test('a failed remove puts the heart AND the row back where it was', () async {
      final f = FavFakes(items: [fav('1'), fav('2'), fav('3')], saved: {'b1', 'b2', 'b3'}, removeError: networkDown);
      final b = f.bloc();
      b.add(const FavoritesBarcodesRequested());
      b.add(const FavoritesListRequested(limit: 10));
      await _until(b, (s) => s.listStatus == FavoritesListStatus.loaded && s.barcodesLoaded);
      b.add(const FavoriteRemoved('b2'));
      final s = await _until(b, (s) => s.notice != null);
      expect(s.items.map((i) => i.barcode), ['b1', 'b2', 'b3']);
      expect(s.barcodes, contains('b2'));
      expect(s.notice, contains("Couldn't remove"));
      await b.close();
    });

    test('a barcodes response that started before a tap does not undo the tap', () async {
      final f = FavFakes(saved: {}); // the server does not know about b9 yet
      f.barcodes.gate = Completer<void>();
      f.add.gate = Completer<void>();
      final b = f.bloc();
      b.add(const FavoritesBarcodesRequested()); // stuck at the gate, will answer "nothing saved"
      await _settle();
      b.add(const FavoriteAdded('b9')); // user taps the heart; the PUT is still running
      await _settle();
      f.barcodes.gate!.complete();
      await _settle();
      expect(b.state.barcodes, contains('b9'), reason: 'the stale answer must not empty the heart');
      f.add.gate!.complete();
      await b.close();
    });

    test('a failed barcodes request changes nothing and shows nothing', () async {
      final f = FavFakes(saved: {'b1'});
      f.barcodes.error = networkDown;
      final b = f.bloc()..add(const FavoritesBarcodesRequested());
      await _settle();
      expect(b.state.barcodesLoaded, isFalse);
      expect(b.state.notice, isNull);
      await b.close();
    });

    test('reset forgets everything (logout)', () async {
      final f = FavFakes(items: [fav('1')], saved: {'b1'});
      final b = f.bloc();
      b.add(const FavoritesBarcodesRequested());
      b.add(const FavoritesListRequested(limit: 10));
      await _until(b, (s) => s.listStatus == FavoritesListStatus.loaded && s.barcodesLoaded);
      b.add(const FavoritesReset());
      final s = await _until(b, (s) => s.items.isEmpty && s.barcodes.isEmpty);
      expect(s.barcodesLoaded, isFalse);
      expect(s.listStatus, FavoritesListStatus.initial);
      await b.close();
    });
  });

  group('list + pagination', () {
    test('first page uses the given size; load more appends with the cursor until the end', () async {
      final f = FavFakes(items: [for (var i = 0; i < 7; i++) fav('$i')]);
      final b = f.bloc()..add(const FavoritesListRequested(limit: 3));
      final first = await _until(b, (s) => s.listStatus == FavoritesListStatus.loaded);
      expect(first.items, hasLength(3));
      expect(first.hasMore, isTrue);
      b.add(const FavoritesLoadMore(limit: 3));
      await _until(b, (s) => s.items.length == 6);
      b.add(const FavoritesLoadMore(limit: 3));
      final last = await _until(b, (s) => s.items.length == 7);
      expect(last.hasMore, isFalse);
      expect(f.list.requests.map((r) => r.cursor), [null, 'c3', 'c6']);
      b.add(const FavoritesLoadMore(limit: 3)); // nothing left: no request
      await _settle();
      expect(f.list.requests, hasLength(3));
      await b.close();
    });

    test('droppable: rapid scroll events fetch ONE next page', () async {
      final f = FavFakes(items: [for (var i = 0; i < 9; i++) fav('$i')]);
      final b = f.bloc()..add(const FavoritesListRequested(limit: 3));
      await _until(b, (s) => s.listStatus == FavoritesListStatus.loaded);
      f.list.gate = Completer<void>();
      b
        ..add(const FavoritesLoadMore(limit: 3))
        ..add(const FavoritesLoadMore(limit: 3))
        ..add(const FavoritesLoadMore(limit: 3));
      await _settle();
      f.list.gate!.complete();
      await _until(b, (s) => s.items.length == 6);
      expect(f.list.requests.where((r) => r.cursor != null), hasLength(1));
      await b.close();
    });

    test('a failed next page keeps the rows, flags it, and a retry works', () async {
      final f = FavFakes(items: [for (var i = 0; i < 6; i++) fav('$i')]);
      f.list.errorOnCursor = networkDown;
      final b = f.bloc()..add(const FavoritesListRequested(limit: 3));
      await _until(b, (s) => s.listStatus == FavoritesListStatus.loaded);
      b.add(const FavoritesLoadMore(limit: 3));
      final failed = await _until(b, (s) => s.loadMoreFailed);
      expect(failed.items, hasLength(3));
      f.list.errorOnCursor = null;
      b.add(const FavoritesLoadMore(limit: 3));
      final ok = await _until(b, (s) => s.items.length == 6);
      expect(ok.loadMoreFailed, isFalse);
      await b.close();
    });

    test('a refresh while the next page is loading discards that stale page', () async {
      final f = FavFakes(items: [for (var i = 0; i < 9; i++) fav('$i')]);
      final b = f.bloc()..add(const FavoritesListRequested(limit: 3));
      await _until(b, (s) => s.listStatus == FavoritesListStatus.loaded);
      f.list.gate = Completer<void>();
      b.add(const FavoritesLoadMore(limit: 3)); // stuck at the gate with the OLD list's page 2
      await _settle();
      f.list.items = [fav('new1'), fav('new2')];
      b.add(const FavoritesListRequested(limit: 3, silent: true));
      await _settle();
      f.list.gate!.complete();
      await _settle();
      expect(b.state.items.map((i) => i.barcode), ['bnew1', 'bnew2']);
      await b.close();
    });

    test('list failure shows the message; a silent refresh failure keeps the rows', () async {
      final f = FavFakes(items: [fav('1')]);
      final b = f.bloc()..add(const FavoritesListRequested(limit: 3));
      await _until(b, (s) => s.listStatus == FavoritesListStatus.loaded);
      f.list.error = networkDown;
      b.add(const FavoritesListRequested(limit: 3, silent: true));
      await _settle();
      expect(b.state.listStatus, FavoritesListStatus.loaded);
      expect(b.state.items, hasLength(1));

      final bad = FavFakes(listError: const ServerException(message: 'boom')).bloc()
        ..add(const FavoritesListRequested(limit: 3));
      final s = await _until(bad, (s) => s.listStatus == FavoritesListStatus.failure);
      expect(s.failureMessage, 'boom');
      await b.close();
      await bad.close();
    });
  });
}
