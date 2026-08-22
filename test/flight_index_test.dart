import 'dart:convert';
import 'dart:io';

import 'package:nuptialflight/controller/flight_index.dart';
import 'package:test/test.dart';

void main() {
  group('FlightIndex (synthetic fixture)', () {
    setUpAll(() {
      // Quantiles: northern January linear 0.0..1.0 across the 21 5%-steps;
      // calibration: p = score / 2.
      final fixture = {
        'quantile_steps': [for (int i = 0; i <= 20; i++) i * 5 / 100],
        'quantiles': {
          'n': {
            for (int m = 1; m <= 12; m++)
              '$m': [for (int i = 0; i <= 20; i++) i / 20],
            'all': [for (int i = 0; i <= 20; i++) i / 20],
          },
          's': {
            for (int m = 1; m <= 12; m++)
              '$m': [for (int i = 0; i <= 20; i++) 0.5 * i / 20],
            'all': [for (int i = 0; i <= 20; i++) 0.5 * i / 20],
          },
        },
        'calibration': {
          'scores': [for (int i = 1; i <= 99; i++) i / 100],
          'probs': [for (int i = 1; i <= 99; i++) i / 200],
        },
      };
      FlightIndex.loadFromString(jsonEncode(fixture));
    });

    test('percentile interpolates linearly', () {
      expect(FlightIndex().percentile(0.5, 45, 1), closeTo(50, 0.5));
      expect(FlightIndex().percentile(0.25, 45, 6), closeTo(25, 0.5));
      expect(FlightIndex().percentile(0.0, 45, 1), 0);
      expect(FlightIndex().percentile(1.0, 45, 1), 100);
    });

    test('southern hemisphere uses its own table', () {
      // SH quantiles run 0..0.5, so score 0.25 is the median.
      expect(FlightIndex().percentile(0.25, -35, 1), closeTo(50, 0.5));
      expect(FlightIndex().percentile(0.5, -35, 1), 100);
    });

    test('calibrated probability and oneInN', () {
      expect(FlightIndex().calibratedProbability(0.5), closeTo(0.25, 0.01));
      expect(FlightIndex().oneInN(0.5), 4);
      expect(FlightIndex().oneInN(0.02), closeTo(100, 1));
    });

    test('band boundaries', () {
      expect(bandFor(0.01, 0), FlightBand.noFly);
      expect(bandFor(0.30, 20), FlightBand.quiet);
      expect(bandFor(0.50, 55), FlightBand.watchful);
      expect(bandFor(0.60, 80), FlightBand.promising);
      expect(bandFor(0.70, 95), FlightBand.prime);
    });

    test('labels are complete', () {
      for (final band in FlightBand.values) {
        expect(bandLabel(band), isNotEmpty);
        expect(bandHeadline(band), isNotEmpty);
        expect(bandAction(band), isNotEmpty);
      }
    });
  });

  group('FlightIndex (shipped asset)', () {
    test('real stats file parses and behaves sanely', () {
      final String json = File('assets/flight_stats.json').readAsStringSync();
      FlightIndex.loadFromString(json);
      // Monotone: better score, never-lower percentile and probability.
      final double p1 = FlightIndex().percentile(0.4, -35, 1);
      final double p2 = FlightIndex().percentile(0.6, -35, 1);
      expect(p2, greaterThanOrEqualTo(p1));
      expect(FlightIndex().calibratedProbability(0.6),
          greaterThanOrEqualTo(FlightIndex().calibratedProbability(0.4)));
      // The old "green" threshold (0.60) should be a genuinely high
      // percentile in the southern-summer table.
      expect(FlightIndex().percentile(0.60, -35, 12), greaterThan(70));
      // Odds are within the plausible range surfaced by the stats run.
      final int n = FlightIndex().oneInN(0.65);
      expect(n, inInclusiveRange(2, 50));
    });
  });
}
