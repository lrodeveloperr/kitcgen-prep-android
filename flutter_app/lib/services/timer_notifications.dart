import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:kitchen_prep_board/domain/kitchen_models.dart';
import 'package:kitchen_prep_board/l10n/kitchen_strings.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

@visibleForTesting
int resolveTimerNotificationId(String input, Map<int, String?> pending) {
  for (final entry in pending.entries) {
    if (entry.value == input) return entry.key;
  }

  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  while (pending.containsKey(hash)) {
    hash = (hash + 1) & 0x7fffffff;
  }
  return hash;
}

class TimerNotifications {
  TimerNotifications({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _timeZonesInitialized = false;
  Future<void>? _operationInFlight;

  int _baseId(String input) => resolveTimerNotificationId(input, const {});

  int _availableId(String input, Iterable<PendingNotificationRequest> pending) {
    return resolveTimerNotificationId(
      input,
      {for (final request in pending) request.id: request.payload},
    );
  }

  Future<void> _serialized(Future<void> Function() callback) async {
    final previous = _operationInFlight;
    if (previous != null) await previous;
    final operation = Future<void>.sync(callback);
    _operationInFlight = operation;
    try {
      await operation;
    } finally {
      if (identical(_operationInFlight, operation)) _operationInFlight = null;
    }
  }

  Future<void> refreshTimeZone() async {
    if (!_timeZonesInitialized) {
      tz_data.initializeTimeZones();
      _timeZonesInitialized = true;
    }
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> initialize(KitchenStrings strings) async {
    await refreshTimeZone();
    if (!_initialized) {
      const android = AndroidInitializationSettings('kitchen_notification');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
      );
      _initialized = true;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        'kitchen_timers',
        strings.t('timerAlerts'),
        description: strings.t('attention'),
        importance: Importance.high,
      ),
    );
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final notifications = await android?.requestNotificationsPermission();
      if (notifications == false) return false;
      final canExact = await android?.canScheduleExactNotifications();
      if (canExact == false) {
        await android?.requestExactAlarmsPermission();
      }
      return (await android?.areNotificationsEnabled()) ?? true;
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return (await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )) ??
          false;
    }
    return false;
  }

  Future<void> schedule(KitchenTask task, KitchenStrings strings) =>
      _serialized(() => _schedule(task, strings));

  Future<void> _schedule(KitchenTask task, KitchenStrings strings) async {
    final deadline = task.deadlineEpochMs;
    if (deadline == null || deadline <= DateTime.now().millisecondsSinceEpoch) return;
    await refreshTimeZone();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await android?.canScheduleExactNotifications();
    final mode = canExact == false
        ? AndroidScheduleMode.inexactAllowWhileIdle
        : AndroidScheduleMode.exactAllowWhileIdle;

    final pending = await _plugin.pendingNotificationRequests();
    await _plugin.zonedSchedule(
      id: _availableId(task.id, pending),
      title: strings.t('attention'),
      body: task.name,
      scheduledDate: tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, deadline),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'kitchen_timers',
          strings.t('timerAlerts'),
          channelDescription: strings.t('attention'),
          importance: Importance.high,
          priority: Priority.high,
          icon: 'kitchen_notification',
        ),
        iOS: const DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: mode,
      payload: task.id,
    );
  }

  Future<void> cancel(KitchenTask task) => _serialized(() => _cancel(task));

  Future<void> _cancel(KitchenTask task) async {
    final pending = await _plugin.pendingNotificationRequests();
    final matches = pending.where((request) => request.payload == task.id).toList();
    if (matches.isEmpty) {
      await _plugin.cancel(id: _baseId(task.id));
      return;
    }
    for (final request in matches) {
      await _plugin.cancel(id: request.id);
    }
  }

  Future<void> cancelAll() => _serialized(_plugin.cancelAllPendingNotifications);
}
