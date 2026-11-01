import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nuptialflight/controller/weather_fetcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

// On 1 Nov 2026 OpenWeatherMap's daily timeline answered 504 Gateway Time-out.
// The app showed "Failed to download daily weather!" followed by the raw HTML
// of the error page, even for users who had a forecast cached a few hours
// earlier.
const _gatewayTimeout =
    '<html><head><title>504 Gateway Time-out</title></head></html>';
const _place =
    '[{"name":"Canberra","lat":-35.28,"lon":149.13,"country":"AU","state":"ACT"}]';

WeatherFetcher _fetcher(http.Client client) =>
    WeatherFetcher(mockLocation: true, httpClient: client)
      ..setTestPosition(-35.28, 149.13);

Future<void> _cacheReverse(WeatherFetcher f, Duration age) async {
  final ts = DateTime.now().subtract(age).millisecondsSinceEpoch;
  SharedPreferences.setMockInitialValues({
    f.cacheKeyFor('reverse'): jsonEncode({'ts': ts, 'body': _place}),
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(envString: 'OPENWEATHERMAP_API_KEY=test');

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('an error page is reported by status, not shown to the user', () async {
    final f = _fetcher(MockClient((_) async => http.Response(_gatewayTimeout, 504)));
    await expectLater(
      f.fetchReverseGeocoding(),
      throwsA(isA<Exception>()
          .having((e) => e.toString(), 'message', contains('HTTP 504'))
          .having((e) => e.toString(), 'message', isNot(contains('<html>')))),
    );
  });

  test('a failed refresh falls back to a recently expired response', () async {
    final f = _fetcher(MockClient((_) async => http.Response(_gatewayTimeout, 504)));
    // The reverse-geocode TTL is 24 h; this entry expired 6 h ago.
    await _cacheReverse(f, const Duration(hours: 30));
    expect((await f.fetchReverseGeocoding()).name, 'Canberra');
  });

  test('a network exception also falls back to the expired response', () async {
    final f = _fetcher(MockClient((_) async => throw http.ClientException('offline')));
    await _cacheReverse(f, const Duration(hours: 30));
    expect((await f.fetchReverseGeocoding()).name, 'Canberra');
  });

  test('a rate-limited refresh falls back to the expired response', () async {
    final f = _fetcher(MockClient((_) async => http.Response('limit', 429)));
    await _cacheReverse(f, const Duration(hours: 30));
    expect((await f.fetchReverseGeocoding()).name, 'Canberra');
  });

  test('a response older than the grace period is not used', () async {
    final f = _fetcher(MockClient((_) async => http.Response(_gatewayTimeout, 504)));
    // TTL 24 h plus 12 h of grace: 40 h is too old.
    await _cacheReverse(f, const Duration(hours: 40));
    await expectLater(f.fetchReverseGeocoding(), throwsException);
  });

  test('a successful refresh still replaces the expired response', () async {
    const fresh =
        '[{"name":"Queanbeyan","lat":-35.35,"lon":149.23,"country":"AU","state":"NSW"}]';
    final f = _fetcher(MockClient((_) async => http.Response(fresh, 200)));
    await _cacheReverse(f, const Duration(hours: 30));
    expect((await f.fetchReverseGeocoding()).name, 'Queanbeyan');
  });
}
