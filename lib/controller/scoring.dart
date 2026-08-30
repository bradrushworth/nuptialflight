// Length-safe scoring over the forecast lists. The 4.0 timeline endpoints
// page their responses, so hourly/daily can arrive shorter than the UI's
// fixed slot counts (#19/#21) - missing slots score 0 instead of throwing.
import 'package:nuptialflight/controller/nuptials.dart';
import 'package:nuptialflight/responses/onecall_response.dart';

List<int> computeHourlyPercentages(num lat, num lon, List<Hourly> hourly, int slots) {
  final out = List<int>.filled(slots, 0);
  for (var i = 0; i < slots && i < hourly.length; i++) {
    out[i] = (nuptialHourlyPercentageModel(lat, lon, hourly[i]) * 100.0).toInt();
  }
  return out;
}

List<int> computeDailyPercentages(num lat, num lon, List<Daily> daily, int slots) {
  final out = List<int>.filled(slots, 0);
  for (var i = 0; i < slots && i < daily.length; i++) {
    out[i] = (nuptialDailyPercentageModel(lat, lon, daily[i],
            pop1: i + 1 < daily.length ? daily[i + 1].pop : null,
            pop2: i + 2 < daily.length ? daily[i + 2].pop : null) *
        100.0)
        .toInt();
  }
  return out;
}
