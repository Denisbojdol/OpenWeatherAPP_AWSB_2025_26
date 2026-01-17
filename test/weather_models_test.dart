import 'package:flutter_application/core/app_strings.dart';
import 'package:flutter_application/core/unit_system.dart';
import 'package:flutter_application/models/weather_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CurrentWeather.fromJson uses fallback description', () {
    final now = DateTime.now();
    final dt = now.toUtc().millisecondsSinceEpoch ~/ 1000;
    final json = <String, dynamic>{
      'name': 'Testville',
      'dt': dt,
      'visibility': 10000,
      'weather': [
        {
          'description': '   ',
          'main': 'Clear',
          'icon': '01d',
        }
      ],
      'main': {
        'temp': 20.5,
        'feels_like': 19.0,
        'temp_min': 18.0,
        'temp_max': 22.0,
        'humidity': 55,
        'pressure': 1012,
      },
      'wind': {'speed': 10.0},
      'sys': {
        'sunrise': dt - 3600,
        'sunset': dt + 3600,
      },
      'coord': {
        'lat': 50.0,
        'lon': 19.0,
      },
    };

    final weather = CurrentWeather.fromJson(
      json,
      UnitSystem.metric,
      AppLanguage.en,
    );

    expect(weather.city, 'Testville');
    expect(weather.description, 'No description');
    expect(weather.windSpeed, closeTo(36.0, 0.01));
    expect(weather.lat, 50.0);
    expect(weather.lon, 19.0);
    expect(weather.main, 'Clear');
    expect(weather.icon, '01d');
  });

  test('ForecastData builds daily aggregates', () {
    final now = DateTime.now();
    final day1a = DateTime(now.year, now.month, now.day, 9);
    final day1b = DateTime(now.year, now.month, now.day, 15);
    final day2 = DateTime(now.year, now.month, now.day, 11)
        .add(const Duration(days: 1));

    final list = [
      _forecastJson(day1a, temp: 5, pop: 0.1, main: 'Clear', icon: '01d'),
      _forecastJson(day1b, temp: 8, pop: 0.3, main: 'Clouds', icon: '02d'),
      _forecastJson(day2, temp: 2, pop: 0.5, main: 'Rain', icon: '09d'),
    ];
    final data = ForecastData.fromJson({'list': list});

    expect(data.entries.length, 3);
    expect(data.daily.length, 2);

    final day1 = data.daily.firstWhere((d) => _sameDay(d.date, day1a));
    expect(day1.min, 5);
    expect(day1.max, 8);
    expect(day1.pop, 0.3);
    expect(day1.main, 'Clear');

    final day2Agg = data.daily.firstWhere((d) => _sameDay(d.date, day2));
    expect(day2Agg.min, 2);
    expect(day2Agg.max, 2);
    expect(day2Agg.pop, 0.5);
  });

  test('WeatherBundle nextHours filters recent entries', () {
    final now = DateTime.now();
    final entries = [
      ForecastEntry(
        time: now.subtract(const Duration(hours: 2)),
        temp: 1,
        main: 'Clear',
        icon: '',
        pop: 0,
      ),
      ForecastEntry(
        time: now.subtract(const Duration(minutes: 30)),
        temp: 2,
        main: 'Clear',
        icon: '',
        pop: 0,
      ),
      ForecastEntry(
        time: now.add(const Duration(hours: 1)),
        temp: 3,
        main: 'Clear',
        icon: '',
        pop: 0,
      ),
    ];

    final bundle = WeatherBundle(
      current: _dummyCurrent(now),
      hourly: entries,
      daily: const [],
    );

    final nextHours = bundle.nextHours;
    expect(nextHours.length, 2);
    expect(
      nextHours.every(
        (e) => e.time.isAfter(now.subtract(const Duration(hours: 1))),
      ),
      isTrue,
    );
  });
}

Map<String, dynamic> _forecastJson(
  DateTime time, {
  required double temp,
  required double pop,
  required String main,
  required String icon,
}) {
  return {
    'dt': time.toUtc().millisecondsSinceEpoch ~/ 1000,
    'main': {'temp': temp},
    'pop': pop,
    'weather': [
      {'main': main, 'icon': icon}
    ],
  };
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

CurrentWeather _dummyCurrent(DateTime now) {
  return CurrentWeather(
    city: 'X',
    temp: 0,
    feelsLike: 0,
    min: 0,
    max: 0,
    humidity: 0,
    pressure: 0,
    visibility: 0,
    windSpeed: 0,
    sunrise: now,
    sunset: now,
    time: now,
    description: 'x',
    main: 'Clear',
    icon: '',
    lat: 0,
    lon: 0,
  );
}
