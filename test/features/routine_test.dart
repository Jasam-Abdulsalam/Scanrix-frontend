import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/error/exceptions.dart';
import 'package:scanrix_frontend/core/theme/app_theme_colors.dart';
import 'package:scanrix_frontend/features/routine/data/models/routine_model.dart';
import 'package:scanrix_frontend/features/routine/domain/entities/routine_entity.dart';
import 'package:scanrix_frontend/features/routine/presentation/bloc/routine_bloc.dart';
import 'package:scanrix_frontend/features/routine/presentation/bloc/routine_event.dart';
import 'package:scanrix_frontend/features/routine/presentation/bloc/routine_state.dart';
import 'package:scanrix_frontend/features/routine/presentation/widgets/add_to_routine_sheet.dart';
import 'package:scanrix_frontend/features/routine/reminders/reminder_scheduler.dart';
import 'package:scanrix_frontend/features/routine/reminders/reminders_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'routine_test_support.dart';

class FakeScheduler implements ReminderScheduler {
  bool allow;
  final scheduled = <RoutineSlot, (TimeOfDay, String, String)>{};

  FakeScheduler({this.allow = true});

  @override
  Future<bool> requestPermission() async => allow;

  @override
  Future<void> scheduleDaily(
    RoutineSlot slot,
    TimeOfDay time, {
    required String title,
    required String body,
  }) async => scheduled[slot] = (time, title, body);

  @override
  Future<void> cancel(RoutineSlot slot) async => scheduled.remove(slot);
}

