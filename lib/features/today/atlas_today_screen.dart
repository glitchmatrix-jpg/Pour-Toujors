import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/design/pt_components.dart';
import '../../app/theme/pour_toujours_theme.dart';
import '../../core/alerts/weather_alert_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/time/availability_engine.dart';
import '../../core/time/timezone_intelligence.dart';
import '../../core/weather/weather_models.dart';
import '../../data/family_seed.dart';
import '../navigation/detail_placeholders.dart';
import 'ambient_sky.dart';
import 'family_atlas.dart';

class AtlasTodayScreen extends StatefulWidget {
  const AtlasTodayScreen({
    super.key,
    required this.viewer,
    required this.snapshots,
    required this.weatherFutures,
    required this.alerts,
    required this.timezone,
    required this.onRefresh,
  });

  final FamilyMember viewer;
  final Map<String, AvailabilitySnapshot> snapshots;
  final Map<String, Future<WeatherBundle>> weatherFutures;
  final WeatherAlertService alerts;
  final TimezoneIntelligenceService timezone;
  final Future<void> Function() onRefresh;

  @override
  State<AtlasTodayScreen> createState() => _AtlasTodayScreenState();
}

class _AtlasTodayScreenState extends State<AtlasTodayScreen> {
  late Future<Map<String, WeatherBundle?>> _weather;
  late Future<List<FamilyWeatherAlert>> _officialAlerts;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant AtlasTodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherFutures != widget.weatherFutures) _bind();
  }

  void _bind() {
    _weather = Future.wait(
      cities.map((city) async {
        try {
          return MapEntry<String, WeatherBundle?>(
            city.id,
            await widget.weatherFutures[city.id]!,
          );
        } on Object {
          return MapEntry<String, WeatherBundle?>(city.id, null);
        }
      }),
    ).then(Map.fromEntries);
    _officialAlerts = widget.alerts.fetchOfficialForCity('hattiesburg');
  }

  Future<void> _refresh() async {
    await widget.onRefresh();
    if (!mounted) return;
    setState(_bind);
  }

  @override
  Widget build(BuildContext context) {
    final awake = widget.snapshots.values
        .where((snapshot) => snapshot.kind != AvailabilityKind.asleep)
        .length;
    final free = widget.snapshots.values
        .where((snapshot) => snapshot.kind == AvailabilityKind.likelyFree)
        .length;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<Map<String, WeatherBundle?>>(
        future: _weather,
        builder: (context, snapshot) {
          final weather = snapshot.data ?? const <String, WeatherBundle?>{};
          final daylight = weather.values
              .whereType<WeatherBundle>()
              .where((bundle) => bundle.current.isDay)
              .length;
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 112),
                sliver: SliverList.list(
                  children: [
                    _Header(viewer: widget.viewer, awake: awake, free: free),
                    const SizedBox(height: 18),
                    FutureBuilder<List<FamilyWeatherAlert>>(
                      future: _officialAlerts,
                      builder: (context, alerts) => _PulseStrip(
                        awake: awake,
                        free: free,
                        daylight: daylight,
                        advisories: _countAlerts(
                          weather,
                          alerts.data ?? const [],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        weather.isEmpty)
                      const PtLoadingSkeleton(height: 250)
                    else
                      FamilyAtlas(
                        viewer: widget.viewer,
                        snapshots: widget.snapshots,
                        weather: weather,
                        timezone: widget.timezone,
                        onCityTap: (city) => _openCity(
                          context,
                          city,
                          widget.viewer,
                          weather[city.id],
                        ),
                      ),
                    const SizedBox(height: 26),
                    const PtSectionHeader('City conditions'),
                    const SizedBox(height: 10),
                    _CityGrid(
                      viewer: widget.viewer,
                      snapshots: widget.snapshots,
                      weather: weather,
                      timezone: widget.timezone,
                      alerts: widget.alerts,
                    ),
                    const SizedBox(height: 26),
                    const PtSectionHeader('Shared day'),
                    const SizedBox(height: 6),
                    Text(
                      'Routine estimates in two-hour blocks. No live activity tracking.',
                      style: TextStyle(color: context.pt.secondaryText),
                    ),
                    const SizedBox(height: 11),
                    _SharedDay(viewer: widget.viewer),
                    const SizedBox(height: 26),
                    const PtSectionHeader('Important today'),
                    const SizedBox(height: 10),
                    FutureBuilder<List<FamilyWeatherAlert>>(
                      future: _officialAlerts,
                      builder: (context, alerts) => _ImportantToday(
                        weather: weather,
                        officialAlerts: alerts.data ?? const [],
                        service: widget.alerts,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const PtSectionHeader('Upcoming family moments'),
                    const SizedBox(height: 10),
                    const _UpcomingBirthdays(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _countAlerts(
    Map<String, WeatherBundle?> weather,
    List<FamilyWeatherAlert> official,
  ) {
    var count = official.length;
    for (final entry in weather.entries) {
      final bundle = entry.value;
      if (bundle != null) count += widget.alerts.derive(entry.key, bundle).length;
    }
    return count;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.viewer, required this.awake, required this.free});

  final FamilyMember viewer;
  final int awake;
  final int free;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMMM').format(DateTime.now()).toUpperCase(),
                style: TextStyle(
                  color: context.pt.secondaryText,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.35,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '$greeting, ${viewer.name}.',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '$awake likely awake · $free in a strong routine window',
                style: TextStyle(color: context.pt.secondaryText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(radius: 25, child: Text(viewer.initials)),
      ],
    );
  }
}

class _PulseStrip extends StatelessWidget {
  const _PulseStrip({
    required this.awake,
    required this.free,
    required this.daylight,
    required this.advisories,
  });

  final int awake;
  final int free;
  final int daylight;
  final int advisories;

  @override
  Widget build(BuildContext context) {
    final birthday = _nextBirthday();
    final items = [
      (Icons.wb_sunny_outlined, '$awake awake'),
      (Icons.chat_bubble_outline_rounded, '$free likely free'),
      (Icons.light_mode_outlined, '$daylight in daylight'),
      (Icons.cake_outlined, '${birthday.$1} in ${birthday.$2}d'),
      (
        advisories == 0
            ? Icons.verified_outlined
            : Icons.warning_amber_rounded,
        advisories == 0 ? 'No advisories' : '$advisories advisories',
      ),
    ];
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: context.pt.card,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: context.pt.outline),
            ),
            child: Row(
              children: [
                Icon(item.$1, size: 17, color: context.pt.accent),
                const SizedBox(width: 7),
                Text(
                  item.$2,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CityGrid extends StatelessWidget {
  const _CityGrid({
    required this.viewer,
    required this.snapshots,
    required this.weather,
    required this.timezone,
    required this.alerts,
  });

  final FamilyMember viewer;
  final Map<String, AvailabilitySnapshot> snapshots;
  final Map<String, WeatherBundle?> weather;
  final TimezoneIntelligenceService timezone;
  final WeatherAlertService alerts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final city in cities)
              SizedBox(
                width: width,
                child: _CityCard(
                  city: city,
                  viewer: viewer,
                  snapshots: snapshots,
                  bundle: weather[city.id],
                  timezone: timezone,
                  alerts: alerts,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CityCard extends StatelessWidget {
  const _CityCard({
    required this.city,
    required this.viewer,
    required this.snapshots,
    required this.bundle,
    required this.timezone,
    required this.alerts,
  });

  final FamilyCity city;
  final FamilyMember viewer;
  final Map<String, AvailabilitySnapshot> snapshots;
  final WeatherBundle? bundle;
  final TimezoneIntelligenceService timezone;
  final WeatherAlertService alerts;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context).value;
    final members = _members(city.id);
    final local = snapshots[members.first.name]!.localTime;
    final free = members
        .where(
          (member) => snapshots[member.name]!.kind == AvailabilityKind.likelyFree,
        )
        .length;
    final offset = timezone
        .snapshot(cityId: city.id, viewerCityId: viewer.cityId)
        .viewerDifference
        .inHours;
    final current = bundle?.current;
    final guidance = bundle == null
        ? 'Weather unavailable'
        : alerts.derive(city.id, bundle!).firstOrNull?.headline ??
            'No major disruption expected';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openCity(context, city, viewer, bundle),
        child: AmbientSky(
          weather: current ?? _offlineWeather(local),
          day: bundle?.daily.firstOrNull,
          height: 210,
          borderRadius: BorderRadius.circular(24),
          semanticLabel:
              '${city.name}, ${DateFormat('h:mm a').format(local)}, ${bundle?.condition ?? 'weather unavailable'}, $free likely free.',
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        city.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                  ],
                ),
                Text(
                  DateFormat(
                    settings.clockFormat == ClockFormat.twentyFourHour
                        ? 'HH:mm'
                        : 'h:mm a',
                  ).format(local),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const Spacer(),
                if (current != null)
                  Text(
                    settings.temperature(current.temperature),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                Text(
                  bundle?.condition ?? 'Offline',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 7),
                Text(
                  guidance,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const SizedBox(height: 7),
                Text(
                  '$free likely free · ${_offsetLabel(offset)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SharedDay extends StatelessWidget {
  const _SharedDay({required this.viewer});
  final FamilyMember viewer;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.now().toUtc();
    final rows = <(String, List<FamilyMember>)>[
      (viewer.name, [viewer]),
      for (final city in cities) (city.name, _members(city.id)),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.pt.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.pt.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 78),
              for (final label in const ['Now', '+4h', '+8h', '+12h', '+16h', '+20h'])
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.pt.secondaryText, fontSize: 9),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final row in rows) ...[
            SizedBox(
              height: 32,
              child: Row(
                children: [
                  SizedBox(
                    width: 78,
                    child: Text(
                      row.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                  for (var block = 0; block < 12; block++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.2),
                        child: _RoutineBlock(
                          instant: start.add(Duration(hours: block * 2)),
                          members: row.$2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 3),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _Legend(context.pt.asleep, 'Asleep'),
              _Legend(context.pt.working, 'Busy'),
              _Legend(context.pt.uncertain, 'Uncertain'),
              _Legend(context.pt.success, 'Likely free'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutineBlock extends StatelessWidget {
  const _RoutineBlock({required this.instant, required this.members});

  final DateTime instant;
  final List<FamilyMember> members;

  @override
  Widget build(BuildContext context) {
    final kinds = members
        .map(
          (member) => evaluateAvailability(
            member: member,
            city: _city(member.cityId),
            now: instant,
          ).kind,
        )
        .toList();
    final kind = _dominant(kinds);
    final color = _availabilityColor(context, kind);
    return Tooltip(
      message: '${DateFormat('EEE h a').format(instant.toLocal())}: ${_kindLabel(kind)}',
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: context.pt.secondaryText, fontSize: 9)),
      ],
    );
  }
}

class _ImportantToday extends StatelessWidget {
  const _ImportantToday({
    required this.weather,
    required this.officialAlerts,
    required this.service,
  });

  final Map<String, WeatherBundle?> weather;
  final List<FamilyWeatherAlert> officialAlerts;
  final WeatherAlertService service;

  @override
  Widget build(BuildContext context) {
    final alerts = <FamilyWeatherAlert>[...officialAlerts];
    for (final entry in weather.entries) {
      final bundle = entry.value;
      if (bundle != null) alerts.addAll(service.derive(entry.key, bundle));
    }
    final birthday = _nextBirthday();
    return Material(
      color: context.pt.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: context.pt.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (alerts.isEmpty)
            const ListTile(
              leading: Icon(Icons.verified_outlined),
              title: Text('No important weather alert'),
              subtitle: Text('No major disruption needs attention right now.'),
            )
          else
            for (final alert in alerts.take(2))
              ListTile(
                onTap: () => Navigator.pushNamed(
                  context,
                  PourToujoursRouteNames.alert,
                  arguments: DetailRouteArgs(
                    title: alert.event,
                    subtitle: alert.headline,
                    payload: alert,
                  ),
                ),
                leading: Icon(Icons.warning_amber_rounded, color: context.pt.warning),
                title: Text(
                  alert.source == WeatherAlertSource.official
                      ? 'Official weather alert'
                      : 'Forecast guidance',
                ),
                subtitle: Text(alert.headline),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
          const Divider(height: 1),
          ListTile(
            onTap: () => Navigator.pushNamed(
              context,
              PourToujoursRouteNames.birthday,
              arguments: DetailRouteArgs(
                title: '${birthday.$1}’s birthday',
                subtitle: birthday.$2 == 0 ? 'Today' : 'In ${birthday.$2} days',
              ),
            ),
            leading: Icon(Icons.cake_outlined, color: context.pt.birthday),
            title: Text('${birthday.$1} · next birthday'),
            subtitle: Text(birthday.$2 == 0 ? 'Today' : 'In ${birthday.$2} days'),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _UpcomingBirthdays extends StatelessWidget {
  const _UpcomingBirthdays();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final birthdays = [...familyBirthdays]
      ..sort((a, b) => a.nextOccurrence(now).compareTo(b.nextOccurrence(now)));
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: math.min(8, birthdays.length),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final birthday = birthdays[index];
          final next = birthday.nextOccurrence(now);
          final days = next.difference(DateTime(now.year, now.month, now.day)).inDays;
          return Material(
            color: context.pt.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(21),
              side: BorderSide(color: context.pt.outline),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(21),
              onTap: () => Navigator.pushNamed(
                context,
                PourToujoursRouteNames.birthday,
                arguments: DetailRouteArgs(
                  title: '${birthday.name}’s birthday',
                  subtitle: DateFormat('d MMMM').format(next),
                ),
              ),
              child: SizedBox(
                width: 146,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.cake_outlined, color: context.pt.birthday),
                      const Spacer(),
                      Text(birthday.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(DateFormat('d MMMM').format(next), style: TextStyle(color: context.pt.secondaryText)),
                      Text(
                        days == 0 ? 'Today' : 'In $days days',
                        style: TextStyle(color: context.pt.success, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

void _openCity(
  BuildContext context,
  FamilyCity city,
  FamilyMember viewer,
  WeatherBundle? bundle,
) {
  Navigator.pushNamed(
    context,
    PourToujoursRouteNames.city,
    arguments: DetailRouteArgs(
      title: city.name,
      subtitle:
          '${_members(city.id).length} family members · ${bundle?.condition ?? 'Weather unavailable'}',
      payload: city.id,
      viewerName: viewer.name,
    ),
  );
}

FamilyCity _city(String id) => cities.firstWhere((city) => city.id == id);

List<FamilyMember> _members(String cityId) =>
    familyMembers.where((member) => member.cityId == cityId).toList();

String _offsetLabel(int hours) => hours == 0
    ? 'same time'
    : '${hours.abs()}h ${hours.isNegative ? 'behind' : 'ahead'}';

AvailabilityKind _dominant(List<AvailabilityKind> kinds) {
  if (kinds.isEmpty) return AvailabilityKind.unknown;
  final counts = <AvailabilityKind, int>{};
  for (final kind in kinds) {
    counts[kind] = (counts[kind] ?? 0) + 1;
  }
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

Color _availabilityColor(BuildContext context, AvailabilityKind kind) =>
    switch (kind) {
      AvailabilityKind.likelyFree => context.pt.success,
      AvailabilityKind.maybeFree => context.pt.uncertain,
      AvailabilityKind.working => context.pt.working,
      AvailabilityKind.asleep => context.pt.asleep,
      AvailabilityKind.unknown => context.pt.unavailable,
    };

String _kindLabel(AvailabilityKind kind) => switch (kind) {
      AvailabilityKind.likelyFree => 'likely free',
      AvailabilityKind.maybeFree => 'may be free',
      AvailabilityKind.working => 'busy',
      AvailabilityKind.asleep => 'asleep',
      AvailabilityKind.unknown => 'uncertain',
    };

(String, int) _nextBirthday() {
  final now = DateTime.now();
  final birthdays = [...familyBirthdays]
    ..sort((a, b) => a.nextOccurrence(now).compareTo(b.nextOccurrence(now)));
  final next = birthdays.first.nextOccurrence(now);
  return (
    birthdays.first.name,
    next.difference(DateTime(now.year, now.month, now.day)).inDays,
  );
}

CurrentWeather _offlineWeather(DateTime local) => CurrentWeather(
      time: local,
      temperature: 0,
      feelsLike: 0,
      weatherCode: 3,
      isDay: local.hour >= 6 && local.hour < 18,
      precipitation: 0,
      rainChance: 0,
      windSpeed: 0,
      windGusts: 0,
      windDirection: 0,
      humidity: 0,
      visibility: 10000,
      uvIndex: 0,
      cloudCover: 80,
      surfacePressure: 1013,
    );

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
