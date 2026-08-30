import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nuptialflight/controller/weather_fetcher.dart';
import 'package:nuptialflight/responses/onecall_response.dart';
import 'package:nuptialflight/responses/reverse_geocoding_response.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Download', () {
    dotenv.load(fileName: 'assets/.env');
    WeatherFetcher weatherFetcher = WeatherFetcher(mockLocation: true);
    weatherFetcher.findLocation(false);

    test('Fetch Geocoding', () async {
      ReverseGeocodingResponse response =
          await weatherFetcher.fetchReverseGeocoding();
      expect(response, isNotNull);
      expect(response.lat, closeTo(-35.93293665, 0.001));
      expect(response.lon, closeTo(149.92440065, 0.001));
      expect(response.name, 'Eurobodalla Shire Council');
      expect(response.state, 'New South Wales');
      expect(response.country, 'AU');
    });

    test('Fetch Weather Location', () async {
      String? response =
          (await weatherFetcher.fetchNearestWeatherLocation()).name;
      expect(response, 'Batemans Bay');
    });

    test('Fetch Weather returns rate-limit message on HTTP 429', () async {
      final client = MockClient((request) async {
        return http.Response('rate limit exceeded', 429);
      });
      final fetcher = WeatherFetcher(mockLocation: true, httpClient: client);
      fetcher.findLocation(false);

      await expectLater(
        fetcher.fetchWeather(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('The app has exceeded global usage limited. Please try again later!'),
        )),
      );
    });

    test('Fetch Weather', () async {
      OneCallResponse response = await weatherFetcher.fetchWeather();
      expect(response, isNotNull);
      expect(response.lat, -35.76);
      expect(response.lon, 150.2053);
      anyOf(response.timezoneOffset, 36000, 39600); // 39600 in daylight savings
      // One Call 4.0's /timeline/1day returns up to 10 daily records; after
      // split-and-route routes the leadUpDays antecedent days into
      // leadUpDaily, the forecast list is exactly today + 7 days.
      expect(response.daily!.length, 8); // daily[0] == local today + 7-day forecast
      final tz = response.timezoneOffset ?? 0;
      final nowUtc = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      expect((response.daily!.first.dt! + tz) ~/ 86400, (nowUtc + tz) ~/ 86400,
          reason: 'daily[0] must be the location-local today');
      expect(response.daily!.first.uvi, greaterThanOrEqualTo(0));
    });
  });
}
