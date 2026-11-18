import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/navigation/tab_scope.dart';
import 'package:scanrix_frontend/core/theme/app_theme_colors.dart';
import 'package:scanrix_frontend/features/routine/domain/entities/routine_entity.dart';
import 'package:scanrix_frontend/features/routine/presentation/bloc/routine_bloc.dart';
import 'package:scanrix_frontend/features/routine/presentation/bloc/routine_event.dart';
import 'package:scanrix_frontend/features/routine/presentation/pages/routine_page.dart';
import 'package:scanrix_frontend/features/routine/presentation/widgets/routine_thumb_stack.dart';
import 'package:scanrix_frontend/features/routine/reminders/reminder_scheduler.dart';
import 'package:scanrix_frontend/features/routine/reminders/reminders_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'routine_test_support.dart';

class _NoopScheduler implements ReminderScheduler {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleDaily(
    RoutineSlot slot,
    TimeOfDay time, {
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancel(RoutineSlot slot) async {}
}

const _cleanser = RoutineItemEntity(barcode: 'm1', name: 'Morning Cleanser');
const _cream = RoutineItemEntity(barcode: 'e1', name: 'Night Cream');

void main() {
  group('canShowToastHere', () {
    Future<bool> check(WidgetTester tester, {bool? active}) async {
      late bool result;
      final probe = Builder(
        builder: (context) {
          result = canShowToastHere(context);
          return const SizedBox();
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: active == null ? probe : TabScope(active: active, child: probe),
        ),
      );
      return result;
    }

    testWidgets('quiet on a hidden tab', (tester) async {
      expect(await check(tester, active: false), isFalse);
    });

    testWidgets('shows on the visible tab', (tester) async {
      expect(await check(tester, active: true), isTrue);
    });

    testWidgets('shows outside a tab (a pushed page)', (tester) async {
      expect(await check(tester), isTrue);
    });
  });

  testWidgets('Routine tab shows the shell-owned slot and switches it', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final server = FakeServer(
      const RoutineEntity(morning: [_cleanser], evening: [_cream]),
    );
    final slot = ValueNotifier(RoutineSlot.evening);
    addTearDown(slot.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          theme: ThemeData(extensions: const [AppThemeColors.darkGreen]),
          home: BlocProvider(
            create: (_) => blocFor(server)..add(const RoutineRequested()),
            child: BlocProvider(
              create: (context) => RemindersCubit(
                scheduler: _NoopScheduler(),
                routineBloc: context.read<RoutineBloc>(),
              ),
              child: Scaffold(body: RoutinePage(slot: slot)),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('My Routine'), findsOneWidget);
    expect(
      find.byIcon(Icons.arrow_back_ios_new_rounded),
      findsNothing,
    ); // a tab: no back button
    expect(find.text('Night Cream'), findsOneWidget);
    expect(find.text('Morning Cleanser'), findsNothing);

    await tester.tap(find.text('Morning · 1'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(slot.value, RoutineSlot.morning);
    expect(find.text('Morning Cleanser'), findsOneWidget);

    slot.value = RoutineSlot.evening; // e.g. Home's "Today" card
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Night Cream'), findsOneWidget);

    await tester.pumpWidget(const SizedBox()); // closes the bloc and cubit
  });

  testWidgets('thumb stack shows the first 3 products and "+N" for the rest', (
    tester,
  ) async {
    Future<void> pump(List<RoutineItemEntity> items) => tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          theme: ThemeData(extensions: const [AppThemeColors.darkGreen]),
          home: Scaffold(body: RoutineThumbStack(items: items)),
        ),
      ),
    );

    await pump([
      for (var i = 0; i < 5; i++)
        RoutineItemEntity(barcode: 'b$i', name: 'P$i'),
    ]);
    expect(
      find.byIcon(Icons.inventory_2_outlined),
      findsNWidgets(3),
    ); // no images: placeholders
    expect(find.text('+2'), findsOneWidget);

    await pump([_cleanser]);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(find.textContaining('+'), findsNothing);

    await pump(const []);
    expect(find.byIcon(Icons.inventory_2_outlined), findsNothing);
  });
}
