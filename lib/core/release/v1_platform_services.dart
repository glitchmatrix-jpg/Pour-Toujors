import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Platform-facing services for Pour Toujours v1.
///
/// No location, call log, WhatsApp, or background activity data is read here.
/// Widget and notification content is derived from city-level public data,
/// locally stored routines, and events explicitly created in the app.
class V1PlatformServices {
  V1PlatformServices._();

  static final V1PlatformServices instance = V1PlatformServices._();

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  Future<void>? _initializing;
  Future<void> _widgetQueue = Future<void>.value();

  bool get _supportsAndroidNativeFeatures =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() {
    if (!_supportsAndroidNativeFeatures) return Future<void>.value();
    return _initializing ??= _initializeSafely();
  }

  Future<void> _initializeSafely() async {
    try {
      const android = AndroidInitializationSettings('@drawable/ic_pour_toujours');
      const settings = InitializationSettings(android: android);
      await notifications.initialize(settings);
    } on MissingPluginException {
      debugPrint('Native notification plugin is not attached to this engine.');
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Notification initialization failed: $error\n$stackTrace');
    } on Object catch (error, stackTrace) {
      debugPrint('Unexpected notification initialization failure: $error\n$stackTrace');
    }
  }

  Future<bool> requestNotificationPermission() async {
    if (!_supportsAndroidNativeFeatures) return false;
    await initialize();
    try {
      final android = notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    } on PlatformException catch (error) {
      debugPrint('Notification permission request failed: $error');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> notificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(NotificationPreferences.enabledKey) ?? false;
    } on Object catch (error) {
      debugPrint('Could not read notification state: $error');
      return false;
    }
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    String payload = 'pourtoujours://calendar',
    NotificationUrgency urgency = NotificationUrgency.normal,
  }) async {
    if (!_supportsAndroidNativeFeatures || id < 0) return;
    final preferences = await NotificationPreferences.load();
    if (!preferences.enabled || preferences.isQuiet(when)) return;
    if (!when.isAfter(tz.TZDateTime.now(when.location))) return;

    await initialize();
    final channel = urgency == NotificationUrgency.urgent
        ? const AndroidNotificationDetails(
            'urgent_family_alerts',
            'Urgent family alerts',
            channelDescription:
                'Opt-in official severe-weather and time-critical alerts.',
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
          )
        : const AndroidNotificationDetails(
            'family_reminders',
            'Family reminders',
            channelDescription:
                'Birthdays, planned calls, family events, and call windows.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          );
    try {
      await notifications.zonedSchedule(
        id,
        title.trim().isEmpty ? 'Pour Toujours' : title.trim(),
        body.trim(),
        when,
        NotificationDetails(android: channel),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Reminder scheduling failed safely: $error\n$stackTrace');
    } on MissingPluginException {
      debugPrint('Reminder plugin unavailable; no reminder was scheduled.');
    }
  }

  Future<void> cancelReminder(int id) async {
    if (!_supportsAndroidNativeFeatures) return;
    await initialize();
    try {
      await notifications.cancel(id);
    } on Object catch (error) {
      debugPrint('Reminder cancellation failed safely: $error');
    }
  }

  Future<void> cancelAllReminders() async {
    if (!_supportsAndroidNativeFeatures) return;
    await initialize();
    try {
      await notifications.cancelAll();
    } on Object catch (error) {
      debugPrint('Reminder cancellation failed safely: $error');
    }
  }

  /// Writes one compact, offline-safe snapshot shared by all Android widgets.
  /// Native widgets keep rendering the last successful snapshot when the app
  /// cannot reach weather or holiday providers.
  Future<void> updateHomeWidgets(WidgetSnapshot snapshot) {
    if (!_supportsAndroidNativeFeatures) return Future<void>.value();
    _widgetQueue = _widgetQueue.then((_) => _writeWidgetSnapshot(snapshot));
    return _widgetQueue;
  }

  Future<void> _writeWidgetSnapshot(WidgetSnapshot snapshot) async {
    try {
      final values = snapshot.sanitized().toMap();
      for (final entry in values.entries) {
        await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
      }
      for (final provider in const [
        'PourToujoursSmallWidget',
        'PourToujoursMediumWidget',
        'PourToujoursLargeWidget',
      ]) {
        await HomeWidget.updateWidget(androidName: provider);
      }
    } on MissingPluginException {
      debugPrint('Home widget plugin is not attached to this engine.');
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Home widget update failed safely: $error\n$stackTrace');
    } on Object catch (error, stackTrace) {
      debugPrint('Unexpected home widget update failure: $error\n$stackTrace');
    }
  }
}

enum NotificationUrgency { normal, urgent }

class NotificationPreferences {
  const NotificationPreferences({
    this.enabled = false,
    this.birthdays = true,
    this.events = true,
    this.callWindows = false,
    this.dstChanges = true,
    this.severeWeather = true,
    this.quietStartHour = 22,
    this.quietEndHour = 8,
    this.birthdayLeadDays = 1,
    this.minimumAlertSeverity = 2,
  });

  static const enabledKey = 'v1_notifications_enabled';
  static const storageKey = 'v1_notification_preferences';

  final bool enabled;
  final bool birthdays;
  final bool events;
  final bool callWindows;
  final bool dstChanges;
  final bool severeWeather;
  final int quietStartHour;
  final int quietEndHour;
  final int birthdayLeadDays;
  final int minimumAlertSeverity;

  bool isQuiet(tz.TZDateTime value) {
    final start = quietStartHour.clamp(0, 23);
    final end = quietEndHour.clamp(0, 23);
    final hour = value.hour;
    if (start == end) return false;
    if (start < end) return hour >= start && hour < end;
    return hour >= start || hour < end;
  }

  NotificationPreferences copyWith({
    bool? enabled,
    bool? birthdays,
    bool? events,
    bool? callWindows,
    bool? dstChanges,
    bool? severeWeather,
    int? quietStartHour,
    int? quietEndHour,
    int? birthdayLeadDays,
    int? minimumAlertSeverity,
  }) =>
      NotificationPreferences(
        enabled: enabled ?? this.enabled,
        birthdays: birthdays ?? this.birthdays,
        events: events ?? this.events,
        callWindows: callWindows ?? this.callWindows,
        dstChanges: dstChanges ?? this.dstChanges,
        severeWeather: severeWeather ?? this.severeWeather,
        quietStartHour: quietStartHour ?? this.quietStartHour,
        quietEndHour: quietEndHour ?? this.quietEndHour,
        birthdayLeadDays: birthdayLeadDays ?? this.birthdayLeadDays,
        minimumAlertSeverity:
            minimumAlertSeverity ?? this.minimumAlertSeverity,
      );

  Map<String, Object> toMap() => {
        'enabled': enabled,
        'birthdays': birthdays,
        'events': events,
        'callWindows': callWindows,
        'dstChanges': dstChanges,
        'severeWeather': severeWeather,
        'quietStartHour': quietStartHour.clamp(0, 23),
        'quietEndHour': quietEndHour.clamp(0, 23),
        'birthdayLeadDays': birthdayLeadDays.clamp(0, 30),
        'minimumAlertSeverity': minimumAlertSeverity.clamp(1, 5),
      };

  static NotificationPreferences fromMap(Map<String, Object?> map) =>
      NotificationPreferences(
        enabled: map['enabled'] as bool? ?? false,
        birthdays: map['birthdays'] as bool? ?? true,
        events: map['events'] as bool? ?? true,
        callWindows: map['callWindows'] as bool? ?? false,
        dstChanges: map['dstChanges'] as bool? ?? true,
        severeWeather: map['severeWeather'] as bool? ?? true,
        quietStartHour: (map['quietStartHour'] as num? ?? 22).toInt().clamp(0, 23),
        quietEndHour: (map['quietEndHour'] as num? ?? 8).toInt().clamp(0, 23),
        birthdayLeadDays:
            (map['birthdayLeadDays'] as num? ?? 1).toInt().clamp(0, 30),
        minimumAlertSeverity:
            (map['minimumAlertSeverity'] as num? ?? 2).toInt().clamp(1, 5),
      );

  static Future<NotificationPreferences> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null) return const NotificationPreferences();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const NotificationPreferences();
      }
      return fromMap(decoded);
    } on Object catch (error) {
      debugPrint('Notification preferences were invalid and reset: $error');
      return const NotificationPreferences();
    }
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(enabledKey, enabled);
      await prefs.setString(storageKey, jsonEncode(toMap()));
    } on Object catch (error) {
      debugPrint('Could not save notification preferences: $error');
    }
  }
}

