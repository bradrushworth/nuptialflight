import 'package:nuptialflight/controller/weather_fetcher.dart';
import 'package:nuptialflight/responses/onecall_response.dart';
import 'package:test/test.dart';

/// Epoch (s) of local midnight of [y-m-d] in a zone tzOffset seconds east of UTC.
int localMidnight(int y, int m, int d, int tz) =>
    DateTime.utc(y, m, d).millisecondsSinceEpoch ~/ 1000 - tz;

Daily day(int dt) => Daily.fromJson({'dt': dt, 'temp': {'day': 20.0}});

void main() {
  const syd = 39600; // UTC+11
  const la = -28800; // UTC-8

  test('Sydney 7am local (still previous UTC date): daily[0] is local today', () {
    // Local dates Aug 29..Sep 2; "now" = Aug 31 07:00 local = Aug 30 20:00 UTC.
    final now = localMidnight(2026, 8, 31, syd) + 7 * 3600;
    final all = [for (var d = 29; d <= 33; d++) day(localMidnight(2026, 8, d, syd))];
    final s = WeatherFetcher.splitDaily(all, syd, now);
    expect(s.leadUp.map((e) => e.dt), [all[0].dt, all[1].dt]); // Aug 29, 30
    expect(s.forecast.first.dt, localMidnight(2026, 8, 31, syd)); // local TODAY
  });

  test('LA 8pm local (already next UTC date): today stays in forecast', () {
    // "now" = Aug 30 20:00 local = Aug 31 04:00 UTC.
    final now = localMidnight(2026, 8, 30, la) + 20 * 3600;
    final all = [for (var d = 28; d <= 32; d++) day(localMidnight(2026, 8, d, la))];
    final s = WeatherFetcher.splitDaily(all, la, now);
    expect(s.leadUp.map((e) => e.dt), [all[0].dt, all[1].dt]); // Aug 28, 29
    expect(s.forecast.first.dt, localMidnight(2026, 8, 30, la)); // local TODAY
  });

  test('UTC noon control case', () {
    final now = localMidnight(2026, 8, 30, 0) + 12 * 3600;
    final all = [for (var d = 28; d <= 31; d++) day(localMidnight(2026, 8, d, 0))];
    final s = WeatherFetcher.splitDaily(all, 0, now);
    expect(s.leadUp.length, 2);
    expect(s.forecast.first.dt, localMidnight(2026, 8, 30, 0));
  });

  test('null-dt record goes to forecast, empty input yields empty lists', () {
    final s = WeatherFetcher.splitDaily([Daily.fromJson({'temp': {'day': 1.0}})], 0, 1700000000);
    expect(s.forecast.length, 1);
    final e = WeatherFetcher.splitDaily([], 0, 1700000000);
    expect(e.forecast, isEmpty);
    expect(e.leadUp, isEmpty);
  });
}
