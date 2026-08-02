import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/time/availability_engine.dart';
import '../../core/weather/weather_service.dart';
import '../../data/family_seed.dart';

class PremiumHomeScreen extends StatefulWidget {
  const PremiumHomeScreen({
    super.key,
    required this.viewerName,
    required this.onSwitchProfile,
  });

  final String viewerName;
  final VoidCallback onSwitchProfile;

  @override
  State<PremiumHomeScreen> createState() => _PremiumHomeScreenState();
}

class _PremiumHomeScreenState extends State<PremiumHomeScreen> {
  final WeatherService _weather = WeatherService();
  late Map<String, Future<CityWeather>> _weatherFutures;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  void _loadWeather() {
    _weatherFutures = {
      for (final city in cities) city.id: _weather.fetch(city.id),
    };
  }

  void _refreshWeather() {
    setState(_loadWeather);
  }

  @override
  Widget build(BuildContext context) {
    final viewer = familyMembers.firstWhere(
      (member) => member.name == widget.viewerName,
      orElse: () => familyMembers.first,
    );
    final snapshots = _snapshotsAt(DateTime.now());
    final viewerCity = cities.firstWhere((city) => city.id == viewer.cityId);

    final pages = <Widget>[
      _TodayPage(
        viewer: viewer,
        viewerCity: viewerCity,
        snapshots: snapshots,
        weatherFutures: _weatherFutures,
        onRefreshWeather: _refreshWeather,
      ),
      _PeoplePage(snapshots: snapshots),
      const _CalendarPage(),
      _SettingsPage(
        viewer: viewer,
        onSwitchProfile: widget.onSwitchProfile,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F3),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;
            if (!desktop) return pages[_tab];

            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _tab,
                  onDestinationSelected: (value) => setState(() => _tab = value),
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 20),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF102A2C),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.public_rounded, color: Colors.white),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: Text('Today'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people_rounded),
                      label: Text('People'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month_rounded),
                      label: Text('Calendar'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: pages[_tab]),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 900
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (value) => setState(() => _tab = value),
              height: 68,
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFFE2EFEB),
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

Map<String, AvailabilitySnapshot> _snapshotsAt(DateTime instant) {
  return {
    for (final member in familyMembers)
      member.name: evaluateAvailability(
        member: member,
        city: cities.firstWhere((city) => city.id == member.cityId),
        now: instant,
      ),
  };
}

class _TodayPage extends StatelessWidget {
  const _TodayPage({
    required this.viewer,
    required this.viewerCity,
    required this.snapshots,
    required this.weatherFutures,
    required this.onRefreshWeather,
  });

  final FamilyMember viewer;
  final FamilyCity viewerCity;
  final Map<String, AvailabilitySnapshot> snapshots;
  final Map<String, Future<CityWeather>> weatherFutures;
  final VoidCallback onRefreshWeather;

