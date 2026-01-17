import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_application/core/app_strings.dart';
import 'package:flutter_application/core/unit_system.dart';
import 'package:flutter_application/models/weather_models.dart';
import 'package:flutter_application/services/weather_cache.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  static const String _base = 'https://api.openweathermap.org/data/2.5';
  final http.Client _client;

  Future<WeatherBundle> fetchByCity(
    String city, {
    required UnitSystem unitSystem,
    required AppLanguage language,
  }) async {
    final currentJson = await _getJson(
      '/weather',
      {'q': city},
      unitSystem: unitSystem,
      language: language,
    );
    final current = CurrentWeather.fromJson(
      currentJson,
      unitSystem,
      language,
    );
    final forecastJson = await _getJson(
      '/forecast',
      {
        'lat': current.lat.toString(),
        'lon': current.lon.toString(),
      },
      unitSystem: unitSystem,
      language: language,
    );
    final forecast = ForecastData.fromJson(forecastJson);
    try {
      await WeatherCache.save(
        currentJson: currentJson,
        forecastJson: forecastJson,
        unitSystem: unitSystem,
        language: language,
        cityQuery: city.trim(),
      );
    } catch (_) {}
    return WeatherBundle(
      current: current,
      hourly: forecast.entries,
      daily: forecast.daily,
    );
  }

  Future<WeatherBundle> fetchByLatLon({
    required double lat,
    required double lon,
    required UnitSystem unitSystem,
    required AppLanguage language,
  }) async {
    final currentJson = await _getJson(
      '/weather',
      {
        'lat': lat.toString(),
        'lon': lon.toString(),
      },
      unitSystem: unitSystem,
      language: language,
    );
    final current = CurrentWeather.fromJson(
      currentJson,
      unitSystem,
      language,
    );
    final forecastJson = await _getJson(
      '/forecast',
      {
        'lat': lat.toString(),
        'lon': lon.toString(),
      },
      unitSystem: unitSystem,
      language: language,
    );
    final forecast = ForecastData.fromJson(forecastJson);
    try {
      await WeatherCache.save(
        currentJson: currentJson,
        forecastJson: forecastJson,
        unitSystem: unitSystem,
        language: language,
        lat: lat,
        lon: lon,
      );
    } catch (_) {}
    return WeatherBundle(
      current: current,
      hourly: forecast.entries,
      daily: forecast.daily,
    );
  }

  Future<Map<String, dynamic>> _getJson(
    String path,
    Map<String, String> params, {
    required UnitSystem unitSystem,
    required AppLanguage language,
  }) async {
    const apiKey = String.fromEnvironment('OWM_API_KEY');
    if (apiKey.isEmpty) {
      throw StateError(AppStrings(language).apiKeyMissing);
    }

    final dynamic connectivity = await Connectivity().checkConnectivity();
    final hasConnection = connectivity is List<ConnectivityResult>
        ? connectivity.any((result) => result != ConnectivityResult.none)
        : connectivity != ConnectivityResult.none;
    if (!hasConnection) {
      throw StateError(AppStrings(language).errorNoInternet);
    }

    final uri = Uri.parse('$_base$path').replace(queryParameters: {
      ...params,
      'appid': apiKey,
      'units': unitSystem.apiValue,
      'lang': language.apiValue,
    });

    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      var message = 'HTTP ${res.statusCode}';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['message'] != null) {
          message = '$message: ${body['message']}';
        }
      } catch (_) {
        message = '$message: ${res.body}';
      }
      throw Exception(message);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  void dispose() {
    _client.close();
  }
}
