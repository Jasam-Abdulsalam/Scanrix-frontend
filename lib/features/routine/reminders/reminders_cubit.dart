import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/routine_entity.dart';
import '../presentation/bloc/routine_bloc.dart';
import '../presentation/bloc/routine_state.dart';
import 'reminder_scheduler.dart';

class RemindersState extends Equatable {
  final bool loaded;
  final bool enabled;
  final TimeOfDay morning;
  final TimeOfDay evening;

  /// One-shot message for a toast (e.g. notifications not allowed).
  final String? notice;

  const RemindersState({
    this.loaded = false,
    this.enabled = false,
    this.morning = const TimeOfDay(hour: 8, minute: 0),
    this.evening = const TimeOfDay(hour: 21, minute: 0),
    this.notice,
  });

  TimeOfDay timeFor(RoutineSlot slot) =>
      slot == RoutineSlot.morning ? morning : evening;

  RemindersState copyWith({
    bool? loaded,
    bool? enabled,
    TimeOfDay? morning,
    TimeOfDay? evening,
    String? notice,
  }) => RemindersState(
    loaded: loaded ?? this.loaded,
    enabled: enabled ?? this.enabled,
    morning: morning ?? this.morning,
    evening: evening ?? this.evening,
    notice: notice, // always replaced
  );

  @override
  List<Object?> get props => [loaded, enabled, morning, evening, notice];
}

/// Routine reminders on THIS phone (settings in shared_preferences, not the backend: notifications are
/// per device). Keeps the scheduled notifications in sync with the settings and the routine: a slot with
/// no steps gets no reminder, and the message lists the slot's steps.
class RemindersCubit extends Cubit<RemindersState> {
  final ReminderScheduler scheduler;
  final RoutineBloc routineBloc;
  final Future<SharedPreferences> Function() _prefs;
  StreamSubscription<RoutineEntity>? _routineSub;

  static const _kEnabled = 'routine_reminders_enabled';
  static const _kMorning = 'routine_reminder_morning_minutes';
  static const _kEvening = 'routine_reminder_evening_minutes';

  RemindersCubit({
    required this.scheduler,
    required this.routineBloc,
    Future<SharedPreferences> Function()? prefs,
  }) : _prefs = prefs ?? SharedPreferences.getInstance,
       super(const RemindersState()) {
    _routineSub = routineBloc.stream
        .map((s) => s.routine)
        .distinct()
        .listen((_) => _sync());
  }

  Future<void> load() async {
    final p = await _prefs();
    emit(
      state.copyWith(
        loaded: true,
        enabled: p.getBool(_kEnabled) ?? false,
        morning: _time(p.getInt(_kMorning)) ?? state.morning,
        evening: _time(p.getInt(_kEvening)) ?? state.evening,
      ),
    );
    await _sync();
  }

  /// Turning on asks for notification permission; if refused, reminders stay off.
  Future<void> setEnabled(bool on) async {
    if (on && !await scheduler.requestPermission()) {
      emit(
        state.copyWith(
          enabled: false,
          notice:
              'Notifications are off for Scanrix. Allow them in your phone Settings to get reminders.',
        ),
      );
      return;
    }
    emit(state.copyWith(enabled: on));
    await (await _prefs()).setBool(_kEnabled, on);
    await _sync();
  }

  Future<void> setTime(RoutineSlot slot, TimeOfDay time) async {
    emit(
      slot == RoutineSlot.morning
          ? state.copyWith(morning: time)
          : state.copyWith(evening: time),
    );
    await (await _prefs()).setInt(
      slot == RoutineSlot.morning ? _kMorning : _kEvening,
      time.hour * 60 + time.minute,
    );
    await _sync();
  }

  /// Logout: this phone must not keep reminding about the previous account's routine.
  /// The switch itself is a phone setting and stays as it is.
  Future<void> cancelAll() async {
    for (final slot in RoutineSlot.values) {
      try {
        await scheduler.cancel(slot);
      } catch (_) {}
    }
  }

  Future<void> _sync() async {
    // Until the routine has loaded we don't know its steps: leave what's scheduled alone instead of
    // cancelling it (at app start the routine is still empty for a moment).
    if (routineBloc.state.status != RoutineStatus.loaded) return;
    final routine = routineBloc.state.routine;
    for (final slot in RoutineSlot.values) {
      final steps = routine.slot(slot);
      try {
        if (state.enabled && steps.isNotEmpty) {
          await scheduler.scheduleDaily(
            slot,
            state.timeFor(slot),
            title: reminderTitle(slot, steps.length),
            body: reminderBody(steps),
          );
        } else {
          await scheduler.cancel(slot);
        }
      } catch (_) {
        // Scheduling is best effort (e.g. plugin not available in a test or on an unsupported platform).
      }
    }
  }

  static TimeOfDay? _time(int? minutes) => minutes == null
      ? null
      : TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60);

  @override
  Future<void> close() async {
    await _routineSub?.cancel();
    return super.close();
  }
}

String reminderTitle(RoutineSlot slot, int count) =>
    '${slot == RoutineSlot.morning ? '☀️' : '🌙'} ${slot.label} routine · $count ${count == 1 ? 'step' : 'steps'}';

/// "Face wash → Serum → Sunscreen", at most 4 names then "+N more".
String reminderBody(List<RoutineItemEntity> steps) {
  String label(RoutineItemEntity i) =>
      i.name.isNotEmpty ? i.name : (i.brand ?? 'Product');
  final shown = steps.take(4).map(label).join(' → ');
  return steps.length > 4 ? '$shown +${steps.length - 4} more' : shown;
}
