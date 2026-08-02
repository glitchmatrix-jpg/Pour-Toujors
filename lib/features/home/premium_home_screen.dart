import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/time/availability_engine.dart';
import '../../core/weather/weather_service.dart';
import '../../data/family_seed.dart';

class PremiumHomeScreen extends StatefulWidget {
  const PremiumHomeScreen({super.key, required this.viewerName, required this.onSwitchProfile});

  final String viewerName;
  final VoidCallback onSwitchProfile;

  @override
  State<PremiumHomeScreen> createState() => _PremiumHomeScreenState();
}

class _PremiumHomeScreenState extends State<PremiumHomeScreen> {
  final _weather = WeatherService();
  late final Map<String, Future<CityWeather>> weatherFutures = {
    for (final city in cities) city.id: _weather.fetch(city.id),
  };
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final snapshots = {
      for (final member in familyMembers)
        member.name: evaluateAvailability(member: member, city: cities.firstWhere((c) => c.id == member.cityId)),
    };
    final viewer = familyMembers.firstWhere((m) => m.name == widget.viewerName, orElse: () => familyMembers.first);
    final viewerCity = cities.firstWhere((c) => c.id == viewer.cityId);
    final free = snapshots.values.where((s) => s.kind == AvailabilityKind.likelyFree).length;
    final awake = snapshots.values.where((s) => s.kind != AvailabilityKind.asleep).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F3),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final content = _Dashboard(
              viewer: viewer,
              viewerCity: viewerCity,
              snapshots: snapshots,
              weatherFutures: weatherFutures,
              awake: awake,
              free: free,
              wide: wide,
            );
            if (!wide) return content;
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: tab,
                  onDestinationSelected: (value) => setState(() => tab = value),
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 20),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: const Color(0xFF102A2C), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.public_rounded, color: Colors.white),
                    ),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: IconButton(onPressed: widget.onSwitchProfile, icon: const Icon(Icons.switch_account_rounded), tooltip: 'Switch profile'),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: Text('Today')),
                    NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people_rounded), label: Text('People')),
                    NavigationRailDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: Text('Calendar')),
                    NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: Text('Settings')),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 900
          ? null
          : NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (value) {
                if (value == 3) widget.onSwitchProfile();
                setState(() => tab = value);
              },
              height: 72,
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFFE2EFEB),
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

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.viewer, required this.viewerCity, required this.snapshots, required this.weatherFutures, required this.awake, required this.free, required this.wide});

  final FamilyMember viewer;
  final FamilyCity viewerCity;
  final Map<String, AvailabilitySnapshot> snapshots;
  final Map<String, Future<CityWeather>> weatherFutures;
  final int awake;
  final int free;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final reachable = familyMembers.where((m) => snapshots[m.name]!.kind == AvailabilityKind.likelyFree).take(6).toList();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(wide ? 42 : 20, 22, wide ? 42 : 20, 110),
          sliver: SliverList.list(
            children: [
              _Header(viewer: viewer, awake: awake, free: free),
              const SizedBox(height: 24),
              _RhythmCard(snapshots: snapshots, viewerCity: viewerCity),
              const SizedBox(height: 28),
              const _SectionTitle(title: 'Family now', action: 'View world'),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: wide ? 4 : 2,
                childAspectRatio: wide ? 1.15 : .92,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: cities.map((city) => _CityCard(city: city, snapshots: snapshots, future: weatherFutures[city.id]!)).toList(),
              ),
              const SizedBox(height: 28),
              _ConnectCard(viewerCity: viewerCity),
              const SizedBox(height: 28),
              const _SectionTitle(title: 'Good moments now', action: 'See everyone'),
              const SizedBox(height: 12),
              _ReachableStrip(members: reachable, snapshots: snapshots),
              const SizedBox(height: 28),
              const _UpcomingCard(),
            ],
          ),
        ),
      ],
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
    final greeting = now.hour < 12 ? 'Good morning' : now.hour < 18 ? 'Good afternoon' : 'Good evening';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('EEEE, d MMMM').format(now), style: const TextStyle(color: Color(0xFF707977), fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('$greeting, ${viewer.name}.', style: const TextStyle(fontSize: 34, height: 1.05, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
              const SizedBox(height: 10),
              Text('$awake likely awake · $free in a good calling window', style: const TextStyle(color: Color(0xFF5F6866), fontSize: 15)),
            ],
          ),
        ),
        CircleAvatar(radius: 23, backgroundColor: const Color(0xFF102A2C), foregroundColor: Colors.white, child: Text(viewer.initials, style: const TextStyle(fontWeight: FontWeight.w800))),
      ],
    );
  }
}

