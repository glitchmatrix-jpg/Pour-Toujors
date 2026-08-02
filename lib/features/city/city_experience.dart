import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/design/pt_components.dart';
import '../../app/theme/pour_toujours_theme.dart';
import '../../core/alerts/weather_alert_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/time/availability_engine.dart';
import '../../core/weather/weather_models.dart';
import '../../core/weather/weather_service.dart';
import '../../data/family_context.dart';
import '../../data/family_seed.dart';
import '../navigation/detail_placeholders.dart';
import '../today/ambient_sky.dart';

class CityRoutePayload {
  const CityRoutePayload({required this.cityId, required this.viewerName});
  final String cityId;
  final String viewerName;
}

class HourlyRoutePayload {
  const HourlyRoutePayload({
    required this.city,
    required this.bundle,
    required this.day,
  });
  final FamilyCity city;
  final WeatherBundle bundle;
  final DailyWeather day;
}

class CityExperienceScreen extends StatefulWidget {
  const CityExperienceScreen({
    super.key,
    required this.initialCityId,
    required this.viewerName,
  });
  final String initialCityId;
  final String viewerName;

  @override
  State<CityExperienceScreen> createState() => _CityExperienceScreenState();
}

class _CityExperienceScreenState extends State<CityExperienceScreen> {
  final WeatherService _weather = WeatherService();
  final WeatherAlertService _alerts = WeatherAlertService();
  late String _cityId;
  late Future<_CityData> _future;
  bool _verticalForecast = false;

  @override
  void initState() {
    super.initState();
    _cityId = widget.initialCityId;
    _reload();
  }

  void _reload({bool force = false}) {
    _future = Future.wait<Object>([
      _weather.fetchBundle(_cityId, forceRefresh: force),
      _alerts.fetchOfficialForCity(_cityId),
    ]).then((values) {
      final bundle = values.first as WeatherBundle;
      final official = values.last as List<FamilyWeatherAlert>;
      return _CityData(bundle, [...official, ..._alerts.derive(_cityId, bundle)]);
    });
  }

  void _selectCity(String id) {
    if (id == _cityId) return;
    setState(() {
      _cityId = id;
      _reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final city = _city(_cityId);
    final viewer = familyMembers.firstWhere(
      (member) => member.name == widget.viewerName,
      orElse: () => familyMembers.first,
    );
    return Scaffold(
      body: FutureBuilder<_CityData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: PtLoadingSkeleton(height: 520),
              ),
            );
          }
          if (!snapshot.hasData) {
            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  PtEmptyState(
                    title: '${city.name} weather is unavailable',
                    message:
                        'The city route remains usable. Retry when a connection returns.',
                    icon: Icons.cloud_off_outlined,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(() => _reload(force: true)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(() => _reload(force: true)),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _CityHero(
                    city: city,
                    viewer: viewer,
                    bundle: data.bundle,
                    alerts: data.alerts,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 80),
                  sliver: SliverList.list(
                    children: [
                      _CitySwitcher(selected: _cityId, onSelected: _selectCity),
                      if (data.alerts.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _AlertBanner(alert: _highestAlert(data.alerts)),
                      ],
                      const SizedBox(height: 24),
                      const PtSectionHeader('The city’s light'),
                      const SizedBox(height: 10),
                      _DaylightArc(city: city, bundle: data.bundle),
                      const SizedBox(height: 24),
                      PtSectionHeader(
                        'Seven-day forecast',
                        action: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              icon: Icon(Icons.view_week_outlined, size: 17),
                            ),
                            ButtonSegment(
                              value: true,
                              icon: Icon(Icons.view_agenda_outlined, size: 17),
                            ),
                          ],
                          selected: {_verticalForecast},
                          onSelectionChanged: (value) {
                            setState(() => _verticalForecast = value.first);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SevenDayForecast(
                        city: city,
                        bundle: data.bundle,
                        alerts: data.alerts,
                        vertical: _verticalForecast,
                      ),
                      const SizedBox(height: 24),
                      const PtSectionHeader('Local day timeline'),
                      const SizedBox(height: 10),
                      _LocalDayTimeline(city: city, bundle: data.bundle),
                      const SizedBox(height: 24),
                      const PtSectionHeader('People in this city'),
                      const SizedBox(height: 10),
                      _CityPeople(city: city, viewer: viewer),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            PourToujoursRouteNames.weatherCompare,
                            arguments: DetailRouteArgs(
                              title: 'Compare family weather',
                              viewerName: viewer.name,
                            ),
                          );
                        },
                        icon: const Icon(Icons.compare_arrows_rounded),
                        label: const Text('Compare all four cities'),
                      ),
                      if (data.bundle.isStale) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Showing the most recent cached forecast.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.pt.secondaryText,
                            fontSize: 11,
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
      ),
    );
  }
}

