import 'package:nuptialflight/controller/weather_fetcher.dart';
import 'package:test/test.dart';

void main() {
  test('daily cache key changes across UTC days; historical key is 4.0-namespaced', () {
    final f = WeatherFetcher();
    // setPosition equivalent: use the test hook the class exposes.
    f.setTestPosition(-35.28, 149.13);
    final d1 = f.cacheKeyFor('onecall_daily', dt: 20700); // day bucket N
    final d2 = f.cacheKeyFor('onecall_daily', dt: 20701); // day bucket N+1
    expect(d1, isNot(equals(d2)));
    expect(f.cacheKeyFor('timemachine4', dt: 123), contains('timemachine4'));
  });
}
