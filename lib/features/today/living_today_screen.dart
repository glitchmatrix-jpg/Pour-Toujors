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

class LivingTodayScreen extends StatefulWidget {
  const LivingTodayScreen({
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
  State<LivingTodayScreen> createState() => _LivingTodayScreenState();
}

class _LivingTodayScreenState extends State<LivingTodayScreen> {
  late Future<Map<String, WeatherBundle?>> _allWeather;
  late Future<List<FamilyWeatherAlert>> _officialAlerts;
  late Set<String> _selectedPeople;

  @override
  void initState() {
    super.initState();
    _selectedPeople = familyMembers.map((member) => member.name).toSet();
    _bindFutures();
  }

  @override
  void didUpdateWidget(covariant LivingTodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherFutures != widget.weatherFutures) _bindFutures();
  }

  void _bindFutures() {
    _allWeather = Future.wait(
      cities.map((city) async {
        try {
          return MapEntry<String, WeatherBundle?>(
            city.id,
            await widget.weatherFutures[city.id]!,
          );
        } catch (_) {
          return MapEntry<String, WeatherBundle?>(city.id, null);
        }
      }),
    ).then((entries) => Map.fromEntries(entries));
    _officialAlerts = widget.alerts.fetchOfficialForCity('hattiesburg');
  }

  Future<void> _refresh() async {
    await widget.onRefresh();
    if (!mounted) return;
    setState(_bindFutures);
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context).value;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<Map<String, WeatherBundle?>>(
        future: _allWeather,
        builder: (context, weatherSnapshot) {
          final weather = weatherSnapshot.data ?? const <String, WeatherBundle?>{};
          final awake = widget.snapshots.values
              .where((item) => item.kind != AvailabilityKind.asleep)
              .length;
          final free = widget.snapshots.values
              .where((item) => item.kind == AvailabilityKind.likelyFree)
              .length;
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
                    _LivingHeader(
                      viewer: widget.viewer,
                      awake: awake,
                      free: free,
                    ),
                    const SizedBox(height: 18),
                    if (weatherSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        weather.isEmpty)
                      const PtLoadingSkeleton(height: 360)
                    else
                      _LivingFamilyWorld(
                        viewer: widget.viewer,
                        snapshots: widget.snapshots,
                        weather: weather,
                        settings: settings,
                        timezone: widget.timezone,
                      ),
                    const SizedBox(height: 18),
                    FutureBuilder<List<FamilyWeatherAlert>>(
                      future: _officialAlerts,
                      builder: (context, alertSnapshot) {
                        final official = alertSnapshot.data ?? const [];
                        return _FamilyPulse(
                          viewer: widget.viewer,
                          awake: awake,
                          free: free,
                          daylightCities: daylight,
                          weather: weather,
                          officialAlerts: official,
                          timezone: widget.timezone,
                          onPlanner: _openPlanner,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    PtSectionHeader(
                      'Shared time',
                      action: TextButton(
                        onPressed: _openPlanner,
                        child: const Text('Open planner'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SharedTimeRibbon(
                      viewer: widget.viewer,
                      selectedPeople: _selectedPeople,
                      onTapOverlap: _openPlanner,
                    ),
                    const SizedBox(height: 24),
                    const PtSectionHeader('City conditions'),
                    const SizedBox(height: 10),
                    _CityConditionGrid(
                      viewer: widget.viewer,
                      snapshots: widget.snapshots,
                      weather: weather,
                      settings: settings,
                      timezone: widget.timezone,
                      alerts: widget.alerts,
                    ),
                    const SizedBox(height: 24),
                    PtSectionHeader(
                      'Best connection window',
                      action: TextButton(
                        onPressed: _choosePeople,
                        child: Text('${_selectedPeople.length} selected'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ConnectionWindowCard(
                      viewer: widget.viewer,
                      selectedPeople: _selectedPeople,
                      weather: weather,
                      onTap: _openPlanner,
                    ),
                    const SizedBox(height: 24),
                    const PtSectionHeader('Important today'),
                    const SizedBox(height: 10),
                    FutureBuilder<List<FamilyWeatherAlert>>(
                      future: _officialAlerts,
                      builder: (context, snapshot) => _ImportantToday(
                        viewer: widget.viewer,
                        weather: weather,
                        officialAlerts: snapshot.data ?? const [],
                        alerts: widget.alerts,
                        timezone: widget.timezone,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const PtSectionHeader('Upcoming family moments'),
                    const SizedBox(height: 10),
                    const _UpcomingMoments(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openPlanner() {
    Navigator.pushNamed(
      context,
      PourToujoursRouteNames.overlapPlanner,
      arguments: DetailRouteArgs(
        title: 'Family overlap planner',
        subtitle:
            'Routine-based estimates for ${_selectedPeople.length} selected people. No live activity or location tracking.',
        payload: _selectedPeople.toList(),
      ),
    );
  }

  Future<void> _choosePeople() async {
    final draft = {..._selectedPeople};
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who should this window include?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'The recommendation uses routines only. It never claims someone is currently available.',
                  style: TextStyle(color: context.pt.secondaryText),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final member in familyMembers)
                        CheckboxListTile(
                          value: draft.contains(member.name),
                          title: Text(member.name),
                          subtitle: Text(
                            cities
                                .firstWhere((city) => city.id == member.cityId)
                                .name,
                          ),
                          onChanged: (value) => setSheetState(() {
                            if (value ?? false) {
                              draft.add(member.name);
                            } else if (draft.length > 1) {
                              draft.remove(member.name);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, draft),
                    child: const Text('Recalculate window'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedPeople = result);
    }
  }
}

class _LivingHeader extends StatelessWidget {
  const _LivingHeader({
    required this.viewer,
    required this.awake,
    required this.free,
  });

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
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '$greeting, ${viewer.name}.',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
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

class _LivingFamilyWorld extends StatelessWidget {
  const _LivingFamilyWorld({
    required this.viewer,
    required this.snapshots,
    required this.weather,
    required this.settings,
    required this.timezone,
  });

  final FamilyMember viewer;
  final Map<String, AvailabilitySnapshot> snapshots;
  final Map<String, WeatherBundle?> weather;
  final AppSettings settings;
  final TimezoneIntelligenceService timezone;

  @override
  Widget build(BuildContext context) {
    final fallback = weather.values.whereType<WeatherBundle>().firstOrNull;
    final current = fallback?.current ?? _neutralWeather();
    final day = fallback?.daily.firstOrNull;
    return AmbientSky(
      weather: current,
      day: day,
      height: 374,
      semanticLabel:
          'Interactive family world showing Karachi, Chiba, Dublin, and Hattiesburg. City positions are illustrative and do not represent live location.',
      child: Stack(
        children: [
          const Positioned(
            left: 20,
            top: 18,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIVING FAMILY WORLD',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Four places, one shared day.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            top: 76,
            child: CustomPaint(
              painter: _WorldConnectionPainter(
                color: Colors.white.withValues(alpha: .24),
              ),
            ),
          ),
          for (final placement in _cityPlacements)
            Align(
              alignment: placement.alignment,
              child: Padding(
                padding: const EdgeInsets.only(top: 58),
                child: _WorldCityNode(
                  city: cities.firstWhere((city) => city.id == placement.cityId),
                  snapshot: snapshots[familyMembers
                      .firstWhere((member) => member.cityId == placement.cityId)
                      .name]!,
                  bundle: weather[placement.cityId],
                  viewerCityId: viewer.cityId,
                  settings: settings,
                  timezone: timezone,
                ),
              ),
            ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 14,
            child: Semantics(
              label:
                  'Routine estimates only. The map does not use GPS, background location, or phone activity.',
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 15, color: Colors.white70),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Illustrative world · routines, local time, and weather — never live location',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  CurrentWeather _neutralWeather() => CurrentWeather(
        time: DateTime.now(),
        temperature: 0,
        feelsLike: 0,
        weatherCode: 2,
        isDay: true,
        precipitation: 0,
        rainChance: 0,
        windSpeed: 0,
        windGusts: 0,
        windDirection: 0,
        humidity: 0,
        visibility: 10000,
        uvIndex: 0,
        cloudCover: 40,
        surfacePressure: 1013,
      );
}

class _WorldCityNode extends StatelessWidget {
  const _WorldCityNode({
    required this.city,
    required this.snapshot,
    required this.bundle,
    required this.viewerCityId,
    required this.settings,
    required this.timezone,
  });

  final FamilyCity city;
  final AvailabilitySnapshot snapshot;
  final WeatherBundle? bundle;
  final String viewerCityId;
  final AppSettings settings;
  final TimezoneIntelligenceService timezone;

  @override
  Widget build(BuildContext context) {
    final members = familyMembers.where((member) => member.cityId == city.id);
    final free = members
        .where(
          (member) => snapshotForMember(member).kind ==
              AvailabilityKind.likelyFree,
        )
        .length;
    final intelligence = timezone.snapshot(
      cityId: city.id,
      viewerCityId: viewerCityId,
    );
    final clock = settings.clockFormat == ClockFormat.twentyFourHour
        ? DateFormat('HH:mm')
        : DateFormat('h:mm a');
    final isDay = bundle?.current.isDay ??
        (snapshot.localTime.hour >= 6 && snapshot.localTime.hour < 18);
    return Semantics(
      button: true,
      label:
          '${city.name}, ${clock.format(snapshot.localTime)}, ${isDay ? 'daylight' : 'night'}, ${members.length} family members, $free usually free. ${bundle?.condition ?? 'Weather unavailable'}.',
      child: InkResponse(
        onTap: () => Navigator.pushNamed(
          context,
          PourToujoursRouteNames.city,
          arguments: DetailRouteArgs(
            title: city.name,
            subtitle:
                '${members.length} family members · ${bundle?.condition ?? 'Weather unavailable'}',
            payload: city.id,
          ),
        ),
        radius: 62,
        child: SizedBox(
          width: 116,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .52),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDay
                                  ? const Color(0xFFFFD484)
                                  : context.pt.globeAccent)
                              .withValues(alpha: .34),
                          blurRadius: free > 0 ? 24 : 12,
                          spreadRadius: free > 0 ? 3 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _weatherIcon(bundle?.current.weatherCode, isDay),
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: isDay
                            ? const Color(0xFFFFD36C)
                            : const Color(0xFFBCC8FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                city.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                clock.format(snapshot.localTime),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                '$free free · ${intelligence.viewerDifference.inHours == 0 ? 'same time' : '${intelligence.viewerDifference.inHours.abs()}h ${intelligence.viewerDifference.isNegative ? 'behind' : 'ahead'}'}',
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(color: Colors.white60, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AvailabilitySnapshot snapshotForMember(FamilyMember member) =>
      evaluateAvailability(
        member: member,
        city: cities.firstWhere((city) => city.id == member.cityId),
      );
}

class _WorldConnectionPainter extends CustomPainter {
  const _WorldConnectionPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final points = [
      Offset(size.width * .22, size.height * .32),
      Offset(size.width * .76, size.height * .24),
      Offset(size.width * .28, size.height * .69),
      Offset(size.width * .73, size.height * .72),
    ];
    for (var i = 0; i < points.length; i++) {
      final next = points[(i + 1) % points.length];
      final path = Path()
        ..moveTo(points[i].dx, points[i].dy)
        ..quadraticBezierTo(
          size.width * .5,
          size.height * (.4 + (i.isEven ? -.15 : .15)),
          next.dx,
          next.dy,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WorldConnectionPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _FamilyPulse extends StatelessWidget {
  const _FamilyPulse({
    required this.viewer,
    required this.awake,
    required this.free,
    required this.daylightCities,
    required this.weather,
    required this.officialAlerts,
    required this.timezone,
    required this.onPlanner,
  });

  final FamilyMember viewer;
  final int awake;
  final int free;
  final int daylightCities;
  final Map<String, WeatherBundle?> weather;
  final List<FamilyWeatherAlert> officialAlerts;
  final TimezoneIntelligenceService timezone;
  final VoidCallback onPlanner;

  @override
  Widget build(BuildContext context) {
    final birthday = _nextBirthday();
    final clockChange = cities
        .map(
          (city) => MapEntry(
            city,
            timezone.snapshot(
              cityId: city.id,
              viewerCityId: viewer.cityId,
            ).nextChange,
          ),
        )
        .where((entry) => entry.value != null)
        .toList()
      ..sort((a, b) => a.value!.at.compareTo(b.value!.at));
    final alertCount = officialAlerts.length +
        weather.entries.fold<int>(
          0,
          (total, entry) => total +
              (entry.value == null
                  ? 0
                  : WeatherAlertService().derive(entry.key, entry.value!).length),
        );
    final items = [
      _PulseItem(Icons.wb_sunny_outlined, '$awake awake', 'Routine estimate',
          () {}),
      _PulseItem(Icons.call_outlined, '$free usually free', 'Strong windows',
          onPlanner),
      _PulseItem(Icons.light_mode_outlined, '$daylightCities in daylight',
          'Across four cities', () {}),
      _PulseItem(Icons.cake_outlined, birthday.$1, birthday.$2, () {
        Navigator.pushNamed(
          context,
          PourToujoursRouteNames.birthday,
          arguments: DetailRouteArgs(title: birthday.$1, subtitle: birthday.$2),
        );
      }),
      _PulseItem(
        Icons.warning_amber_rounded,
        alertCount == 0 ? 'No major alerts' : '$alertCount advisories',
        officialAlerts.isEmpty ? 'Forecast guidance' : 'Includes official alert',
        () {
          Navigator.pushNamed(
            context,
            PourToujoursRouteNames.alert,
            arguments: DetailRouteArgs(
              title: 'Family weather advisories',
              subtitle: '$alertCount currently relevant items',
            ),
          );
        },
      ),
      _PulseItem(
        Icons.more_time_rounded,
        clockChange.isEmpty
            ? 'No clock change soon'
            : '${clockChange.first.key.name} changes clocks',
        clockChange.isEmpty
            ? 'Karachi and Chiba stay fixed'
            : DateFormat('d MMM').format(clockChange.first.value!.at),
        () {},
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
      decoration: BoxDecoration(
        color: context.pt.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.pt.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Family pulse',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                'RIGHT NOW',
                style: TextStyle(
                  color: context.pt.secondaryText,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const VerticalDivider(width: 18),
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 132,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(item.icon, size: 18, color: context.pt.accent),
                          const Spacer(),
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.pt.secondaryText,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  (String, String) _nextBirthday() {
    final now = DateTime.now();
    final values = [...familyBirthdays]
      ..sort(
        (a, b) =>
            a.nextOccurrence(now).compareTo(b.nextOccurrence(now)),
      );
    final next = values.first;
    final date = next.nextOccurrence(now);
    final days = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    return ('${next.name}’s birthday', days == 0 ? 'Today' : 'In $days days');
  }
}

class _PulseItem {
  const _PulseItem(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _SharedTimeRibbon extends StatelessWidget {
  const _SharedTimeRibbon({
    required this.viewer,
    required this.selectedPeople,
    required this.onTapOverlap,
  });

  final FamilyMember viewer;
  final Set<String> selectedPeople;
  final VoidCallback onTapOverlap;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.now().toUtc().subtract(const Duration(hours: 2));
    const hourWidth = 46.0;
    final rows = <(String, List<FamilyMember>)>[
      (viewer.name, [viewer]),
      for (final city in cities)
        (
          city.name,
          familyMembers.where((member) => member.cityId == city.id).toList(),
        ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: context.pt.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.pt.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Next 24 hours',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  'Scroll →',
                  style: TextStyle(
                    color: context.pt.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 232,
            child: Row(
              children: [
                SizedBox(
                  width: 82,
                  child: Column(
                    children: [
                      const SizedBox(height: 31),
                      for (final row in rows)
                        SizedBox(
                          height: 38,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                row.$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: hourWidth * 24,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 31,
                            child: Row(
                              children: [
                                for (var hour = 0; hour < 24; hour++)
                                  SizedBox(
                                    width: hourWidth,
                                    child: Text(
                                      DateFormat('ha').format(
                                        start.add(Duration(hours: hour)),
                                      ),
                                      style: TextStyle(
                                        color: context.pt.secondaryText,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          for (final row in rows)
                            SizedBox(
                              height: 38,
                              child: Row(
                                children: [
                                  for (var hour = 0; hour < 24; hour++)
                                    _TimelineCell(
                                      width: hourWidth,
                                      instant: start.add(Duration(hours: hour)),
                                      members: row.$2,
                                      selectedPeople: selectedPeople,
                                      onTap: onTapOverlap,
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Text(
              'Bands are cautious routine estimates, not live activity. Bright borders mark stronger overlap for the selected people.',
              style: TextStyle(color: context.pt.secondaryText, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCell extends StatelessWidget {
  const _TimelineCell({
    required this.width,
    required this.instant,
    required this.members,
    required this.selectedPeople,
    required this.onTap,
  });

  final double width;
  final DateTime instant;
  final List<FamilyMember> members;
  final Set<String> selectedPeople;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final snapshots = [
      for (final member in members)
        evaluateAvailability(
          member: member,
          city: cities.firstWhere((city) => city.id == member.cityId),
          now: instant,
        ),
    ];
    final kind = _dominantKind(snapshots.map((item) => item.kind));
    final selected = familyMembers
        .where((member) => selectedPeople.contains(member.name))
        .map(
          (member) => evaluateAvailability(
            member: member,
            city: cities.firstWhere((city) => city.id == member.cityId),
            now: instant,
          ).kind,
        );
    final score = selected.isEmpty
        ? 0.0
        : selected.map(_availabilityScore).reduce((a, b) => a + b) /
            selected.length;
    final color = _timelineColor(context, kind);
    return Semantics(
      button: score >= .6,
      label:
          '${DateFormat('EEEE h a').format(instant.toLocal())}: ${_kindLabel(kind)}. Family overlap score ${(score * 100).round()} percent.',
      child: GestureDetector(
        onTap: score >= .6 ? onTap : null,
        child: Container(
          width: width,
          margin: const EdgeInsets.fromLTRB(1, 3, 1, 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(7),
            border: score >= .72
                ? Border.all(color: context.pt.accent, width: 2)
                : score >= .55
                    ? Border.all(
                        color: context.pt.accent.withValues(alpha: .5),
                      )
                    : null,
          ),
        ),
      ),
    );
  }
}

class _CityConditionGrid extends StatelessWidget {
  const _CityConditionGrid({
    required this.viewer,
    required this.snapshots,
    required this.weather,
    required this.settings,
    required this.timezone,
    required this.alerts,
  });

  final FamilyMember viewer;
  final Map<String, AvailabilitySnapshot> snapshots;
  final Map<String, WeatherBundle?> weather;
  final AppSettings settings;
  final TimezoneIntelligenceService timezone;
  final WeatherAlertService alerts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        final spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final city in cities)
              SizedBox(
                width: width,
                child: _CompactCityCard(
                  city: city,
                  viewer: viewer,
                  snapshots: snapshots,
                  bundle: weather[city.id],
                  settings: settings,
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

class _CompactCityCard extends StatelessWidget {
  const _CompactCityCard({
    required this.city,
    required this.viewer,
    required this.snapshots,
    required this.bundle,
    required this.settings,
    required this.timezone,
    required this.alerts,
  });

  final FamilyCity city;
  final FamilyMember viewer;
  final Map<String, AvailabilitySnapshot> snapshots;
  final WeatherBundle? bundle;
  final AppSettings settings;
  final TimezoneIntelligenceService timezone;
  final WeatherAlertService alerts;

  @override
  Widget build(BuildContext context) {
    final members = familyMembers.where((member) => member.cityId == city.id);
    final representative = members.first;
    final local = snapshots[representative.name]!.localTime;
    final free = members
        .where(
          (member) => snapshots[member.name]!.kind ==
              AvailabilityKind.likelyFree,
        )
        .length;
    final difference = timezone
        .snapshot(cityId: city.id, viewerCityId: viewer.cityId)
        .viewerDifference
        .inHours;
    final practical = bundle == null
        ? 'Weather unavailable'
        : alerts.derive(city.id, bundle!).firstOrNull?.headline ??
            'No major disruption expected';
    final current = bundle?.current;
    final day = bundle?.daily.firstOrNull;
    final sky = current ?? _offlineSky(local);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.pushNamed(
          context,
          PourToujoursRouteNames.city,
          arguments: DetailRouteArgs(
            title: city.name,
            subtitle:
                '${members.length} family members · ${bundle?.condition ?? 'Weather unavailable'}',
            payload: city.id,
          ),
        ),
        child: AmbientSky(
          weather: sky,
          day: day,
          height: 206,
          borderRadius: BorderRadius.circular(24),
          semanticLabel:
              '${city.name}, ${DateFormat('h:mm a').format(local)}, ${bundle?.condition ?? 'weather unavailable'}, $free people usually free.',
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white70),
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
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                Text(
                  bundle?.condition ?? 'Offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  practical,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const SizedBox(height: 8),
                Text(
                  '$free usually free · ${difference == 0 ? 'same time' : '${difference.abs()}h ${difference.isNegative ? 'behind' : 'ahead'}'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  CurrentWeather _offlineSky(DateTime local) => CurrentWeather(
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
}

class _ConnectionWindowCard extends StatelessWidget {
  const _ConnectionWindowCard({
    required this.viewer,
    required this.selectedPeople,
    required this.weather,
    required this.onTap,
  });

  final FamilyMember viewer;
  final Set<String> selectedPeople;
  final Map<String, WeatherBundle?> weather;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final window = _bestWindow(selectedPeople);
    final viewerCity = cities.firstWhere((city) => city.id == viewer.cityId);
    final viewerLocal = evaluateAvailability(
      member: viewer,
      city: viewerCity,
      now: window.start,
    ).localTime;
    final cityTimes = [
      for (final city in cities)
        (
          city,
          evaluateAvailability(
            member: familyMembers.firstWhere(
              (member) => member.cityId == city.id,
            ),
            city: city,
            now: window.start,
          ).localTime,
        ),
    ];
    final conflicts = weather.entries
        .where(
          (entry) => entry.value != null &&
              WeatherAlertService().derive(entry.key, entry.value!).any(
                    (alert) => alert.severity == WeatherAlertSeverity.severe ||
                        alert.severity == WeatherAlertSeverity.extreme,
                  ),
        )
        .length;
    return Material(
      color: context.pt.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: context.pt.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: context.pt.accent.withValues(alpha: .13),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.call_rounded, color: context.pt.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _relativeDay(window.start, viewerLocal),
                          style: TextStyle(
                            color: context.pt.secondaryText,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${DateFormat('h:mm').format(viewerLocal)}–${DateFormat('h:mm a').format(viewerLocal.add(window.duration))}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  _ComfortRing(score: window.score),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                window.reason,
                style: TextStyle(color: context.pt.secondaryText),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in cityTimes)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: context.pt.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${item.$1.name} ${DateFormat('h:mm a').format(item.$2)}${item.$2.hour < 6 || item.$2.hour >= 23 ? ' · late' : ''}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Icon(
                    conflicts == 0
                        ? Icons.check_circle_outline_rounded
                        : Icons.warning_amber_rounded,
                    size: 17,
                    color: conflicts == 0
                        ? context.pt.success
                        : context.pt.warning,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      conflicts == 0
                          ? 'No severe forecast conflict detected for this preview.'
                          : '$conflicts city conditions may make this window less comfortable.',
                      style: TextStyle(
                        color: context.pt.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeDay(DateTime instant, DateTime viewerLocal) {
    final now = DateTime.now();
    final localNow = evaluateAvailability(
      member: viewer,
      city: cities.firstWhere((city) => city.id == viewer.cityId),
      now: now,
    ).localTime;
    final dayDifference = DateTime(
      viewerLocal.year,
      viewerLocal.month,
      viewerLocal.day,
    ).difference(
      DateTime(localNow.year, localNow.month, localNow.day),
    ).inDays;
    if (dayDifference == 0) return 'TODAY · YOUR TIME';
    if (dayDifference == 1) return 'TOMORROW · YOUR TIME';
    return '${DateFormat('EEEE').format(viewerLocal).toUpperCase()} · YOUR TIME';
  }
}

class _ComfortRing extends StatelessWidget {
  const _ComfortRing({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Comfort score ${(score * 100).round()} percent',
      child: SizedBox(
        width: 54,
        height: 54,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: score,
              strokeWidth: 5,
              backgroundColor: context.pt.outline,
            ),
            Text(
              '${(score * 100).round()}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportantToday extends StatelessWidget {
  const _ImportantToday({
    required this.viewer,
    required this.weather,
    required this.officialAlerts,
    required this.alerts,
    required this.timezone,
  });

  final FamilyMember viewer;
  final Map<String, WeatherBundle?> weather;
  final List<FamilyWeatherAlert> officialAlerts;
  final WeatherAlertService alerts;
  final TimezoneIntelligenceService timezone;

  @override
  Widget build(BuildContext context) {
    final items = <_ImportantItem>[];
    for (final alert in officialAlerts) {
      items.add(
        _ImportantItem(
          priority: 0,
          icon: Icons.warning_rounded,
          color: context.pt.warning,
          eyebrow: 'OFFICIAL WEATHER ALERT',
          title: alert.headline,
          subtitle: alert.instruction,
          onTap: () => Navigator.pushNamed(
            context,
            PourToujoursRouteNames.alert,
            arguments: DetailRouteArgs(
              title: alert.event,
              subtitle: alert.headline,
              payload: alert,
            ),
          ),
        ),
      );
    }
    for (final entry in weather.entries) {
      final bundle = entry.value;
      if (bundle == null) continue;
      for (final alert in alerts.derive(entry.key, bundle).take(1)) {
        final city = cities.firstWhere((city) => city.id == entry.key);
        items.add(
          _ImportantItem(
            priority: alert.severity.index + 2,
            icon: Icons.cloud_outlined,
            color: context.pt.warning,
            eyebrow: 'APP-GENERATED GUIDANCE · ${city.name.toUpperCase()}',
            title: alert.headline,
            subtitle: alert.instruction,
            onTap: () => Navigator.pushNamed(
              context,
              PourToujoursRouteNames.alert,
              arguments: DetailRouteArgs(
                title: alert.event,
                subtitle: alert.headline,
                payload: alert,
              ),
            ),
          ),
        );
      }
    }
    final changes = [
      for (final city in cities)
        (
          city,
          timezone.snapshot(
            cityId: city.id,
            viewerCityId: viewer.cityId,
          ).nextChange,
        ),
    ].where((item) => item.$2 != null).toList()
      ..sort((a, b) => a.$2!.at.compareTo(b.$2!.at));
    if (changes.isNotEmpty &&
        changes.first.$2!.at.difference(DateTime.now().toUtc()).inDays <= 14) {
      final change = changes.first;
      items.add(
        _ImportantItem(
          priority: 3,
          icon: Icons.more_time_rounded,
          color: context.pt.accent,
          eyebrow: 'CLOCK CHANGE',
          title: timezone.describeChange(change.$2!, change.$1.name),
          subtitle: 'The time difference across the family will change.',
          onTap: () {},
        ),
      );
    }
    final birthday = _nearestBirthday();
    if (birthday.$3 <= 14) {
      items.add(
        _ImportantItem(
          priority: 4,
          icon: Icons.cake_rounded,
          color: context.pt.birthday,
          eyebrow: birthday.$3 == 0 ? 'BIRTHDAY TODAY' : 'UPCOMING BIRTHDAY',
          title: '${birthday.$1} · ${DateFormat('d MMMM').format(birthday.$2)}',
          subtitle: birthday.$3 == 0 ? 'Today' : 'In ${birthday.$3} days',
          onTap: () => Navigator.pushNamed(
            context,
            PourToujoursRouteNames.birthday,
            arguments: DetailRouteArgs(
              title: '${birthday.$1}’s birthday',
              subtitle: DateFormat('d MMMM').format(birthday.$2),
            ),
          ),
        ),
      );
    }
    items.sort((a, b) => a.priority.compareTo(b.priority));
    if (items.isEmpty) {
      return const PtEmptyState(
        title: 'A quiet family day',
        message:
            'No major alert, clock change, or near birthday needs attention right now.',
        icon: Icons.spa_outlined,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: context.pt.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.pt.outline),
      ),
      child: Column(
        children: [
          for (var index = 0; index < math.min(items.length, 5); index++) ...[
            ListTile(
              onTap: items[index].onTap,
              leading: CircleAvatar(
                backgroundColor: items[index].color.withValues(alpha: .13),
                child: Icon(items[index].icon, color: items[index].color),
              ),
              title: Text(
                items[index].eyebrow,
                style: TextStyle(
                  color: context.pt.secondaryText,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 3),
                  Text(
                    items[index].title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    items[index].subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
            if (index < math.min(items.length, 5) - 1)
              const Divider(height: 1, indent: 72),
          ],
        ],
      ),
    );
  }

  (String, DateTime, int) _nearestBirthday() {
    final now = DateTime.now();
    final values = [...familyBirthdays]
      ..sort(
        (a, b) =>
            a.nextOccurrence(now).compareTo(b.nextOccurrence(now)),
      );
    final item = values.first;
    final date = item.nextOccurrence(now);
    return (
      item.name,
      date,
      date.difference(DateTime(now.year, now.month, now.day)).inDays,
    );
  }
}

class _ImportantItem {
  const _ImportantItem({
    required this.priority,
    required this.icon,
    required this.color,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final int priority;
  final IconData icon;
  final Color color;
  final String eyebrow;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _UpcomingMoments extends StatelessWidget {
  const _UpcomingMoments();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final values = [...familyBirthdays]
      ..sort(
        (a, b) =>
            a.nextOccurrence(now).compareTo(b.nextOccurrence(now)),
      );
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: math.min(values.length, 8),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = values[index];
          final next = item.nextOccurrence(now);
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
                  title: '${item.name}’s birthday',
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
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        DateFormat('d MMMM').format(next),
                        style: TextStyle(color: context.pt.secondaryText),
                      ),
                      Text(
                        days == 0 ? 'Today' : 'In $days days',
                        style: TextStyle(
                          color: context.pt.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
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

class _CityPlacement {
  const _CityPlacement(this.cityId, this.alignment);
  final String cityId;
  final Alignment alignment;
}

const _cityPlacements = [
  _CityPlacement('karachi', Alignment(-.72, -.35)),
  _CityPlacement('chiba', Alignment(.72, -.48)),
  _CityPlacement('dublin', Alignment(-.64, .55)),
  _CityPlacement('hattiesburg', Alignment(.68, .62)),
];

class _WindowRecommendation {
  const _WindowRecommendation({
    required this.start,
    required this.duration,
    required this.score,
    required this.reason,
  });

  final DateTime start;
  final Duration duration;
  final double score;
  final String reason;
}

_WindowRecommendation _bestWindow(Set<String> selectedPeople) {
  final selected = familyMembers
      .where((member) => selectedPeople.contains(member.name))
      .toList();
  final now = DateTime.now().toUtc();
  var bestStart = now;
  var bestScore = -1.0;
  var awakeCount = 0;
  for (var step = 0; step < 96; step++) {
    final instant = now.add(Duration(minutes: step * 15));
    final scores = <double>[];
    var awake = 0;
    for (final member in selected) {
      final snapshot = evaluateAvailability(
        member: member,
        city: cities.firstWhere((city) => city.id == member.cityId),
        now: instant,
      );
      scores.add(_availabilityScore(snapshot.kind));
      if (snapshot.kind != AvailabilityKind.asleep) awake++;
    }
    final mean = scores.isEmpty
        ? 0.0
        : scores.reduce((a, b) => a + b) / scores.length;
    final awakeBonus = selected.isEmpty ? 0 : awake / selected.length * .12;
    final score = (mean + awakeBonus).clamp(0.0, 1.0);
    if (score > bestScore) {
      bestScore = score;
      bestStart = instant;
      awakeCount = awake;
    }
  }
  final included = selected.length;
  return _WindowRecommendation(
    start: bestStart,
    duration: const Duration(minutes: 75),
    score: bestScore,
    reason:
        '$awakeCount of $included selected people are expected to be awake, with the strongest combined routine comfort in the next 24 hours.',
  );
}

double _availabilityScore(AvailabilityKind kind) => switch (kind) {
      AvailabilityKind.likelyFree => 1,
      AvailabilityKind.maybeFree => .68,
      AvailabilityKind.unknown => .45,
      AvailabilityKind.working => .24,
      AvailabilityKind.asleep => 0,
    };

AvailabilityKind _dominantKind(Iterable<AvailabilityKind> kinds) {
  final values = kinds.toList();
  if (values.isEmpty) return AvailabilityKind.unknown;
  final counts = <AvailabilityKind, int>{};
  for (final kind in values) {
    counts[kind] = (counts[kind] ?? 0) + 1;
  }
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

Color _timelineColor(BuildContext context, AvailabilityKind kind) =>
    switch (kind) {
      AvailabilityKind.likelyFree => context.pt.success,
      AvailabilityKind.maybeFree => context.pt.uncertain,
      AvailabilityKind.working => context.pt.working,
      AvailabilityKind.asleep => context.pt.asleep,
      AvailabilityKind.unknown => context.pt.unavailable,
    };

String _kindLabel(AvailabilityKind kind) => switch (kind) {
      AvailabilityKind.likelyFree => 'usually free',
      AvailabilityKind.maybeFree => 'may be free',
      AvailabilityKind.working => 'likely working or studying',
      AvailabilityKind.asleep => 'probably asleep',
      AvailabilityKind.unknown => 'routine uncertain',
    };

IconData _weatherIcon(int? code, bool isDay) {
  if (code == null) return Icons.cloud_off_outlined;
  if (code >= 95) return Icons.thunderstorm_rounded;
  if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
    return Icons.water_drop_outlined;
  }
  if (code == 45 || code == 48) return Icons.blur_on_rounded;
  if (code >= 2) return Icons.cloud_outlined;
  return isDay ? Icons.light_mode_rounded : Icons.dark_mode_rounded;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
