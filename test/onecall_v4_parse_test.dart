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

    // Regression test for the split-and-route optimisation in
    // WeatherFetcher.fetchWeather(): the daily-timeline request is anchored
    // `leadUpDays` into the past and sized so one page holds the antecedent
    // days AND the 8-day forecast (leadUpDays + 8 <= 10 = the 4.0 page cap).
    // OneCallResponse parses the combined array into `.daily` in order; the
    // fetcher then splits at today's midnight. This test guarantees the parser
    // handles the full 10-record combined page that the split relies on.
    test('split-and-route: 10-record combined daily page parses in order', () {
      // 2 lead-up days (dt < today) + 8 forecast days (dt >= today), where
      // "today" is 1700000000 (arbitrary fixed epoch) for test determinism.
      final today = 1700000000;
      final oneDay = 86400;
      final dailyRecords = <Map<String, dynamic>>[];
      for (var i = 2; i >= 1; i--) {
        dailyRecords.add({
          'dt': today - i * oneDay,
          'temp': {'day': 20.0, 'min': 15.0, 'max': 25.0},
          'pop': 0.1 * i,
          'rain': 0.1 * i,
        });
      }
      for (var i = 0; i < 8; i++) {
        dailyRecords.add({
          'dt': today + i * oneDay,
          'temp': {'day': 25.0 + i, 'min': 18.0, 'max': 30.0 + i},
          'pop': 0.2 + i * 0.05,
        });
      }
      final body = jsonEncode({
        'lat': -35.28,
        'lon': 149.13,
        'timezone': 'Australia/Sydney',
        'timezone_offset': 39600,
        'data': dailyRecords,
      });
      final r = OneCallResponse.fromJson(jsonDecode(body));
      expect(r.daily, isNotNull);
      expect(r.daily!.length, 10);
      // Records stay in the order the API returned them (past-first), which is
      // what the fetcher's split loop depends on.
      expect(r.daily!.first.dt, today - 2 * oneDay);
      expect(r.daily!.last.dt, today + 7 * oneDay);
      // The transient leadUpDaily field is null from fromJson (it is derived
      // by the fetcher, not parsed).
      expect(r.leadUpDaily, isNull);
      // The split boundary: first 2 records are "before today", last 8 are
      // "today and later" — verify the fields the split uses are present.
      expect(r.daily![0].dt! < today, isTrue);
      expect(r.daily![1].dt! < today, isTrue);
      expect(r.daily![2].dt! >= today, isTrue);
      expect(r.daily![9].dt! >= today, isTrue);
    });
  });

  group('fromTimelineJson hardening', () {
    test('empty data binds an empty list of the requested kind', () {
      final json = {'lat': -35.28, 'lon': 149.13, 'timezone_offset': 39600, 'data': []};
      final d = OneCallResponse.fromTimelineJson(Map<String, dynamic>.from(json), TimelineKind.daily);
      expect(d.daily, isNotNull);
      expect(d.daily, isEmpty);
      expect(d.hourly, isNull);
      final h = OneCallResponse.fromTimelineJson(Map<String, dynamic>.from(json), TimelineKind.hourly);
      expect(h.hourly, isNotNull);
      expect(h.hourly, isEmpty);
      expect(h.daily, isNull);
    });

    test('missing data key is treated as empty, not null-both', () {
      final r = OneCallResponse.fromTimelineJson({'lat': 1.0, 'lon': 2.0}, TimelineKind.daily);
      expect(r.daily, isEmpty);
    });

    test('hourly rain as bare number (3.0-style) parses instead of throwing', () {
      final r = OneCallResponse.fromTimelineJson({
        'lat': 1.0, 'lon': 2.0,
        'data': [{'dt': 1700000000, 'temp': 22.5, 'rain': 0.21}]
      }, TimelineKind.hourly);
      expect(r.hourly!.first.rain!.d1h, 0.21);
    });

    test('toJson never emits pagination URLs', () {
      final r = OneCallResponse.fromJson({
        'lat': 1.0, 'lon': 2.0,
        'data': [{'dt': 1700000000, 'temp': 22.5}],
        'next': 'https://api.openweathermap.org/x?appid=KEY',
      });
      expect(r.toJson().containsKey('next'), isFalse);
      expect(r.toJson().containsKey('prev'), isFalse);
    });
  });
}