class _CityData {
  const _CityData(this.bundle, this.alerts);
  final WeatherBundle bundle;
  final List<FamilyWeatherAlert> alerts;
}

class _CityHero extends StatelessWidget {
  const _CityHero({
    required this.city,
    required this.viewer,
    required this.bundle,
    required this.alerts,
  });
  final FamilyCity city;
  final FamilyMember viewer;
  final WeatherBundle bundle;
  final List<FamilyWeatherAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final current = bundle.current;
    final local = _localNow(city);
    final viewerLocal = _localNow(_city(viewer.cityId));
    final difference = local.timeZoneOffset - viewerLocal.timeZoneOffset;
    final members = _members(city.id);
    final settings = AppSettingsScope.of(context).value;
    return AmbientSky(
      weather: current,
      day: bundle.daily.firstOrNull,
      height: 430,
      borderRadius: BorderRadius.zero,
      semanticLabel:
          '${city.name}, ${bundle.condition}, ${settings.temperature(current.temperature)}. ${members.length} family members.',
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _CityIdentityPainter(city.id)),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 10,
            child: IconButton.filledTonal(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          if (alerts.isNotEmpty)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 10,
              child: Badge(
                label: Text('${alerts.length}'),
                child: IconButton.filledTonal(
                  onPressed: () => _openAlert(context, _highestAlert(alerts)),
                  icon: const Icon(Icons.warning_amber_rounded),
                ),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city.country.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                Text(
                  city.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${DateFormat('EEEE, d MMMM').format(local)} · ${DateFormat(settings.clockFormat == ClockFormat.twentyFourHour ? 'HH:mm' : 'h:mm a').format(local)}',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                Text(
                  _differenceText(difference),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      settings.temperature(current.temperature),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 58,
                        height: .9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -3,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bundle.condition,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Feels like ${settings.temperature(current.feelsLike)} · ${members.length} people here',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CitySwitcher extends StatelessWidget {
  const _CitySwitcher({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final city = cities[index];
          return ChoiceChip(
            selected: city.id == selected,
            label: Text(city.name),
            onSelected: (_) => onSelected(city.id),
          );
        },
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.alert});
  final FamilyWeatherAlert alert;

  @override
  Widget build(BuildContext context) {
    final tornadoWarning = alert.source == WeatherAlertSource.official &&
        alert.event.toLowerCase().contains('tornado warning');
    final color = tornadoWarning ||
            alert.severity == WeatherAlertSeverity.extreme
        ? context.pt.warning
        : alert.source == WeatherAlertSource.official
            ? context.pt.warning
            : context.pt.accent;
    final shelterSupported = tornadoWarning &&
        alert.instruction.toLowerCase().contains('seek shelter');
    return Material(
      color: color.withValues(alpha: .12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: color.withValues(alpha: .55)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openAlert(context, alert),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_rounded, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _alertType(alert),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alert.headline,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (shelterSupported)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          'Seek shelter now',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    const SizedBox(height: 5),
                    Text(
                      _expiryText(alert),
                      style: TextStyle(
                        color: context.pt.secondaryText,
                        fontSize: 11,
                      ),
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

class _DaylightArc extends StatelessWidget {
  const _DaylightArc({required this.city, required this.bundle});
  final FamilyCity city;
  final WeatherBundle bundle;

  @override
  Widget build(BuildContext context) {
    final day = bundle.daily.first;
    final local = _localNow(city);
    final dawn = day.sunrise.subtract(const Duration(minutes: 30));
    final dusk = day.sunset.add(const Duration(minutes: 30));
    final noon = day.sunrise.add(
      Duration(seconds: day.daylightDuration.inSeconds ~/ 2),
    );
    final progress = local.isBefore(day.sunrise)
        ? 0.0
        : local.isAfter(day.sunset)
            ? 1.0
            : local.difference(day.sunrise).inMinutes /
                math.max(1, day.daylightDuration.inMinutes);
    final untilSunrise = day.sunrise.isAfter(local)
        ? day.sunrise.difference(local)
        : day.sunrise.add(const Duration(days: 1)).difference(local);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: context.pt.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.pt.outline),
      ),
      child: Column(
        children: [
          Semantics(
            label:
                'Dawn ${DateFormat('h:mm a').format(dawn)}, sunrise ${DateFormat('h:mm a').format(day.sunrise)}, solar noon ${DateFormat('h:mm a').format(noon)}, sunset ${DateFormat('h:mm a').format(day.sunset)}, dusk ${DateFormat('h:mm a').format(dusk)}.',
            child: SizedBox(
              height: 145,
              width: double.infinity,
              child: CustomPaint(
                painter: _SolarArcPainter(progress: progress.clamp(0, 1)),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TimePoint('Dawn', dawn),
              _TimePoint('Sunrise', day.sunrise),
              _TimePoint('Noon', noon),
              _TimePoint('Sunset', day.sunset),
              _TimePoint('Dusk', dusk),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            local.isBefore(day.sunrise)
                ? 'Sunrise in ${_duration(untilSunrise)}'
                : local.isBefore(day.sunset)
                    ? 'Sunset in ${_duration(day.sunset.difference(local))}'
                    : 'Sunrise in ${_duration(untilSunrise)}',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${_duration(day.daylightDuration)} of daylight · ${_daylightElapsed(local, day)}',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.pt.secondaryText),
          ),
          if (!bundle.current.isDay) ...[
            const SizedBox(height: 8),
            Text(
              'Moon: ${_moonPhase(local)}',
              style: TextStyle(
                color: context.pt.secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimePoint extends StatelessWidget {
  const _TimePoint(this.label, this.time);
  final String label;
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: context.pt.secondaryText, fontSize: 9),
        ),
        Text(
          DateFormat('HH:mm').format(time),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
        ),
      ],
    );
  }
}

class _SevenDayForecast extends StatelessWidget {
  const _SevenDayForecast({
    required this.city,
    required this.bundle,
    required this.alerts,
    required this.vertical,
  });
  final FamilyCity city;
  final WeatherBundle bundle;
  final List<FamilyWeatherAlert> alerts;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return Column(
        children: [
          for (var index = 0; index < bundle.daily.length; index++) ...[
            _ForecastDayTile(
              city: city,
              bundle: bundle,
              day: bundle.daily[index],
              today: index == 0,
              alert: alerts.firstOrNull,
            ),
            if (index != bundle.daily.length - 1) const SizedBox(height: 8),
          ],
        ],
      );
    }
    return SizedBox(
      height: 218,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: bundle.daily.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 144,
            child: _ForecastDayTile(
              city: city,
              bundle: bundle,
              day: bundle.daily[index],
              today: index == 0,
              alert: alerts.firstOrNull,
              compact: true,
            ),
          );
        },
      ),
    );
  }
}

class _ForecastDayTile extends StatelessWidget {
  const _ForecastDayTile({
    required this.city,
    required this.bundle,
    required this.day,
    required this.today,
    required this.alert,
    this.compact = false,
  });
  final FamilyCity city;
  final WeatherBundle bundle;
  final DailyWeather day;
  final bool today;
  final FamilyWeatherAlert? alert;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context).value;
    final dayAlert = alert;
    return Material(
      color: today ? context.pt.accent.withValues(alpha: .11) : context.pt.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(21),
        side: BorderSide(color: today ? context.pt.accent : context.pt.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: () {
          Navigator.pushNamed(
            context,
            PourToujoursRouteNames.hourlyWeather,
            arguments: DetailRouteArgs(
              title: '${city.name} hourly forecast',
              payload: HourlyRoutePayload(city: city, bundle: bundle, day: day),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _contents(context, settings, dayAlert),
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _contents(context, settings, dayAlert),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
        ),
      ),
    );
  }

  List<Widget> _contents(
    BuildContext context,
    AppSettings settings,
    FamilyWeatherAlert? dayAlert,
  ) {
    return [
      Row(
        children: [
          Expanded(
            child: Text(
              today ? 'Today' : DateFormat('EEEE').format(day.date),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          if (dayAlert?.isInterruptive ?? false)
            Icon(Icons.warning_rounded, size: 16, color: context.pt.warning),
        ],
      ),
      const SizedBox(height: 7),
      Icon(_weatherIcon(day.weatherCode), size: 26),
      const SizedBox(height: 6),
      Text(
        '${settings.temperature(day.high)} / ${settings.temperature(day.low)}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      Text(
        '${day.precipitationProbability}% rain · ${day.windMaximum.round()} km/h',
        style: TextStyle(color: context.pt.secondaryText, fontSize: 10),
      ),
      Text(
        '↑ ${DateFormat('HH:mm').format(day.sunrise)}  ↓ ${DateFormat('HH:mm').format(day.sunset)}',
        style: TextStyle(color: context.pt.secondaryText, fontSize: 10),
      ),
      Text(
        'UV ${day.uvMaximum.round()} · ${_practicalSummary(day)}',
        maxLines: compact ? 3 : 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: context.pt.secondaryText, fontSize: 10),
      ),
    ];
  }
}

class _LocalDayTimeline extends StatelessWidget {
  const _LocalDayTimeline({required this.city, required this.bundle});
  final FamilyCity city;
  final WeatherBundle bundle;

  @override
  Widget build(BuildContext context) {
    final members = _members(city.id);
    final day = bundle.daily.first;
    final local = _localNow(city);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.pt.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.pt.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather, daylight, and routine estimates',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Semantics(
            label:
                'Twenty-four hour timeline for ${city.name}, combining daylight, rain chance, and routine availability.',
            child: SizedBox(
              height: 74,
              child: Row(
                children: [
                  for (var hour = 0; hour < 24; hour++)
                    Expanded(
                      child: _DayCell(
                        hour: hour,
                        city: city,
                        members: members,
                        day: day,
                        hourly: _hourFor(bundle, hour),
                        current: hour == local.hour,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12a', style: TextStyle(fontSize: 9)),
              Text('6a', style: TextStyle(fontSize: 9)),
              Text('12p', style: TextStyle(fontSize: 9)),
              Text('6p', style: TextStyle(fontSize: 9)),
              Text('12a', style: TextStyle(fontSize: 9)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'At ${DateFormat('h:mm a').format(local)}, ${_availableCount(members)} of ${members.length} people are in a likely-free routine window. This is not live activity tracking.',
            style: TextStyle(color: context.pt.secondaryText, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.hour,
    required this.city,
    required this.members,
    required this.day,
    required this.hourly,
    required this.current,
  });
  final int hour;
  final FamilyCity city;
  final List<FamilyMember> members;
  final DailyWeather day;
  final HourlyWeather? hourly;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final instant = tz.TZDateTime(
      tz.getLocation(city.timezone),
      day.date.year,
      day.date.month,
      day.date.day,
      hour,
    );
    final daylight = instant.isAfter(day.sunrise) && instant.isBefore(day.sunset);
    final free = members.where((member) {
      return evaluateAvailability(
            member: member,
            city: city,
            now: instant,
          ).kind ==
          AvailabilityKind.likelyFree;
    }).length;
    final rain = (hourly?.precipitationProbability ?? 0) / 100;
    return Tooltip(
      message:
          '$hour:00 · ${daylight ? 'daylight' : 'night'} · $free usually free · ${(rain * 100).round()}% rain',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: .5),
        decoration: BoxDecoration(
          color: daylight
              ? context.pt.warning.withValues(alpha: .16 + free * .03)
              : context.pt.asleep.withValues(alpha: .42),
          border: current ? Border.all(color: context.pt.accent, width: 2) : null,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: rain.clamp(.05, 1),
          widthFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.pt.accent.withValues(alpha: .38),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}

class _CityPeople extends StatelessWidget {
  const _CityPeople({required this.city, required this.viewer});
  final FamilyCity city;
  final FamilyMember viewer;

  @override
  Widget build(BuildContext context) {
    final members = _members(city.id);
    return Column(
      children: [
        for (var index = 0; index < members.length; index++) ...[
          _PersonPreview(member: members[index], viewer: viewer, city: city),
          if (index != members.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PersonPreview extends StatelessWidget {
  const _PersonPreview({
    required this.member,
    required this.viewer,
    required this.city,
  });
  final FamilyMember member;
  final FamilyMember viewer;
  final FamilyCity city;

  @override
  Widget build(BuildContext context) {
    final snapshot = evaluateAvailability(member: member, city: city);
    final next = _nextContact(member, city);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () {
          Navigator.pushNamed(
            context,
            PourToujoursRouteNames.person,
            arguments: DetailRouteArgs(
              title: member.name,
              subtitle: relationshipFor(viewer: viewer, person: member),
              payload: member.name,
              viewerName: viewer.name,
            ),
          );
        },
        leading: CircleAvatar(child: Text(member.initials)),
        title: Row(
          children: [
            Expanded(child: Text(member.name)),
            Text(
              snapshot.label,
              style: TextStyle(
                color: _availabilityColor(context, snapshot.kind),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${relationshipFor(viewer: viewer, person: member)} · ${snapshot.reason}\nNext good window: ${DateFormat('EEE h:mm a').format(next)}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class HourlyForecastScreen extends StatelessWidget {
  const HourlyForecastScreen({super.key, required this.payload});
  final HourlyRoutePayload payload;

  @override
  Widget build(BuildContext context) {
    final values = payload.bundle.hourly.take(48).toList();
    return Scaffold(
      appBar: AppBar(title: Text('${payload.city.name} · hourly')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 60),
        children: [
          Text(
            DateFormat('EEEE, d MMMM').format(payload.day.date),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Temperature, feels-like, rain, wind, gusts, humidity, UV, and daylight for up to 48 hours.',
            style: TextStyle(color: context.pt.secondaryText),
          ),
          const SizedBox(height: 18),
          if (values.isEmpty)
            const PtEmptyState(
              title: 'Hourly values unavailable',
              message: 'The daily forecast remains available.',
            )
          else ...[
            _HourlyChart(values: values),
            const SizedBox(height: 18),
            for (final item in values)
              Semantics(
                label:
                    '${DateFormat('EEEE h a').format(item.time)}. ${item.temperature.round()} degrees, feels like ${item.feelsLike.round()}, ${item.precipitationProbability} percent rain, wind ${item.windSpeed.round()}, gusts ${item.windGusts.round()}, humidity ${item.humidity} percent, UV ${item.uvIndex.round()}.',
                child: ListTile(
                  leading: Text(DateFormat('ha').format(item.time)),
                  title: Text(
                    '${item.temperature.round()}° · feels ${item.feelsLike.round()}°',
                  ),
                  subtitle: Text(
                    '${item.precipitationProbability}% rain · wind ${item.windSpeed.round()} / gust ${item.windGusts.round()} · humidity ${item.humidity}% · UV ${item.uvIndex.round()}',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HourlyChart extends StatelessWidget {
  const _HourlyChart({required this.values});
  final List<HourlyWeather> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: context.pt.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.pt.outline),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: math.max(600, values.length * 52),
          child: CustomPaint(
            painter: _HourlyPainter(
              values: values,
              accent: context.pt.accent,
              secondary: context.pt.warning,
              grid: context.pt.outline,
              text: context.pt.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}

class WeatherComparisonScreen extends StatefulWidget {
  const WeatherComparisonScreen({super.key, required this.viewerName});
  final String viewerName;

  @override
  State<WeatherComparisonScreen> createState() => _WeatherComparisonScreenState();
}

class _WeatherComparisonScreenState extends State<WeatherComparisonScreen> {
  final WeatherService _weather = WeatherService();
  final WeatherAlertService _alerts = WeatherAlertService();
  late Future<List<_CompareRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.wait(cities.map((city) async {
      final bundle = await _weather.fetchBundle(city.id);
      final official = await _alerts.fetchOfficialForCity(city.id);
      return _CompareRow(
        city,
        bundle,
        [...official, ..._alerts.derive(city.id, bundle)],
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Four-city weather comparison')),
      body: FutureBuilder<List<_CompareRow>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: PtLoadingSkeleton(height: 420),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 50),
            children: [
              Text(
                'One matrix, four family cities',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Values share the same visual structure for direct comparison.',
                style: TextStyle(color: context.pt.secondaryText),
              ),
              const SizedBox(height: 18),
              _ComparisonMatrix(rows: snapshot.data!),
            ],
          );
        },
      ),
    );
  }
}

class _CompareRow {
  const _CompareRow(this.city, this.bundle, this.alerts);
  final FamilyCity city;
  final WeatherBundle bundle;
  final List<FamilyWeatherAlert> alerts;
}

class _ComparisonMatrix extends StatelessWidget {
  const _ComparisonMatrix({required this.rows});
  final List<_CompareRow> rows;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context).value;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 62,
        dataRowMaxHeight: 76,
        columns: const [
          DataColumn(label: Text('City')),
          DataColumn(label: Text('Now')),
          DataColumn(label: Text('Rain')),
          DataColumn(label: Text('Wind')),
          DataColumn(label: Text('Light left')),
          DataColumn(label: Text('Sunrise / sunset')),
          DataColumn(label: Text('Warnings')),
          DataColumn(label: Text('Best outdoors')),
        ],
        rows: [
          for (final row in rows)
            DataRow(
              cells: [
                DataCell(
                  Text(
                    row.city.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                DataCell(
                  Text(
                    '${settings.temperature(row.bundle.current.temperature)}\nFeels ${settings.temperature(row.bundle.current.feelsLike)}\n${row.bundle.condition}',
                  ),
                ),
                DataCell(Text('${row.bundle.current.rainChance}%')),
                DataCell(Text('${row.bundle.current.windSpeed.round()} km/h')),
                DataCell(Text(_lightRemaining(row.city, row.bundle))),
                DataCell(
                  Text(
                    '${DateFormat('HH:mm').format(row.bundle.daily.first.sunrise)} / ${DateFormat('HH:mm').format(row.bundle.daily.first.sunset)}',
                  ),
                ),
                DataCell(
                  Text(row.alerts.isEmpty ? 'None' : row.alerts.first.event),
                ),
                DataCell(Text(_bestOutdoor(row.bundle))),
              ],
            ),
        ],
      ),
    );
  }
}

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.alert});
  final FamilyWeatherAlert alert;

  @override
  Widget build(BuildContext context) {
    final official = alert.source == WeatherAlertSource.official;
    return Scaffold(
      appBar: AppBar(title: Text(alert.event)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            Icons.warning_rounded,
            size: 48,
            color: alert.isInterruptive ? context.pt.warning : context.pt.accent,
          ),
          const SizedBox(height: 16),
          Text(
            _alertType(alert),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            alert.headline,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 18),
          Text(alert.instruction, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 22),
          _DetailLine(
            'Source',
            alert.attribution ??
                (official ? 'Official authority' : 'Pour Toujours guidance'),
          ),
          _DetailLine('Severity', alert.severity.name),
          _DetailLine('Expires', _expiryText(alert)),
          if (alert.area != null) _DetailLine('Affected area', alert.area!),
          if (alert.urgency != null) _DetailLine('Urgency', alert.urgency!),
          if (alert.certainty != null) _DetailLine('Certainty', alert.certainty!),
          const SizedBox(height: 20),
          Text(
            official
                ? 'Follow the issuing authority and local emergency instructions.'
                : 'This is forecast-derived practical guidance, not an official warning or watch.',
            style: TextStyle(color: context.pt.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: context.pt.secondaryText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SolarArcPainter extends CustomPainter {
  const _SolarArcPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(16, size.height - 20)
      ..quadraticBezierTo(size.width / 2, 8, size.width - 16, size.height - 20);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: .22)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    final metric = path.computeMetrics().first;
    final tangent = metric.getTangentForOffset(metric.length * progress);
    if (tangent != null) {
      canvas.drawCircle(
        tangent.position,
        15,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFFFE5A0), Color(0x00FFE5A0)],
          ).createShader(
            Rect.fromCircle(center: tangent.position, radius: 15),
          ),
      );
      canvas.drawCircle(
        tangent.position,
        5,
        Paint()..color = const Color(0xFFFFD56A),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SolarArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CityIdentityPainter extends CustomPainter {
  const _CityIdentityPainter(this.cityId);
  final String cityId;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height * .74;
    final silhouette = Paint()..color = Colors.black.withValues(alpha: .18);
    if (cityId == 'karachi' || cityId == 'chiba') {
      final water = cityId == 'karachi'
          ? const Color(0xFF255A67)
          : const Color(0xFF173E63);
      canvas.drawRect(
        Rect.fromLTWH(0, baseline, size.width, size.height - baseline),
        Paint()..color = water.withValues(alpha: .35),
      );
      for (var index = 0; index < 12; index++) {
        final height = 22.0 + (index % 5) * 13;
        canvas.drawRect(
          Rect.fromLTWH(
            index * size.width / 11,
            baseline - height,
            size.width / 15,
            height,
          ),
          silhouette,
        );
      }
    } else if (cityId == 'dublin') {
      for (var index = 0; index < 11; index++) {
        final x = index * size.width / 10;
        final roof = Path()
          ..moveTo(x, baseline)
          ..lineTo(x + size.width / 22, baseline - 25)
          ..lineTo(x + size.width / 11, baseline)
          ..close();
        canvas.drawPath(roof, silhouette);
        canvas.drawRect(
          Rect.fromLTWH(x, baseline, size.width / 11, 42),
          silhouette,
        );
      }
    } else {
      final canopy = Paint()
        ..color = const Color(0xFF183E32).withValues(alpha: .35);
      for (var index = 0; index < 12; index++) {
        canvas.drawCircle(
          Offset(index * size.width / 11, baseline - 18 - (index % 3) * 8),
          30,
          canopy,
        );
      }
      canvas.drawRect(
        Rect.fromLTWH(0, baseline, size.width, size.height - baseline),
        silhouette,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CityIdentityPainter oldDelegate) {
    return oldDelegate.cityId != cityId;
  }
}

class _HourlyPainter extends CustomPainter {
  const _HourlyPainter({
    required this.values,
    required this.accent,
    required this.secondary,
    required this.grid,
    required this.text,
  });
  final List<HourlyWeather> values;
  final Color accent;
  final Color secondary;
  final Color grid;
  final Color text;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 38.0;
    const top = 25.0;
    const bottom = 42.0;
    final plot = Rect.fromLTRB(left, top, size.width - 12, size.height - bottom);
    final temperatures = values.expand((value) {
      return [value.temperature, value.feelsLike];
    });
    final minimum = temperatures.reduce(math.min) - 2;
    final maximum = temperatures.reduce(math.max) + 2;
    for (var index = 0; index <= 4; index++) {
      final y = plot.top + plot.height * index / 4;
      canvas.drawLine(
        Offset(plot.left, y),
        Offset(plot.right, y),
        Paint()..color = grid,
      );
      final value = maximum - (maximum - minimum) * index / 4;
      _drawText(canvas, '${value.round()}°', Offset(3, y - 7), 9);
    }
    final temperaturePath = Path();
    final feelsPath = Path();
    for (var index = 0; index < values.length; index++) {
      final x = plot.left + plot.width * index / math.max(1, values.length - 1);
      final temperatureY = plot.bottom -
          (values[index].temperature - minimum) /
              (maximum - minimum) *
              plot.height;
      final feelsY = plot.bottom -
          (values[index].feelsLike - minimum) /
              (maximum - minimum) *
              plot.height;
      if (index == 0) {
        temperaturePath.moveTo(x, temperatureY);
        feelsPath.moveTo(x, feelsY);
      } else {
        temperaturePath.lineTo(x, temperatureY);
        feelsPath.lineTo(x, feelsY);
      }
      final rainHeight = plot.height *
          .24 *
          values[index].precipitationProbability /
          100;
      canvas.drawRect(
        Rect.fromLTWH(x - 4, plot.bottom - rainHeight, 8, rainHeight),
        Paint()..color = accent.withValues(alpha: .28),
      );
      if (index % 3 == 0) {
        _drawText(
          canvas,
          DateFormat('ha').format(values[index].time),
          Offset(x - 12, plot.bottom + 9),
          8,
        );
      }
    }
    canvas.drawPath(
      temperaturePath,
      Paint()
        ..color = accent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      feelsPath,
      Paint()
        ..color = secondary
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke,
    );
    _drawText(canvas, 'Temperature', const Offset(42, 5), 9, color: accent);
    _drawText(canvas, 'Feels-like', const Offset(120, 5), 9, color: secondary);
  }

  void _drawText(
    Canvas canvas,
    String value,
    Offset offset,
    double size, {
    Color? color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(color: color ?? text, fontSize: size),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _HourlyPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

FamilyCity _city(String id) {
  return cities.firstWhere((city) => city.id == id);
}

List<FamilyMember> _members(String id) {
  return familyMembers.where((member) => member.cityId == id).toList();
}

tz.TZDateTime _localNow(FamilyCity city) {
  return tz.TZDateTime.now(tz.getLocation(city.timezone));
}

String _differenceText(Duration difference) {
  final minutes = difference.inMinutes;
  if (minutes == 0) return 'Same time as you';
  final hours = minutes.abs() ~/ 60;
  final extra = minutes.abs() % 60;
  final value = extra == 0 ? '${hours}h' : '${hours}h ${extra}m';
  return '$value ${minutes.isNegative ? 'behind' : 'ahead'} of you';
}

FamilyWeatherAlert _highestAlert(List<FamilyWeatherAlert> alerts) {
  final values = [...alerts]
    ..sort((first, second) {
      if (first.source != second.source) {
        return first.source == WeatherAlertSource.official ? -1 : 1;
      }
      return second.severity.index.compareTo(first.severity.index);
    });
  return values.first;
}

void _openAlert(BuildContext context, FamilyWeatherAlert alert) {
  Navigator.pushNamed(
    context,
    PourToujoursRouteNames.alert,
    arguments: DetailRouteArgs(
      title: alert.event,
      subtitle: alert.headline,
      payload: alert,
    ),
  );
}

String _alertType(FamilyWeatherAlert alert) {
  if (alert.source == WeatherAlertSource.derived) {
    return 'FORECAST-DERIVED ADVISORY';
  }
  if (alert.event.toLowerCase().contains('warning')) {
    return 'OFFICIAL WARNING';
  }
  if (alert.event.toLowerCase().contains('watch')) {
    return 'OFFICIAL WATCH';
  }
  return 'OFFICIAL WEATHER ALERT';
}

String _expiryText(FamilyWeatherAlert alert) {
  if (alert.expires == null) return 'Expiry not provided';
  return 'Expires ${DateFormat('EEE h:mm a').format(alert.expires!.toLocal())}';
}

String _duration(Duration value) {
  final total = value.inMinutes.abs();
  final hours = total ~/ 60;
  final minutes = total % 60;
  if (hours == 0) return '$minutes min';
  if (minutes == 0) return '$hours h';
  return '$hours h $minutes min';
}

String _daylightElapsed(DateTime local, DailyWeather day) {
  if (local.isBefore(day.sunrise)) return 'daylight has not begun';
  if (local.isAfter(day.sunset)) return 'daylight complete';
  final elapsed = local.difference(day.sunrise);
  final remaining = day.sunset.difference(local);
  return '${_duration(elapsed)} elapsed · ${_duration(remaining)} remaining';
}

String _moonPhase(DateTime date) {
  final days = date
          .toUtc()
          .difference(DateTime.utc(2000, 1, 6, 18, 14))
          .inMinutes /
      1440;
  final phase = ((days % 29.53058867) / 29.53058867 + 1) % 1;
  if (phase < .03 || phase > .97) return 'new moon';
  if (phase < .22) return 'waxing crescent';
  if (phase < .28) return 'first quarter';
  if (phase < .47) return 'waxing gibbous';
  if (phase < .53) return 'full moon';
  if (phase < .72) return 'waning gibbous';
  if (phase < .78) return 'last quarter';
  return 'waning crescent';
}

String _practicalSummary(DailyWeather day) {
  if (day.weatherCode >= 95) return 'Keep indoor options ready';
  if (day.precipitationProbability >= 70) return 'Carry rain protection';
  if (day.uvMaximum >= 8) return 'Seek shade near midday';
  if (day.windMaximum >= 45) return 'Wind may affect plans';
  return 'Generally workable conditions';
}

HourlyWeather? _hourFor(WeatherBundle bundle, int hour) {
  for (final item in bundle.hourly) {
    if (item.time.hour == hour) return item;
  }
  return null;
}

int _availableCount(List<FamilyMember> members) {
  return members.where((member) {
    return evaluateAvailability(
          member: member,
          city: _city(member.cityId),
        ).kind ==
        AvailabilityKind.likelyFree;
  }).length;
}

DateTime _nextContact(FamilyMember member, FamilyCity city) {
  final now = DateTime.now().toUtc();
  for (var step = 1; step <= 96; step++) {
    final instant = now.add(Duration(minutes: step * 15));
    final kind = evaluateAvailability(
      member: member,
      city: city,
      now: instant,
    ).kind;
    if (kind == AvailabilityKind.likelyFree) return instant;
  }
  return now.add(const Duration(days: 1));
}

String _lightRemaining(FamilyCity city, WeatherBundle bundle) {
  final now = _localNow(city);
  final day = bundle.daily.first;
  if (now.isAfter(day.sunset)) return 'Night';
  if (now.isBefore(day.sunrise)) return 'Before sunrise';
  return _duration(day.sunset.difference(now));
}

String _bestOutdoor(WeatherBundle bundle) {
  final candidates = bundle.hourly.where((item) {
    return item.precipitationProbability < 35 &&
        item.uvIndex < 7 &&
        item.windGusts < 40;
  }).take(12).toList();
  if (candidates.isEmpty) return 'No clear window';
  return DateFormat('h a').format(candidates.first.time);
}

Color _availabilityColor(BuildContext context, AvailabilityKind kind) {
  return switch (kind) {
    AvailabilityKind.likelyFree => context.pt.success,
    AvailabilityKind.maybeFree => context.pt.uncertain,
    AvailabilityKind.working => context.pt.working,
    AvailabilityKind.asleep => context.pt.asleep,
    AvailabilityKind.unknown => context.pt.unavailable,
  };
}

IconData _weatherIcon(int code) {
  if (code >= 95) return Icons.thunderstorm_rounded;
  if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
    return Icons.water_drop_outlined;
  }
  if (code == 45 || code == 48) return Icons.blur_on_rounded;
  if (code >= 2) return Icons.cloud_outlined;
  return Icons.light_mode_rounded;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
