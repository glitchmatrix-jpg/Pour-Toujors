import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/design/pt_components.dart';
import '../../app/theme/pour_toujours_theme.dart';
import '../../core/alerts/weather_alert_service.dart';
import '../../core/holidays/holiday_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/time/availability_engine.dart';
import '../../core/time/timezone_intelligence.dart';
import '../../core/weather/weather_models.dart';
import '../../core/weather/weather_service.dart';
import '../../data/family_context.dart';
import '../../data/family_seed.dart';
import '../navigation/detail_placeholders.dart';
import '../settings/settings_screen.dart';

class PremiumHomeScreenV3 extends StatefulWidget {
  const PremiumHomeScreenV3({
    super.key,
    required this.viewerName,
    required this.onSwitchProfile,
  });

  final String viewerName;
  final VoidCallback onSwitchProfile;

  @override
  State<PremiumHomeScreenV3> createState() => _PremiumHomeScreenV3State();
}

class _PremiumHomeScreenV3State extends State<PremiumHomeScreenV3> {
  final _weather = WeatherService();
  final _alerts = WeatherAlertService();
  final _holidays = HolidayService();
  final _timezone = TimezoneIntelligenceService();
  late Map<String, Future<WeatherBundle>> _weatherFutures;
  late Future<List<NationalHoliday>> _holidayFuture;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload({bool force = false}) {
    _weatherFutures = {
      for (final city in cities)
        city.id: _weather.fetchBundle(city.id, forceRefresh: force),
    };
    _holidayFuture = Future.wait(
      cities.map((city) => _holidays.fetchUpcoming(city.id, limit: 3)),
    ).then((groups) {
      final values = groups.expand((group) => group).toList();
      values.sort((a, b) => a.date.compareTo(b.date));
      return values;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewer = familyMembers.firstWhere((member) => member.name == widget.viewerName);
    final snapshots = {
      for (final member in familyMembers)
        member.name: evaluateAvailability(
          member: member,
          city: cities.firstWhere((city) => city.id == member.cityId),
        ),
    };
    final pages = [
      _TodayFoundationPage(
        viewer: viewer,
        snapshots: snapshots,
        weatherFutures: _weatherFutures,
        alerts: _alerts,
        timezone: _timezone,
        onRefresh: () async => setState(() => _reload(force: true)),
      ),
      _PeopleFoundationPage(viewer: viewer, snapshots: snapshots),
      _CalendarFoundationPage(holidayFuture: _holidayFuture),
      SettingsScreen(
        viewerName: viewer.name,
        viewerInitials: viewer.initials,
        onSwitchProfile: widget.onSwitchProfile,
      ),
    ];
    return Scaffold(
      body: SafeArea(bottom: false, child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people_rounded), label: 'People'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

class _TodayFoundationPage extends StatelessWidget {
  const _TodayFoundationPage({
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
  Widget build(BuildContext context) {
    final awake = snapshots.values.where((item) => item.kind != AvailabilityKind.asleep).length;
    final free = snapshots.values.where((item) => item.kind == AvailabilityKind.likelyFree).length;
    final settings = AppSettingsScope.of(context).value;
    final viewerCity = cities.firstWhere((city) => city.id == viewer.cityId);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        children: [
          PtPageHeader(
            title: '${_greeting()}, ${viewer.name}.',
            subtitle: '$awake likely awake · $free in a strong free window',
            trailing: CircleAvatar(radius: 25, child: Text(viewer.initials)),
          ),
          const SizedBox(height: 22),
          _FoundationWorldCard(
            viewerCityId: viewerCity.id,
            snapshots: snapshots,
            timezone: timezone,
            settings: settings,
          ),
          const SizedBox(height: 26),
          const PtSectionHeader('Family now'),
          const SizedBox(height: 12),
          for (final city in cities) ...[
            _FoundationWeatherCard(
              city: city,
              future: weatherFutures[city.id]!,
              settings: settings,
              alertService: alerts,
              onTap: () => Navigator.pushNamed(
                context,
                PourToujoursRouteNames.city,
                arguments: DetailRouteArgs(
                  title: city.name,
                  subtitle: 'Seven-day weather, daylight, local time, family routines, and alerts.',
                  payload: city.id,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          PtSectionHeader(
            'Next birthdays',
            action: TextButton(
              onPressed: () => Navigator.pushNamed(
                context,
                PourToujoursRouteNames.birthday,
                arguments: const DetailRouteArgs(title: 'Family birthdays'),
              ),
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: 10),
          const _BirthdayRail(),
        ],
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _FoundationWorldCard extends StatelessWidget {
  const _FoundationWorldCard({
    required this.viewerCityId,
    required this.snapshots,
    required this.timezone,
    required this.settings,
  });

  final String viewerCityId;
  final Map<String, AvailabilitySnapshot> snapshots;
  final TimezoneIntelligenceService timezone;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [context.pt.globe, Color.lerp(context.pt.globe, context.pt.globeAccent, .22)!]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR FAMILY WORLD', style: TextStyle(color: Colors.white.withValues(alpha: .65), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
          const SizedBox(height: 5),
          const Text('Time zones that change with the world.', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          for (final city in cities) ...[
            Builder(builder: (context) {
              final member = familyMembers.firstWhere((person) => person.cityId == city.id);
              final local = snapshots[member.name]!.localTime;
              final intelligence = timezone.snapshot(cityId: city.id, viewerCityId: viewerCityId);
              final offset = intelligence.viewerDifference.inHours;
              final clock = settings.clockFormat == ClockFormat.twentyFourHour ? DateFormat('HH:mm') : DateFormat('h:mm a');
              return Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: context.pt.globeAccent, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(city.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                  Text(clock.format(local), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text(offset == 0 ? 'same' : '${offset.abs()}h ${offset > 0 ? 'ahead' : 'behind'}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              );
            }),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          Text('Offsets are calculated from IANA time-zone rules, including daylight-saving changes.', style: TextStyle(color: Colors.white.withValues(alpha: .62), fontSize: 11)),
        ],
      ),
    );
  }
}

class _FoundationWeatherCard extends StatelessWidget {
  const _FoundationWeatherCard({
    required this.city,
    required this.future,
    required this.settings,
    required this.alertService,
    required this.onTap,
  });

  final FamilyCity city;
  final Future<WeatherBundle> future;
  final AppSettings settings;
  final WeatherAlertService alertService;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherBundle>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const PtLoadingSkeleton(height: 188);
        }
        if (!snapshot.hasData) {
          return const PtEmptyState(title: 'Weather unavailable', message: 'Pull down to retry. Cached values are shown whenever available.', icon: Icons.cloud_off_outlined);
        }
        final bundle = snapshot.data!;
        final current = bundle.current;
        final today = bundle.daily.first;
        final derived = alertService.derive(city.id, bundle);
        final colors = current.isDay ? context.pt.weatherDay : context.pt.weatherNight;
        final foreground = current.isDay ? Theme.of(context).colorScheme.onSurface : Colors.white;
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(26),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(26)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(city.name, style: TextStyle(color: foreground, fontSize: 23, fontWeight: FontWeight.w800))),
                      if (bundle.isStale) PtMetricPill(icon: Icons.history_rounded, label: 'Cached') else Icon(Icons.chevron_right_rounded, color: foreground),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(settings.temperature(current.temperature), style: TextStyle(color: foreground, fontSize: 43, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1.8)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(bundle.condition, style: TextStyle(color: foreground.withValues(alpha: .74), fontWeight: FontWeight.w700))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PtMetricPill(icon: Icons.thermostat_rounded, label: 'Feels ${settings.temperature(current.feelsLike)}'),
                      PtMetricPill(icon: Icons.air_rounded, label: settings.wind(current.windSpeed)),
                      PtMetricPill(icon: Icons.water_drop_outlined, label: '${today.precipitationProbability}% rain'),
                      PtMetricPill(icon: Icons.wb_sunny_outlined, label: 'UV ${current.uvIndex.toStringAsFixed(1)}'),
                    ],
                  ),
                  if (derived.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(derived.first.headline, style: TextStyle(color: foreground, fontWeight: FontWeight.w800)),
                  ],
                  const SizedBox(height: 10),
                  Text('Updated ${DateFormat('h:mm a').format(bundle.updatedAt)}', style: TextStyle(color: foreground.withValues(alpha: .65), fontSize: 11)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BirthdayRail extends StatelessWidget {
  const _BirthdayRail();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final values = [...familyBirthdays]..sort((a, b) => a.nextOccurrence(now).compareTo(b.nextOccurrence(now)));
    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = values[index];
          final next = item.nextOccurrence(now);
          final days = next.difference(DateTime(now.year, now.month, now.day)).inDays;
          return InkWell(
            onTap: () => Navigator.pushNamed(context, PourToujoursRouteNames.birthday, arguments: DetailRouteArgs(title: '${item.name}’s birthday', subtitle: DateFormat('d MMMM').format(next), payload: item.name)),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: context.pt.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: context.pt.outline)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cake_rounded, color: context.pt.birthday),
                  const Spacer(),
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(DateFormat('d MMM').format(next), style: TextStyle(color: context.pt.secondaryText)),
                  Text(days == 0 ? 'Today' : 'In $days days', style: TextStyle(color: context.pt.success, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PeopleFoundationPage extends StatelessWidget {
  const _PeopleFoundationPage({required this.viewer, required this.snapshots});
  final FamilyMember viewer;
  final Map<String, AvailabilitySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      children: [
        const PtPageHeader(title: 'People', subtitle: 'Relationships and routine-based availability relative to you.'),
        const SizedBox(height: 20),
        for (final member in familyMembers) ...[
          Card(
            child: ListTile(
              onTap: () => Navigator.pushNamed(context, PourToujoursRouteNames.person, arguments: DetailRouteArgs(title: member.name, subtitle: relationshipFor(viewer: viewer, person: member), payload: member.name)),
              leading: CircleAvatar(child: Text(member.initials)),
              title: Text(member.name),
              subtitle: Text(relationshipFor(viewer: viewer, person: member)),
              trailing: Text(snapshots[member.name]!.label, style: TextStyle(color: _availabilityColor(context, snapshots[member.name]!.kind), fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CalendarFoundationPage extends StatelessWidget {
  const _CalendarFoundationPage({required this.holidayFuture});
  final Future<List<NationalHoliday>> holidayFuture;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      children: [
        const PtPageHeader(title: 'Calendar', subtitle: 'Birthdays and relevant national holidays.'),
        const SizedBox(height: 24),
        const PtSectionHeader('Birthdays'),
        const SizedBox(height: 10),
        const _BirthdayRail(),
        const SizedBox(height: 28),
        const PtSectionHeader('National holidays'),
        const SizedBox(height: 10),
        FutureBuilder<List<NationalHoliday>>(
          future: holidayFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const PtLoadingSkeleton(height: 210);
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const PtEmptyState(title: 'Holiday information unavailable', message: 'Connect to the internet and pull down on Today to retry.');
            return Column(
              children: [
                for (final holiday in snapshot.data!.take(10)) ...[
                  Card(
                    child: ListTile(
                      onTap: () => Navigator.pushNamed(context, PourToujoursRouteNames.holiday, arguments: DetailRouteArgs(title: holiday.name, subtitle: DateFormat('EEEE, d MMMM').format(holiday.date), payload: holiday)),
                      leading: CircleAvatar(backgroundColor: context.pt.holiday.withValues(alpha: .15), child: Text(holiday.countryCode)),
                      title: Text(holiday.name),
                      subtitle: Text(DateFormat('EEEE, d MMMM').format(holiday.date)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

Color _availabilityColor(BuildContext context, AvailabilityKind kind) => switch (kind) {
      AvailabilityKind.likelyFree => context.pt.success,
      AvailabilityKind.maybeFree => context.pt.uncertain,
      AvailabilityKind.working => context.pt.working,
      AvailabilityKind.asleep => context.pt.asleep,
      AvailabilityKind.unknown => context.pt.unavailable,
    };
