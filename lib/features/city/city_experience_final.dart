import 'dart:math' as math;

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

enum CelestialBody { sun, moon }

@immutable
class CelestialPosition {
  const CelestialPosition({
    required this.body,
    required this.progress,
    required this.isTwilight,
  });

  final CelestialBody body;
  final double progress;
  final bool isTwilight;
}

CelestialPosition celestialPosition({
  required DateTime now,
  required DateTime sunrise,
  required DateTime sunset,
}) {
  final dawn = sunrise.subtract(const Duration(minutes: 30));
  final dusk = sunset.add(const Duration(minutes: 30));
  if (!now.isBefore(sunrise) && now.isBefore(sunset)) {
    final span = math.max(1, sunset.difference(sunrise).inSeconds);
    return CelestialPosition(
      body: CelestialBody.sun,
      progress: (now.difference(sunrise).inSeconds / span).clamp(0, 1),
      isTwilight: now.isBefore(sunrise.add(const Duration(minutes: 30))) ||
          now.isAfter(sunset.subtract(const Duration(minutes: 30))),
    );
  }

  final nightStart = now.isBefore(sunrise)
      ? sunset.subtract(const Duration(days: 1))
      : sunset;
  final nightEnd = now.isBefore(sunrise)
      ? sunrise
      : sunrise.add(const Duration(days: 1));
  final span = math.max(1, nightEnd.difference(nightStart).inSeconds);
  return CelestialPosition(
    body: CelestialBody.moon,
    progress: (now.difference(nightStart).inSeconds / span).clamp(0, 1),
    isTwilight: (!now.isBefore(dawn) && now.isBefore(sunrise)) ||
        (!now.isBefore(sunset) && now.isBefore(dusk)),
  );
}

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
  late String _cityId = widget.initialCityId;
  late Future<_CityData> _future = _load();
  bool _verticalForecast = false;

  Future<_CityData> _load({bool force = false}) async {
    final bundle = await _weather.fetchBundle(_cityId, forceRefresh: force);
    final official = await _alerts.fetchOfficialForCity(_cityId);
    return _CityData(bundle, [...official, ..._alerts.derive(_cityId, bundle)]);
  }

  void _selectCity(String cityId) {
    if (cityId == _cityId) return;
    setState(() {
      _cityId = cityId;
      _future = _load();
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
          if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
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
                    message: 'Retry when a connection returns. Cached family information remains available.',
                    icon: Icons.cloud_off_outlined,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(() => _future = _load(force: true)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load(force: true)),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _CityHero(city: city, viewer: viewer, data: data),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
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
                            ButtonSegment(value: false, icon: Icon(Icons.view_week_outlined, size: 17)),
                            ButtonSegment(value: true, icon: Icon(Icons.view_agenda_outlined, size: 17)),
                          ],
                          selected: {_verticalForecast},
                          onSelectionChanged: (value) => setState(() => _verticalForecast = value.first),
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
                        onPressed: () => Navigator.pushNamed(
                          context,
                          PourToujoursRouteNames.weatherCompare,
                          arguments: DetailRouteArgs(
                            title: 'Compare family weather',
                            viewerName: viewer.name,
                          ),
                        ),
                        icon: const Icon(Icons.compare_arrows_rounded),
                        label: const Text('Compare all four cities'),
                      ),
                      if (data.bundle.isStale) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Showing the most recent cached forecast.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.pt.secondaryText, fontSize: 11),
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
  const _CityHero({required this.city, required this.viewer, required this.data});
  final FamilyCity city;
  final FamilyMember viewer;
  final _CityData data;

  @override
  Widget build(BuildContext context) {
    final local = _localNow(city);
    final viewerLocal = _localNow(_city(viewer.cityId));
    final settings = AppSettingsScope.of(context).value;
    final current = data.bundle.current;
    final members = _members(city.id);
    return AmbientSky(
      weather: current,
      day: data.bundle.daily.firstOrNull,
      height: 430,
      borderRadius: BorderRadius.zero,
      semanticLabel: '${city.name}, ${data.bundle.condition}, ${settings.temperature(current.temperature)}, ${members.length} people.',
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _CityIdentityPainter(city.id))),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 10,
            child: IconButton.filledTonal(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          if (data.alerts.isNotEmpty)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 10,
              child: Badge(
                label: Text('${data.alerts.length}'),
                child: IconButton.filledTonal(
                  tooltip: 'Weather alerts',
                  onPressed: () => _openAlert(context, _highestAlert(data.alerts)),
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
                Text(city.country.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                Text(city.name, style: const TextStyle(color: Colors.white, fontSize: 42, height: 1, fontWeight: FontWeight.w900, letterSpacing: -1.8)),
                const SizedBox(height: 8),
                Text(
                  '${DateFormat('EEEE, d MMMM').format(local)} · ${DateFormat(settings.clockFormat == ClockFormat.twentyFourHour ? 'HH:mm' : 'h:mm a').format(local)}',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                Text(_differenceText(local.timeZoneOffset - viewerLocal.timeZoneOffset), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(settings.temperature(current.temperature), style: const TextStyle(color: Colors.white, fontSize: 58, height: .9, fontWeight: FontWeight.w800, letterSpacing: -3)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data.bundle.condition, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            Text('Feels like ${settings.temperature(current.feelsLike)} · ${members.length} people here', style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
  Widget build(BuildContext context) => SizedBox(
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

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.alert});
  final FamilyWeatherAlert alert;

  @override
  Widget build(BuildContext context) {
    final warning = alert.source == WeatherAlertSource.official && alert.event.toLowerCase().contains('warning');
    final tornado = warning && alert.event.toLowerCase().contains('tornado');
    final color = warning || alert.severity == WeatherAlertSeverity.extreme ? context.pt.warning : context.pt.accent;
    final shelter = tornado && alert.instruction.toLowerCase().contains('seek shelter');
    return Material(
      color: color.withValues(alpha: .12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: color.withValues(alpha: .55))),
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
                    Text(_alertType(alert), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 3),
                    Text(alert.headline, style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (shelter) Padding(padding: const EdgeInsets.only(top: 5), child: Text('Seek shelter now', style: TextStyle(color: color, fontWeight: FontWeight.w900))),
                    const SizedBox(height: 5),
                    Text(_expiryText(alert), style: TextStyle(color: context.pt.secondaryText, fontSize: 11)),
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
    final noon = day.sunrise.add(Duration(seconds: day.daylightDuration.inSeconds ~/ 2));
    final celestial = celestialPosition(now: local, sunrise: day.sunrise, sunset: day.sunset);
    final untilSunrise = day.sunrise.isAfter(local)
        ? day.sunrise.difference(local)
        : day.sunrise.add(const Duration(days: 1)).difference(local);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(color: context.pt.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: context.pt.outline)),
      child: Column(
        children: [
          Semantics(
            label: '${celestial.body.name} at ${(celestial.progress * 100).round()} percent of its ${celestial.body == CelestialBody.sun ? 'daylight' : 'night'} path. Dawn ${DateFormat('h:mm a').format(dawn)}, sunrise ${DateFormat('h:mm a').format(day.sunrise)}, solar noon ${DateFormat('h:mm a').format(noon)}, sunset ${DateFormat('h:mm a').format(day.sunset)}, dusk ${DateFormat('h:mm a').format(dusk)}.',
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: CustomPaint(
                key: const ValueKey('celestial-arc'),
                painter: _CelestialArcPainter(position: celestial, accent: context.pt.accent),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('${_duration(day.daylightDuration)} of daylight · ${_daylightElapsed(local, day)}', textAlign: TextAlign.center, style: TextStyle(color: context.pt.secondaryText)),
          if (celestial.body == CelestialBody.moon) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.nightlight_round, size: 15),
                const SizedBox(width: 6),
                Text('Moon: ${_moonPhase(local)}', style: TextStyle(color: context.pt.secondaryText, fontSize: 11)),
              ],
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
  Widget build(BuildContext context) => Column(
        children: [
          Text(label, style: TextStyle(color: context.pt.secondaryText, fontSize: 9)),
          Text(DateFormat('HH:mm').format(time), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10)),
        ],
      );
}

class _SevenDayForecast extends StatelessWidget {
  const _SevenDayForecast({required this.city, required this.bundle, required this.alerts, required this.vertical});
  final FamilyCity city;
  final WeatherBundle bundle;
  final List<FamilyWeatherAlert> alerts;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      for (var index = 0; index < bundle.daily.length; index++)
        _ForecastDayTile(city: city, bundle: bundle, day: bundle.daily[index], today: index == 0, alert: alerts.firstOrNull, compact: !vertical),
    ];
    if (vertical) return Column(children: [for (final tile in tiles) ...[tile, const SizedBox(height: 8)]]);
    return SizedBox(
      height: 232,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, index) => SizedBox(width: 148, child: tiles[index]),
      ),
    );
  }
}

class _ForecastDayTile extends StatelessWidget {
  const _ForecastDayTile({required this.city, required this.bundle, required this.day, required this.today, required this.alert, required this.compact});
  final FamilyCity city;
  final WeatherBundle bundle;
  final DailyWeather day;
  final bool today;
  final FamilyWeatherAlert? alert;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context).value;
    final contents = <Widget>[
      Row(children: [Expanded(child: Text(today ? 'Today' : DateFormat('EEEE').format(day.date), style: const TextStyle(fontWeight: FontWeight.w900))), if (alert?.isInterruptive ?? false) Icon(Icons.warning_rounded, size: 16, color: context.pt.warning)]),
      const SizedBox(height: 8),
      Icon(_weatherIcon(day.weatherCode), size: 26),
      const SizedBox(height: 7),
      Text('${settings.temperature(day.high)} / ${settings.temperature(day.low)}', style: const TextStyle(fontWeight: FontWeight.w800)),
      Text('${day.precipitationProbability}% rain · ${day.windMaximum.round()} km/h', style: TextStyle(color: context.pt.secondaryText, fontSize: 10)),
      Text('↑ ${DateFormat('HH:mm').format(day.sunrise)}  ↓ ${DateFormat('HH:mm').format(day.sunset)}', style: TextStyle(color: context.pt.secondaryText, fontSize: 10)),
      Text('UV ${day.uvMaximum.round()} · ${_practicalSummary(day)}', maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.pt.secondaryText, fontSize: 10)),
    ];
    return Material(
      color: today ? context.pt.accent.withValues(alpha: .11) : context.pt.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21), side: BorderSide(color: today ? context.pt.accent : context.pt.outline)),
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: () => Navigator.pushNamed(
          context,
          PourToujoursRouteNames.hourlyWeather,
          arguments: DetailRouteArgs(title: '${city.name} hourly forecast', payload: HourlyRoutePayload(city: city, bundle: bundle, day: day)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: compact
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: contents)
              : Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: contents)), const Icon(Icons.chevron_right_rounded)]),
        ),
      ),
    );
  }
}

