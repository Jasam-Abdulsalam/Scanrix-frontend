import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/theme/app_theme_colors.dart';
import 'package:scanrix_frontend/features/history/domain/entities/scan_history_entity.dart';
import 'package:scanrix_frontend/features/history/presentation/bloc/history_bloc.dart';
import 'package:scanrix_frontend/features/history/presentation/pages/history_page.dart';

import 'history_test_support.dart';

/// A few fixed frames instead of `pumpAndSettle`: the page's spinner/indicators never "settle".
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

FakeGetHistory? lastFake;

Future<(FakeDeleteEntry, FakeClear)> _pump(
  WidgetTester t, {
  List<ScanHistoryEntity> items = const [],
  Object? error,
  int? serverPageCap,
}) async {
  final del = FakeDeleteEntry();
  final clear = FakeClear();
  final fake = lastFake = FakeGetHistory(items, error: error)..serverPageCap = serverPageCap;
  final bloc = HistoryBloc(
    getScanHistoryUseCase: fake,
    deleteHistoryEntryUseCase: del,
    clearHistoryUseCase: clear,
  );
  t.view.physicalSize = const Size(1125, 2400);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        theme: ThemeData(extensions: const [AppThemeColors.darkGreen]),
        home: Scaffold(
          body: BlocProvider.value(value: bloc, child: const HistoryPage()),
        ),
      ),
    ),
  );
  await _settle(t);
  return (del, clear);
}

void main() {
  testWidgets('shows each scan with brand, name and the verdict it had', (t) async {
    await _pump(t, items: [
      entry('a', verdict: 'avoid'),
      entry('b', verdict: 'safe'),
    ]);
    expect(find.text('Product a'), findsOneWidget);
    expect(find.text('Product b'), findsOneWidget);
    expect(find.text('Avoid'), findsOneWidget);
    expect(find.text('Safe'), findsOneWidget);
    expect(find.text('Clear all'), findsOneWidget);
  });

  testWidgets('as a tab the list ends above the floating nav bar', (t) async {
    await _pump(t, items: [for (var i = 0; i < 12; i++) entry('r$i')]);
    final list = t.getRect(find.byType(ListView));
    final screenBottom = t.view.physicalSize.height / t.view.devicePixelRatio;
    // The nav bar is ~90 logical px tall (78 + 12 padding); rows must stay clear of it.
    expect(list.bottom, lessThanOrEqualTo(screenBottom - 90));
  });

  testWidgets('first page size follows the screen height (not a fixed number)', (t) async {
    await _pump(t, items: [for (var i = 0; i < 60; i++) entry('r$i')]);
    final limit = lastFake!.requests.first.limit;
    expect(limit, inInclusiveRange(10, 50));
    expect(limit, isNot(50)); // a phone screen is not clamped to the maximum
    expect(find.text('Product r0'), findsOneWidget);
    expect(find.text('Product r${limit - 1}'), findsNothing); // built lazily, only what is near the screen
  });

  testWidgets('scrolling to the end loads the next page and the rows continue', (t) async {
    await _pump(t, items: [for (var i = 0; i < 60; i++) entry('r$i')]);
    final fake = lastFake!;
    expect(fake.requests, hasLength(1));
    await t.drag(find.byType(ListView), const Offset(0, -6000));
    await _settle(t);
    expect(fake.requests.length, greaterThanOrEqualTo(2));
    expect(fake.requests[1].cursor, 'c${fake.requests[0].limit}');
    await t.drag(find.byType(ListView), const Offset(0, -6000));
    await _settle(t);
    expect(fake.requests.length, greaterThanOrEqualTo(3)); // page 3 follows page 2
    expect(fake.requests[2].cursor, 'c${fake.requests[0].limit * 2}');
  });

  testWidgets('a first page too short to scroll keeps fetching until the screen is filled', (t) async {
    await _pump(t, items: [for (var i = 0; i < 40; i++) entry('r$i')], serverPageCap: 2);
    final fake = lastFake!;
    // 2 rows cannot fill the screen, so without a scroll the next pages must be requested by themselves.
    expect(fake.requests.length, greaterThan(3));
    expect(find.text('Product r5'), findsOneWidget);
  });

  testWidgets('a scan whose product was deleted is still listed, with a placeholder', (t) async {
    await _pump(t, items: [
      ScanHistoryEntity(id: 'x', userId: 'u', productId: 'p', verdict: 'caution', scannedAt: DateTime(2026, 10, 16)),
    ]);
    expect(find.text('Product no longer available'), findsOneWidget);
    expect(find.text('Caution'), findsOneWidget);
  });

  testWidgets('a verdict we cannot classify uses a short label, not "Unable To Determine"', (t) async {
    await _pump(t, items: [entry('u', verdict: 'unknown')]);
    expect(find.text('Unknown'), findsOneWidget);
    expect(find.text('Unable To Determine'), findsNothing);
  });

  testWidgets('empty history shows the empty state and no Clear all', (t) async {
    await _pump(t);
    expect(find.text('No scans yet'), findsOneWidget);
    expect(find.text('Clear all'), findsNothing);
  });

  testWidgets('load failure shows the message and a retry button', (t) async {
    await _pump(t, error: networkDown);
    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('swiping a row left deletes it', (t) async {
    final (del, _) = await _pump(t, items: [entry('a'), entry('b')]);
    await t.drag(find.text('Product a'), const Offset(-600, 0));
    await _settle(t);
    expect(find.text('Product a'), findsNothing);
    expect(find.text('Product b'), findsOneWidget);
    expect(del.deleted, ['a']);
  });

  testWidgets('Clear all asks first; cancel keeps everything, confirm empties it', (t) async {
    final (_, clear) = await _pump(t, items: [entry('a'), entry('b')]);
    await t.tap(find.text('Clear all'));
    await _settle(t);
    expect(find.text('Clear history?'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await _settle(t);
    expect(find.text('Product a'), findsOneWidget);
    expect(clear.calls, 0);

    await t.tap(find.text('Clear all'));
    await _settle(t);
    await t.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Clear all')));
    await _settle(t);
    expect(find.text('No scans yet'), findsOneWidget);
    expect(clear.calls, 1);
  });
}