  @override
  Widget build(BuildContext context) {
    final likelyFree = familyMembers
        .where((member) => snapshots[member.name]!.kind == AvailabilityKind.likelyFree)
        .toList();
    final awake = snapshots.values
        .where((snapshot) => snapshot.kind != AvailabilityKind.asleep)
        .length;
    final recommendation = _findBestWindow(viewerCity);

    return RefreshIndicator(
      onRefresh: () async => onRefreshWeather(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 108),
            sliver: SliverList.list(
              children: [
                _Header(
                  viewer: viewer,
                  awake: awake,
                  free: likelyFree.length,
                ),
                const SizedBox(height: 22),
                _FamilyDayCard(snapshots: snapshots),
                const SizedBox(height: 26),
                const _SectionHeader(title: 'Family now'),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 980
                        ? 4
                        : constraints.maxWidth >= 560
                            ? 2
                            : 1;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: columns,
                      childAspectRatio: columns == 1 ? 1.75 : 1.28,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        for (final city in cities)
                          _CityCard(
                            city: city,
                            snapshots: snapshots,
                            weatherFuture: weatherFutures[city.id]!,
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),
                _CallWindowCard(recommendation: recommendation),
                const SizedBox(height: 26),
                const _SectionHeader(title: 'Good moments now'),
                const SizedBox(height: 12),
                if (likelyFree.isEmpty)
                  const _EmptyCard(
                    icon: Icons.nightlight_round,
                    title: 'Nobody has a strong free window right now',
                    subtitle: 'The call planner below still finds the next comfortable overlap.',
                  )
                else
                  _ReachableStrip(
                    members: likelyFree.take(6).toList(),
                    snapshots: snapshots,
                  ),
                const SizedBox(height: 26),
                const _UpcomingCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.viewer, required this.awake, required this.free});

  final FamilyMember viewer;
  final int awake;
  final int free;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 18
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
                DateFormat('EEEE, d MMMM').format(now),
                style: const TextStyle(
                  color: Color(0xFF707977),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$greeting, ${viewer.name}.',
                style: const TextStyle(
                  fontSize: 32,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.3,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                '$awake likely awake · $free in a good calling window',
                style: const TextStyle(
                  color: Color(0xFF5F6866),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 23,
          backgroundColor: const Color(0xFF102A2C),
          foregroundColor: Colors.white,
          child: Text(
            viewer.initials,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _FamilyDayCard extends StatelessWidget {
  const _FamilyDayCard({required this.snapshots});

  final Map<String, AvailabilitySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF102A2C),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THE FAMILY DAY',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Four cities, one moving day.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 18),
          for (final city in cities)
            _CityTimelineRow(
              city: city,
              snapshot: snapshots[
                  familyMembers.firstWhere((member) => member.cityId == city.id).name]!,
            ),
          const SizedBox(height: 4),
          const Text(
            'Routine estimates only · no live activity tracking',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _CityTimelineRow extends StatelessWidget {
  const _CityTimelineRow({required this.city, required this.snapshot});

  final FamilyCity city;
  final AvailabilitySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final minute = snapshot.localTime.hour * 60 + snapshot.localTime.minute;
    final color = _availabilityColor(snapshot.kind);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              city.name,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final left = (constraints.maxWidth - 10) * (minute / 1439);
                return SizedBox(
                  height: 12,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Positioned(
                        left: left.clamp(0, constraints.maxWidth - 10),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 58,
            child: Text(
              DateFormat('h:mm').format(snapshot.localTime),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  const _CityCard({
    required this.city,
    required this.snapshots,
    required this.weatherFuture,
  });

  final FamilyCity city;
  final Map<String, AvailabilitySnapshot> snapshots;
  final Future<CityWeather> weatherFuture;

  @override
  Widget build(BuildContext context) {
    final members = familyMembers.where((member) => member.cityId == city.id).toList();
    final local = snapshots[members.first.name]!.localTime;
    final free = members
        .where((member) => snapshots[member.name]!.kind == AvailabilityKind.likelyFree)
        .length;

    return Semantics(
      button: true,
      label: '${city.name}, ${DateFormat('h:mm a').format(local)}, $free good now',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE4E7E2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        city.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('h:mm a').format(local),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF67706E),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FutureBuilder<CityWeather>(
                  future: weatherFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _WeatherSkeleton();
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Row(
                        children: [
                          Icon(Icons.cloud_off_outlined, size: 18, color: Color(0xFF7B8381)),
                          SizedBox(width: 7),
                          Text(
                            'Weather unavailable',
                            style: TextStyle(color: Color(0xFF7B8381), fontSize: 12),
                          ),
                        ],
                      );
                    }
                    final weather = snapshot.data!;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${weather.temperature.round()}°',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              weather.condition,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF68716F),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const Spacer(),
                Row(
                  children: [
                    for (final member in members.take(3))
                      Align(
                        widthFactor: 0.76,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFE8EFEC),
                          child: Text(
                            member.initials,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      '$free good now',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF277A66),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherSkeleton extends StatelessWidget {
  const _WeatherSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE9ECE8),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFE9ECE8),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ],
    );
  }
}

class _CallRecommendation {
  const _CallRecommendation({
    required this.instant,
    required this.score,
    required this.comfortableCount,
  });

  final DateTime instant;
  final int score;
  final int comfortableCount;
}

_CallRecommendation _findBestWindow(FamilyCity viewerCity) {
  final now = DateTime.now();
  _CallRecommendation? best;

  for (var step = 0; step < 96; step++) {
    final instant = now.add(Duration(minutes: step * 15));
    final snapshots = _snapshotsAt(instant);
    var score = 0;
    var comfortable = 0;

    for (final snapshot in snapshots.values) {
      switch (snapshot.kind) {
        case AvailabilityKind.likelyFree:
          score += 3;
          comfortable++;
        case AvailabilityKind.maybeFree:
          score += 1;
        case AvailabilityKind.working:
          score -= 2;
        case AvailabilityKind.asleep:
          score -= 4;
        case AvailabilityKind.unknown:
          score -= 1;
      }
    }

    final candidate = _CallRecommendation(
      instant: instant,
      score: score,
      comfortableCount: comfortable,
    );
    if (best == null || candidate.score > best.score) best = candidate;
  }

  return best!;
}

class _CallWindowCard extends StatelessWidget {
  const _CallWindowCard({required this.recommendation});

  final _CallRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final karachi = evaluateAvailability(
      member: familyMembers.firstWhere((member) => member.cityId == 'karachi'),
      city: cities.firstWhere((city) => city.id == 'karachi'),
      now: recommendation.instant,
    ).localTime;

    return Material(
      color: const Color(0xFFE8EFEC),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(19),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF102A2C),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.call_rounded, color: Colors.white),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Best shared window in the next 24 hours',
                      style: TextStyle(fontSize: 12, color: Color(0xFF65706D)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat('EEE · h:mm a').format(karachi),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${recommendation.comfortableCount} people in strong free windows · Karachi time',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF65706D)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReachableStrip extends StatelessWidget {
  const _ReachableStrip({required this.members, required this.snapshots});

  final List<FamilyMember> members;
  final Map<String, AvailabilitySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final member = members[index];
          final snapshot = snapshots[member.name]!;
          return Container(
            width: 145,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE4E7E2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: const Color(0xFFE8EFEC),
                      child: Text(
                        member.initials,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.circle, color: Color(0xFF54C6A5), size: 8),
                  ],
                ),
                const Spacer(),
                Text(
                  member.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  DateFormat('h:mm a').format(snapshot.localTime),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF707977)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E7E2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Coming up', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          SizedBox(height: 16),
          _UpcomingRow(
            icon: Icons.cake_outlined,
            color: Color(0xFFC98B42),
            title: 'Birthdays',
            subtitle: 'Add dates to enable local-time reminders',
          ),
          Divider(height: 24),
          _UpcomingRow(
            icon: Icons.event_outlined,
            color: Color(0xFF7868A8),
            title: 'Relevant holidays',
            subtitle: 'Pakistan, Japan, Ireland, and the United States',
          ),
          Divider(height: 24),
          _UpcomingRow(
            icon: Icons.schedule_rounded,
            color: Color(0xFF327F91),
            title: 'Clock changes',
            subtitle: 'Dublin and Hattiesburg daylight-saving shifts',
          ),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF707977)),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA19F)),
      ],
    );
  }
}

class _PeoplePage extends StatelessWidget {
  const _PeoplePage({required this.snapshots});

  final Map<String, AvailabilitySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
      children: [
        const _PageTitle(
          title: 'People',
          subtitle: 'Routine-based availability, always explained.',
        ),
        const SizedBox(height: 18),
        for (final member in familyMembers)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            color: Colors.white,
            child: ListTile(
              leading: CircleAvatar(child: Text(member.initials)),
              title: Text(member.name),
              subtitle: Text(member.relationship),
              trailing: Text(
                snapshots[member.name]!.label,
                style: TextStyle(
                  color: _availabilityColor(snapshots[member.name]!.kind),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarPage extends StatelessWidget {
  const _CalendarPage();

  @override
  Widget build(BuildContext context) {
    return const ListView(
      padding: EdgeInsets.fromLTRB(20, 22, 20, 100),
      children: [
        _PageTitle(
          title: 'Calendar',
          subtitle: 'Birthdays, holidays, visits, and family calls.',
        ),
        SizedBox(height: 18),
        _EmptyCard(
          icon: Icons.calendar_month_outlined,
          title: 'Calendar setup comes next',
          subtitle: 'No fake events are shown. We will add verified birthdays and relevant holidays during QA.',
        ),
      ],
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.viewer, required this.onSwitchProfile});

  final FamilyMember viewer;
  final VoidCallback onSwitchProfile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
      children: [
        const _PageTitle(
          title: 'Settings',
          subtitle: 'Your identity is stored only on this device.',
        ),
        const SizedBox(height: 18),
        Card(
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(child: Text(viewer.initials)),
            title: Text('Using Pour Toujours as ${viewer.name}'),
            subtitle: const Text('Times and recommendations are personalized to this profile.'),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onSwitchProfile,
          icon: const Icon(Icons.switch_account_rounded),
          label: const Text('Switch profile'),
        ),
      ],
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Color(0xFF67706E))),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4E7E2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF67706E)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF707977)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _availabilityColor(AvailabilityKind kind) {
  return switch (kind) {
    AvailabilityKind.likelyFree => const Color(0xFF3B9A7D),
    AvailabilityKind.maybeFree => const Color(0xFFC8902F),
    AvailabilityKind.working => const Color(0xFFB65B70),
    AvailabilityKind.asleep => const Color(0xFF667895),
    AvailabilityKind.unknown => const Color(0xFF7A8380),
  };
}
