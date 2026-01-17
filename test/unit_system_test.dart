import 'package:flutter_application/core/unit_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('metric formatting and conversions', () {
    expect(UnitSystem.metric.formatTemp(12.34), '12.3\u00B0C');
    expect(UnitSystem.metric.formatWind(10), '10.0 km/h');
    expect(UnitSystem.metric.formatVisibility(1000), '1.0 km');
    expect(UnitSystem.metric.normalizeWindSpeed(10), 36.0);
  });

  test('imperial formatting and conversions', () {
    expect(UnitSystem.imperial.formatTemp(12.34), '12.3\u00B0F');
    expect(UnitSystem.imperial.formatWind(10), '10.0 mph');
    expect(UnitSystem.imperial.formatVisibility(1609), '1.0 mi');
    expect(UnitSystem.imperial.normalizeWindSpeed(10), 10);
  });

  test('api value mapping', () {
    expect(unitSystemFromApiValue('imperial'), UnitSystem.imperial);
    expect(unitSystemFromApiValue('metric'), UnitSystem.metric);
    expect(unitSystemFromApiValue(null), UnitSystem.metric);
  });
}
