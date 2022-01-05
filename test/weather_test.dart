import 'package:nuptialflight/responses/reverse_geocoding_response.dart';
import 'package:nuptialflight/responses/weather_response.dart';
import 'package:nuptialflight/weather_fetcher.dart';
import 'package:test/test.dart';

void main() {
  group('Download', () {
    WeatherFetcher weatherFetcher = WeatherFetcher(mockLocation: true);
    weatherFetcher.getLocation();

    test('Fetch Geocoding', () async {
      ReverseGeocodingResponse response = await weatherFetcher.fetchReverseGeocoding();
      expect(response, isNotNull);
      expect(response.lat, closeTo(-35.93293665, 0.001));
      expect(response.lon, closeTo(149.92440065, 0.001));
      expect(response.name, 'Eurobodalla Shire Council');
      expect(response.state, 'New South Wales');
      expect(response.country, 'AU');
    });

    test('Fetch Weather Location', () async {
      String response = await weatherFetcher.fetchNearestWeatherLocation();
      expect(response, 'Batemans Bay');
    });

    test('Fetch Weather', () async {
      WeatherResponse response = await weatherFetcher.fetchWeather();
      expect(response, isNotNull);
      expect(response.lat, -35.76);
      expect(response.lon, 150.2053);
      expect(response.timezoneOffset, 39600);
      expect(response.daily!.length, 8);
      expect(response.daily!.first.uvi, greaterThan(0));
    });
  });
}
