import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    const android = AndroidInitializationSettings('@drawable/ic_pour_toujours');
    const settings = InitializationSettings(android: android);
    await notifications.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestNotificationPermission() async {
    await initialize();
    final android = notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  Future<bool> notificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(NotificationPreferences.enabledKey) ?? false;
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    String payload = 'pourtoujours://calendar',
    NotificationUrgency urgency = NotificationUrgency.normal,
  }) async {
    final preferences = await NotificationPreferences.load();
    if (!preferences.enabled || preferences.isQuiet(when)) return;
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
    await notifications.zonedSchedule(
      id,
      title,
      body,
      when,
      NotificationDetails(android: channel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancelReminder(int id) => notifications.cancel(id);

  Future<void> cancelAllReminders() => notifications.cancelAll();

  /// Writes one compact, offline-safe snapshot shared by all Android widgets.
  /// Native widgets keep rendering the last successful snapshot when the app
  /// cannot reach weather or holiday providers.
  Future<void> updateHomeWidgets(WidgetSnapshot snapshot) async {
    if (kIsWeb) return;
    final values = snapshot.toMap();
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
    final hour = value.hour;
    if (quietStartHour == quietEndHour) return false;
    if (quietStartHour < quietEndHour) {
      return hour >= quietStartHour && hour < quietEndHour;
    }
    return hour >= quietStartHour || hour < quietEndHour;
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
        'quietStartHour': quietStartHour,
        'quietEndHour': quietEndHour,
        'birthdayLeadDays': birthdayLeadDays,
        'minimumAlertSeverity': minimumAlertSeverity,
      };

  static NotificationPreferences fromMap(Map<String, Object?> map) =>
      NotificationPreferences(
        enabled: map['enabled'] as bool? ?? false,
        birthdays: map['birthdays'] as bool? ?? true,
        events: map['events'] as bool? ?? true,
        callWindows: map['callWindows'] as bool? ?? false,
        dstChanges: map['dstChanges'] as bool? ?? true,
        severeWeather: map['severeWeather'] as bool? ?? true,
        quietStartHour: map['quietStartHour'] as int? ?? 22,
        quietEndHour: map['quietEndHour'] as int? ?? 8,
        birthdayLeadDays: map['birthdayLeadDays'] as int? ?? 1,
        minimumAlertSeverity: map['minimumAlertSeverity'] as int? ?? 2,
      );

  static Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return const NotificationPreferences();
    try {
      return fromMap(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return const NotificationPreferences();
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, enabled);
    await prefs.setString(storageKey, jsonEncode(toMap()));
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
