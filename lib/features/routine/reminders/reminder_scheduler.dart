import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/entities/routine_entity.dart';

/// What the reminders need from the phone. An interface so tests use a fake instead of real notifications.
abstract class ReminderScheduler {
  /// Asks for permission to show notifications (iOS prompt, Android 13+ prompt). True = allowed.
  Future<bool> requestPermission();

  /// A notification every day at [time] (phone's local time), replacing this slot's previous one.
  Future<void> scheduleDaily(
    RoutineSlot slot,
    TimeOfDay time, {
    required String title,
    required String body,
  });

  Future<void> cancel(RoutineSlot slot);
}

/// Real phone notifications via flutter_local_notifications. Set up lazily on first use, so app start
/// isn't slowed down for people who never turn reminders on.
class LocalReminderScheduler implements ReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _ready;

  LocalReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationDetails(
    'routine_reminders',
    'Routine reminders',
    channelDescription: 'Your morning and evening skincare routine',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> _ensureReady() => _ready ??= _init();

  Future<void> _init() async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Unknown zone name: tz.local stays UTC, so times would shift; better than no reminder at all.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is asked when the user turns reminders on, not at app start.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureReady();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null)
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null)
      return await android.requestNotificationsPermission() ?? false;
    return false;
  }

  @override
  Future<void> scheduleDaily(
    RoutineSlot slot,
    TimeOfDay time, {
    required String title,
    required String body,
  }) async {
    await _ensureReady();
    await _plugin.zonedSchedule(
      id: _id(slot),
      scheduledDate: nextOccurrence(tz.TZDateTime.now(tz.local), time),
      notificationDetails: const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(),
      ),
      // Inexact: Android may deliver a few minutes late, but needs no "exact alarm" permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.time, // repeat daily at this time
      title: title,
      body: body,
    );
  }

  @override
  Future<void> cancel(RoutineSlot slot) async {
    await _ensureReady();
    await _plugin.cancel(id: _id(slot));
  }

  static int _id(RoutineSlot slot) => 100 + slot.index;
}

/// The next [time] at or after [now] (today if still ahead, else tomorrow).
tz.TZDateTime nextOccurrence(tz.TZDateTime now, TimeOfDay time) {
  var at = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );
  if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
  return at;
}
