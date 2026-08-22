import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// The Ant Flight Index: turns the daily model's raw score (an uncalibrated
/// tree-vote fraction) into things a person can act on:
///
///  * a PERCENTILE against ~219k historical days at the same hemisphere and
///    calendar month (rank order is what the forest is actually good at), and
///  * a calibrated probability that a day like this gets a flight REPORTED
///    (isotonic regression fitted offline against the flights DB).
///
/// Both come from `assets/flight_stats.json`, regenerated alongside model
/// retrains by the stats pipeline (see docs/model_training_findings.md).
class FlightIndex {
  static final FlightIndex _instance = FlightIndex._internal();
  static Future<void>? _loading;

  Map<String, dynamic>? _stats;

  factory FlightIndex() => _instance;

  FlightIndex._internal();

  /// Parses the stats asset once. MUST complete before the query methods are
  /// used (mirrors Nuptials.ensureLoaded()).
  static Future<void> ensureLoaded() => _loading ??= _load();

  static Future<void> _load() async {
    _instance._stats =
        jsonDecode(await rootBundle.loadString('assets/flight_stats.json'))
            as Map<String, dynamic>;
  }

  /// Test hook: inject stats from a raw JSON string (no rootBundle).
  static void loadFromString(String statsJson) {
    _instance._stats = jsonDecode(statsJson) as Map<String, dynamic>;
    _loading = Future.value();
  }

  bool get isLoaded => _stats != null;

  /// Percentile (0..100) of [score] among historical days in the same
  /// hemisphere and [month] (1..12). Linear interpolation between the stored
  /// quantile steps.
  double percentile(double score, num lat, int month) {
    final Map<String, dynamic> stats = _stats!;
    final List<dynamic> steps = stats['quantile_steps'] as List<dynamic>;
    final Map<String, dynamic> hemi =
        (stats['quantiles'] as Map<String, dynamic>)[lat > 0 ? 'n' : 's']
            as Map<String, dynamic>;
    final List<dynamic> qs =
        (hemi['$month'] ?? hemi['all']) as List<dynamic>;

    if (score <= (qs.first as num)) return 0;
    if (score >= (qs.last as num)) return 100;
    for (int i = 0; i < qs.length - 1; i++) {
      final double lo = (qs[i] as num).toDouble();
      final double hi = (qs[i + 1] as num).toDouble();
      if (score >= lo && score <= hi) {
        final double t = hi == lo ? 1.0 : (score - lo) / (hi - lo);
        final double pLo = (steps[i] as num).toDouble() * 100;
        final double pHi = (steps[i + 1] as num).toDouble() * 100;
        return pLo + t * (pHi - pLo);
      }
    }
    return 100;
  }

  /// Calibrated probability that a day with this [score] gets a flight
  /// reported, from the offline isotonic fit. Piecewise-linear lookup.
  double calibratedProbability(double score) {
    final Map<String, dynamic> cal =
        _stats!['calibration'] as Map<String, dynamic>;
    final List<dynamic> xs = cal['scores'] as List<dynamic>;
    final List<dynamic> ys = cal['probs'] as List<dynamic>;
    if (score <= (xs.first as num)) return (ys.first as num).toDouble();
    if (score >= (xs.last as num)) return (ys.last as num).toDouble();
    for (int i = 0; i < xs.length - 1; i++) {
      final double lo = (xs[i] as num).toDouble();
      final double hi = (xs[i + 1] as num).toDouble();
      if (score >= lo && score <= hi) {
        final double t = hi == lo ? 1.0 : (score - lo) / (hi - lo);
        final double yLo = (ys[i] as num).toDouble();
        final double yHi = (ys[i + 1] as num).toDouble();
        return yLo + t * (yHi - yLo);
      }
    }
    return (ys.last as num).toDouble();
  }

  /// "1 in N" denominator for the calibrated probability (N >= 1), the
  /// friendliest honest framing of a small probability.
  int oneInN(double score) {
    final double p = calibratedProbability(score);
    if (p <= 0) return 999;
    final int n = (1 / p).round();
    return n < 1 ? 1 : n;
  }
}

/// The five bands of the Ant Flight Index, defined by percentile against
/// days at the same hemisphere + month (plus the model's hard weather
/// cutoffs for [noFly]). Band boundaries chosen from the 2026-08 stats run:
/// the old "green" threshold (score 0.60) sat at the 92.6th percentile
/// overall, so [prime] ~ the old green and [promising] ~ the old amber.
enum FlightBand { noFly, quiet, watchful, promising, prime }

FlightBand bandFor(double score, double percentile) {
  // The runtime scoring floors impossible weather (cold/gale) to 0.01.
  if (score <= 0.011) return FlightBand.noFly;
  if (percentile < 40) return FlightBand.quiet;
  if (percentile < 70) return FlightBand.watchful;
  if (percentile < 90) return FlightBand.promising;
  return FlightBand.prime;
}

String bandLabel(FlightBand band) {
  switch (band) {
    case FlightBand.noFly:
      return 'No-fly';
    case FlightBand.quiet:
      return 'Quiet';
    case FlightBand.watchful:
      return 'Watchful';
    case FlightBand.promising:
      return 'Promising';
    case FlightBand.prime:
      return 'Prime';
  }
}

/// The headline phrase for the hero card.
String bandHeadline(FlightBand band) {
  switch (band) {
    case FlightBand.noFly:
      return 'No flights today';
    case FlightBand.quiet:
      return 'Quiet day';
    case FlightBand.watchful:
      return 'Worth watching';
    case FlightBand.promising:
      return 'Promising day';
    case FlightBand.prime:
      return 'Prime conditions';
  }
}

/// The action a keeper should take, phrased as a recommendation.
String bandAction(FlightBand band) {
  switch (band) {
    case FlightBand.noFly:
      return 'Ants stay home in this weather';
    case FlightBand.quiet:
      return 'Not worth a special trip';
    case FlightBand.watchful:
      return 'Keep an eye out if you\'re outside';
    case FlightBand.promising:
      return 'Worth a look at the best window';
    case FlightBand.prime:
      return 'Get out there - conditions are rare';
  }
}
