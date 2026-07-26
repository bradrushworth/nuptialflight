import 'dart:io';
import 'dart:math';

import 'package:nuptialflight/models/forest_model.dart';
import 'package:test/test.dart';

void main() {
  group('Hour Model', () {
    test('Score', () {
      final model = ForestModel.fromJsonString(
          File('assets/hour_model.json').readAsStringSync());
      // The hourly model (retrained 2026-07-26 part 4) expects 14 features:
      // [lat, lon, hemisphere, sin_doy, cos_doy, hour, temp, wind, humid,
      //  press, dewPoint, dew_dep, uvi, windGust] (no rain/cloud/visibility).
      // dayOfYear 281, hour 11 (2022-10-08 11:00 UTC).
      const doy = 281;
      final sinDoy = sin(2 * pi * doy / 365.25);
      final cosDoy = cos(2 * pi * doy / 365.25);
      expect(
          model.scorePositive([-35.2, 149.1, 0.0, sinDoy, cosDoy, 11, 16.4, 5.7, 77, 1015, 12.0, 4.4, 6.0, 7.0]),
          closeTo(0.38, 0.01));
    });
  });
}