class _LocalDayTimeline extends StatelessWidget {
  const _LocalDayTimeline({required this.city, required this.bundle});
  final FamilyCity city;
  final WeatherBundle bundle;

  @override
  Widget build(BuildContext context) {
    final members = _members(city.id);
    final local = _localNow(city);
    final day = bundle.daily.first;
    return Container(
      key: const ValueKey('local-day-block-timeline'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.pt.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: context.pt.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A readable day at a glance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          Text('Two-hour blocks combine light, routine comfort, and rain chance.', style: TextStyle(color: context.pt.secondaryText, fontSize: 11)),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 4.0;
              final width = (constraints.maxWidth - gap * 5) / 6;
              return Wrap(
                spacing: gap,
                runSpacing: 8,
                children: [
                  for (var start = 0; start < 24; start += 2)
                    SizedBox(
                      width: width,
                      child: _TimeBlock(
                        startHour: start,
                        city: city,
                        members: members,
                        day: day,
                        hourly: _hourFor(bundle, start),
                        current: local.hour >= start && local.hour < start + 2,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 7,
            children: const [
              _LegendDot(label: 'Likely free', kind: AvailabilityKind.likelyFree),
              _LegendDot(label: 'Busy', kind: AvailabilityKind.working),
              _LegendDot(label: 'Uncertain', kind: AvailabilityKind.maybeFree),
              _LegendDot(label: 'Asleep', kind: AvailabilityKind.asleep),
            ],
          ),
          const SizedBox(height: 13),
          Text('At ${DateFormat('h:mm a').format(local)}, ${_availableCount(members)} of ${members.length} people are in a likely-free routine window. These are estimates, not live activity.', style: TextStyle(color: context.pt.secondaryText, fontSize: 11)),
        ],
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({required this.startHour, required this.city, required this.members, required this.day, required this.hourly, required this.current});
  final int startHour;
  final FamilyCity city;
  final List<FamilyMember> members;
  final DailyWeather day;
  final HourlyWeather? hourly;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final instant = tz.TZDateTime(tz.getLocation(city.timezone), day.date.year, day.date.month, day.date.day, startHour);
    final daylight = !instant.isBefore(day.sunrise) && instant.isBefore(day.sunset);
    final snapshots = [for (final member in members) evaluateAvailability(member: member, city: city, now: instant)];
    final kind = _dominantKind(snapshots.map((value) => value.kind));
    final rain = hourly?.precipitationProbability ?? 0;
    final color = _availabilityColor(context, kind);
    return Tooltip(
      message: '${_hourLabel(startHour)}–${_hourLabel((startHour + 2) % 24)} · ${daylight ? 'daylight' : 'night'} · ${_kindLabel(kind)} · $rain% rain',
      child: Semantics(
        label: '${_hourLabel(startHour)} to ${_hourLabel((startHour + 2) % 24)}, ${daylight ? 'daylight' : 'night'}, ${_kindLabel(kind)}, $rain percent rain.',
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: current ? context.pt.accent : color.withValues(alpha: .36), width: current ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Icon(daylight ? Icons.light_mode_rounded : Icons.nightlight_round, size: 12, color: daylight ? context.pt.warning : context.pt.asleep), const Spacer(), if (rain >= 40) const Icon(Icons.water_drop_outlined, size: 11)]),
              const Spacer(),
              Text(_hourLabel(startHour), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
              Text(_shortKind(kind), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.pt.secondaryText, fontSize: 8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.kind});
  final String label;
  final AvailabilityKind kind;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: _availabilityColor(context, kind), shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: context.pt.secondaryText, fontSize: 9)),
        ],
      );
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
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              onTap: () => Navigator.pushNamed(
                context,
                PourToujoursRouteNames.person,
                arguments: DetailRouteArgs(
                  title: members[index].name,
                  subtitle: relationshipFor(viewer: viewer, person: members[index]),
                  payload: members[index].name,
                  viewerName: viewer.name,
                ),
              ),
              leading: CircleAvatar(child: Text(members[index].initials)),
              title: Text(members[index].name),
              subtitle: Text('${relationshipFor(viewer: viewer, person: members[index])} · ${evaluateAvailability(member: members[index], city: city).reason}', maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          if (index != members.length - 1) const SizedBox(height: 8),
        ],
      ],
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
          Text(DateFormat('EEEE, d MMMM').format(payload.day.date), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          if (values.isEmpty)
            const PtEmptyState(title: 'Hourly values unavailable', message: 'The daily forecast remains available.')
          else
            for (final item in values)
              ListTile(
                leading: Text(DateFormat('ha').format(item.time)),
                title: Text('${item.temperature.round()}° · feels ${item.feelsLike.round()}°'),
                subtitle: Text('${item.precipitationProbability}% rain · wind ${item.windSpeed.round()} · gust ${item.windGusts.round()} · humidity ${item.humidity}% · UV ${item.uvIndex.round()}'),
              ),
        ],
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
  late Future<List<WeatherBundle>> _future = Future.wait([for (final city in cities) _weather.fetchBundle(city.id)]);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Four-city weather comparison')),
        body: FutureBuilder<List<WeatherBundle>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(20), child: PtLoadingSkeleton(height: 420));
            final settings = AppSettingsScope.of(context).value;
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text('One clear comparison', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 14),
                for (var index = 0; index < cities.length; index++)
                  Card(
                    child: ListTile(
                      title: Text(cities[index].name, style: const TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: Text('${snapshot.data![index].condition} · ${snapshot.data![index].current.rainChance}% rain · wind ${snapshot.data![index].current.windSpeed.round()} km/h'),
                      trailing: Text(settings.temperature(snapshot.data![index].current.temperature), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    ),
                  ),
              ],
            );
          },
        ),
      );
}

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.alert});
  final FamilyWeatherAlert alert;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(alert.event)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Icon(Icons.warning_rounded, size: 48, color: alert.isInterruptive ? context.pt.warning : context.pt.accent),
            const SizedBox(height: 16),
            Text(_alertType(alert), style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(alert.headline, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            Text(alert.instruction),
            const SizedBox(height: 20),
            _DetailLine('Source', alert.attribution ?? (alert.source == WeatherAlertSource.official ? 'Official authority' : 'Pour Toujours guidance')),
            _DetailLine('Severity', alert.severity.name),
            _DetailLine('Expires', _expiryText(alert)),
            if (alert.area != null) _DetailLine('Affected area', alert.area!),
          ],
        ),
      );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 100, child: Text(label)), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)))]),
      );
}

