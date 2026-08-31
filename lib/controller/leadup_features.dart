// Lead-up (antecedent weather) feature engineering for the 2026-08-30
// retrained models. The definitions here are a CONTRACT with the training
// pipeline (scripts/train_leadup_experiment.py: add_leadup) — change both
// together or the models silently mis-score.
//
// This file is pure Dart (no Flutter imports) so plain `package:test` tests
// can use it directly.
import '../responses/onecall_response.dart';

/// Daily rain amount (mm) above which a day counts as "wet"
/// (training: RAIN_WET_MM).
const double kRainWetMm = 0.2;

/// The 7 lead-up features, in the exact order the retrained models expect
/// them appended: [prev1_rain, prev2_rain, dpress1, dtemp1, days_since_rain,
/// warm_dry_after_rain, has_prev1].
class LeadUpFeatures {
  const LeadUpFeatures({
    required this.prev1Rain,
    required this.prev2Rain,
    required this.dPress1,
    required this.dTemp1,
    required this.daysSinceRain,
    required this.warmDryAfterRain,
    required this.hasPrev1,
  });

  final double prev1Rain;
  final double prev2Rain;
  final double dPress1;
  final double dTemp1;
  final double daysSinceRain;
  final double warmDryAfterRain;
  final double hasPrev1;

  /// The no-coverage row the model saw in training (~40% of rows): zeros,
  /// days_since_rain censored at 2, has_prev1 = 0.
  static const LeadUpFeatures none = LeadUpFeatures(
      prev1Rain: 0,
      prev2Rain: 0,
      dPress1: 0,
      dTemp1: 0,
      daysSinceRain: 2,
      warmDryAfterRain: 0,
      hasPrev1: 0);

  List<double> get vector => [
        prev1Rain,
        prev2Rain,
        dPress1,
        dTemp1,
        daysSinceRain,
        warmDryAfterRain,
        hasPrev1,
      ];
}

/// Lead-up features for the day at [index] of [timeline] — an ASCENDING list
/// of daily records where entries before the scored day are its antecedents
/// (prev1 = timeline[index-1], prev2 = timeline[index-2]). At runtime the
/// caller builds the timeline as [...leadUpDaily, ...daily] so day 0 scores
/// against the split-out past slice and later days score against the
/// forecast days before them.
///
/// Mirrors training exactly: missing prev-day values contribute 0 (rain) /
/// 0 (deltas); days_since_rain = 0 if prev1 wet, 1 if prev2 wet, else 2;
/// warm_dry_after_rain = 2-day rain sum > 1 mm AND today dry AND today's
/// day-temp >= 20C.
LeadUpFeatures leadUpFeaturesAt(List<Daily> timeline, int index) {
  Daily? at(int i) => (i >= 0 && i < timeline.length) ? timeline[i] : null;
  final Daily? today = at(index);
  final Daily? prev1 = at(index - 1);
  final Daily? prev2 = at(index - 2);
  if (today == null || prev1 == null) return LeadUpFeatures.none;

  double rainOf(Daily? d) => d?.rain?.toDouble() ?? 0.0;
  final double p1r = rainOf(prev1);
  final double p2r = rainOf(prev2);
  final double dPress = (today.pressure != null && prev1.pressure != null)
      ? today.pressure!.toDouble() - prev1.pressure!.toDouble()
      : 0.0;
  final double dTemp = (today.temp?.day != null && prev1.temp?.day != null)
      ? today.temp!.day!.toDouble() - prev1.temp!.day!.toDouble()
      : 0.0;
  final double daysSinceRain = p1r > kRainWetMm
      ? 0
      : (prev2 != null && p2r > kRainWetMm ? 1 : 2);
  final bool warmDry = (p1r + p2r) > 1.0 &&
      (today.rain?.toDouble() ?? 0.0) < kRainWetMm &&
      (today.temp?.day?.toDouble() ?? 0.0) >= 20;
  return LeadUpFeatures(
      prev1Rain: p1r,
      prev2Rain: p2r,
      dPress1: dPress,
      dTemp1: dTemp,
      daysSinceRain: daysSinceRain,
      warmDryAfterRain: warmDry ? 1 : 0,
      hasPrev1: 1);
}