class _RhythmCard extends StatelessWidget {
  const _RhythmCard({required this.snapshots, required this.viewerCity});
  final Map<String, AvailabilitySnapshot> snapshots;
  final FamilyCity viewerCity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF102A2C), borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Text('THE FAMILY DAY', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4)), Spacer(), Icon(Icons.drag_indicator_rounded, color: Colors.white38)]),
          const SizedBox(height: 8),
          const Text('Four cities, one moving day.', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w750, letterSpacing: -.6)),
          const SizedBox(height: 18),
          ...cities.map((city) {
            final member = familyMembers.firstWhere((m) => m.cityId == city.id);
            final snap = snapshots[member.name]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                children: [
                  SizedBox(width: 86, child: Text(city.name, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w650))),
                  Expanded(child: _DayBand(hour: snap.localTime.hour, kind: snap.kind)),
                  const SizedBox(width: 10),
                  SizedBox(width: 54, child: Text(DateFormat('h:mm').format(snap.localTime), textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 12, fontFeatures: [FontFeature.tabularFigures()]))),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          const Text('Routine estimates only · no live activity tracking', style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}

class _DayBand extends StatelessWidget {
  const _DayBand({required this.hour, required this.kind});
  final int hour;
  final AvailabilityKind kind;
  @override
  Widget build(BuildContext context) {
    final active = switch (kind) { AvailabilityKind.likelyFree => const Color(0xFF54C6A5), AvailabilityKind.maybeFree => const Color(0xFFE6B768), AvailabilityKind.working => const Color(0xFFD8798F), AvailabilityKind.asleep => const Color(0xFF71819D), AvailabilityKind.unknown => const Color(0xFF929B98) };
    return LayoutBuilder(builder: (context, box) => Stack(children: [
      Container(height: 9, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(99))),
      Positioned(left: (box.maxWidth - 8) * (hour / 23), child: Container(width: 8, height: 9, decoration: BoxDecoration(color: active, borderRadius: BorderRadius.circular(99), boxShadow: [BoxShadow(color: active.withValues(alpha: .5), blurRadius: 8)]))),
    ]));
  }
}

class _CityCard extends StatelessWidget {
  const _CityCard({required this.city, required this.snapshots, required this.future});
  final FamilyCity city;
  final Map<String, AvailabilitySnapshot> snapshots;
  final Future<CityWeather> future;

  @override
  Widget build(BuildContext context) {
    final members = familyMembers.where((m) => m.cityId == city.id).toList();
    final local = snapshots[members.first.name]!.localTime;
    final free = members.where((m) => snapshots[m.name]!.kind == AvailabilityKind.likelyFree).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE4E7E2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(city.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w750))), Text(DateFormat('h:mm a').format(local), style: const TextStyle(fontSize: 12, color: Color(0xFF67706E), fontFeatures: [FontFeature.tabularFigures()]))]),
        const SizedBox(height: 12),
        FutureBuilder<CityWeather>(future: future, builder: (context, snapshot) {
          if (!snapshot.hasData) return const Text('Weather loading…', style: TextStyle(color: Color(0xFF7B8381), fontSize: 12));
          final w = snapshot.data!;
          return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${w.temperature.round()}°', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -1.5)), const SizedBox(width: 8), Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 5), child: Text(w.condition, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF68716F), fontSize: 12))))]);
        }),
        const Spacer(),
        Row(children: [
          ...members.take(3).map((m) => Align(widthFactor: .76, child: CircleAvatar(radius: 16, backgroundColor: const Color(0xFFE8EFEC), child: Text(m.initials, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)))),
          const Spacer(),
          Text('$free good now', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF277A66))),
        ]),
      ]),
    );
  }
}

class _ConnectCard extends StatelessWidget {
  const _ConnectCard({required this.viewerCity});
  final FamilyCity viewerCity;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xFFE8EFEC), borderRadius: BorderRadius.circular(26)),
    child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF102A2C), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.call_rounded, color: Colors.white)),
      const SizedBox(width: 16),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Best shared window today', style: TextStyle(fontSize: 13, color: Color(0xFF65706D))), SizedBox(height: 4), Text('7:30–8:15 PM Karachi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.5)), SizedBox(height: 3), Text('Comfortable for Karachi, Dublin, and Hattiesburg', style: TextStyle(fontSize: 12, color: Color(0xFF65706D)))])),
      const Icon(Icons.chevron_right_rounded),
    ]),
  );
}

class _ReachableStrip extends StatelessWidget {
  const _ReachableStrip({required this.members, required this.snapshots});
  final List<FamilyMember> members;
  final Map<String, AvailabilitySnapshot> snapshots;
  @override
  Widget build(BuildContext context) => SizedBox(height: 104, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: members.length, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (context, index) {
    final m = members[index];
    final s = snapshots[m.name]!;
    return Container(width: 142, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE4E7E2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [CircleAvatar(radius: 17, backgroundColor: const Color(0xFFE8EFEC), child: Text(m.initials, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800))), const Spacer(), const Icon(Icons.circle, color: Color(0xFF54C6A5), size: 8)]), const Spacer(), Text(m.name, style: const TextStyle(fontWeight: FontWeight.w750)), Text(DateFormat('h:mm a').format(s.localTime), style: const TextStyle(fontSize: 11, color: Color(0xFF707977)))]));
  }));
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFFE4E7E2))),
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Coming up', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      SizedBox(height: 16),
      _UpcomingRow(icon: Icons.cake_outlined, color: Color(0xFFC98B42), title: 'Next family birthday', subtitle: 'Add birthdays to begin local-time reminders'),
      Divider(height: 24),
      _UpcomingRow(icon: Icons.event_outlined, color: Color(0xFF7868A8), title: 'Local holidays', subtitle: 'Japan, Ireland, Pakistan, and the United States'),
      Divider(height: 24),
      _UpcomingRow(icon: Icons.schedule_rounded, color: Color(0xFF327F91), title: 'Clock changes', subtitle: 'We will warn you before Dublin or Hattiesburg shifts'),
    ]),
  );
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.icon, required this.color, required this.title, required this.subtitle});
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF707977)))])), const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA19F))]);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action});
  final String title;
  final String action;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -.6))), Text(action, style: const TextStyle(color: Color(0xFF277A66), fontWeight: FontWeight.w700, fontSize: 12))]);
}
