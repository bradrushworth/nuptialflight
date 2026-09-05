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

  /// The optional `hourly` sibling block: quantiles + isotonic calibration
  /// fitted on HOURLY scores (see scripts/flight_stats_pipeline.py).
  ///
  /// Null on stats assets generated before 2026-09-05. Everything hourly
  /// falls back to the daily tables in that case, which is what the app did
  /// unconditionally before the hourly fit existed — wrong, but no worse
  /// than it used to be, and it keeps old assets and hand-written test
  /// fixtures working.
  Map<String, dynamic>? get _hourlyStats =>
      _stats!['hourly'] as Map<String, dynamic>?;

  bool get hasHourlyStats => _hourlyStats != null;

  /// The all-days positive rate from the stats build (P(reported flight) on
  /// a random historical day) — the anchor the band ladder is measured
  /// against.
  double get baseRate => (_stats!['base_rate'] as num).toDouble();

  /// The per-hour equivalent of [baseRate]: P(reported flight) on a random
  /// historical hour. Falls back to [baseRate] when no hourly block exists.
  double get hourlyBaseRate =>
      ((_hourlyStats?['base_rate'] ?? _stats!['base_rate']) as num).toDouble();

  /// Percentile (0..100) of [score] among historical days in the same
  /// hemisphere and [month] (1..12). Linear interpolation between the stored
  /// quantile steps.
  double percentile(double score, num lat, int month) => _percentileIn(
      _stats!['quantiles'] as Map<String, dynamic>, score, lat, month);

  /// [percentile] against the HOURLY distribution.
  double percentileHourly(double score, num lat, int month) => _percentileIn(
      (_hourlyStats?['quantiles'] ?? _stats!['quantiles'])
          as Map<String, dynamic>,
      score,
      lat,
      month);

  double _percentileIn(
      Map<String, dynamic> quantiles, double score, num lat, int month) {
    final List<dynamic> steps = _stats!['quantile_steps'] as List<dynamic>;
    final Map<String, dynamic> hemi =
        quantiles[lat > 0 ? 'n' : 's'] as Map<String, dynamic>;
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
  double calibratedProbability(double score) => _calibratedIn(
      _stats!['calibration'] as Map<String, dynamic>, score);

  /// [calibratedProbability] against the HOURLY isotonic fit. A daily 0.55
  /// and an hourly 0.55 do NOT mean the same thing — the two models score
  /// different distributions — so hourly scores must use this one.
  double calibratedProbabilityHourly(double score) => _calibratedIn(
      (_hourlyStats?['calibration'] ?? _stats!['calibration'])
          as Map<String, dynamic>,
      score);

  double _calibratedIn(Map<String, dynamic> cal, double score) {
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
  int oneInN(double score) => _oneIn(calibratedProbability(score));

  /// [oneInN] for an hourly score.
  int oneInNHourly(double score) => _oneIn(calibratedProbabilityHourly(score));

  int _oneIn(double p) {
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
  return _bandFrom(fi.calibratedProbability(score), fi.baseRate);
}

/// [bandFor] for a score from the HOURLY model.
///
/// The two models score different distributions, so an hourly score must be
/// interpreted against the hourly calibration and the hourly base rate. Using
/// [bandFor] here — which is what the app did before 2026-09-05 — bands an
/// hourly score against daily-fitted thresholds and is simply wrong, though
/// it degrades to exactly that when the shipped stats asset predates the
/// hourly fit (see [FlightIndex.hasHourlyStats]).
FlightBand bandForHourly(double score) {
  if (score <= 0.011) return FlightBand.noFly;
  final FlightIndex fi = FlightIndex();
  return _bandFrom(
      fi.calibratedProbabilityHourly(score), fi.hourlyBaseRate);
}

FlightBand _bandFrom(double p, double base) {
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
/// The reason the cap still earns its place is the hourly model's FEATURE
/// SET, not its accuracy: it has NO rain and NO cloud feature (see
/// `nuptialHourlyPercentageModel` — 22 features, none of them precipitation).
/// It literally cannot see that it is pouring. The daily model carries pop,
/// cloud, rainMm and popNext1/2, so capping at the day stops a downpour
/// reading as a promising afternoon.
///
/// A second reason applied until 2026-09-05: `flight_stats.json` held only a
/// daily-fitted calibration, so [bandFor] banded hourly scores against daily
/// thresholds. That is fixed — hourly scores now go through [bandForHourly]
/// against an hourly-fitted table (bead nf-k0o). Giving the hourly model
/// rain/cloud features is what would let the cap itself be revisited.
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
