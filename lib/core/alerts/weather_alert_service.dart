import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../weather/weather_models.dart';

enum WeatherAlertSource { official, derived }
enum WeatherAlertSeverity { minor, moderate, severe, extreme }

class FamilyWeatherAlert {
  const FamilyWeatherAlert({
    required this.id,
    required this.cityId,
    required this.event,
    required this.headline,
    required this.instruction,
    required this.source,
    required this.severity,
    required this.effective,
    required this.expires,
    this.urgency,
    this.certainty,
    this.area,
    this.attribution,
  });

  final String id;
  final String cityId;
  final String event;
  final String headline;
  final String instruction;
  final WeatherAlertSource source;
  final WeatherAlertSeverity severity;
  final DateTime? effective;
  final DateTime? expires;
  final String? urgency;
  final String? certainty;
  final String? area;
  final String? attribution;

  bool get isInterruptive =>
      severity == WeatherAlertSeverity.severe ||
      severity == WeatherAlertSeverity.extreme;

  bool get isEarthquake => event.toLowerCase().contains('earthquake');
}

class WeatherAlertService {
  WeatherAlertService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _cityCoordinates = <String, (double, double)>{
    'karachi': (24.8607, 67.0011),
    'chiba': (35.6074, 140.1065),
    'dublin': (53.3498, -6.2603),
    'hattiesburg': (31.3271, -89.2903),
  };

  static Map<String, List<FamilyWeatherAlert>>? debugOfficialOverrides;
  static Map<String, List<FamilyWeatherAlert>>? debugEarthquakeOverrides;

  static List<_EarthquakeEvent>? _earthquakeCache;
  static DateTime? _earthquakeCacheTime;
  static Future<List<_EarthquakeEvent>>? _earthquakeInFlight;
  static const _earthquakeCacheLifetime = Duration(minutes: 5);

  Future<List<FamilyWeatherAlert>> fetchOfficialForCity(String cityId) async {
    final weatherDebug = debugOfficialOverrides;
    final earthquakeDebug = debugEarthquakeOverrides;
    if (weatherDebug != null || earthquakeDebug != null) {
      return [
        ...?weatherDebug?[cityId],
        ...?earthquakeDebug?[cityId],
      ];
    }

    final results = await Future.wait<List<FamilyWeatherAlert>>([
      _fetchWeatherAlerts(cityId),
      _fetchEarthquakeReports(cityId),
    ]);
    return [...results[0], ...results[1]];
  }

