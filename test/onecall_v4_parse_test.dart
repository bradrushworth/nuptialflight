import 'dart:convert';
import 'package:nuptialflight/responses/onecall_response.dart';
import 'package:test/test.dart';

// Regression tests for the One Call API 4.0 response shape: every timeline
// endpoint returns a flat `data` array (hourly records have `temp` as a number,
// daily records have `temp` as an object). `daily.rain` may be a bare number
// (3.0-style) or an object with a `1h` key (4.0-style).
void main() {
  group('OneCallResponse 4.0 parsing', () {
    test('hourly timeline -> .hourly populated, .daily null', () {
      final body = jsonEncode({
        'lat': -35.28,
        'lon': 149.13,
        'timezone': 'Australia/Sydney',
        'timezone_offset': 39600,
        'data': [
          {
            'dt': 1700000000,
            'temp': 22.5,
            'feels_like': 21.0,
            'pressure': 1015,
            'humidity': 60,
            'dew_point': 14.0,
            'uvi': 5.0,
            'clouds': 10,
            'visibility': 10000,
            'wind_speed': 4.0,
            'wind_deg': 90,
            'wind_gust': 7.0,
            'weather': [
              {'id': 500, 'main': 'Rain', 'description': 'light rain', 'icon': '10d'}
            ],
            'pop': 0.3,
            'rain': {'1h': 0.21}
          },
          {
            'dt': 1700003600,
            'temp': 21.0,
            'pop': 0.1,
          }
        ],
        'next':
            'https://api.openweathermap.org/data/4.0/onecall/timeline/1h?appid=KEY'
      });
      final r = OneCallResponse.fromJson(jsonDecode(body));
      expect(r.lat, -35.28);
      expect(r.timezoneOffset, 39600);
      expect(r.next, isNotNull);
      expect(r.hourly, isNotNull);
      expect(r.hourly!.length, 2);
      expect(r.daily, isNull);
      expect(r.hourly!.first.temp, 22.5);
      expect(r.hourly!.first.pop, 0.3);
      expect(r.hourly!.first.rain!.d1h, 0.21);
      expect(r.hourly!.first.weather!.first.description, 'light rain');
    });

    test('daily timeline -> .daily populated, .hourly null', () {
      final body = jsonEncode({
        'lat': -35.28,
        'lon': 149.13,
        'timezone': 'Australia/Sydney',
        'timezone_offset': 39600,
        'data': [
          {
            'dt': 1700000000,
            'sunrise': 1,
            'sunset': 2,
            'moonrise': 3,
            'moonset': 4,
            'moon_phase': 0.5,
            'temp': {
              'day': 28.0,
              'min': 16.0,
              'max': 29.0,
              'night': 21.0,
              'eve': 25.0,
              'morn': 18.0
            },
            'feels_like': {
              'day': 29.0,
              'night': 21.0,
              'eve': 25.0,
              'morn': 18.0
            },
            'pressure': 1006,
            'humidity': 57,
            'dew_point': 18.0,
            'wind_speed': 7.0,
            'wind_deg': 43,
            'wind_gust': 11.0,
            'weather': [
              {'id': 500, 'main': 'Rain', 'description': 'light rain', 'icon': '10d'}
            ],
            'clouds': 2,
            'pop': 0.43,
            'uvi': 14.0,
            'rain': 0.29
          }
        ]
      });
      final r = OneCallResponse.fromJson(jsonDecode(body));
      expect(r.daily, isNotNull);
      expect(r.daily!.length, 1);
      expect(r.hourly, isNull);
      expect(r.daily!.first.temp!.day, 28.0);
      expect(r.daily!.first.pop, 0.43);
      expect(r.daily!.first.windGust, 11.0);
      expect(r.daily!.first.rain, 0.29); // bare-number rain (3.0-style)
    });

    test('daily rain as object {1h} is also accepted', () {
      final body = jsonEncode({
        'lat': -35.28,
        'lon': 149.13,
        'data': [
          {
            'dt': 1700000000,
            'temp': {'day': 28.0, 'min': 16.0, 'max': 29.0},
            'pop': 0.5,
            'rain': {'1h': 0.42}
          }
        ]
      });
      final r = OneCallResponse.fromJson(jsonDecode(body));
      expect(r.daily!.first.rain, 0.42);
    });

    test('toJson round-trips without throwing', () {
      final body = jsonEncode({
        'lat': -35.28,
        'lon': 149.13,
        'timezone': 'Australia/Sydney',
        'timezone_offset': 39600,
        'data': [
          {'dt': 1700000000, 'temp': 22.5, 'pop': 0.3}
        ]
      });
      final r = OneCallResponse.fromJson(jsonDecode(body));
      expect(() => r.toJson(), returnsNormally);
      expect(r.toJson()['hourly'], isNotNull);
    });
  });
}
