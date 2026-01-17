import 'package:flutter/material.dart';

class WeatherIcon extends StatelessWidget {
  const WeatherIcon({
    super.key,
    required this.iconCode,
    required this.main,
    required this.size,
  });

  final String iconCode;
  final String main;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (iconCode.isEmpty) {
      return Icon(WeatherVisuals.iconFor(main), size: size);
    }
    return Image.network(
      'https://openweathermap.org/img/wn/${iconCode}@2x.png',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) =>
          Icon(WeatherVisuals.iconFor(main), size: size),
    );
  }
}

class WeatherVisuals {
  static LinearGradient gradientFor(
    String? main,
    DateTime? time,
    Brightness brightness,
  ) {
    final isNight = time != null && (time.hour < 6 || time.hour >= 19);
    List<Color> colors;
    switch (main) {
      case 'Clear':
        colors = isNight
            ? const [Color(0xFF0D1B2A), Color(0xFF1B263B)]
            : const [Color(0xFF3A86FF), Color(0xFF8ECAE6)];
        break;
      case 'Clouds':
        colors = const [Color(0xFF5C677D), Color(0xFFB5C0D0)];
        break;
      case 'Rain':
      case 'Drizzle':
        colors = const [Color(0xFF335C67), Color(0xFF76C1CF)];
        break;
      case 'Thunderstorm':
        colors = const [Color(0xFF22223B), Color(0xFF4A4E69)];
        break;
      case 'Snow':
        colors = const [Color(0xFFE0FBFC), Color(0xFF8ECAE6)];
        break;
      case 'Mist':
      case 'Fog':
      case 'Haze':
      case 'Smoke':
        colors = const [Color(0xFF6C757D), Color(0xFFADB5BD)];
        break;
      default:
        colors = const [Color(0xFF284B63), Color(0xFF3C6E71)];
    }

    if (brightness == Brightness.dark) {
      colors = colors.map((color) => _darken(color, 0.22)).toList();
    }

    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Color _darken(Color color, double amount) {
    final factor = 1 - amount;
    return Color.fromARGB(
      color.alpha,
      (color.red * factor).round(),
      (color.green * factor).round(),
      (color.blue * factor).round(),
    );
  }

  static IconData iconFor(String? main) {
    switch (main) {
      case 'Clear':
        return Icons.wb_sunny;
      case 'Clouds':
        return Icons.cloud;
      case 'Rain':
      case 'Drizzle':
        return Icons.grain;
      case 'Thunderstorm':
        return Icons.flash_on;
      case 'Snow':
        return Icons.ac_unit;
      case 'Mist':
      case 'Fog':
      case 'Haze':
      case 'Smoke':
        return Icons.blur_on;
      default:
        return Icons.cloud_outlined;
    }
  }
}
