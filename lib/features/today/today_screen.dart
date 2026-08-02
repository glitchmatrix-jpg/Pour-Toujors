import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../app/theme/pour_toujours_theme.dart';
import '../../core/time/availability_engine.dart';
import '../../data/family_seed.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final snapshots = {
      for (final member in familyMembers)
        member.name: evaluateAvailability(
          member: member,
          city: cities.firstWhere((city) => city.id == member.cityId),
        ),
    };

    final likelyFree = snapshots.values
        .where((snapshot) => snapshot.kind == AvailabilityKind.likelyFree)
        .length;
    final awake = snapshots.values
        .where((snapshot) => snapshot.kind != AvailabilityKind.asleep)
        .length;

    return Scaffold(
      extendBody: true,
      backgroundColor: PtColors.paper,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _FamilyHorizon(
              awakeCount: awake,
              freeCount: likelyFree,
              snapshots: snapshots,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 130),
            sliver: SliverList.list(
              children: [
                const _SectionHeading(
                  eyebrow: 'LIVE FAMILY RHYTHM',
                  title: 'Four cities. One day.',
                  body:
                      'Local time and routine estimates are combined without tracking anyone’s location or phone activity.',
                ),
                const SizedBox(height: 18),
                ...cities.map(
                  (city) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _PremiumCityCard(
                      city: city,
                      snapshots: snapshots,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _BestWindowCard(snapshots: snapshots),
                const SizedBox(height: 22),
                const _TrustPanel(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _FloatingNavigation(),
    );
  }
}

class _FamilyHorizon extends StatelessWidget {
  const _FamilyHorizon({
    required this.awakeCount,
    required this.freeCount,
    required this.snapshots,
  });

  final int awakeCount;
  final int freeCount;
  final Map<String, AvailabilitySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return Container(
      constraints: const BoxConstraints(minHeight: 600),
      decoration: const BoxDecoration(color: PtColors.midnight),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.36,
              child: SvgPicture.asset(
                'assets/cities/hattiesburg.svg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x3317202A),
                    Color(0xCC17202A),
                    Color(0xFF17202A),
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            width: 48,
                            height: 48,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.11),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                            child: SvgPicture.asset('assets/brand/mark.svg'),
                          ),
                        ),
                      ),
                      const Spacer(),
                      _GlassIconButton(
                        icon: Icons.notifications_none_rounded,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const Spacer(),
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
                      fontSize: 48,
                      height: 0.96,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -2.2,
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
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroMetric(
                          value: '$awakeCount',
                          label: 'likely awake',
                          icon: Icons.wb_sunny_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HeroMetric(
                          value: '$freeCount',
                          label: 'usually free',
                          icon: Icons.call_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _LiveCityStrip(snapshots: snapshots),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.10),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
            minimumSize: const Size(48, 48),
          ),
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveCityStrip extends StatelessWidget {
  const _LiveCityStrip({required this.snapshots});

  final Map<String, AvailabilitySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: PtColors.mauve,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          title,
          style: const TextStyle(
            color: PtColors.ink,
            fontSize: 31,
            height: 1.08,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(
            color: PtColors.mutedInk,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _PremiumCityCard extends StatelessWidget {
  const _PremiumCityCard({required this.city, required this.snapshots});

  final FamilyCity city;
  final Map<String, AvailabilitySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final members = familyMembers.where((m) => m.cityId == city.id).toList();
    final local = snapshots[members.first.name]!.localTime;
    final available = members
        .where((m) => snapshots[m.name]!.kind == AvailabilityKind.likelyFree)
        .length;

    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SvgPicture.asset(city.asset, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xE817202A)],
                      stops: [0.3, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  right: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
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
                        '$available free',
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
                      (member) => _StatusRow(
                        member: member,
                        snapshot: snapshots[member.name]!,
                      ),
                    ),
                if (members.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: TextButton(
                      onPressed: () {},
                      child: Text('View all ${members.length} people'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.member, required this.snapshot});

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
      leading: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: PtColors.mist.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          member.initials,
          style: const TextStyle(
            color: PtColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(
        member.name,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(
        member.relationship,
        style: const TextStyle(color: PtColors.mutedInk, fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
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
            snapshot.reason,
            style: const TextStyle(
              color: PtColors.mutedInk,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            snapshot.confidenceLabel,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _BestWindowCard extends StatelessWidget {
  const _BestWindowCard({required this.snapshots});

  final Map<String, AvailabilitySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final people = familyMembers
        .where((member) => snapshots[member.name]!.kind == AvailabilityKind.likelyFree)
        .take(4)
        .map((member) => member.name)
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
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.favorite_outline_rounded, color: Colors.white),
          ),
          const SizedBox(height: 22),
          const Text(
            'A little closer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            people.isEmpty
                ? 'No one has a high-confidence free window right now. A message may be safer than a call.'
                : '$people are inside their usual free windows right now.',
            style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: PtColors.midnight,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            ),
            icon: const Icon(Icons.timeline_rounded),
            label: const Text('Explore the next 24 hours'),
          ),
        ],
      ),
    );
  }
}

class _TrustPanel extends StatelessWidget {
  const _TrustPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PtColors.mist.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: PtColors.ink),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Helpful, never certain.',
                  style: TextStyle(
                    color: PtColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Every label is calculated from a manually entered routine. Tap a person to see why the estimate was shown and how confident it is.',
                  style: TextStyle(
                    color: PtColors.mutedInk,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavigation extends StatelessWidget {
  const _FloatingNavigation();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: PtColors.midnight.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4017202A),
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.wb_twilight_rounded, label: 'Today', selected: true),
            _NavItem(icon: Icons.people_outline_rounded, label: 'People'),
            _NavItem(icon: Icons.calendar_month_outlined, label: 'Our Days'),
            _NavItem(icon: Icons.person_outline_rounded, label: 'You'),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, this.selected = false});

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: selected ? Colors.white : Colors.white54, size: 21),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