class WidgetSnapshot {
  const WidgetSnapshot({
    required this.primaryLine,
    required this.secondaryLine,
    required this.citiesLine,
    required this.timelineLine,
    required this.nextEventLine,
    required this.alertLine,
    required this.updatedAt,
    this.isStale = false,
  });

  final String primaryLine;
  final String secondaryLine;
  final String citiesLine;
  final String timelineLine;
  final String nextEventLine;
  final String alertLine;
  final DateTime updatedAt;
  final bool isStale;

  WidgetSnapshot sanitized() => WidgetSnapshot(
        primaryLine: _clean(primaryLine, 72),
        secondaryLine: _clean(secondaryLine, 110),
        citiesLine: _clean(citiesLine, 180),
        timelineLine: _clean(timelineLine, 150),
        nextEventLine: _clean(nextEventLine, 110),
        alertLine: _clean(alertLine, 110),
        updatedAt: updatedAt,
        isStale: isStale,
      );

  Map<String, String> toMap() => {
        'pt_primary': primaryLine,
        'pt_secondary': secondaryLine,
        'pt_cities': citiesLine,
        'pt_timeline': timelineLine,
        'pt_next_event': nextEventLine,
        'pt_alert': alertLine,
        'pt_updated': updatedAt.toUtc().toIso8601String(),
        'pt_stale': isStale ? '1' : '0',
      };

  static String _clean(String value, int maximum) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return 'Open Pour Toujours';
    if (normalized.length <= maximum) return normalized;
    return '${normalized.substring(0, maximum - 1).trimRight()}…';
  }
}

/// Platform-neutral contract reserved for a future iOS WidgetKit extension.
/// The same keys are intentionally used by Android AppWidget storage.
abstract final class IosWidgetDataContract {
  static const schemaVersion = 1;
  static const keys = <String>[
    'pt_primary',
    'pt_secondary',
    'pt_cities',
    'pt_timeline',
    'pt_next_event',
    'pt_alert',
    'pt_updated',
    'pt_stale',
  ];
}
