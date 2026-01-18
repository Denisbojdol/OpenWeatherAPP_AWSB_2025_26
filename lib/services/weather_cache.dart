import 'dart:convert';

import 'package:flutter_application/core/app_strings.dart';
import 'package:flutter_application/core/unit_system.dart';
import 'package:flutter_application/models/weather_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CachedWeather {
  CachedWeather({
    required this.bundle,
    required this.updatedAt,
    required this.unitSystem,
    required this.language,
    this.cityQuery,
    this.lat,
    this.lon,
  });

  final WeatherBundle bundle;
  final DateTime updatedAt;
  final UnitSystem unitSystem;
  final AppLanguage language;
  final String? cityQuery;
  final double? lat;
  final double? lon;

  bool get usedLocation => cityQuery == null || cityQuery!.isEmpty;
}

class WeatherCache {
  static const String _key = 'weather_cache_v1';

  static Future<void> save({
    required Map<String, dynamic> currentJson,
    required Map<String, dynamic> forecastJson,
    required UnitSystem unitSystem,
    required AppLanguage language,
    String? cityQuery,
    double? lat,
    double? lon,
  }) async {
    final payload = <String, dynamic>{
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'unit': unitSystem.apiValue,
      'language': language.apiValue,
      'cityQuery': cityQuery,
      'lat': lat,
      'lon': lon,
      'current': currentJson,
      'forecast': forecastJson,
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(payload));
  }

  static Future<CachedWeather?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final unitSystem = unitSystemFromApiValue(data['unit'] as String?);
      final language = appLanguageFromApiValue(data['language'] as String?);
      final currentJson = Map<String, dynamic>.from(
        data['current'] as Map<dynamic, dynamic>,
      );
      final forecastJson = Map<String, dynamic>.from(
        data['forecast'] as Map<dynamic, dynamic>,
      );
      final current = CurrentWeather.fromJson(
        currentJson,
        unitSystem,
        language,
      );
      final forecast = ForecastData.fromJson(forecastJson);
      final bundle = WeatherBundle(
        current: current,
        hourly: forecast.entries,
        daily: forecast.daily,
      );
      final timestamp = data['timestamp'] as int? ?? 0;
      final cityQuery = data['cityQuery'] as String?;
      final lat = (data['lat'] as num?)?.toDouble();
      final lon = (data['lon'] as num?)?.toDouble();

      return CachedWeather(
        bundle: bundle,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal(),
        unitSystem: unitSystem,
        language: language,
        cityQuery: cityQuery,
        lat: lat,
        lon: lon,
      );
    } catch (_) {
      return null;
    }
  }
}
