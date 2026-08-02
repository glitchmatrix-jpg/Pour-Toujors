import 'package:flutter/material.dart';

import '../../app/design/pt_components.dart';
import '../../app/theme/pour_toujours_theme.dart';
import '../../core/alerts/weather_alert_service.dart';
import '../../core/time/availability_engine.dart';
import '../../core/time/timezone_intelligence.dart';
import '../../core/weather/weather_models.dart';
import '../../core/weather/weather_service.dart';
import '../../data/family_context.dart';
import '../../data/family_graph.dart';
import '../../data/family_seed.dart';
import '../navigation/detail_placeholders.dart';
import '../people/people_calendar_experience.dart';
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
  final _timezone = TimezoneIntelligenceService();
  late Map<String, Future<WeatherBundle>> _weatherFutures;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    PourToujoursRoutes.viewerName = widget.viewerName;
    _reload();
  }

  void _reload({bool force = false}) {
    _weatherFutures = {
      for (final city in cities)
        city.id: _weather.fetchBundle(city.id, forceRefresh: force),
    };
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
      FamilyCalendarScreen(viewerName: viewer.name),
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
          subtitle: 'Relationships, local context, and routine-based availability relative to you.',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  PourToujoursRouteNames.overlapPlanner,
                  arguments: DetailRouteArgs(
                    title: 'Family contact planner',
                    viewerName: viewer.name,
                  ),
                ),
                icon: const Icon(Icons.groups_2_outlined),
                label: const Text('Plan a call'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        for (final member in familyMembers) ...[
          Card(
            child: ListTile(
              onTap: () => Navigator.pushNamed(
                context,
                PourToujoursRouteNames.person,
                arguments: DetailRouteArgs(
                  title: member.name,
                  subtitle: relationshipFor(viewer: viewer, person: member),
                  payload: PersonRoutePayload(
                    personName: member.name,
                    viewerName: viewer.name,
                  ),
                  viewerName: viewer.name,
                ),
              ),
              leading: CircleAvatar(child: Text(member.initials)),
              title: Text(member.name),
              subtitle: Text(
                '${familyGraph.relationship(viewer: viewer.name, person: member.name)} · ${cities.firstWhere((city) => city.id == member.cityId).name}',
              ),
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
        ExpansionTile(
          title: const Text('Family graph needs input'),
          subtitle: const Text('Unknown links are never inferred.'),
          children: [
            for (final note in familyGraph.missingLinks)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(note),
              ),
          ],
        ),
      ],
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
