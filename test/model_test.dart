import 'dart:io';
import 'dart:math';

import 'package:nuptialflight/models/forest_model.dart';
import 'package:test/test.dart';

void main() {
  group('Daily Model', () {
    test('Score', () {
      final model = ForestModel.fromJsonString(
          File('assets/final_model.json').readAsStringSync());
      // The daily model (retrained 2026-07-26) expects 15 features:
      // [lat, lon, hemisphere, sin_doy, cos_doy, temp, wind, rain0, humid,
      //  cloud, press, dewPoint, dew_dep, rain1, rain2]
      // dayOfYear 281 (2022-10-08 UTC).
      const doy = 281;
      final sinDoy = sin(2 * pi * doy / 365.25);
      final cosDoy = cos(2 * pi * doy / 365.25);
      expect(
          model.scorePositive([-35.2, 149.1, 0.0, sinDoy, cosDoy, 16.4, 5.7, 0.95, 77, 74, 1013, 12.0, 4.4, 0.2, 0.1]),
          closeTo(0.48, 0.01));
    });
  });
}