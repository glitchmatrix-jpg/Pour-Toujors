import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/pour_toujours_theme.dart';
import '../../core/settings/app_settings.dart';
import '../../core/time/availability_engine.dart';
import '../../core/time/timezone_intelligence.dart';
import '../../core/weather/weather_models.dart';
import '../../data/family_seed.dart';

class FamilyAtlas extends StatelessWidget {
  const FamilyAtlas({
    super.key,
    required this.viewer,
    required this.snapshots,
    required this.weather,
    required this.timezone,
    required this.onCityTap,
  });

  final FamilyMember viewer;
  final Map<String, AvailabilitySnapshot> snapshots;
  final Map<String, WeatherBundle?> weather;
  final TimezoneIntelligenceService timezone;
  final ValueChanged<FamilyCity> onCityTap;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context).value;
    return Container(
      decoration: BoxDecoration(
        color: context.pt.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.pt.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FAMILY ATLAS',
                        style: TextStyle(
                          color: context.pt.secondaryText,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Four cities, right now',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.public_rounded, color: context.pt.accent),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 1.78,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _AtlasPainter(
                          land: context.pt.globeAccent.withValues(alpha: .34),
                          ocean: context.pt.globe,
                          line: context.pt.outline,
                          night: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withValues(alpha: .22)
                              : const Color(0xFF0D2130).withValues(alpha: .18),
                          utcHour: DateTime.now().toUtc().hour +
                              DateTime.now().toUtc().minute / 60,
                        ),
                      ),
                    ),
                    for (final marker in _markers)
                      Positioned(
                        left: marker.x * constraints.maxWidth - 38,
                        top: marker.y * constraints.maxHeight - 27,
                        child: _CityMarker(
                          city: _city(marker.cityId),
                          viewer: viewer,
                          snapshot:
                              snapshots[_members(marker.cityId).first.name]!,
                          bundle: weather[marker.cityId],
                          timezone: timezone,
                          settings: settings,
                          onTap: () => onCityTap(_city(marker.cityId)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 15),
            child: Text(
              'Markers show city-level time and weather only. No GPS or live location is used.',
              style: TextStyle(color: context.pt.secondaryText, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _CityMarker extends StatelessWidget {
  const _CityMarker({
    required this.city,
    required this.viewer,
    required this.snapshot,
    required this.bundle,
    required this.timezone,
    required this.settings,
    required this.onTap,
  });

  final FamilyCity city;
  final FamilyMember viewer;
  final AvailabilitySnapshot snapshot;
  final WeatherBundle? bundle;
  final TimezoneIntelligenceService timezone;
  final AppSettings settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final members = _members(city.id);
    final free = members
        .where(
          (member) => evaluateAvailability(member: member, city: city).kind ==
              AvailabilityKind.likelyFree,
        )
        .length;
    final isDay = bundle?.current.isDay ??
        (snapshot.localTime.hour >= 6 && snapshot.localTime.hour < 18);
    final offset = timezone
        .snapshot(cityId: city.id, viewerCityId: viewer.cityId)
        .viewerDifference
        .inHours;
    final clock = DateFormat(
      settings.clockFormat == ClockFormat.twentyFourHour ? 'HH:mm' : 'h:mm a',
    );
    final markerColor =
        isDay ? const Color(0xFFF3C86C) : const Color(0xFF8BB8FF);

    return Semantics(
      button: true,
      label:
          '${city.name}, ${clock.format(snapshot.localTime)}, ${bundle?.condition ?? 'weather unavailable'}, $free likely free.',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.pt.card.withValues(alpha: .9),
                  shape: BoxShape.circle,
                  border: Border.all(color: markerColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: markerColor.withValues(alpha: .28),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _icon(bundle?.current.weatherCode, isDay),
                  size: 20,
                  color: markerColor,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: context.pt.card.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.pt.outline),
                ),
                child: Column(
                  children: [
                    Text(
                      city.name == 'Hattiesburg' ? 'H’burg' : city.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      clock.format(snapshot.localTime),
                      maxLines: 1,
                      style: TextStyle(
                        color: context.pt.secondaryText,
                        fontSize: 8,
                      ),
                    ),
                    Text(
                      offset == 0
                          ? '$free free · same time'
                          : '$free free · ${offset.abs()}h ${offset.isNegative ? 'behind' : 'ahead'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.pt.secondaryText,
                        fontSize: 7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AtlasPainter extends CustomPainter {
  const _AtlasPainter({
    required this.land,
    required this.ocean,
    required this.line,
    required this.night,
    required this.utcHour,
  });

  final Color land;
  final Color ocean;
  final Color line;
  final Color night;
  final double utcHour;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = ocean);

    final grid = Paint()
      ..color = line.withValues(alpha: .35)
      ..strokeWidth = 1;
    for (var x = 1; x < 6; x++) {
      final dx = size.width * x / 6;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), grid);
    }
    for (var y = 1; y < 4; y++) {
      final dy = size.height * y / 4;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), grid);
    }

    final landPaint = Paint()..color = land;
    for (final polygon in _landPolygons) {
      final path = Path();
      for (var index = 0; index < polygon.length; index++) {
        final point = Offset(
          polygon[index].dx * size.width,
          polygon[index].dy * size.height,
        );
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, landPaint);
    }

    final subsolarLongitude = (12 - utcHour) / 24;
    final center = ((subsolarLongitude % 1) + 1) % 1 * size.width;
    final nightWidth = size.width * .48;
    final gradient = LinearGradient(
      colors: [night, Colors.transparent, Colors.transparent, night],
      stops: const [0, .22, .78, 1],
    ).createShader(
      Rect.fromLTWH(center - nightWidth, 0, nightWidth * 2, size.height),
    );
    canvas.drawRect(rect, Paint()..shader = gradient);

    canvas.drawRect(
      rect.deflate(.5),
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _AtlasPainter oldDelegate) {
    return oldDelegate.land != land ||
        oldDelegate.ocean != ocean ||
        oldDelegate.utcHour != utcHour ||
        oldDelegate.night != night;
  }
}

class _Marker {
  const _Marker(this.cityId, this.x, this.y);
  final String cityId;
  final double x;
  final double y;
}

const _markers = [
  _Marker('karachi', .68, .53),
  _Marker('chiba', .87, .43),
  _Marker('dublin', .47, .30),
  _Marker('hattiesburg', .24, .47),
];

const _landPolygons = <List<Offset>>[
  [
    Offset(.05, .24),
    Offset(.15, .14),
    Offset(.29, .18),
    Offset(.34, .31),
    Offset(.28, .43),
    Offset(.21, .44),
    Offset(.17, .59),
    Offset(.10, .54),
    Offset(.08, .38),
  ],
  [
    Offset(.29, .49),
    Offset(.35, .54),
    Offset(.37, .70),
    Offset(.33, .90),
    Offset(.27, .79),
    Offset(.24, .62),
  ],
  [
    Offset(.43, .24),
    Offset(.54, .17),
    Offset(.72, .20),
    Offset(.84, .28),
    Offset(.93, .40),
    Offset(.87, .55),
    Offset(.74, .54),
    Offset(.67, .66),
    Offset(.55, .59),
    Offset(.49, .46),
  ],
  [
    Offset(.51, .49),
    Offset(.61, .50),
    Offset(.64, .68),
    Offset(.58, .88),
    Offset(.49, .76),
    Offset(.46, .59),
  ],
  [
    Offset(.82, .72),
    Offset(.91, .69),
    Offset(.96, .82),
    Offset(.89, .90),
    Offset(.81, .84),
  ],
];

FamilyCity _city(String id) => cities.firstWhere((city) => city.id == id);

List<FamilyMember> _members(String cityId) =>
    familyMembers.where((member) => member.cityId == cityId).toList();

IconData _icon(int? code, bool isDay) {
  if (code == null) return Icons.cloud_off_outlined;
  if (code >= 95) return Icons.thunderstorm_rounded;
  if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
    return Icons.water_drop_outlined;
  }
  if (code == 45 || code == 48) return Icons.blur_on_rounded;
  if (code >= 2) return Icons.cloud_outlined;
  return isDay ? Icons.light_mode_rounded : Icons.dark_mode_rounded;
}
