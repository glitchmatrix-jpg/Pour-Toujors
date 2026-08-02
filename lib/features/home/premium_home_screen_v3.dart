import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/design/pt_components.dart';
import '../../app/theme/pour_toujours_theme.dart';
import '../../core/alerts/weather_alert_service.dart';
import '../../core/release/v1_platform_services.dart';
import '../../core/time/availability_engine.dart';
import '../../core/time/timezone_intelligence.dart';
import '../../core/weather/weather_models.dart';
import '../../core/weather/weather_service.dart';
import '../../data/family_context.dart';
import '../../data/family_graph.dart';
import '../../data/family_seed.dart';
import '../navigation/detail_placeholders.dart';
import '../people/family_calendar_final.dart';
import '../people/people_calendar_experience.dart';
import '../settings/settings_screen.dart';
import '../today/atlas_today_screen.dart';

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

class _PremiumHomeScreenV3State extends State<PremiumHomeScreenV3>
    with WidgetsBindingObserver {
  final _weather = WeatherService();
  final _alerts = WeatherAlertService();
  final _timezone = TimezoneIntelligenceService();
  late Map<String, Future<WeatherBundle>> _weatherFutures;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PourToujoursRoutes.viewerName = widget.viewerName;
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishWidgetSnapshot());
  }

  @override
  void didUpdateWidget(covariant PremiumHomeScreenV3 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewerName != widget.viewerName) {
      PourToujoursRoutes.viewerName = widget.viewerName;
      _publishWidgetSnapshot();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _publishWidgetSnapshot();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _reload({bool force = false}) {
    _weatherFutures = {
      for (final city in cities)
        city.id: _weather.fetchBundle(city.id, forceRefresh: force),
    };
  }

  Future<void> _publishWidgetSnapshot() async {
    try {
      final now = DateTime.now();
      final availability = {
        for (final member in familyMembers)
          member.name: evaluateAvailability(
            member: member,
            city: cities.firstWhere((city) => city.id == member.cityId),
          ),
      };
      final free = familyMembers
          .where((member) =>
              member.name != widget.viewerName &&
              availability[member.name]?.kind == AvailabilityKind.likelyFree)
          .toList();
      final weatherResults = await Future.wait(
        cities.map((city) async {
          try {
            final bundle = await _weather.fetchBundle(city.id);
            final alerts = [
              ...await _alerts.fetchOfficialForCity(city.id),
              ..._alerts.derive(city.id, bundle),
            ];
            return (city: city, bundle: bundle, alerts: alerts);
          } on Object catch (error) {
            debugPrint('Widget weather unavailable for ${city.name}: $error');
            return (city: city, bundle: null, alerts: <FamilyWeatherAlert>[]);
          }
        }),
      );

      final citySnapshots = <WidgetCitySnapshot>[];
      var daylightCities = 0;
      var activeAlerts = 0;
      var stale = false;
      for (final result in weatherResults) {
        final city = result.city;
        final local = tz.TZDateTime.now(tz.getLocation(city.timezone));
        final bundle = result.bundle;
        final members = familyMembers.where((member) => member.cityId == city.id);
        final likelyFree = members.where((member) =>
            availability[member.name]?.kind == AvailabilityKind.likelyFree).length;
        final isDay = bundle?.current.isDay ?? (local.hour >= 7 && local.hour < 19);
        if (isDay) daylightCities++;
        activeAlerts += result.alerts.length;
        stale = stale || (bundle?.isStale ?? true);
        final alert = result.alerts.isEmpty
            ? 'No important alert'
            : result.alerts.first.headline;
        citySnapshots.add(
          WidgetCitySnapshot(
            id: city.id,
            name: city.name,
            time: DateFormat('h:mm a').format(local),
            date: DateFormat('EEE, d MMM').format(local),
            temperature: bundle == null
                ? '—'
                : '${bundle.current.temperature.round()}°C',
            condition: bundle?.condition ?? 'Open app to refresh',
            weatherCode: bundle?.current.weatherCode ?? 0,
            isDay: isDay,
            status: '$likelyFree likely free · ${members.length} here',
            alert: alert,
          ),
        );
      }

      final viewer = familyMembers.firstWhere((member) => member.name == widget.viewerName);
      final viewerCity = cities.firstWhere((city) => city.id == viewer.cityId);
      final viewerLocal = tz.TZDateTime.now(tz.getLocation(viewerCity.timezone));
      final events = await FamilyEventStore().load();
      final upcoming = events.where((event) => event.utcStart.isAfter(now.toUtc())).toList()
        ..sort((a, b) => a.utcStart.compareTo(b.utcStart));
      final nextEvent = upcoming.isEmpty
          ? 'No upcoming saved family event'
          : '${upcoming.first.title} · ${DateFormat('EEE d MMM').format(upcoming.first.utcStart.toLocal())}';
      final mostImportantAlert = weatherResults
          .expand((result) => result.alerts)
          .fold<FamilyWeatherAlert?>(
            null,
            (best, alert) => best == null || alert.severity.index > best.severity.index
                ? alert
                : best,
          );

      await V1PlatformServices.instance.updateHomeWidgets(
        WidgetSnapshot(
          primaryLine: free.isEmpty
              ? 'Family across four cities'
              : '${free.length} ${free.length == 1 ? 'person is' : 'people are'} likely free',
          secondaryLine: free.isEmpty
              ? 'Weather, time, and family context'
              : free.take(3).map((member) => member.name).join(' · '),
          citiesLine: citySnapshots
              .map((city) => '${city.name} ${city.time} ${city.temperature}')
              .join('  •  '),
          timelineLine:
              '${viewer.name} · ${viewerCity.name} ${DateFormat('h:mm a').format(viewerLocal)} · ${availability[viewer.name]?.label ?? 'Unknown'}',
          nextEventLine: nextEvent,
          alertLine: mostImportantAlert?.headline ?? 'No important alert cached',
          updatedAt: now,
          citySnapshots: citySnapshots,
          daylightCities: daylightCities,
          activeAlerts: activeAlerts,
          isStale: stale,
        ),
      );
    } on Object catch (error, stackTrace) {
      debugPrint('Widget snapshot publishing failed safely: $error\n$stackTrace');
    }
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
      AtlasTodayScreen(
        viewer: viewer,
        snapshots: snapshots,
        weatherFutures: _weatherFutures,
        alerts: _alerts,
        timezone: _timezone,
        onRefresh: () async {
          setState(() => _reload(force: true));
          await _publishWidgetSnapshot();
        },
      ),
      _PeoplePage(viewer: viewer, snapshots: snapshots),
      FamilyCalendarFinalScreen(viewerName: viewer.name),
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

class _PeoplePage extends StatelessWidget {
  const _PeoplePage({required this.viewer, required this.snapshots});
  final FamilyMember viewer;
  final Map<String, AvailabilitySnapshot> snapshots;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        children: [
          const PtPageHeader(
            title: 'People',
            subtitle: 'Local time, city, and routine-based availability. Relationships follow the selected profile.',
          ),
          const SizedBox(height: 18),
          for (final member in familyMembers) ...[
            Semantics(
              button: true,
              label: '${member.name}, ${familyGraph.relationship(viewer: viewer.name, person: member.name)}, ${snapshots[member.name]!.label}',
              child: Card(
                child: ListTile(
                  minVerticalPadding: 14,
                  onTap: () => Navigator.pushNamed(
                    context,
                    PourToujoursRouteNames.person,
                    arguments: DetailRouteArgs(
                      title: member.name,
                      subtitle: relationshipFor(viewer: viewer, person: member),
                      payload: PersonRoutePayload(personName: member.name, viewerName: viewer.name),
                      viewerName: viewer.name,
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: context.pt.globeAccent.withValues(alpha: .14),
                    child: Text(member.initials, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${familyGraph.relationship(viewer: viewer.name, person: member.name)} · ${cities.firstWhere((city) => city.id == member.cityId).name}'),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: _availabilityColor(context, snapshots[member.name]!.kind).withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      snapshots[member.name]!.label,
                      style: TextStyle(
                        color: _availabilityColor(context, snapshots[member.name]!.kind),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          ExpansionTile(
            title: const Text('Unmapped family details'),
            subtitle: const Text('Unknown links are shown honestly, never guessed.'),
            children: [
              for (final note in familyGraph.missingLinks)
                ListTile(leading: const Icon(Icons.info_outline), title: Text(note)),
            ],
          ),
        ],
      );
}

Color _availabilityColor(BuildContext context, AvailabilityKind kind) => switch (kind) {
      AvailabilityKind.likelyFree => context.pt.success,
      AvailabilityKind.maybeFree => context.pt.uncertain,
      AvailabilityKind.working => context.pt.working,
      AvailabilityKind.asleep => context.pt.asleep,
      AvailabilityKind.unknown => context.pt.unavailable,
    };
