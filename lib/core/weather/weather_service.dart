import 'dart:convert';

import 'package:http/http.dart' as http;

class CityWeather {
  const CityWeather({
    required this.temperature,
    required this.feelsLike,
    required this.windSpeed,
    required this.code,
    required this.isDay,
    required this.high,
    required this.low,
    required this.rainChance,
    required this.sunrise,
    required this.sunset,
    this.isLive = true,
  });

  final double temperature;
  final double feelsLike;
  final double windSpeed;
  final int code;
  final bool isDay;
  final double high;
  final double low;
  final int rainChance;
  final DateTime sunrise;
  final DateTime sunset;
  final bool isLive;

  String get condition {
    if (!isLive) return 'Weather unavailable';
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Partly cloudy';
    if (code == 45 || code == 48) return 'Foggy';
    if (code >= 51 && code <= 67) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 95) return 'Thunderstorms';
    return 'Mixed weather';
  }

  String get practicalLine {
    if (!isLive) return 'Pull down to retry live weather';
    if (code >= 95) return 'Storms may disrupt plans';
    if (rainChance >= 65) return 'Rain is likely today';
    if (feelsLike >= 38) return 'Dangerously hot outside';
    if (temperature <= 2) return 'Very cold outside';
    if (windSpeed >= 35) return 'Strong winds outside';
    return 'No major disruption expected';
  }
}

class WeatherService {
  static const coordinates = <String, (double, double)>{
    'karachi': (24.8607, 67.0011),
    'chiba': (35.6074, 140.1065),
    'dublin': (53.3498, -6.2603),
    'hattiesburg': (31.3271, -89.2903),
  };

  /// Test-only deterministic values. Production leaves this null.
  static Map<String, CityWeather>? debugOverrides;

  Future<CityWeather> fetch(String cityId) async {
    final override = debugOverrides?[cityId];
    if (override != null) return override;

    try {
      final point = coordinates[cityId]!;
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${point.$1}',
        'longitude': '${point.$2}',
        'current':
            'temperature_2m,apparent_temperature,weather_code,is_day,wind_speed_10m',
        'hourly': 'precipitation_probability',
        'daily': 'temperature_2m_max,temperature_2m_min,sunrise,sunset',
        'forecast_days': '1',
        'timezone': 'auto',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return _offline();
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>;
      final hourly = data['hourly'] as Map<String, dynamic>;
      final rain = (hourly['precipitation_probability'] as List).cast<num>();
      return CityWeather(
        temperature: (current['temperature_2m'] as num).toDouble(),
        feelsLike: (current['apparent_temperature'] as num).toDouble(),
        windSpeed: (current['wind_speed_10m'] as num).toDouble(),
        code: (current['weather_code'] as num).toInt(),
        isDay: (current['is_day'] as num).toInt() == 1,
        high: ((daily['temperature_2m_max'] as List).first as num).toDouble(),
        low: ((daily['temperature_2m_min'] as List).first as num).toDouble(),
        rainChance:
            rain.isEmpty ? 0 : rain.reduce((a, b) => a > b ? a : b).toInt(),
        sunrise: DateTime.parse((daily['sunrise'] as List).first as String),
        sunset: DateTime.parse((daily['sunset'] as List).first as String),
      );
    } catch (_) {
      return _offline();
    }
  }

  CityWeather _offline() {
    final now = DateTime.now();
    return CityWeather(
      temperature: 0,
      feelsLike: 0,
      windSpeed: 0,
      code: 3,
      isDay: now.hour >= 6 && now.hour < 18,
      high: 0,
      low: 0,
      rainChance: 0,
      sunrise: DateTime(now.year, now.month, now.day, 6),
      sunset: DateTime(now.year, now.month, now.day, 18),
      isLive: false,
    );
  }
}
