import 'dart:io';
import 'dart:math';

import 'package:nuptialflight/models/forest_model.dart';
import 'package:test/test.dart';

void main() {
  group('Daily Model', () {
    test('Score', () {
      final model = ForestModel.fromJsonString(
          File('assets/final_model.json').readAsStringSync());
      // The daily model (retrained 2026-07-26 part 4) expects 21 features:
      // [lat, lon, hemisphere, sin_doy, cos_doy, temp, wind, rain0(pop), humid,
      //  cloud, press, dewPoint, dew_dep, popNext1, popNext2, uvi, windGust,
      //  rainMm, daylength, moonSin, moonCos]
      // dayOfYear 281 (2022-10-08 UTC); moon phase 0.5.
      const doy = 281;
      final sinDoy = sin(2 * pi * doy / 365.25);
      final cosDoy = cos(2 * pi * doy / 365.25);
      final moonSin = sin(2 * pi * 0.5);
      final moonCos = cos(2 * pi * 0.5);
      expect(
          model.scorePositive([-35.2, 149.1, 0.0, sinDoy, cosDoy, 16.4, 5.7, 0.95, 77, 74, 1013, 12.0, 4.4, 0.2, 0.1, 6.0, 7.0, 0.0, 13.0, moonSin, moonCos]),
          closeTo(0.45, 0.01));
    });
  });
}