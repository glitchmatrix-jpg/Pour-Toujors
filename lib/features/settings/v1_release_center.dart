import 'package:flutter/material.dart';

import '../../app/theme/pour_toujours_theme.dart';
import '../../core/release/v1_platform_services.dart';

class NotificationControlScreen extends StatefulWidget {
  const NotificationControlScreen({super.key});

  @override
  State<NotificationControlScreen> createState() =>
      _NotificationControlScreenState();
}

class _NotificationControlScreenState
    extends State<NotificationControlScreen> {
  NotificationPreferences? _preferences;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    NotificationPreferences.load().then((value) {
      if (mounted) setState(() => _preferences = value);
    });
  }

  Future<void> _update(NotificationPreferences next) async {
    setState(() {
      _preferences = next;
      _saving = true;
    });
    await next.save();
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _toggleGlobal(bool enabled) async {
    var next = _preferences!.copyWith(enabled: enabled);
    if (enabled) {
      final granted =
          await V1PlatformServices.instance.requestNotificationPermission();
      if (!granted) {
        next = next.copyWith(enabled: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notification permission was not granted. Pour Toujours will remain quiet.',
              ),
            ),
          );
        }
      }
    } else {
      await V1PlatformServices.instance.cancelAllReminders();
    }
    await _update(next);
  }

  @override
  Widget build(BuildContext context) {
    final p = _preferences;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: p == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                Text(
                  'Quiet by default',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Reminders are local, opt-in, and based on routines or events you choose. No activity or location is monitored.',
                  style: TextStyle(color: context.pt.secondaryText),
                ),
                const SizedBox(height: 20),
                Card(
                  child: SwitchListTile.adaptive(
                    value: p.enabled,
                    title: const Text('Allow notifications'),
                    subtitle: Text(
                      _saving
                          ? 'Saving…'
                          : 'Nothing is scheduled until this is enabled.',
                    ),
                    onChanged: _saving ? null : _toggleGlobal,
                  ),
                ),
                const SizedBox(height: 12),
                _Toggle(
                  title: 'Birthday reminders',
                  subtitle:
                      'Lead-time and local-midnight reminders for known birthdays.',
                  value: p.birthdays,
                  enabled: p.enabled,
                  onChanged: (value) => _update(p.copyWith(birthdays: value)),
                ),
                _Toggle(
                  title: 'Family events and planned calls',
                  subtitle: 'Only events saved inside Pour Toujours.',
                  value: p.events,
                  enabled: p.enabled,
                  onChanged: (value) => _update(p.copyWith(events: value)),
                ),
                _Toggle(
                  title: 'Good time to call',
                  subtitle:
                      'Occasional reminders when routine overlap is unusually comfortable.',
                  value: p.callWindows,
                  enabled: p.enabled,
                  onChanged: (value) =>
                      _update(p.copyWith(callWindows: value)),
                ),
                _Toggle(
                  title: 'Clock changes',
                  subtitle: 'Daylight-saving changes that alter family time gaps.',
                  value: p.dstChanges,
                  enabled: p.enabled,
                  onChanged: (value) => _update(p.copyWith(dstChanges: value)),
                ),
                _Toggle(
                  title: 'Severe weather',
                  subtitle:
                      'Prioritizes official warnings. It does not replace emergency services.',
                  value: p.severeWeather,
                  enabled: p.enabled,
                  onChanged: (value) =>
                      _update(p.copyWith(severeWeather: value)),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Quiet hours'),
                        subtitle: Text(
                          '${_hour(p.quietStartHour)} – ${_hour(p.quietEndHour)}',
                        ),
                      ),
                      RangeSlider(
                        min: 0,
                        max: 23,
                        divisions: 23,
                        labels: RangeLabels(
                          _hour(p.quietStartHour),
                          _hour(p.quietEndHour),
                        ),
                        values: RangeValues(
                          p.quietStartHour.toDouble(),
                          p.quietEndHour.toDouble(),
                        ),
                        onChanged: p.enabled
                            ? (value) => _update(
                                  p.copyWith(
                                    quietStartHour: value.start.round(),
                                    quietEndHour: value.end.round(),
                                  ),
                                )
                            : null,
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          'Urgent official alerts may still be shown prominently when enabled and allowed by Android.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _hour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Card(
        child: SwitchListTile.adaptive(
          value: value,
          title: Text(title),
          subtitle: Text(subtitle),
          onChanged: enabled ? onChanged : null,
        ),
      );
}

class PrivacyTrustScreen extends StatelessWidget {
  const PrivacyTrustScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        Icons.location_off_outlined,
        'No GPS or background location',
        'Pour Toujours uses the city assigned to each profile. It does not request precise location or follow anyone in the background.'
      ),
      (
        Icons.visibility_off_outlined,
        'No activity tracking',
        'The app does not read WhatsApp, calls, messages, motion, app usage, or live presence.'
      ),
      (
        Icons.schedule_outlined,
        'Availability is an estimate',
        'Statuses are calculated from local time and routines entered in the app. Every estimate should explain why it was produced.'
      ),
      (
        Icons.phone_android_outlined,
        'Identity and family data stay local',
        'The selected viewer, routines, events, reminder preferences, and manual contact history are stored on this device unless a future sync feature is explicitly added.'
      ),
      (
        Icons.cloud_outlined,
        'City-level public requests',
        'Weather, holidays, and official alerts may contact public providers using a city or country—not a person’s live coordinates.'
      ),
      (
        Icons.warning_amber_rounded,
        'Important limitations',
        'Routine estimates can be wrong. Weather data can be stale or unavailable. Official alerts should be confirmed with local authorities and never replace emergency instructions.'
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and trust')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(
            'Family awareness without surveillance',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Pour Toujours is designed to help a family understand time, weather, routines, and plans—not to observe one another.',
            style: TextStyle(color: context.pt.secondaryText),
          ),
          const SizedBox(height: 20),
          for (final item in items)
            Card(
              child: ListTile(
                leading: Icon(item.$1),
                title: Text(item.$2),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(item.$3),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Offline behavior: the app remains usable with locally stored family information and last-known public data. Stale information must retain its timestamp and be labeled as stale.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AttributionScreen extends StatelessWidget {
  const AttributionScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sources and licenses')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            ListTile(
              leading: Icon(Icons.cloud_outlined),
              title: Text('Open-Meteo'),
              subtitle: Text('City-level weather forecasts and observations.'),
            ),
            ListTile(
              leading: Icon(Icons.event_outlined),
              title: Text('Nager.Date'),
              subtitle: Text('Public national-holiday data where available.'),
            ),
            ListTile(
              leading: Icon(Icons.warning_amber_rounded),
              title: Text('Official weather authorities'),
              subtitle: Text(
                'Severe-weather alerts are labeled with their issuing source inside the app.',
              ),
            ),
            AboutListTile(
              icon: Icon(Icons.code_rounded),
              applicationName: 'Pour Toujours',
              applicationVersion: '1.0.0',
              applicationLegalese: 'Privacy-first family awareness.',
            ),
          ],
        ),
      );
}
