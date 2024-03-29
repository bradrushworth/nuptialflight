import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nuptialflight/controller/weather_fetcher.dart';
import 'package:nuptialflight/responses/onecall_response.dart';
import 'package:nuptialflight/responses/reverse_geocoding_response.dart';
import 'package:test/test.dart';

void main() {
  group('Download', () {
    dotenv.testLoad(fileInput: File('assets/.env').readAsStringSync());
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

    test('Fetch Weather', () async {
      OneCallResponse response = await weatherFetcher.fetchWeather();
      expect(response, isNotNull);
      expect(response.lat, -35.76);
      expect(response.lon, 150.2053);
      anyOf(response.timezoneOffset, 36000, 39600); // 39600 in daylight savings
      expect(response.daily!.length, 8);
      expect(response.daily!.first.uvi, greaterThanOrEqualTo(0));
    });
  });
}
