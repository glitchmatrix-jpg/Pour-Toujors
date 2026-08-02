class CurrentWeather {
  const CurrentWeather({
    required this.time,
    required this.temperature,
    required this.feelsLike,
    required this.weatherCode,
    required this.isDay,
    required this.precipitation,
    required this.rainChance,
    required this.windSpeed,
    required this.windGusts,
    required this.windDirection,
    required this.humidity,
    required this.visibility,
    required this.uvIndex,
    required this.cloudCover,
    required this.surfacePressure,
  });

  final DateTime time;
  final double temperature;
  final double feelsLike;
  final int weatherCode;
  final bool isDay;
  final double precipitation;
  final int rainChance;
  final double windSpeed;
  final double windGusts;
  final int windDirection;
  final int humidity;
  final double visibility;
  final double uvIndex;
  final int cloudCover;
  final double surfacePressure;
}

class HourlyWeather {
  const HourlyWeather({
    required this.time,
    required this.temperature,
    required this.feelsLike,
    required this.weatherCode,
    required this.precipitationProbability,
    required this.precipitation,
    required this.windSpeed,
    required this.windGusts,
    required this.humidity,
    required this.uvIndex,
    required this.visibility,
  });

  final DateTime time;
  final double temperature;
  final double feelsLike;
  final int weatherCode;
  final int precipitationProbability;
  final double precipitation;
  final double windSpeed;
  final double windGusts;
  final int humidity;
  final double uvIndex;
  final double visibility;
}

class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.weatherCode,
    required this.high,
    required this.low,
    required this.precipitationProbability,
    required this.precipitation,
    required this.windMaximum,
    required this.gustMaximum,
    required this.sunrise,
    required this.sunset,
    required this.daylightDuration,
    required this.uvMaximum,
  });

  final DateTime date;
  final int weatherCode;
  final double high;
  final double low;
  final int precipitationProbability;
  final double precipitation;
  final double windMaximum;
  final double gustMaximum;
  final DateTime sunrise;
  final DateTime sunset;
  final Duration daylightDuration;
  final double uvMaximum;
}

class WeatherBundle {
  const WeatherBundle({
    required this.cityId,
    required this.current,
    required this.hourly,
    required this.daily,
    required this.updatedAt,
    this.isStale = false,
  });

  final String cityId;
  final CurrentWeather current;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;
  final DateTime updatedAt;
  final bool isStale;

  WeatherBundle copyWith({bool? isStale}) => WeatherBundle(
        cityId: cityId,
        current: current,
        hourly: hourly,
        daily: daily,
        updatedAt: updatedAt,
        isStale: isStale ?? this.isStale,
      );

  String get condition => weatherCodeLabel(current.weatherCode);
}

String weatherCodeLabel(int code) {
  if (code == 0) return 'Clear';
  if (code <= 3) return 'Partly cloudy';
  if (code == 45 || code == 48) return 'Fog';
  if (code >= 51 && code <= 67) return 'Rain';
  if (code >= 71 && code <= 77) return 'Snow';
  if (code >= 80 && code <= 82) return 'Showers';
  if (code >= 95) return 'Thunderstorms';
  return 'Mixed weather';
}
