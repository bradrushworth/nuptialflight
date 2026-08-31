import 'dart:io';
import 'dart:math';

import 'package:nuptialflight/models/forest_model.dart';
import 'package:test/test.dart';

void main() {
  group('Hour Model', () {
    test('Score', () {
      final model = ForestModel.fromJsonString(
          File('assets/hour_model.json').readAsStringSync());
      // The hourly model (retrained 2026-08-30) expects 22 features:
      // [lat, lon, hemisphere, sin_doy, cos_doy, temp, wind, humid, press,
      //  dewPoint, dew_dep, uvi, windGust, solar_sin, solar_cos] plus the 7
      // LeadUpFeatures (here: the no-coverage row). UTC `hour` was replaced
      // by the cyclical local-solar hour = (hour + lon/15) mod 24.
      // dayOfYear 281, hour 11 UTC (2022-10-08 11:00 UTC).
      const doy = 281;
      final sinDoy = sin(2 * pi * doy / 365.25);
      final cosDoy = cos(2 * pi * doy / 365.25);
      final solar = (((11 + 149.1 / 15.0) % 24) + 24) % 24;
      final solarSin = sin(2 * pi * solar / 24);
      final solarCos = cos(2 * pi * solar / 24);
      expect(
          model.scorePositive([-35.2, 149.1, 0.0, sinDoy, cosDoy, 16.4, 5.7, 77, 1015, 12.0, 4.4, 6.0, 7.0, solarSin, solarCos, 0.0, 0.0, 0.0, 0.0, 2.0, 0.0, 0.0]),
          closeTo(0.449, 0.01));
    });
  });
}