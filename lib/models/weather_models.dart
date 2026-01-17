import 'dart:math' as math;

import 'package:flutter_application/core/app_strings.dart';
import 'package:flutter_application/core/unit_system.dart';

class WeatherBundle {
  WeatherBundle({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  final CurrentWeather current;
  final List<ForecastEntry> hourly;
  final List<DailyForecast> daily;

  List<ForecastEntry> get nextHours {
    final now = DateTime.now();
    final upcoming = hourly
        .where(
          (entry) => entry.time.isAfter(now.subtract(const Duration(hours: 1))),
        )
        .toList();
    return upcoming.take(10).toList();
  }

  List<DailyForecast> get dailyForecast {
    final today = DateTime.now();
    return daily
        .where(
          (day) => day.date
              .isAfter(DateTime(today.year, today.month, today.day - 1)),
        )
        .take(6)
        .toList();
  }
}

class CurrentWeather {
  CurrentWeather({
    required this.city,
    required this.temp,
    required this.feelsLike,
    required this.min,
    required this.max,
    required this.humidity,
    required this.pressure,
    required this.visibility,
    required this.windSpeed,
    required this.sunrise,
    required this.sunset,
    required this.time,
    required this.description,
    required this.main,
    required this.icon,
    required this.lat,
    required this.lon,
  });

  final String city;
  final double temp;
  final double feelsLike;
  final double min;
  final double max;
  final int humidity;
  final int pressure;
  final int visibility;
  final double windSpeed;
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime time;
  final String description;
  final String main;
  final String icon;
  final double lat;
  final double lon;

  factory CurrentWeather.fromJson(
    Map<String, dynamic> json,
    UnitSystem unitSystem,
    AppLanguage language,
  ) {
    final weather =
        (json['weather'] as List<dynamic>? ?? const []).firstOrNull()
            as Map<String, dynamic>? ?? const {};
    final mainData = json['main'] as Map<String, dynamic>? ?? const {};
    final windData = json['wind'] as Map<String, dynamic>? ?? const {};
    final sysData = json['sys'] as Map<String, dynamic>? ?? const {};
    final coord = json['coord'] as Map<String, dynamic>? ?? const {};

    return CurrentWeather(
      city: json['name'] as String? ?? '-',
      temp: _toDouble(mainData['temp']),
      feelsLike: _toDouble(mainData['feels_like']),
      min: _toDouble(mainData['temp_min']),
      max: _toDouble(mainData['temp_max']),
      humidity: _toInt(mainData['humidity']),
      pressure: _toInt(mainData['pressure']),
      visibility: _toInt(json['visibility']),
      windSpeed: unitSystem.normalizeWindSpeed(_toDouble(windData['speed'])),
      sunrise: _fromSeconds(sysData['sunrise']),
      sunset: _fromSeconds(sysData['sunset']),
      time: _fromSeconds(json['dt']),
      description: (weather['description'] as String?)?.trim().isNotEmpty == true
          ? weather['description'] as String
          : AppStrings(language).noDescription,
      main: weather['main'] as String? ?? 'Clouds',
      icon: weather['icon'] as String? ?? '',
      lat: _toDouble(coord['lat']),
      lon: _toDouble(coord['lon']),
    );
  }
}

class ForecastEntry {
  ForecastEntry({
    required this.time,
    required this.temp,
    required this.main,
    required this.icon,
    required this.pop,
  });

  final DateTime time;
  final double temp;
  final String main;
  final String icon;
  final double pop;

  factory ForecastEntry.fromJson(Map<String, dynamic> json) {
    final weather =
        (json['weather'] as List<dynamic>? ?? const []).firstOrNull()
            as Map<String, dynamic>? ?? const {};
    final mainData = json['main'] as Map<String, dynamic>? ?? const {};
    return ForecastEntry(
      time: _fromSeconds(json['dt']),
      temp: _toDouble(mainData['temp']),
      main: weather['main'] as String? ?? 'Clouds',
      icon: weather['icon'] as String? ?? '',
      pop: _toDouble(json['pop']),
    );
  }
}

class DailyForecast {
  DailyForecast({
    required this.date,
    required this.min,
    required this.max,
    required this.main,
    required this.icon,
    required this.pop,
  });

  final DateTime date;
  final double min;
  final double max;
  final String main;
  final String icon;
  final double pop;
}

class ForecastData {
  ForecastData({required this.entries, required this.daily});

  final List<ForecastEntry> entries;
  final List<DailyForecast> daily;

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    final list = json['list'] as List<dynamic>? ?? const [];
    final entries = list
        .map((e) => ForecastEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final daily = _buildDaily(entries);
    return ForecastData(entries: entries, daily: daily);
  }

  static List<DailyForecast> _buildDaily(List<ForecastEntry> entries) {
    final map = <DateTime, _DailyAccumulator>{};
    for (final entry in entries) {
      final day = DateTime(entry.time.year, entry.time.month, entry.time.day);
      final accumulator = map.putIfAbsent(
        day,
        () => _DailyAccumulator(entry),
      );
      accumulator.add(entry);
    }

    final daily = map.entries
        .map((entry) => entry.value.toDaily(entry.key))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return daily;
  }
}

class _DailyAccumulator {
  _DailyAccumulator(ForecastEntry entry)
      : min = entry.temp,
        max = entry.temp,
        pop = entry.pop,
        representative = entry;

  double min;
  double max;
  double pop;
  ForecastEntry representative;

  void add(ForecastEntry entry) {
    min = math.min(min, entry.temp);
    max = math.max(max, entry.temp);
    pop = math.max(pop, entry.pop);
    final target = DateTime(
      entry.time.year,
      entry.time.month,
      entry.time.day,
      12,
    );
    if ((entry.time.difference(target).abs()) <
        (representative.time.difference(target).abs())) {
      representative = entry;
    }
  }

  DailyForecast toDaily(DateTime day) {
    return DailyForecast(
      date: day,
      min: min,
      max: max,
      main: representative.main,
      icon: representative.icon,
      pop: pop,
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return 0;
}

int _toInt(Object? value) {
  if (value is num) return value.toInt();
  return 0;
}

DateTime _fromSeconds(Object? value) {
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true)
        .toLocal();
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000, isUtc: true)
        .toLocal();
  }
  return DateTime.now();
}

extension on List<dynamic> {
  dynamic firstOrNull() => isEmpty ? null : first;
}
