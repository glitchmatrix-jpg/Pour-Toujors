import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../app/theme/pour_toujours_theme.dart';
import '../../core/time/availability_engine.dart';
import '../../data/family_seed.dart';

class TodayScreenV2 extends StatelessWidget {
  const TodayScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    final snapshots = {
      for (final member in familyMembers)
        member.name: evaluateAvailability(
          member: member,
          city: cities.firstWhere((city) => city.id == member.cityId),
        ),
    };

    final awake = snapshots.values
        .where((s) => s.kind != AvailabilityKind.asleep)
        .length;
    final free = snapshots.values
        .where((s) => s.kind == AvailabilityKind.likelyFree)
        .length;

    return Scaffold(
      extendBody: true,
      backgroundColor: PtColors.paper,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _Hero(
              awake: awake,
              free: free,
              snapshots: snapshots,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 34, 20, 132),
            sliver: SliverList.list(
              children: [
                const _SectionIntro(),
                const SizedBox(height: 20),
                ...cities.map(
                  (city) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _CityCard(city: city, snapshots: snapshots),
                  ),
                ),
                const SizedBox(height: 6),
                _BestTimeCard(snapshots: snapshots),
                const SizedBox(height: 20),
                const _PrivacyCard(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.awake, required this.free, required this.snapshots});

  final int awake;
  final int free;
  final Map<String, AvailabilitySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return SizedBox(
      height: 620,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            'assets/cities/hattiesburg.svg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x3017202A),
                  Color(0xB817202A),
                  Color(0xFF17202A),
                ],
                stops: [0, .48, 1],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .18),
                          ),
                        ),
                        child: SvgPicture.asset('assets/brand/mark.svg'),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .18),
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 86),
                  Text(
                    DateFormat('EEEE, d MMMM').format(now).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.7,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$greeting,\nHasan.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      height: .96,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -2.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Your family is moving through four different parts of the day.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroStat(
                          value: '$awake',
                          label: 'likely awake',
                          icon: Icons.light_mode_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HeroStat(
                          value: '$free',
                          label: 'usually free',
                          icon: Icons.call_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _CityTimes(snapshots: snapshots),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CityTimes extends StatelessWidget {
  const _CityTimes({required this.snapshots});

  final Map<String, AvailabilitySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .17),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .09)),
      ),
      child: Row(
        children: cities.map((city) {
          final member = familyMembers.firstWhere((m) => m.cityId == city.id);
          final local = snapshots[member.name]!.localTime;
          return Expanded(
            child: Column(
              children: [
                Text(
                  DateFormat('h:mm').format(local),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  city.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LIVE FAMILY RHYTHM',
          style: TextStyle(
            color: PtColors.mauve,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        SizedBox(height: 9),
        Text(
          'Four cities. One day.',
          style: TextStyle(
            color: PtColors.ink,
            fontSize: 32,
            height: 1.05,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Local time and familiar routines, combined without tracking anyone’s location or phone activity.',
          style: TextStyle(
            color: PtColors.mutedInk,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _CityCard extends StatelessWidget {
  const _CityCard({required this.city, required this.snapshots});

  final FamilyCity city;
  final Map<String, AvailabilitySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final members = familyMembers.where((m) => m.cityId == city.id).toList();
    final local = snapshots[members.first.name]!.localTime;
    final free = members
        .where((m) => snapshots[m.name]!.kind == AvailabilityKind.likelyFree)
        .length;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: PtColors.mist),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1017202A),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SvgPicture.asset(city.asset, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xEC17202A)],
                      stops: [.24, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  right: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white.withValues(alpha: .2)),
                    ),
                    child: Text(
                      DateFormat('EEE · h:mm a').format(local),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              city.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 31,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              '${city.country} · ${city.weatherLine}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$free free',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              children: [
                ...members.take(5).map(
                  (member) => _PersonStatus(
                    member: member,
                    snapshot: snapshots[member.name]!,
                  ),
                ),
                if (members.length > 5)
                  TextButton(
                    onPressed: () {},
                    child: Text('View all ${members.length} people'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonStatus extends StatelessWidget {
  const _PersonStatus({required this.member, required this.snapshot});

  final FamilyMember member;
  final AvailabilitySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final color = switch (snapshot.kind) {
      AvailabilityKind.likelyFree => PtColors.leaf,
      AvailabilityKind.maybeFree => PtColors.sun,
      AvailabilityKind.working => PtColors.mauve,
      AvailabilityKind.asleep => PtColors.midnight,
      AvailabilityKind.unknown => PtColors.mutedInk,
    };

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 6),
      childrenPadding: const EdgeInsets.fromLTRB(58, 0, 14, 14),
      shape: const Border(),
      collapsedShape: const Border(),
      leading: CircleAvatar(
        radius: 21,
        backgroundColor: PtColors.mist,
        foregroundColor: PtColors.ink,
        child: Text(
          member.initials,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
      title: Text(
        member.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(member.relationship),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          snapshot.label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${snapshot.reason}\n${snapshot.confidenceLabel} · local time ${DateFormat('h:mm a').format(snapshot.localTime)}',
            style: const TextStyle(
              color: PtColors.mutedInk,
              height: 1.45,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _BestTimeCard extends StatelessWidget {
  const _BestTimeCard({required this.snapshots});

  final Map<String, AvailabilitySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final names = familyMembers
        .where((m) => snapshots[m.name]!.kind == AvailabilityKind.likelyFree)
        .map((m) => m.name)
        .take(5)
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PtColors.midnight,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.favorite_outline_rounded, color: Colors.white),
          ),
          const SizedBox(height: 18),
          const Text(
            'A little closer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w700,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            names.isEmpty
                ? 'No one has a high-confidence free window right now.'
                : '$names may be comfortable to call right now.',
            style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.schedule_rounded),
            label: const Text('Find a better time'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: PtColors.midnight,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PtColors.mist.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: PtColors.mutedInk),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'See their world, not their whereabouts. Every status is a routine-based estimate, never live tracking.',
              style: TextStyle(color: PtColors.mutedInk, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: PtColors.midnight,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3217202A),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: const Row(
          children: [
            _NavItem(icon: Icons.wb_twilight_rounded, label: 'Today', active: true),
            _NavItem(icon: Icons.group_outlined, label: 'People'),
            _NavItem(icon: Icons.calendar_month_outlined, label: 'Our Days'),
            _NavItem(icon: Icons.person_outline_rounded, label: 'You'),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, this.active = false});

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white.withValues(alpha: .12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? Colors.white : Colors.white54, size: 21),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white54,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
