import 'dart:convert';

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

  bool get isInterruptive => severity == WeatherAlertSeverity.severe || severity == WeatherAlertSeverity.extreme;
}

class WeatherAlertService {
  WeatherAlertService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const _hattiesburg = (31.3271, -89.2903);

  Future<List<FamilyWeatherAlert>> fetchOfficialForCity(String cityId) async {
    if (cityId != 'hattiesburg') return const [];
    final uri = Uri.https('api.weather.gov', '/alerts/active', {
      'point': '${_hattiesburg.$1},${_hattiesburg.$2}',
      'status': 'actual',
      'message_type': 'alert',
    });
    try {
      final response = await _client.get(uri, headers: const {
        'Accept': 'application/geo+json',
        'User-Agent': 'PourToujours/0.6 (family-weather-app)',
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return const [];
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final features = (body['features'] as List<dynamic>? ?? const []);
      return features.map((raw) {
        final feature = raw as Map<String, dynamic>;
        final p = feature['properties'] as Map<String, dynamic>;
        final event = (p['event'] as String?) ?? 'Weather alert';
        return FamilyWeatherAlert(
          id: (feature['id'] as String?) ?? event,
          cityId: cityId,
          event: event,
          headline: (p['headline'] as String?) ?? event,
          instruction: _instruction(event, p['instruction'] as String?),
          source: WeatherAlertSource.official,
          severity: _severity(p['severity'] as String?),
          effective: _date(p['effective']),
          expires: _date(p['expires']),
          urgency: p['urgency'] as String?,
          certainty: p['certainty'] as String?,
          area: p['areaDesc'] as String?,
          attribution: 'U.S. National Weather Service',
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  List<FamilyWeatherAlert> derive(String cityId, WeatherBundle bundle) {
    final c = bundle.current;
    final today = bundle.daily.first;
    final alerts = <FamilyWeatherAlert>[];
    void add(String event, String headline, String instruction, WeatherAlertSeverity severity) {
      alerts.add(FamilyWeatherAlert(
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
      ));
    }

    if (c.feelsLike >= 43) {
      add('Extreme heat', 'Dangerous heat may affect normal plans', 'Limit strenuous outdoor activity and check on vulnerable relatives.', WeatherAlertSeverity.severe);
    } else if (c.feelsLike >= 38) {
      add('Very hot', 'Heat may be uncomfortable or risky', 'Hydrate and reduce prolonged outdoor exposure.', WeatherAlertSeverity.moderate);
    }
    if (today.uvMaximum >= 8) {
      add('Very high UV', 'UV levels are very high', 'Use shade, protective clothing, and sunscreen.', WeatherAlertSeverity.moderate);
    }
    if (today.precipitation >= 35 || today.precipitationProbability >= 85) {
      add('Heavy rain', 'Heavy rain may disrupt travel', 'Allow extra travel time and avoid flooded roads.', WeatherAlertSeverity.moderate);
    }
    if (c.weatherCode >= 95) {
      add('Thunderstorm risk', 'Thunderstorms are forecast', 'Move indoors when thunder is heard and monitor local official alerts.', WeatherAlertSeverity.moderate);
    }
    if (c.windGusts >= 65) {
      add('Dangerous gusts', 'Very strong gusts are possible', 'Secure loose objects and avoid exposed areas.', WeatherAlertSeverity.severe);
    } else if (c.windGusts >= 45) {
      add('Strong wind', 'Strong winds may affect travel', 'Use extra care outdoors and while driving.', WeatherAlertSeverity.moderate);
    }
    if (c.visibility < 1000) {
      add('Poor visibility', 'Visibility is very low', 'Slow down while travelling and use appropriate lights.', WeatherAlertSeverity.moderate);
    }
    if (c.temperature <= 0 || today.low <= 0) {
      add('Freezing conditions', 'Freezing conditions are possible', 'Watch for icy surfaces and protect exposed pipes or plants.', WeatherAlertSeverity.moderate);
    }
    return alerts;
  }

  static WeatherAlertSeverity _severity(String? value) => switch (value?.toLowerCase()) {
        'extreme' => WeatherAlertSeverity.extreme,
        'severe' => WeatherAlertSeverity.severe,
        'moderate' => WeatherAlertSeverity.moderate,
        _ => WeatherAlertSeverity.minor,
      };

  static DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value) : null;

  static String _instruction(String event, String? official) {
    if (official != null && official.trim().isNotEmpty) return official.trim();
    final lower = event.toLowerCase();
    if (lower.contains('tornado warning')) return 'Seek shelter now in a sturdy interior room on the lowest floor, away from windows.';
    if (lower.contains('tornado watch')) return 'Be ready to shelter and monitor official warnings.';
    if (lower.contains('flash flood warning')) return 'Avoid flooded roads and move to higher ground when instructed.';
    if (lower.contains('severe thunderstorm warning')) return 'Move indoors and stay away from windows.';
    return 'Follow local authority guidance and monitor official updates.';
  }
}
