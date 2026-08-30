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
        // Base rate 0.05 with p = score/2 puts the band boundaries at
        // scores 0.10 (1x), 0.20 (2x) and 0.40 (4x).
        'base_rate': 0.05,
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

    test('band boundaries follow calibrated multiples of the base rate', () {
      // Fixture: p = score/2, base_rate = 0.05.
      expect(bandFor(0.01), FlightBand.noFly); // hard weather cutoff
      expect(bandFor(0.05), FlightBand.quiet); // p 0.025 < 1x base
      expect(bandFor(0.15), FlightBand.watchful); // p 0.075 in [1x, 2x)
      expect(bandFor(0.30), FlightBand.promising); // p 0.15  in [2x, 4x)
      expect(bandFor(0.50), FlightBand.prime); // p 0.25 >= 4x base
    });

    test('a below-base-rate day can never escape quiet', () {
      // p < base for every score below 0.10 in this fixture, whatever its
      // seasonal percentile would have been - the anti-overpromise gate.
      for (double s = 0.02; s < 0.10; s += 0.01) {
        expect(bandFor(s), FlightBand.quiet, reason: 'score $s');
      }
    });

    test('minBand caps an hour at its day', () {
      expect(minBand(FlightBand.prime, FlightBand.quiet), FlightBand.quiet);
      expect(minBand(FlightBand.quiet, FlightBand.prime), FlightBand.quiet);
      expect(minBand(FlightBand.noFly, FlightBand.promising), FlightBand.noFly);
      expect(minBand(FlightBand.promising, FlightBand.promising),
          FlightBand.promising);
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

    test('bands cannot overpromise on the shipped calibration', () {
      final String json = File('assets/flight_stats.json').readAsStringSync();
      FlightIndex.loadFromString(json);
      final double base = FlightIndex().baseRate;
      expect(base, inInclusiveRange(0.02, 0.10));
      // The original complaint: ~1-in-35 odds (worse than the ~1-in-21 base
      // rate) used to show "Watchful" + amber. It must read quiet now.
      final double oneIn35Score = 0.42; // calibrates to ~1-in-41..35 odds
      expect(FlightIndex().calibratedProbability(oneIn35Score), lessThan(base));
      expect(bandFor(oneIn35Score), FlightBand.quiet);
      // And the ladder still opens up for genuinely good days (anchors
      // re-pinned for the 2026-08-30 28-feature stats build).
      expect(bandFor(0.50), FlightBand.watchful); // ~1.4x base
      expect(bandFor(0.60), FlightBand.promising); // ~3.0x base
      expect(bandFor(0.80), FlightBand.prime); // >4x base (~1-in-5+)
    });
  });
}
