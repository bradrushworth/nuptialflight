import 'package:appwidgetflutter/weather_response.dart';
import 'package:test/test.dart';
import 'package:appwidgetflutter/weather.dart';

void main() {
  group('Download', () {
    test('Response', () async {
      WeatherResponse weatherResponse = await fetchWeather(mockLocation: true);
      expect(weatherResponse, isNotNull);
      expect(weatherResponse.lat, -35.76);
      expect(weatherResponse.lon, 150.2053);
      expect(weatherResponse.timezoneOffset, 39600);
      expect(weatherResponse.daily!.length, 8);
      expect(weatherResponse.daily!.first.uvi, greaterThan(0));
    });
  });
}
