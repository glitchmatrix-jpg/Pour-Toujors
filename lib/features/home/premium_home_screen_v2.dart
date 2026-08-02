import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../core/holidays/holiday_service.dart';
import '../../core/time/availability_engine.dart';
import '../../core/weather/weather_service.dart';
import '../../data/family_context.dart';
import '../../data/family_seed.dart';

class PremiumHomeScreenV2 extends StatefulWidget {
  const PremiumHomeScreenV2({
    super.key,
    required this.viewerName,
    required this.onSwitchProfile,
  });

  final String viewerName;
  final VoidCallback onSwitchProfile;

  @override
  State<PremiumHomeScreenV2> createState() => _PremiumHomeScreenV2State();
}

class _PremiumHomeScreenV2State extends State<PremiumHomeScreenV2> {
  final WeatherService _weatherService = WeatherService();
  final HolidayService _holidayService = HolidayService();

  late Map<String, Future<CityWeather>> _weatherFutures;
  late Future<List<NationalHoliday>> _holidayFuture;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _weatherFutures = {
      for (final city in cities) city.id: _weatherService.fetch(city.id),
    };
    _holidayFuture = Future.wait(
      cities.map((city) => _holidayService.fetchUpcoming(city.id, limit: 2)),
    ).then((groups) {
      final holidays = groups.expand((group) => group).toList();
      holidays.sort((a, b) => a.date.compareTo(b.date));
      return holidays;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewer = familyMembers.firstWhere(
      (member) => member.name == widget.viewerName,
    );
    final snapshots = <String, AvailabilitySnapshot>{
      for (final member in familyMembers)
        member.name: evaluateAvailability(
          member: member,
          city: cities.firstWhere((city) => city.id == member.cityId),
        ),
    };

    final pages = <Widget>[
      _TodayPage(
        viewer: viewer,
        snapshots: snapshots,
        weatherFutures: _weatherFutures,
        onRefresh: () async => setState(_reload),
      ),
      _PeoplePage(viewer: viewer, snapshots: snapshots),
      _CalendarPage(holidayFuture: _holidayFuture),
      _SettingsPage(
        viewer: viewer,
        onSwitchProfile: widget.onSwitchProfile,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F2),
      body: SafeArea(bottom: false, child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDDECE7),
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

class _TodayPage extends StatelessWidget {
  const _TodayPage({
    required this.viewer,
    required this.snapshots,
    required this.weatherFutures,
    required this.onRefresh,
  });

  final FamilyMember viewer;
  final Map<String, AvailabilitySnapshot> snapshots;
  final Map<String, Future<CityWeather>> weatherFutures;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final awake = snapshots.values
        .where((snapshot) => snapshot.kind != AvailabilityKind.asleep)
        .length;
    final free = snapshots.values
        .where((snapshot) => snapshot.kind == AvailabilityKind.likelyFree)
        .length;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        children: [
          Text(
            DateFormat('EEEE, d MMMM').format(DateTime.now()),
            style: const TextStyle(
              color: Color(0xFF747D7A),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$greeting, ${viewer.name}.',
                  style: const TextStyle(
                    fontSize: 34,
                    height: 1.03,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.4,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF103536),
                foregroundColor: Colors.white,
                child: Text(
                  viewer.initials,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            '$awake likely awake · $free in a strong free window',
            style: const TextStyle(color: Color(0xFF606966), fontSize: 15),
          ),
          const SizedBox(height: 24),
          _WorldCard(snapshots: snapshots),
          const SizedBox(height: 28),
          const _SectionHeading('Family now'),
          const SizedBox(height: 12),
          for (final city in cities) ...[
            _WeatherCityCard(
              city: city,
              future: weatherFutures[city.id]!,
              snapshots: snapshots,
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 12),
          const _SectionHeading('Next birthdays'),
          const SizedBox(height: 12),
          const _BirthdayStrip(),
        ],
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({required this.snapshots});

  final Map<String, AvailabilitySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF092D30), Color(0xFF174C4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR FAMILY WORLD',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Four cities under one sky.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              painter: _WorldPainter(),
              child: const SizedBox.expand(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final city in cities)
                Builder(
                  builder: (context) {
                    final member = familyMembers.firstWhere(
                      (person) => person.cityId == city.id,
                    );
                    return Column(
                      children: [
                        Text(
                          city.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          DateFormat('h:mm')
                              .format(snapshots[member.name]!.localTime),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius, gridPaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 2,
        height: radius * 0.65,
      ),
      gridPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 0.75,
        height: radius * 2,
      ),
      gridPaint,
    );

    final points = <Offset>[
      Offset(center.dx + radius * 0.50, center.dy + radius * 0.14),
      Offset(center.dx + radius * 0.78, center.dy - radius * 0.20),
      Offset(center.dx - radius * 0.40, center.dy - radius * 0.28),
      Offset(center.dx - radius * 0.66, center.dy + radius * 0.26),
    ];
    final linePaint = Paint()
      ..color = const Color(0xFF76D7BA).withValues(alpha: 0.5)
      ..strokeWidth = 1.5;

    for (var index = 0; index < points.length - 1; index++) {
      canvas.drawLine(points[index], points[index + 1], linePaint);
    }
    for (final point in points) {
      canvas.drawCircle(
        point,
        8,
        Paint()..color = const Color(0xFF76D7BA).withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        point,
        4,
        Paint()..color = const Color(0xFF76D7BA),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WeatherCityCard extends StatelessWidget {
  const _WeatherCityCard({
    required this.city,
    required this.future,
    required this.snapshots,
  });

  final FamilyCity city;
  final Future<CityWeather> future;
  final Map<String, AvailabilitySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final members = familyMembers
        .where((member) => member.cityId == city.id)
        .toList();
    final local = snapshots[members.first.name]!.localTime;

    return FutureBuilder<CityWeather>(
      future: future,
      builder: (context, snapshot) {
        final weather = snapshot.data;
        final night = weather != null && !weather.isDay;
        final colors = night
            ? const [Color(0xFF152840), Color(0xFF304864)]
            : const [Color(0xFFB9DBEA), Color(0xFFF1D3A5)];
        final foreground = night ? Colors.white : const Color(0xFF173035);
        final secondary =
            night ? Colors.white70 : const Color(0xFF405B60);

        return Container(
          height: 220,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -12,
                width: 210,
                child: Opacity(
                  opacity: 0.28,
                  child: SvgPicture.asset(city.asset),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            city.name,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('h:mm a').format(local),
                          style: TextStyle(
                            color: secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const CircularProgressIndicator(strokeWidth: 2)
                    else if (weather == null)
                      Text(
                        'Weather unavailable · pull to retry',
                        style: TextStyle(color: secondary),
                      )
                    else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${weather.temperature.round()}°',
                            style: TextStyle(
                              color: foreground,
                              fontSize: 48,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              weather.condition,
                              style: TextStyle(
                                color: secondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetricChip(
                            icon: Icons.thermostat_rounded,
                            text: 'Feels ${weather.feelsLike.round()}°',
                            dark: night,
                          ),
                          _MetricChip(
                            icon: Icons.air_rounded,
                            text: '${weather.windSpeed.round()} km/h',
                            dark: night,
                          ),
                          _MetricChip(
                            icon: Icons.water_drop_outlined,
                            text: '${weather.rainChance}% rain',
                            dark: night,
                          ),
                          _MetricChip(
                            icon: Icons.unfold_more_rounded,
                            text:
                                '${weather.high.round()}° / ${weather.low.round()}°',
                            dark: night,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        weather.practicalLine,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.text,
    required this.dark,
  });

  final IconData icon;
  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: dark ? Colors.white12 : Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: dark ? Colors.white70 : const Color(0xFF36575A),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: dark ? Colors.white : const Color(0xFF244548),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthdayStrip extends StatelessWidget {
  const _BirthdayStrip();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final items = [...familyBirthdays]
      ..sort(
        (a, b) =>
            a.nextOccurrence(now).compareTo(b.nextOccurrence(now)),
      );

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final birthday = items[index];
          final date = birthday.nextOccurrence(now);
          final today = DateTime(now.year, now.month, now.day);
          final days = date.difference(today).inDays;

          return Container(
            width: 150,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E5E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cake_rounded, color: Color(0xFFC98255)),
                const Spacer(),
                Text(
                  birthday.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  DateFormat('d MMM').format(date),
                  style: const TextStyle(color: Color(0xFF69726F)),
                ),
                Text(
                  days == 0 ? 'Today' : 'In $days days',
                  style: const TextStyle(
                    color: Color(0xFF277A66),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        const _PageTitle(
          'People',
          'Relationships and availability relative to you.',
        ),
        const SizedBox(height: 18),
        for (final member in familyMembers)
          Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFDCE8F8),
                child: Text(member.initials),
              ),
              title: Text(member.name),
              subtitle: Text(
                relationshipFor(viewer: viewer, person: member),
              ),
              trailing: Text(
                snapshots[member.name]!.label,
                style: TextStyle(
                  color: _availabilityColor(snapshots[member.name]!.kind),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        const _PageTitle(
          'Calendar',
          'Birthdays and relevant national holidays.',
        ),
        const SizedBox(height: 20),
        const _SectionHeading('Birthdays'),
        const SizedBox(height: 12),
        const _BirthdayStrip(),
        const SizedBox(height: 28),
        const _SectionHeading('National holidays'),
        const SizedBox(height: 12),
        FutureBuilder<List<NationalHoliday>>(
          future: holidayFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const _EmptyState(
                'Holiday information unavailable',
                'Connect to the internet and reopen the app.',
              );
            }

            return Column(
              children: [
                for (final holiday in snapshot.data!.take(8))
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE8E2F4),
                        child: Text(
                          holiday.countryCode,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(holiday.name),
                      subtitle: Text(
                        DateFormat('EEEE, d MMMM').format(holiday.date),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.viewer,
    required this.onSwitchProfile,
  });

  final FamilyMember viewer;
  final VoidCallback onSwitchProfile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        const _PageTitle(
          'Settings',
          'Your identity is stored only on this device.',
        ),
        const SizedBox(height: 18),
        Card(
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(child: Text(viewer.initials)),
            title: Text('Using Pour Toujours as ${viewer.name}'),
            subtitle: const Text(
              'Times, relationships, and recommendations are personalized.',
            ),
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
  const _PageTitle(this.title, this.subtitle);

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
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF69726F),
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF69726F)),
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
