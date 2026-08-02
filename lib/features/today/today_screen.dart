import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/pour_toujours_theme.dart';
import '../../data/family_seed.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final freeCount = familyMembers
        .where((member) => member.availability == Availability.free)
        .length;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
              sliver: SliverList.list(
                children: [
                  const _Header(),
                  const SizedBox(height: 28),
                  _FamilyPulse(freeCount: freeCount),
                  const SizedBox(height: 34),
                  Text('Our world today', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 14),
                  ...cities.map(
                    (city) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _CityWindow(city: city),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _CloserCard(),
                  const SizedBox(height: 24),
                  const _PrivacyNote(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.wb_twilight_outlined), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'People'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Our Days'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'You'),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: PtColors.midnight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.window_rounded, color: PtColors.paper),
            ),
            const Spacer(),
            IconButton.filledTonal(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
              tooltip: 'Notifications',
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('Good morning, Hasan.', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 12),
        Text(
          'Karachi is well into its day, Dublin is beginning its morning, and Chiba is moving toward evening.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: PtColors.mutedInk),
        ),
      ],
    );
  }
}

class _FamilyPulse extends StatelessWidget {
  const _FamilyPulse({required this.freeCount});

  final int freeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PtColors.midnight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Expanded(child: _PulseMetric(value: '11', label: 'likely awake')),
          Container(width: 1, height: 44, color: Colors.white24),
          Expanded(child: _PulseMetric(value: '$freeCount', label: 'good to call')),
          Container(width: 1, height: 44, color: Colors.white24),
          const Expanded(child: _PulseMetric(value: '12d', label: 'next birthday')),
        ],
      ),
    );
  }
}

class _PulseMetric extends StatelessWidget {
  const _PulseMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _CityWindow extends StatelessWidget {
  const _CityWindow({required this.city});

  final FamilyCity city;

  @override
  Widget build(BuildContext context) {
    final members = familyMembers.where((member) => member.cityId == city.id).toList();
    final preview = members.take(4).toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 170,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SvgPicture.asset(city.asset, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xB317202A)],
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
                              Text(city.name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                              Text(city.country, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                        const Text('NOW', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(city.weatherLine, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(city.timeLine, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Column(
                children: [
                  ...preview.map((member) => _PersonRow(member: member)),
                  if (members.length > preview.length)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {},
                        child: Text('${members.length - preview.length} more in ${city.name}'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (member.availability) {
      Availability.free => ('Usually free', PtColors.leaf),
      Availability.maybeFree => ('May be free', PtColors.sun),
      Availability.busy => ('Likely busy', PtColors.mauve),
      Availability.asleep => ('Probably asleep', PtColors.midnight),
    };

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: PtColors.mist,
        foregroundColor: PtColors.ink,
        child: Text(member.initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
      title: Text(member.name),
      subtitle: Text(member.relationship),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _CloserCard extends StatelessWidget {
  const _CloserCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PtColors.sun.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: PtColors.sun.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite_border_rounded, color: PtColors.ink),
          const SizedBox(height: 14),
          Text('A little closer', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Talat, Ramsha, Ami, Nanu, and Affan may be comfortable to call right now.', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.schedule_rounded), label: const Text('Find a better time')),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline_rounded, size: 19, color: PtColors.mutedInk),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'See their world, not their whereabouts. Pour Toujours uses home cities and transparent routine estimates—never live GPS.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
