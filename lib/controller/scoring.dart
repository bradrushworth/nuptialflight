// Length-safe scoring over the forecast lists. The 4.0 timeline endpoints
// page their responses, so hourly/daily can arrive shorter than the UI's
// fixed slot counts (#19/#21) - missing slots score 0 instead of throwing.
//
// Since the 2026-08-30 retrain both models also take lead-up (antecedent
// weather) features. Callers pass the split-out `leadUpDaily` slice; each
// scored day's antecedents are the two days before it in the combined
// [leadUpDaily..., daily...] timeline, so day 0 uses the real past days and
// later forecast days use the forecast days before them.
import 'package:nuptialflight/controller/leadup_features.dart';
import 'package:nuptialflight/controller/nuptials.dart';
import 'package:nuptialflight/responses/onecall_response.dart';

/// Raw 0..1 model scores, zero-filled past the available data. The model is
/// invoked at most once per slot; percentage helpers below derive from this.
/// [daily]/[leadUpDaily] locate each hour's day in the combined timeline so
/// its lead-up features are day-correct ([tzOffsetSeconds] buckets local
/// days the same way WeatherFetcher.splitDaily does).
List<double> computeHourlyScores(num lat, num lon, List<Hourly> hourly, int slots,
    {List<Daily> daily = const [], List<Daily> leadUpDaily = const [],
    int tzOffsetSeconds = 0}) {
  final timeline = [...leadUpDaily, ...daily];
  final int todayIndex = leadUpDaily.length;
  final int? todayBucket = daily.isNotEmpty && daily.first.dt != null
      ? (daily.first.dt! + tzOffsetSeconds) ~/ 86400
      : null;
  final out = List<double>.filled(slots, 0);
  for (var i = 0; i < slots && i < hourly.length; i++) {
    int dayOffset = 0;
    if (todayBucket != null && hourly[i].dt != null) {
      dayOffset = ((hourly[i].dt! + tzOffsetSeconds) ~/ 86400) - todayBucket;
      if (dayOffset < 0) dayOffset = 0;
    }
    final leadUp = timeline.isEmpty
        ? LeadUpFeatures.none
        : leadUpFeaturesAt(timeline, todayIndex + dayOffset);
    out[i] = nuptialHourlyPercentageModel(lat, lon, hourly[i], leadUp: leadUp);
  }
  return out;
}

/// Raw 0..1 model scores, zero-filled past the available data, keeping the
/// pop1/pop2 neighbor look-ahead used by the daily model.
List<double> computeDailyScores(num lat, num lon, List<Daily> daily, int slots,
    {List<Daily> leadUpDaily = const []}) {
  final timeline = [...leadUpDaily, ...daily];
  final int todayIndex = leadUpDaily.length;
  final out = List<double>.filled(slots, 0);
  for (var i = 0; i < slots && i < daily.length; i++) {
    out[i] = nuptialDailyPercentageModel(lat, lon, daily[i],
        pop1: i + 1 < daily.length ? daily[i + 1].pop : null,
        pop2: i + 2 < daily.length ? daily[i + 2].pop : null,
        leadUp: leadUpFeaturesAt(timeline, todayIndex + i));
  }
  return out;
}

List<int> computeHourlyPercentages(num lat, num lon, List<Hourly> hourly, int slots,
    {List<Daily> daily = const [], List<Daily> leadUpDaily = const [],
    int tzOffsetSeconds = 0}) {
  final scores = computeHourlyScores(lat, lon, hourly, slots,
      daily: daily, leadUpDaily: leadUpDaily, tzOffsetSeconds: tzOffsetSeconds);
  return [for (final s in scores) (s * 100.0).toInt()];
}

List<int> computeDailyPercentages(num lat, num lon, List<Daily> daily, int slots,
    {List<Daily> leadUpDaily = const []}) {
  final scores = computeDailyScores(lat, lon, daily, slots, leadUpDaily: leadUpDaily);
  return [for (final s in scores) (s * 100.0).toInt()];
}