class _CelestialArcPainter extends CustomPainter {
  const _CelestialArcPainter({required this.position, required this.accent});
  final CelestialPosition position;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(16, size.height - 20)
      ..quadraticBezierTo(size.width / 2, 4, size.width - 16, size.height - 20);
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: .22)..strokeWidth = 2..style = PaintingStyle.stroke);
    final metric = path.computeMetrics().first;
    final tangent = metric.getTangentForOffset(metric.length * position.progress);
    if (tangent == null) return;
    final isSun = position.body == CelestialBody.sun;
    canvas.drawCircle(
      tangent.position,
      17,
      Paint()
        ..shader = RadialGradient(colors: isSun ? const [Color(0xFFFFE5A0), Color(0x00FFE5A0)] : const [Color(0xFFDCE8FF), Color(0x00DCE8FF)]).createShader(Rect.fromCircle(center: tangent.position, radius: 17)),
    );
    if (isSun) {
      canvas.drawCircle(tangent.position, 6, Paint()..color = const Color(0xFFFFD56A));
    } else {
      canvas.drawCircle(tangent.position, 7, Paint()..color = const Color(0xFFEAF0FF));
      canvas.drawCircle(tangent.position.translate(3, -2), 7, Paint()..color = contextlessNightColor);
    }
  }

  static const contextlessNightColor = Color(0xFF25241F);

  @override
  bool shouldRepaint(covariant _CelestialArcPainter oldDelegate) => oldDelegate.position.body != position.body || oldDelegate.position.progress != position.progress || oldDelegate.accent != accent;
}