  Future<List<FamilyWeatherAlert>> _fetchWeatherAlerts(String cityId) async {
    if (cityId != 'hattiesburg') return const [];
    final point = _cityCoordinates[cityId]!;
    final uri = Uri.https('api.weather.gov', '/alerts/active', {
      'point': '${point.$1},${point.$2}',
      'status': 'actual',
      'message_type': 'alert',
    });
    try {
      final response = await _client.get(uri, headers: const {
        'Accept': 'application/geo+json',
        'User-Agent': 'PourToujours/1.0 (family-awareness-app)',
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return const [];
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final features = body['features'] as List<dynamic>? ?? const [];
      return features.map((raw) {
        final feature = raw as Map<String, dynamic>;
        final properties = feature['properties'] as Map<String, dynamic>;
        final event = (properties['event'] as String?) ?? 'Weather alert';
        return FamilyWeatherAlert(
          id: (feature['id'] as String?) ?? event,
          cityId: cityId,
          event: event,
          headline: (properties['headline'] as String?) ?? event,
          instruction:
              _instruction(event, properties['instruction'] as String?),
          source: WeatherAlertSource.official,
          severity: _severity(properties['severity'] as String?),
          effective: _date(properties['effective']),
          expires: _date(properties['expires']),
          urgency: properties['urgency'] as String?,
          certainty: properties['certainty'] as String?,
          area: properties['areaDesc'] as String?,
          attribution: 'U.S. National Weather Service',
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<FamilyWeatherAlert>> _fetchEarthquakeReports(
    String cityId,
  ) async {
    final city = _cityCoordinates[cityId];
    if (city == null) return const [];
    try {
      final events = await _earthquakes();
      final reports = <FamilyWeatherAlert>[];
      for (final quake in events) {
        final distance = _distanceKm(
          city.$1,
          city.$2,
          quake.latitude,
          quake.longitude,
        );
        if (!_isRelevantEarthquake(quake.magnitude, distance)) continue;
        final magnitude = quake.magnitude.toStringAsFixed(1);
        final roundedDistance = distance.round();
        reports.add(
          FamilyWeatherAlert(
            id: 'usgs-${quake.id}-$cityId',
            cityId: cityId,
            event: 'Earthquake report · M$magnitude',
            headline:
                'M$magnitude earthquake reported $roundedDistance km from ${_cityName(cityId)}',
            instruction:
                'This is rapid earthquake reporting, not advance warning. '
                'If shaking is occurring, Drop, Cover, and Hold On. After shaking, '
                'check local emergency guidance and avoid damaged structures.',
            source: WeatherAlertSource.official,
            severity: _earthquakeSeverity(quake.magnitude, distance),
            effective: quake.time,
            expires: quake.time.add(const Duration(hours: 24)),
            urgency: quake.magnitude >= 6 ? 'Immediate' : 'Expected',
            certainty: 'Observed',
            area: quake.place,
            attribution: 'U.S. Geological Survey',
          ),
        );
      }
      reports.sort((a, b) {
        final severity = b.severity.index.compareTo(a.severity.index);
        if (severity != 0) return severity;
        return (b.effective ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.effective ?? DateTime.fromMillisecondsSinceEpoch(0));
      });
      return reports.take(3).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<_EarthquakeEvent>> _earthquakes() async {
    final now = DateTime.now();
    final cached = _earthquakeCache;
    final cachedAt = _earthquakeCacheTime;
    if (cached != null &&
        cachedAt != null &&
        now.difference(cachedAt) < _earthquakeCacheLifetime) {
      return cached;
    }
    final existing = _earthquakeInFlight;
    if (existing != null) return existing;
    final request = _requestEarthquakes();
    _earthquakeInFlight = request;
    try {
      final events = await request;
      _earthquakeCache = events;
      _earthquakeCacheTime = now;
      return events;
    } finally {
      _earthquakeInFlight = null;
    }
  }

  Future<List<_EarthquakeEvent>> _requestEarthquakes() async {
    final uri = Uri.https(
      'earthquake.usgs.gov',
      '/earthquakes/feed/v1.0/summary/all_day.geojson',
    );
    final response = await _client.get(uri, headers: const {
      'Accept': 'application/geo+json, application/json',
      'User-Agent': 'PourToujours/1.0 (family-awareness-app)',
    }).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return const [];
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final features = body['features'] as List<dynamic>? ?? const [];
    final events = <_EarthquakeEvent>[];
    for (final raw in features) {
      if (raw is! Map<String, dynamic>) continue;
      final properties = raw['properties'];
      final geometry = raw['geometry'];
      if (properties is! Map<String, dynamic> ||
          geometry is! Map<String, dynamic>) {
        continue;
      }
      final coordinates = geometry['coordinates'];
      final magnitude = properties['mag'];
      final milliseconds = properties['time'];
      if (coordinates is! List ||
          coordinates.length < 2 ||
          magnitude is! num ||
          milliseconds is! num) {
        continue;
      }
      final longitude = coordinates[0];
      final latitude = coordinates[1];
      if (longitude is! num || latitude is! num) continue;
      events.add(
        _EarthquakeEvent(
          id: (raw['id'] as String?) ??
              '${milliseconds.toInt()}-${magnitude.toDouble()}',
          magnitude: magnitude.toDouble(),
          longitude: longitude.toDouble(),
          latitude: latitude.toDouble(),
          time: DateTime.fromMillisecondsSinceEpoch(
            milliseconds.toInt(),
            isUtc: true,
          ),
          place: (properties['place'] as String?) ?? 'Location not provided',
        ),
      );
    }
    return events;
  }

  List<FamilyWeatherAlert> derive(String cityId, WeatherBundle bundle) {
    if (bundle.daily.isEmpty) return const [];
    final current = bundle.current;
    final today = bundle.daily.first;
    final alerts = <FamilyWeatherAlert>[];

    void add(
      String event,
      String headline,
      String instruction,
      WeatherAlertSeverity severity,
    ) {
      alerts.add(
        FamilyWeatherAlert(
          id: 'derived-$cityId-${event.toLowerCase().replaceAll(' ', '-')}',
          cityId: cityId,
          event: event,
          headline: headline,
          instruction: instruction,
          source: WeatherAlertSource.derived,
          severity: severity,
          effective: DateTime.now(),
          expires: DateTime.now().add(const Duration(hours: 12)),
          attribution: 'Pour Toujours guidance from forecast data',
        ),
      );
    }

    if (current.feelsLike >= 43) {
      add(
        'Extreme heat',
        'Dangerous heat may affect normal plans',
        'Limit strenuous outdoor activity and check on vulnerable relatives.',
        WeatherAlertSeverity.severe,
      );
    } else if (current.feelsLike >= 38) {
      add(
        'Very hot',
        'Heat may be uncomfortable or risky',
        'Hydrate and reduce prolonged outdoor exposure.',
        WeatherAlertSeverity.moderate,
      );
    }
    if (today.uvMaximum >= 8) {
      add(
        'Very high UV',
        'UV levels are very high',
        'Use shade, protective clothing, and sunscreen.',
        WeatherAlertSeverity.moderate,
      );
    }
    if (today.precipitation >= 35 || today.precipitationProbability >= 85) {
      add(
        'Heavy rain',
        'Heavy rain may disrupt travel',
        'Allow extra travel time and avoid flooded roads.',
        WeatherAlertSeverity.moderate,
      );
    }
    if (current.weatherCode >= 95) {
      add(
        'Thunderstorm risk',
        'Thunderstorms are forecast',
        'Move indoors when thunder is heard and monitor local official alerts.',
        WeatherAlertSeverity.moderate,
      );
    }
    if (current.windGusts >= 65) {
      add(
        'Dangerous gusts',
        'Very strong gusts are possible',
        'Secure loose objects and avoid exposed areas.',
        WeatherAlertSeverity.severe,
      );
    } else if (current.windGusts >= 45) {
      add(
        'Strong wind',
        'Strong winds may affect travel',
        'Use extra care outdoors and while driving.',
        WeatherAlertSeverity.moderate,
      );
    }
    if (current.visibility < 1000) {
      add(
        'Poor visibility',
        'Visibility is very low',
        'Slow down while travelling and use appropriate lights.',
        WeatherAlertSeverity.moderate,
      );
    }
    if (current.temperature <= 0 || today.low <= 0) {
      add(
        'Freezing conditions',
        'Freezing conditions are possible',
        'Watch for icy surfaces and protect exposed pipes or plants.',
        WeatherAlertSeverity.moderate,
      );
    }
    return alerts;
  }

  static bool _isRelevantEarthquake(double magnitude, double distanceKm) {
    if (magnitude >= 6 && distanceKm <= 1500) return true;
    if (magnitude >= 5 && distanceKm <= 800) return true;
    if (magnitude >= 4 && distanceKm <= 300) return true;
    return magnitude >= 3 && distanceKm <= 100;
  }

  static WeatherAlertSeverity _earthquakeSeverity(
    double magnitude,
    double distanceKm,
  ) {
    if (magnitude >= 7 || (magnitude >= 6.5 && distanceKm <= 300)) {
      return WeatherAlertSeverity.extreme;
    }
    if (magnitude >= 6 || (magnitude >= 5.5 && distanceKm <= 150)) {
      return WeatherAlertSeverity.severe;
    }
    if (magnitude >= 5 || (magnitude >= 4 && distanceKm <= 100)) {
      return WeatherAlertSeverity.moderate;
    }
    return WeatherAlertSeverity.minor;
  }

  static double _distanceKm(
    double latitudeA,
    double longitudeA,
    double latitudeB,
    double longitudeB,
  ) {
    const radius = 6371.0;
    final latitudeDelta = _radians(latitudeB - latitudeA);
    final longitudeDelta = _radians(longitudeB - longitudeA);
    final a = math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(_radians(latitudeA)) *
            math.cos(_radians(latitudeB)) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    return radius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;

  static String _cityName(String cityId) => switch (cityId) {
        'karachi' => 'Karachi',
        'chiba' => 'Chiba',
        'dublin' => 'Dublin',
        'hattiesburg' => 'Hattiesburg',
        _ => cityId,
      };

  static WeatherAlertSeverity _severity(String? value) =>
      switch (value?.toLowerCase()) {
        'extreme' => WeatherAlertSeverity.extreme,
        'severe' => WeatherAlertSeverity.severe,
        'moderate' => WeatherAlertSeverity.moderate,
        _ => WeatherAlertSeverity.minor,
      };

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static String _instruction(String event, String? official) {
    if (official != null && official.trim().isNotEmpty) return official.trim();
    final lower = event.toLowerCase();
    if (lower.contains('tornado warning')) {
      return 'Seek shelter now in a sturdy interior room on the lowest floor, away from windows.';
    }
    if (lower.contains('tornado watch')) {
      return 'Be ready to shelter and monitor official warnings.';
    }
    if (lower.contains('flash flood warning')) {
      return 'Avoid flooded roads and move to higher ground when instructed.';
    }
    if (lower.contains('severe thunderstorm warning')) {
      return 'Move indoors and stay away from windows.';
    }
    return 'Follow local authority guidance and monitor official updates.';
  }
}

class _EarthquakeEvent {
  const _EarthquakeEvent({
    required this.id,
    required this.magnitude,
    required this.longitude,
    required this.latitude,
    required this.time,
    required this.place,
  });

  final String id;
  final double magnitude;
  final double longitude;
  final double latitude;
  final DateTime time;
  final String place;
}
