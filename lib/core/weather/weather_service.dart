import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;

import 'weather_models.dart';

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const coordinates = <String, (double, double)>{
    'karachi': (24.8607, 67.0011),
    'chiba': (35.6074, 140.1065),
    'dublin': (53.3498, -6.2603),
    'hattiesburg': (31.3271, -89.2903),
  };

  static const cityTimezones = <String, String>{
    'karachi': 'Asia/Karachi',
    'chiba': 'Asia/Tokyo',
    'dublin': 'Europe/Dublin',
    'hattiesburg': 'America/Chicago',
  };

  static final Map<String, WeatherBundle> _cache = {};
  static final Map<String, Future<WeatherBundle>> _inFlight = {};
  static const cacheLifetime = Duration(minutes: 20);
  static Map<String, WeatherBundle>? debugBundleOverrides;

  Future<WeatherBundle> fetchBundle(
    String cityId, {
    bool forceRefresh = false,
  }) async {
    final debug = debugBundleOverrides?[cityId];
    if (debug != null) return debug;

    final cached = _cache[cityId];
    final fresh = cached != null &&
        DateTime.now().difference(cached.updatedAt) < cacheLifetime;
    if (!forceRefresh && fresh) return cached;

    final inFlight = _inFlight[cityId];
    if (!forceRefresh && inFlight != null) return inFlight;

    final request = _request(cityId);
    _inFlight[cityId] = request;
    try {
      final result = await request;
      _cache[cityId] = result;
      return result;
    } catch (_) {
      if (cached != null) return cached.copyWith(isStale: true);
      rethrow;
    } finally {
      _inFlight.remove(cityId);
    }
  }

  Future<WeatherBundle> _request(String cityId) async {
    final point = coordinates[cityId];
    if (point == null) throw ArgumentError.value(cityId, 'cityId');

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${point.$1}',
      'longitude': '${point.$2}',
      'current': [
        'temperature_2m',
        'apparent_temperature',
        'weather_code',
        'is_day',
        'precipitation',
        'wind_speed_10m',
        'wind_gusts_10m',
        'wind_direction_10m',
        'relative_humidity_2m',
        'visibility',
        'uv_index',
        'cloud_cover',
        'surface_pressure',
      ].join(','),
      'hourly': [
        'temperature_2m',
        'apparent_temperature',
        'weather_code',
        'precipitation_probability',
        'precipitation',
        'wind_speed_10m',
        'wind_gusts_10m',
        'relative_humidity_2m',
        'uv_index',
        'visibility',
      ].join(','),
      'daily': [
        'weather_code',
        'temperature_2m_max',
        'temperature_2m_min',
        'precipitation_probability_max',
        'precipitation_sum',
        'wind_speed_10m_max',
        'wind_gusts_10m_max',
        'sunrise',
        'sunset',
        'daylight_duration',
        'uv_index_max',
      ].join(','),
      'forecast_days': '7',
      'timezone': 'auto',
    });

    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Weather request failed: ${response.statusCode}',
        uri,
      );
    }
    return _parse(cityId, jsonDecode(response.body) as Map<String, dynamic>);
  }

  WeatherBundle _parse(String cityId, Map<String, dynamic> data) {
    final current = data['current'] as Map<String, dynamic>;
    final hourly = data['hourly'] as Map<String, dynamic>;
    final daily = data['daily'] as Map<String, dynamic>;
    final hourlyTimes = _strings(hourly, 'time');
    final dailyTimes = _strings(daily, 'time');

    final hourlyItems = List<HourlyWeather>.generate(
      hourlyTimes.length,
      (index) => HourlyWeather(
        time: _cityLocalTime(cityId, hourlyTimes[index]),
        temperature: _numberAt(hourly, 'temperature_2m', index),
        feelsLike: _numberAt(hourly, 'apparent_temperature', index),
        weatherCode: _intAt(hourly, 'weather_code', index),
        precipitationProbability:
            _intAt(hourly, 'precipitation_probability', index),
        precipitation: _numberAt(hourly, 'precipitation', index),
        windSpeed: _numberAt(hourly, 'wind_speed_10m', index),
        windGusts: _numberAt(hourly, 'wind_gusts_10m', index),
        humidity: _intAt(hourly, 'relative_humidity_2m', index),
        uvIndex: _numberAt(hourly, 'uv_index', index),
        visibility: _numberAt(hourly, 'visibility', index),
      ),
    );

    final sunrises = _strings(daily, 'sunrise');
    final sunsets = _strings(daily, 'sunset');
    final dailyItems = List<DailyWeather>.generate(
      dailyTimes.length,
      (index) => DailyWeather(
        date: _cityLocalTime(cityId, dailyTimes[index]),
        weatherCode: _intAt(daily, 'weather_code', index),
        high: _numberAt(daily, 'temperature_2m_max', index),
        low: _numberAt(daily, 'temperature_2m_min', index),
        precipitationProbability:
            _intAt(daily, 'precipitation_probability_max', index),
        precipitation: _numberAt(daily, 'precipitation_sum', index),
        windMaximum: _numberAt(daily, 'wind_speed_10m_max', index),
        gustMaximum: _numberAt(daily, 'wind_gusts_10m_max', index),
        sunrise: _cityLocalTime(cityId, sunrises[index]),
        sunset: _cityLocalTime(cityId, sunsets[index]),
        daylightDuration: Duration(
          seconds: _numberAt(daily, 'daylight_duration', index).round(),
        ),
        uvMaximum: _numberAt(daily, 'uv_index_max', index),
      ),
    );

    final rainChance = hourlyItems.isEmpty
        ? 0
        : hourlyItems
            .take(24)
            .map((item) => item.precipitationProbability)
            .reduce((a, b) => a > b ? a : b);

    return WeatherBundle(
      cityId: cityId,
      updatedAt: DateTime.now(),
      current: CurrentWeather(
        time: _cityLocalTime(cityId, current['time'] as String),
        temperature: _number(current['temperature_2m']),
        feelsLike: _number(current['apparent_temperature']),
        weatherCode: _integer(current['weather_code']),
        isDay: _integer(current['is_day']) == 1,
        precipitation: _number(current['precipitation']),
        rainChance: rainChance,
        windSpeed: _number(current['wind_speed_10m']),
        windGusts: _number(current['wind_gusts_10m']),
        windDirection: _integer(current['wind_direction_10m']),
        humidity: _integer(current['relative_humidity_2m']),
        visibility: _number(current['visibility']),
        uvIndex: _number(current['uv_index']),
        cloudCover: _integer(current['cloud_cover']),
        surfacePressure: _number(current['surface_pressure']),
      ),
      hourly: hourlyItems,
      daily: dailyItems,
    );
  }

  static tz.TZDateTime _cityLocalTime(String cityId, String raw) {
    final parsed = DateTime.parse(raw);
    final timezone = cityTimezones[cityId];
    if (timezone == null) {
      throw ArgumentError.value(cityId, 'cityId', 'Unknown city timezone');
    }
    final location = tz.getLocation(timezone);
    return tz.TZDateTime(
      location,
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  static List<String> _strings(Map<String, dynamic> map, String key) =>
      (map[key] as List<dynamic>).cast<String>();

  static double _numberAt(
    Map<String, dynamic> map,
    String key,
    int index,
  ) =>
      _number((map[key] as List<dynamic>)[index]);

  static int _intAt(Map<String, dynamic> map, String key, int index) =>
      _integer((map[key] as List<dynamic>)[index]);

  static double _number(Object? value) => (value as num?)?.toDouble() ?? 0;
  static int _integer(Object? value) => (value as num?)?.toInt() ?? 0;
}
