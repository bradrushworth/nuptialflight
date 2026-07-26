import 'package:flutter_test/flutter_test.dart';
import 'package:nuptialflight/controller/nuptials.dart';

void main() {
  group('sizeSeasonalMultiplier', () {
    // Northern hemisphere (lat > 0): small ants peak in July (month 7).
    test('NH small peaks in July', () {
      final july = DateTime.utc(2024, 7, 15);
      final jan = DateTime.utc(2024, 1, 15);
      expect(sizeSeasonalMultiplier('small', 50, july), 1.0);
      expect(sizeSeasonalMultiplier('small', 50, jan) < 0.2, isTrue);
    });

    // NH large ants fly earlier/broader than small.
    test('NH large flies earlier than small', () {
      final march = DateTime.utc(2024, 3, 15);
      expect(sizeSeasonalMultiplier('large', 50, march) >
          sizeSeasonalMultiplier('small', 50, march), isTrue);
    });

    // Southern hemisphere (lat < 0) offset ~6 months: small peaks Dec.
    test('SH small peaks in December', () {
      final dec = DateTime.utc(2024, 12, 15);
      expect(sizeSeasonalMultiplier('small', -33, dec), 1.0);
    });

    test('unknown/null size returns neutral 1.0', () {
      final july = DateTime.utc(2024, 7, 15);
      expect(sizeSeasonalMultiplier(null, 50, july), 1.0);
      expect(sizeSeasonalMultiplier('giant', 50, july), 1.0);
    });

    test('multiplier is always within [0,1]', () {
      for (final size in ['small', 'medium', 'large']) {
        for (var m = 1; m <= 12; m++) {
          final v = sizeSeasonalMultiplier(size, 50, DateTime.utc(2024, m, 15));
          expect(v >= 0.0 && v <= 1.0, isTrue);
        }
      }
    });
  });

  group('sizeSeasonalPercentages', () {
    test('scales base percentage per size and is ordered by season', () {
      final july = DateTime.utc(2024, 7, 15);
      final p = sizeSeasonalPercentages(80, 50, july);
      expect(p['small'], 80);
      expect(p['large']! < p['small']!, isTrue);
      expect(p.values.every((v) => v >= 0 && v <= 80), isTrue);
    });
  });
}