const _wash = RoutineItemEntity(
  barcode: 'b1',
  name: 'Face wash',
  verdict: 'safe',
);
const _serum = RoutineItemEntity(barcode: 'b2', name: 'Serum');
const _spf = RoutineItemEntity(barcode: 'b3', name: 'Sunscreen');

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  group('RoutineModel', () {
    test('parses both slots and drops items without a barcode', () {
      final r = RoutineModel.fromJson({
        'morning': [
          {
            'barcode': 'b1',
            'name': 'Face wash',
            'verdict': 'safe',
            'overall_score': 80,
          },
          {'name': 'no barcode'},
          'junk',
        ],
        'evening': 'nope',
      });
      expect(r.morning.map((i) => i.barcode), ['b1']);
      expect(r.morning.first.overallScore, 80);
      expect(r.evening, isEmpty);
    });

    test('parses product_type; an unknown value is ignored', () {
      final r = RoutineModel.fromJson({
        'morning': [
          {'barcode': 'b1', 'name': 'Serum', 'product_type': 'serum'},
          {'barcode': 'b2', 'name': 'X', 'product_type': 'shampoo'},
        ],
      });
      expect(r.morning.map((i) => i.productType), [
        RoutineProductType.serum,
        null,
      ]);
    });

    test('slotsOf', () {
      const r = RoutineEntity(morning: [_wash, _serum], evening: [_wash]);
      expect(r.slotsOf('b1'), {RoutineSlot.morning, RoutineSlot.evening});
      expect(r.slotsOf('b2'), {RoutineSlot.morning});
      expect(r.slotsOf('zz'), isEmpty);
    });
  });

  group('RoutineBloc', () {
    test('saving slots adds and removes optimistically', () async {
      final server = FakeServer(const RoutineEntity(evening: [_wash]));
      final bloc = blocFor(server)..add(const RoutineRequested());
      await settle();
      bloc.add(const RoutineSlotsSaved(_wash, {RoutineSlot.morning}));
      await settle();
      expect(bloc.state.routine.slotsOf('b1'), {RoutineSlot.morning});
      expect(server.calls, ['get', 'add:morning:b1', 'remove:evening:b1']);
      await bloc.close();
    });

    test('a failed add is undone with a notice, then reloaded', () async {
      final server = FakeServer();
      final bloc = blocFor(server)..add(const RoutineRequested());
      await settle();
      server.failWith = const ServerException(
        message: 'This routine is full.',
        statusCode: 409,
        code: 'routine_slot_full',
      );
      bloc.add(const RoutineSlotsSaved(_wash, {RoutineSlot.morning}));
      final notice = await bloc.stream.firstWhere((s) => s.notice != null);
      expect(notice.routine.morning, isEmpty);
      expect(notice.notice, contains('This routine is full.'));
      await settle();
      expect(server.calls.last, 'get');
      await bloc.close();
    });

    test('remove and reorder', () async {
      final server = FakeServer(
        const RoutineEntity(morning: [_wash, _serum, _spf]),
      );
      final bloc = blocFor(server)..add(const RoutineRequested());
      await settle();
      bloc.add(
        const RoutineStepMoved(RoutineSlot.morning, 2, 0),
      ); // sunscreen to the top
      await settle();
      expect(bloc.state.routine.morning.map((i) => i.barcode), [
        'b3',
        'b1',
        'b2',
      ]);
      expect(server.calls.last, 'reorder:morning:b3,b1,b2');
      bloc.add(const RoutineStepRemoved(RoutineSlot.morning, 'b1'));
      await settle();
      expect(bloc.state.routine.morning.map((i) => i.barcode), ['b3', 'b2']);
      await bloc.close();
    });

    test(
      'a new product type is saved after the add and labels the product in both slots',
      () async {
        final server = FakeServer(const RoutineEntity(evening: [_wash]));
        final bloc = blocFor(server)..add(const RoutineRequested());
        await settle();
        bloc.add(
          const RoutineSlotsSaved(_wash, {
            RoutineSlot.morning,
            RoutineSlot.evening,
          }, productType: RoutineProductType.cleanser),
        );
        await settle();
        expect(server.calls, ['get', 'add:morning:b1', 'type:b1:cleanser']);
        expect(
          bloc.state.routine.morning.single.productType,
          RoutineProductType.cleanser,
        );
        expect(
          bloc.state.routine.evening.single.productType,
          RoutineProductType.cleanser,
        );
        await bloc.close();
      },
    );

    test(
      'only the type changed: one request; unchanged: none; removed: no type request',
      () async {
        final labelled = _wash.withProductType(RoutineProductType.toner);
        final server = FakeServer(RoutineEntity(morning: [labelled]));
        final bloc = blocFor(server)..add(const RoutineRequested());
        await settle();
        bloc.add(
          const RoutineSlotsSaved(_wash, {
            RoutineSlot.morning,
          }, productType: RoutineProductType.toner),
        );
        await settle();
        expect(server.calls, ['get']); // nothing changed
        bloc.add(const RoutineSlotsSaved(_wash, {RoutineSlot.morning}));
        await settle();
        expect(server.calls.last, 'type:b1:null'); // cleared
        bloc.add(
          const RoutineSlotsSaved(
            _wash,
            {},
            productType: RoutineProductType.serum,
          ),
        );
        await settle();
        expect(
          server.calls.last,
          'remove:morning:b1',
        ); // the backend drops the label with the product
        await bloc.close();
      },
    );

    test('reset forgets the routine', () async {
      final bloc = blocFor(FakeServer(const RoutineEntity(morning: [_wash])))
        ..add(const RoutineRequested());
      await settle();
      bloc.add(const RoutineReset());
      await settle();
      expect(bloc.state, const RoutineState());
      await bloc.close();
    });
  });

  group('RemindersCubit', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<(RoutineBloc, RemindersCubit, FakeScheduler)> make(
      RoutineEntity routine, {
      bool allow = true,
    }) async {
      final bloc = blocFor(FakeServer(routine));
      final scheduler = FakeScheduler(allow: allow);
      final cubit = RemindersCubit(scheduler: scheduler, routineBloc: bloc);
      await cubit.load();
      return (bloc, cubit, scheduler);
    }

    test(
      'nothing is scheduled (or cancelled) before the routine has loaded',
      () async {
        final (bloc, cubit, scheduler) = await make(
          const RoutineEntity(morning: [_wash]),
        );
        await cubit.setEnabled(true);
        expect(scheduler.scheduled, isEmpty);
        bloc.add(const RoutineRequested());
        await settle();
        expect(scheduler.scheduled.keys, [RoutineSlot.morning]);
        await cubit.close();
        await bloc.close();
      },
    );

    test('only slots with steps get a reminder, listing the steps', () async {
      final (bloc, cubit, scheduler) = await make(
        const RoutineEntity(morning: [_wash, _serum, _spf]),
      );
      bloc.add(const RoutineRequested());
      await settle();
      await cubit.setEnabled(true);
      expect(scheduler.scheduled.keys, [RoutineSlot.morning]);
      final (time, title, body) = scheduler.scheduled[RoutineSlot.morning]!;
      expect(time, const TimeOfDay(hour: 8, minute: 0));
      expect(title, '☀️ Morning routine · 3 steps');
      expect(body, 'Face wash → Serum → Sunscreen');

      await cubit.setTime(
        RoutineSlot.morning,
        const TimeOfDay(hour: 6, minute: 30),
      );
      expect(
        scheduler.scheduled[RoutineSlot.morning]!.$1,
        const TimeOfDay(hour: 6, minute: 30),
      );

      // Removing the last step cancels that slot's reminder.
      bloc
        ..add(const RoutineStepRemoved(RoutineSlot.morning, 'b1'))
        ..add(const RoutineStepRemoved(RoutineSlot.morning, 'b2'))
        ..add(const RoutineStepRemoved(RoutineSlot.morning, 'b3'));
      await settle();
      expect(scheduler.scheduled, isEmpty);
      await cubit.close();
      await bloc.close();
    });

    test('permission denied keeps reminders off with a notice', () async {
      final (bloc, cubit, scheduler) = await make(
        const RoutineEntity(morning: [_wash]),
        allow: false,
      );
      await cubit.setEnabled(true);
      expect(cubit.state.enabled, isFalse);
      expect(cubit.state.notice, contains('Settings'));
      expect(scheduler.scheduled, isEmpty);
      await cubit.close();
      await bloc.close();
    });

    test('settings survive a restart (stored on the phone)', () async {
      final (bloc, cubit, _) = await make(RoutineEntity.empty);
      await cubit.setEnabled(true);
      await cubit.setTime(
        RoutineSlot.evening,
        const TimeOfDay(hour: 22, minute: 15),
      );
      await cubit.close();
      final again = RemindersCubit(
        scheduler: FakeScheduler(),
        routineBloc: bloc,
      );
      await again.load();
      expect(again.state.enabled, isTrue);
      expect(again.state.evening, const TimeOfDay(hour: 22, minute: 15));
      await again.close();
      await bloc.close();
    });

    test('reminder body is capped at 4 names', () {
      final steps = [
        for (var i = 0; i < 6; i++)
          RoutineItemEntity(barcode: 'b$i', name: 'P$i'),
      ];
      expect(reminderBody(steps), 'P0 → P1 → P2 → P3 +2 more');
    });
  });

  test('nextOccurrence: today if still ahead, otherwise tomorrow', () {
    tz_data.initializeTimeZones();
    final now = tz.TZDateTime(tz.UTC, 2026, 11, 7, 9, 0);
    expect(
      nextOccurrence(now, const TimeOfDay(hour: 21, minute: 0)),
      tz.TZDateTime(tz.UTC, 2026, 11, 7, 21, 0),
    );
    expect(
      nextOccurrence(now, const TimeOfDay(hour: 8, minute: 0)),
      tz.TZDateTime(tz.UTC, 2026, 11, 8, 8, 0),
    );
    expect(
      nextOccurrence(now, const TimeOfDay(hour: 9, minute: 0)),
      tz.TZDateTime(tz.UTC, 2026, 11, 8, 9, 0),
    );
  });

  Future<(FakeServer, RemindersCubit, FakeScheduler)> openSheet(
    WidgetTester tester, {
    RoutineEntity? routine,
  }) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final server = FakeServer(routine ?? RoutineEntity.empty);
    final scheduler = FakeScheduler();
    late RemindersCubit reminders;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          theme: ThemeData(extensions: const [AppThemeColors.darkGreen]),
          // The tree owns (and closes) the bloc and cubit, as in the app.
          home: BlocProvider(
            create: (_) => blocFor(server)..add(const RoutineRequested()),
            child: BlocProvider(
              lazy: false,
              create: (context) => reminders = RemindersCubit(
                scheduler: scheduler,
                routineBloc: context.read<RoutineBloc>(),
              ),
              child: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showAddToRoutineSheet(context, _wash),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600)); // sheet slides up
    return (server, reminders, scheduler);
  }

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f);
    await tester.pump();
  }

  testWidgets('add sheet saves the chosen slots', (tester) async {
    final (server, _, _) = await openSheet(tester);
    expect(find.text('Add to your routine'), findsOneWidget);
    expect(find.text('PRODUCT TYPE'), findsNothing); // nothing ticked yet
    await tester.tap(find.text('Morning'));
    await tester.tap(find.text('Evening'));
    await tester.pump();
    await tapVisible(tester, find.text('Save'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(server.calls, containsAll(['add:morning:b1', 'add:evening:b1']));
    expect(
      find.text('Added to your morning and evening routine'),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 600)); // sheet slides down
    await tester.pump(
      const Duration(seconds: 3),
    ); // the toast fades out and removes itself
    expect(find.text('Add to your routine'), findsNothing); // sheet closed
    await tester.pumpWidget(
      const SizedBox(),
    ); // unmount: closes the bloc inside the test
  });

  testWidgets(
    'add sheet saves the product type and turns the routine reminder on',
    (tester) async {
      final (server, reminders, scheduler) = await openSheet(tester);
      await tester.tap(find.text('Evening'));
      await tester.pump();
      await tapVisible(tester, find.text('Moisturizer'));
      expect(
        find.text('Evening routine'),
        findsNothing,
      ); // reminders off: no times shown
      await tapVisible(tester, find.byType(Switch));
      expect(find.text('Evening routine'), findsOneWidget);
      expect(
        find.text('9:00 PM'),
        findsOneWidget,
      ); // the routine's current time
      await tapVisible(tester, find.text('Save'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        server.calls,
        containsAllInOrder(['add:evening:b1', 'type:b1:moisturizer']),
      );
      expect(reminders.state.enabled, isTrue);
      expect(scheduler.scheduled.keys, [
        RoutineSlot.evening,
      ]); // only the slot with steps
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