class _CityIdentityPainter extends CustomPainter {
  const _CityIdentityPainter(this.cityId);
  final String cityId;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height * .74;
    final silhouette = Paint()..color = Colors.black.withValues(alpha: .18);
    if (cityId == 'karachi' || cityId == 'chiba') {
      canvas.drawRect(Rect.fromLTWH(0, baseline, size.width, size.height - baseline), Paint()..color = const Color(0xFF255A67).withValues(alpha: .30));
      for (var index = 0; index < 12; index++) {
        final height = 22.0 + (index % 5) * 13;
        canvas.drawRect(Rect.fromLTWH(index * size.width / 11, baseline - height, size.width / 15, height), silhouette);
      }
    } else if (cityId == 'dublin') {
      for (var index = 0; index < 11; index++) {
        final x = index * size.width / 10;
        final roof = Path()..moveTo(x, baseline)..lineTo(x + size.width / 22, baseline - 25)..lineTo(x + size.width / 11, baseline)..close();
        canvas.drawPath(roof, silhouette);
        canvas.drawRect(Rect.fromLTWH(x, baseline, size.width / 11, 42), silhouette);
      }
    } else {
      for (var index = 0; index < 12; index++) {
        canvas.drawCircle(Offset(index * size.width / 11, baseline - 18 - (index % 3) * 8), 30, Paint()..color = const Color(0xFF183E32).withValues(alpha: .35));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CityIdentityPainter oldDelegate) => oldDelegate.cityId != cityId;
}

FamilyCity _city(String id) => cities.firstWhere((city) => city.id == id);
List<FamilyMember> _members(String id) => familyMembers.where((member) => member.cityId == id).toList();
tz.TZDateTime _localNow(FamilyCity city) => tz.TZDateTime.now(tz.getLocation(city.timezone));

String _differenceText(Duration difference) {
  if (difference == Duration.zero) return 'Same time as you';
  final minutes = difference.inMinutes.abs();
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return '${hours}h${remainder == 0 ? '' : ' ${remainder}m'} ${difference.isNegative ? 'behind' : 'ahead'} of you';
}

FamilyWeatherAlert _highestAlert(List<FamilyWeatherAlert> alerts) {
  final values = [...alerts]..sort((a, b) {
    if (a.source != b.source) return a.source == WeatherAlertSource.official ? -1 : 1;
    return b.severity.index.compareTo(a.severity.index);
  });
  return values.first;
}

void _openAlert(BuildContext context, FamilyWeatherAlert alert) => Navigator.pushNamed(context, PourToujoursRouteNames.alert, arguments: DetailRouteArgs(title: alert.event, subtitle: alert.headline, payload: alert));
String _alertType(FamilyWeatherAlert alert) => alert.source == WeatherAlertSource.derived ? 'FORECAST-DERIVED ADVISORY' : alert.event.toLowerCase().contains('warning') ? 'OFFICIAL WARNING' : alert.event.toLowerCase().contains('watch') ? 'OFFICIAL WATCH' : 'OFFICIAL WEATHER ALERT';
String _expiryText(FamilyWeatherAlert alert) => alert.expires == null ? 'Expiry not provided' : 'Expires ${DateFormat('EEE h:mm a').format(alert.expires!.toLocal())}';
String _duration(Duration value) { final minutes = value.inMinutes.abs(); final hours = minutes ~/ 60; final remainder = minutes % 60; return hours == 0 ? '$remainder min' : remainder == 0 ? '$hours h' : '$hours h $remainder min'; }
String _daylightElapsed(DateTime local, DailyWeather day) => local.isBefore(day.sunrise) ? 'daylight has not begun' : local.isAfter(day.sunset) ? 'daylight complete' : '${_duration(local.difference(day.sunrise))} elapsed · ${_duration(day.sunset.difference(local))} remaining';
String _moonPhase(DateTime date) { final days = date.toUtc().difference(DateTime.utc(2000, 1, 6, 18, 14)).inMinutes / 1440; final phase = ((days % 29.53058867) / 29.53058867 + 1) % 1; if (phase < .03 || phase > .97) return 'new moon'; if (phase < .22) return 'waxing crescent'; if (phase < .28) return 'first quarter'; if (phase < .47) return 'waxing gibbous'; if (phase < .53) return 'full moon'; if (phase < .72) return 'waning gibbous'; if (phase < .78) return 'last quarter'; return 'waning crescent'; }
String _practicalSummary(DailyWeather day) => day.weatherCode >= 95 ? 'Keep indoor options ready' : day.precipitationProbability >= 70 ? 'Carry rain protection' : day.uvMaximum >= 8 ? 'Seek shade near midday' : day.windMaximum >= 45 ? 'Wind may affect plans' : 'Generally workable conditions';
HourlyWeather? _hourFor(WeatherBundle bundle, int hour) { for (final item in bundle.hourly) { if (item.time.hour == hour) return item; } return null; }
int _availableCount(List<FamilyMember> members) => members.where((member) => evaluateAvailability(member: member, city: _city(member.cityId)).kind == AvailabilityKind.likelyFree).length;
AvailabilityKind _dominantKind(Iterable<AvailabilityKind> kinds) { final values = kinds.toList(); if (values.any((value) => value == AvailabilityKind.likelyFree)) return AvailabilityKind.likelyFree; if (values.any((value) => value == AvailabilityKind.maybeFree)) return AvailabilityKind.maybeFree; if (values.any((value) => value == AvailabilityKind.working)) return AvailabilityKind.working; if (values.any((value) => value == AvailabilityKind.asleep)) return AvailabilityKind.asleep; return AvailabilityKind.unknown; }
Color _availabilityColor(BuildContext context, AvailabilityKind kind) => switch (kind) { AvailabilityKind.likelyFree => context.pt.success, AvailabilityKind.maybeFree => context.pt.uncertain, AvailabilityKind.working => context.pt.working, AvailabilityKind.asleep => context.pt.asleep, AvailabilityKind.unknown => context.pt.unavailable };
String _kindLabel(AvailabilityKind kind) => switch (kind) { AvailabilityKind.likelyFree => 'likely free', AvailabilityKind.maybeFree => 'uncertain', AvailabilityKind.working => 'busy', AvailabilityKind.asleep => 'likely asleep', AvailabilityKind.unknown => 'unknown' };
String _shortKind(AvailabilityKind kind) => switch (kind) { AvailabilityKind.likelyFree => 'Free', AvailabilityKind.maybeFree => 'Maybe', AvailabilityKind.working => 'Busy', AvailabilityKind.asleep => 'Sleep', AvailabilityKind.unknown => 'Unknown' };
String _hourLabel(int hour) { final normalized = hour % 24; if (normalized == 0) return '12a'; if (normalized == 12) return '12p'; return normalized < 12 ? '${normalized}a' : '${normalized - 12}p'; }
IconData _weatherIcon(int code) { if (code >= 95) return Icons.thunderstorm_rounded; if (code >= 71 && code <= 77) return Icons.ac_unit_rounded; if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return Icons.water_drop_outlined; if (code == 45 || code == 48) return Icons.blur_on_rounded; if (code >= 2) return Icons.cloud_outlined; return Icons.light_mode_rounded; }

extension _FirstOrNull<T> on Iterable<T> { T? get firstOrNull => isEmpty ? null : first; }
