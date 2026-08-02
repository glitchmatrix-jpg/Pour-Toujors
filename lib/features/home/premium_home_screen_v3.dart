import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/design/pt_components.dart';
import '../../app/theme/pour_toujours_theme.dart';
import '../../core/alerts/weather_alert_service.dart';
import '../../core/holidays/holiday_service.dart';
import '../../core/time/availability_engine.dart';
import '../../core/time/timezone_intelligence.dart';
import '../../core/weather/weather_models.dart';
import '../../core/weather/weather_service.dart';
import '../../data/family_context.dart';
import '../../data/family_seed.dart';
import '../navigation/detail_placeholders.dart';
import '../settings/settings_screen.dart';
import '../today/living_today_screen.dart';

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
    final viewer = familyMembers.firstWhere(
      (member) => member.name == widget.viewerName,
    );
    final snapshots = {
      for (final member in familyMembers)
        member.name: evaluateAvailability(
          member: member,
          city: cities.firstWhere((city) => city.id == member.cityId),
        ),
    };
    final pages = [
      LivingTodayScreen(
        viewer: viewer,
        snapshots: snapshots,
        weatherFutures: _weatherFutures,
        alerts: _alerts,
        timezone: _timezone,
        onRefresh: () async => setState(() => _reload(force: true)),
      ),
      _PeoplePage(viewer: viewer, snapshots: snapshots),
      _CalendarPage(holidayFuture: _holidayFuture),
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
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'People',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _PeoplePage extends StatelessWidget {
  const _PeoplePage({required this.viewer, required this.snapshots});

  final FamilyMember viewer;
  final Map<String, AvailabilitySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      children: [
        const PtPageHeader(
          title: 'People',
          subtitle:
              'Relationships and routine-based availability relative to you.',
        ),
        const SizedBox(height: 20),
        for (final member in familyMembers) ...[
          Card(
            child: ListTile(
              onTap: () => Navigator.pushNamed(
                context,
                PourToujoursRouteNames.person,
                arguments: DetailRouteArgs(
                  title: member.name,
                  subtitle: relationshipFor(viewer: viewer, person: member),
                  payload: member.name,
                ),
              ),
              leading: CircleAvatar(child: Text(member.initials)),
              title: Text(member.name),
              subtitle: Text(relationshipFor(viewer: viewer, person: member)),
              trailing: Text(
                snapshots[member.name]!.label,
                style: TextStyle(
                  color: _availabilityColor(
                    context,
                    snapshots[member.name]!.kind,
                  ),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CalendarPage extends StatelessWidget {
  const _CalendarPage({required this.holidayFuture});

  final Future<List<NationalHoliday>> holidayFuture;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      children: [
        const PtPageHeader(
          title: 'Calendar',
          subtitle: 'Birthdays and relevant national holidays.',
        ),
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const PtLoadingSkeleton(height: 210);
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const PtEmptyState(
                title: 'Holiday information unavailable',
                message:
                    'Connect to the internet and pull down on Today to retry.',
              );
            }
            return Column(
              children: [
                for (final holiday in snapshot.data!.take(10)) ...[
                  Card(
                    child: ListTile(
                      onTap: () => Navigator.pushNamed(
                        context,
                        PourToujoursRouteNames.holiday,
                        arguments: DetailRouteArgs(
                          title: holiday.name,
                          subtitle: DateFormat('EEEE, d MMMM')
                              .format(holiday.date),
                          payload: holiday,
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            context.pt.holiday.withValues(alpha: .15),
                        child: Text(holiday.countryCode),
                      ),
                      title: Text(holiday.name),
                      subtitle:
                          Text(DateFormat('EEEE, d MMMM').format(holiday.date)),
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

class _BirthdayRail extends StatelessWidget {
  const _BirthdayRail();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final values = [...familyBirthdays]
      ..sort(
        (a, b) =>
            a.nextOccurrence(now).compareTo(b.nextOccurrence(now)),
      );
    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = values[index];
          final next = item.nextOccurrence(now);
          final days =
              next.difference(DateTime(now.year, now.month, now.day)).inDays;
          return Material(
            color: context.pt.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: context.pt.outline),
            ),
            child: InkWell(
              onTap: () => Navigator.pushNamed(
                context,
                PourToujoursRouteNames.birthday,
                arguments: DetailRouteArgs(
                  title: '${item.name}’s birthday',
                  subtitle: DateFormat('d MMMM').format(next),
                  payload: item.name,
                ),
              ),
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: 150,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.cake_rounded, color: context.pt.birthday),
                      const Spacer(),
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        DateFormat('d MMM').format(next),
                        style: TextStyle(color: context.pt.secondaryText),
                      ),
                      Text(
                        days == 0 ? 'Today' : 'In $days days',
                        style: TextStyle(
                          color: context.pt.success,
                          fontSize: 11,
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

Color _availabilityColor(BuildContext context, AvailabilityKind kind) =>
    switch (kind) {
      AvailabilityKind.likelyFree => context.pt.success,
      AvailabilityKind.maybeFree => context.pt.uncertain,
      AvailabilityKind.working => context.pt.working,
      AvailabilityKind.asleep => context.pt.asleep,
      AvailabilityKind.unknown => context.pt.unavailable,
    };
