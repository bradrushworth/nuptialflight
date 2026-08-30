// Length-safe scoring over the forecast lists. The 4.0 timeline endpoints
// page their responses, so hourly/daily can arrive shorter than the UI's
// fixed slot counts (#19/#21) - missing slots score 0 instead of throwing.
import 'package:nuptialflight/controller/nuptials.dart';
import 'package:nuptialflight/responses/onecall_response.dart';

/// Raw 0..1 model scores, zero-filled past the available data. The model is
/// invoked at most once per slot; percentage helpers below derive from this.
List<double> computeHourlyScores(num lat, num lon, List<Hourly> hourly, int slots) {
  final out = List<double>.filled(slots, 0);
  for (var i = 0; i < slots && i < hourly.length; i++) {
    out[i] = nuptialHourlyPercentageModel(lat, lon, hourly[i]);
  }
  return out;
}

/// Raw 0..1 model scores, zero-filled past the available data, keeping the
/// pop1/pop2 neighbor look-ahead used by the daily model.
List<double> computeDailyScores(num lat, num lon, List<Daily> daily, int slots) {
  final out = List<double>.filled(slots, 0);
  for (var i = 0; i < slots && i < daily.length; i++) {
    out[i] = nuptialDailyPercentageModel(lat, lon, daily[i],
        pop1: i + 1 < daily.length ? daily[i + 1].pop : null,
        pop2: i + 2 < daily.length ? daily[i + 2].pop : null);
  }
  return out;
}

List<int> computeHourlyPercentages(num lat, num lon, List<Hourly> hourly, int slots) {
  final scores = computeHourlyScores(lat, lon, hourly, slots);
  return [for (final s in scores) (s * 100.0).toInt()];
}

List<int> computeDailyPercentages(num lat, num lon, List<Daily> daily, int slots) {
  final scores = computeDailyScores(lat, lon, daily, slots);
  return [for (final s in scores) (s * 100.0).toInt()];
}
