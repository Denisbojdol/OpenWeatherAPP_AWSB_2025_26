enum UnitSystem { metric, imperial }

extension UnitSystemX on UnitSystem {
  String get label {
    switch (this) {
      case UnitSystem.metric:
        return 'Metryczne (\u00B0C, km/h)';
      case UnitSystem.imperial:
        return 'Imperialne (\u00B0F, mph)';
    }
  }

  String get tempSymbol =>
      this == UnitSystem.metric ? '\u00B0C' : '\u00B0F';
  String get windUnit => this == UnitSystem.metric ? 'km/h' : 'mph';
  String get visibilityUnit => this == UnitSystem.metric ? 'km' : 'mi';
  String get apiValue => this == UnitSystem.metric ? 'metric' : 'imperial';

  String formatTemp(double value, {int digits = 1}) {
    return '${value.toStringAsFixed(digits)}$tempSymbol';
  }

  String formatWind(double speed) {
    return '${speed.toStringAsFixed(1)} $windUnit';
  }

  String formatVisibility(int meters) {
    final value =
        this == UnitSystem.metric ? meters / 1000 : meters / 1609.344;
    return '${value.toStringAsFixed(1)} $visibilityUnit';
  }

  double normalizeWindSpeed(double rawSpeed) {
    if (this == UnitSystem.metric) {
      return rawSpeed * 3.6;
    }
    return rawSpeed;
  }
}

UnitSystem unitSystemFromApiValue(String? value) {
  if (value == UnitSystem.imperial.apiValue) {
    return UnitSystem.imperial;
  }
  return UnitSystem.metric;
}
