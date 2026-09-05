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

  /// The all-days positive rate from the stats build (P(reported flight) on
  /// a random historical day) — the anchor the band ladder is measured
  /// against.
  double get baseRate => (_stats!['base_rate'] as num).toDouble();

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

/// The five bands of the Ant Flight Index, anchored to CALIBRATED odds
/// (multiples of the all-days base rate) rather than seasonal rank.
///
/// Rationale (2026-08 recalibration): the previous percentile-only bands put
/// the 40th-70th percentile in "watchful" — but per the calibration table
/// those days run ~1-in-41 to ~1-in-19 odds, i.e. mostly BELOW the ~1-in-21
/// base rate. Calling a below-average day "worth watching" (with an amber
/// pill and green-leaning chart) overpromised. Now a day only escapes
/// [quiet] when its calibrated probability beats the base rate, and:
///
///   quiet      p <  1x base rate   (at or below an average day)
///   watchful   p >= 1x base rate   ("Fair" - modestly better than average)
///   promising  p >= 2x base rate   (~1-in-11 or better on 2026-08 stats)
///   prime      p >= 4x base rate   (~1-in-5 or better - genuinely rare)
///
/// [noFly] still comes from the model's hard weather cutoffs. On the
/// 2026-08 stats these thresholds sit near raw scores 0.48 / 0.52 / 0.70,
/// but the mapping is computed from the shipped calibration table so it
/// tracks every retrain automatically.
enum FlightBand { noFly, quiet, watchful, promising, prime }

FlightBand bandFor(double score) {
  // The runtime scoring floors impossible weather (cold/gale) to 0.01.
  if (score <= 0.011) return FlightBand.noFly;
  final FlightIndex fi = FlightIndex();
  final double p = fi.calibratedProbability(score);
  final double base = fi.baseRate;
  if (p < base) return FlightBand.quiet;
  if (p < 2 * base) return FlightBand.watchful;
  if (p < 4 * base) return FlightBand.promising;
  return FlightBand.prime;
}

/// The lower (least promising) of two bands — used to cap an hour's band at
/// its day's band, so intra-day bars can't out-promise the day they sit in.
///
/// IMPORTANT — the cap is NOT justified by the daily model being better.
/// It isn't. Under the honest protocol (grouped CV by install + dedup +
/// temporal holdout, docs/model_training_findings.md Part 5) the shipped
/// hourly model beats the shipped daily one on every metric:
///
///   daily 28f   AUC 0.660 (holdout 0.639)   AP 0.147 (holdout 0.097)
///   hourly 22f  AUC 0.671 (holdout 0.666)   AP 0.149 (holdout 0.102)
///
/// Two real reasons the cap still earns its place:
///
///  1. The hourly model has NO rain or cloud feature (see
///     `nuptialHourlyPercentageModel` — 22 features, none of them
///     precipitation). It literally cannot see that it is pouring. The daily
///     model carries pop, cloud, rainMm and popNext1/2, so capping at the day
///     stops a downpour reading as a promising afternoon.
///  2. Band thresholds come from `flight_stats.json`, whose calibration and
///     quantiles were fitted on DAILY scores only. An hourly score of 0.55
///     therefore does not mean what a daily 0.55 means, and [bandFor] cannot
///     tell them apart. Until an hourly calibration table ships, capping
///     bounds the error from that mismatch.
///
/// Fixing (2) — fitting hourly quantiles/isotonic alongside the daily ones —
/// is what would let the cap be revisited. Do not remove it before then.
FlightBand minBand(FlightBand a, FlightBand b) =>
    a.index <= b.index ? a : b;

String bandLabel(FlightBand band) {
  switch (band) {
    case FlightBand.noFly:
      return 'No-fly';
    case FlightBand.quiet:
      return 'Quiet';
    case FlightBand.watchful:
      return 'Fair';
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
      return 'Slightly better than average';
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
