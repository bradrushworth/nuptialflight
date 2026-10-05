import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nuptialflight/controller/arangodb.dart';
import 'package:nuptialflight/controller/geo.dart';
import 'package:nuptialflight/controller/install_id.dart';
import 'package:nuptialflight/responses/onecall_response.dart';
import 'package:nuptialflight/responses/weather_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const install = '123e4567-e89b-42d3-a456-426614174000';
const endpoint = 'https://example.test/nuptialflight/v1';

ApiClient client(
  MockClient mock, {
  String key = 'test-key',
  String url = endpoint,
  Duration timeout = const Duration(milliseconds: 100),
}) => ApiClient(
  baseUrl: url,
  apiKey: key,
  httpClient: mock,
  installId: () async => install,
  retryDelay: Duration.zero,
  timeout: timeout,
);

void main() {
  late Map<String, dynamic> fixture;
  setUpAll(() {
    fixture =
        jsonDecode(File('test/fixtures/api_contract.json').readAsStringSync())
            as Map<String, dynamic>;
  });

  test('shared contract covers snapshot and sighting wire requests', () async {
    final requests = <http.Request>[];
    final api = client(
      MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST')
          return http.Response('{"handle":"signed"}', 201);
        if (request.method == 'PUT')
          return http.Response('{"handle":"signed"}', 200);
        return http.Response('not found', 404);
      }),
    );
    final handle = await api.createSnapshot(fixture['request']);
    expect(handle, 'signed');
    expect(
      await api.confirmSighting(handle!, fixture['sighting_request']),
      isTrue,
    );
    expect(requests.map((r) => r.method), ['POST', 'PUT']);
    expect(requests[0].url.path, '/nuptialflight/v1/snapshots');
    expect(requests[1].url.path, '/nuptialflight/v1/snapshots/signed/sighting');
    expect(jsonDecode(requests[0].body), fixture['request']);
    expect(jsonDecode(requests[1].body), fixture['sighting_request']);
    for (final request in requests) {
      expect(request.followRedirects, isFalse);
      expect(request.headers['X-NF-Key'], 'test-key');
      expect(request.headers['X-NF-Install'], install);
      expect(
        request.headers['X-NF-Request'],
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    }
    expect(
      requests[0].headers['X-NF-Request'],
      isNot(requests[1].headers['X-NF-Request']),
    );
  });

  test(
    'recent and nearby reads return fixture rows and normalize windows',
    () async {
      final requests = <http.Request>[];
      final api = client(
        MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode(
              request.url.path.endsWith('/recent')
                  ? fixture['expected_recent']
                  : fixture['expected_nearby'],
            ),
            200,
          );
        }),
      );
      expect(await api.recentFlights(), fixture['expected_recent']);
      expect(
        await api.nearbyFlights(-35.3, 149.1, -1800),
        fixture['expected_nearby'],
      );
      expect(requests[1].url.queryParameters, {
        'lat': '-35.3',
        'lon': '149.1',
        'minutes': '1440',
      });
      expect(requests[0].headers['X-NF-Install'], install);
      expect(requests[0].headers, isNot(contains('X-NF-Request')));
      expect(ApiClient.normalizeMinutes(0), 30);
      expect(ApiClient.normalizeMinutes(-45), 45);
    },
  );

  test(
    'server error retries once with stable request UUID and payload',
    () async {
      final requests = <http.Request>[];
      final api = client(
        MockClient((request) async {
          requests.add(request);
          return requests.length == 1
              ? http.Response('unavailable', 503)
              : http.Response('{"handle":"signed"}', 201);
        }),
      );
      expect(await api.createSnapshot(fixture['request']), 'signed');
      expect(requests, hasLength(2));
      expect(
        requests[0].headers['X-NF-Request'],
        requests[1].headers['X-NF-Request'],
      );
      expect(requests[0].body, requests[1].body);
    },
  );

  test('429 and auth or validation errors never cause a retry', () async {
    for (final status in [400, 401, 403, 404, 422, 429]) {
      var calls = 0;
      final api = client(
        MockClient((request) async {
          calls++;
          return http.Response('', status, headers: {'Retry-After': '120'});
        }),
      );
      expect(await api.createSnapshot(fixture['request']), isNull);
      expect(calls, 1);
    }
  });

  test('malformed results, network failures and timeouts degrade', () async {
    final malformed = client(
      MockClient((_) async => http.Response('oops', 200)),
    );
    expect(await malformed.recentFlights(), isEmpty);
    expect(await malformed.createSnapshot(fixture['request']), isNull);
    var calls = 0;
    final failed = client(
      MockClient((_) async {
        calls++;
        throw const SocketException('offline');
      }),
    );
    expect(await failed.recentFlights(), isEmpty);
    expect(calls, 2);
    final slow = client(
      MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response('[]', 200);
      }),
      timeout: const Duration(milliseconds: 1),
    );
    expect(await slow.recentFlights(), isEmpty);
  });

  test(
    'redirect responses are terminal and never forward credentials',
    () async {
      final destination = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final source = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var destinationHits = 0;
      destination.listen((request) async {
        destinationHits++;
        request.response
          ..statusCode = 200
          ..write('[]');
        await request.response.close();
      });
      source.listen((request) async {
        request.response.statusCode = request.method == 'GET'
            ? HttpStatus.found
            : HttpStatus.temporaryRedirect;
        request.response.headers.set(
          HttpHeaders.locationHeader,
          'http://127.0.0.1:${destination.port}/nuptialflight/v1/flights/recent',
        );
        await request.response.close();
      });
      final api = ApiClient(
        baseUrl: 'http://127.0.0.1:${source.port}/nuptialflight/v1',
        apiKey: 'test-key',
        installId: () async => install,
        retryDelay: Duration.zero,
      );
      try {
        expect(await api.recentFlights(), isEmpty);
        expect(await api.createSnapshot(fixture['request']), isNull);
        expect(destinationHits, 0);
      } finally {
        await source.close(force: true);
        await destination.close(force: true);
      }
    },
  );

  test('successful rows must satisfy the map and nearby projections', () async {
    final good = <String, dynamic>{
      'key': 'report-1',
      'weather': null,
      'size': null,
      'lat': -35,
      'lon': 149,
      'distance': 2.0,
    };
    for (final bad in <Map<String, dynamic>>[
      {...good}..remove('key'),
      {...good, 'lat': 'south'},
      {...good, 'lat': 91},
      {...good, 'lon': -181},
      {
        ...good,
        'weather': <String, String>{'description': 'clear'},
      },
      {...good, 'size': 'giant'},
      {...good}..remove('distance'),
      {...good, 'distance': -1},
      {...good, 'distance': 1.5},
    ]) {
      final api = client(
        MockClient((_) async => http.Response(jsonEncode([good, bad]), 200)),
      );
      expect(await api.nearbyFlights(-35.3, 149.1, 30), isEmpty);
    }
    final api = client(
      MockClient((_) async => http.Response(jsonEncode([good]), 200)),
    );
    final nearby = await api.nearbyFlights(-35.3, 149.1, 30);
    expect(nearby.single['lat'], -35.0);
    expect(nearby.single['lon'], 149.0);
    expect(nearby.single['distance'], 2);
    final invalidRecent = client(
      MockClient(
        (_) async => http.Response(
          jsonEncode([
            {'key': 'x', 'lat': null, 'lon': 149},
          ]),
          200,
        ),
      ),
    );
    expect(await invalidRecent.recentFlights(), isEmpty);
  });

  test('missing key and unsafe endpoint disable transport', () async {
    var calls = 0;
    final mock = MockClient((_) async {
      calls++;
      return http.Response('[]', 200);
    });
    for (final api in [
      client(mock, key: ''),
      client(mock, url: 'http://example.test/nuptialflight/v1'),
      client(mock, url: 'https://example.test:8530/nuptialflight/v1'),
    ]) {
      expect(api.enabled, isFalse);
      expect(await api.recentFlights(), isEmpty);
      expect(await api.createSnapshot(fixture['request']), isNull);
    }
    expect(calls, 0);
  });

  test('headless init and install identity need no widget context', () async {
    SharedPreferences.setMockInitialValues({});
    final id = await InstallId.get();
    expect(Uuid.isValidUUID(fromString: id), isTrue);
    expect(await InstallId.get(), id);
    final requests = <http.Request>[];
    final facade = ArangoSingleton.withConfigForTesting(
      {'NF_API_URL': endpoint, 'NF_API_KEY': 'test-key'},
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(jsonEncode(fixture['expected_nearby']), 200);
      }),
      installId: InstallId.get,
    );
    expect(requests, isEmpty);
    await facade.init(); // Lazy configuration, no widget tree or network.
    expect(requests, isEmpty);
    expect(await facade.getRecentFlightsNearMe(null, 30), isEmpty);
    expect(
      await facade.getRecentFlightsNearMe(syntheticPosition(-35.3, 149.1), -45),
      fixture['expected_nearby'],
    );
    expect(requests, hasLength(1));
    expect(requests.single.headers['X-NF-Key'], 'test-key');
    expect(requests.single.headers['X-NF-Install'], id);
    expect(requests.single.url.queryParameters['minutes'], '45');
  });

  test(
    'facade waits for create; failed create cannot reuse a prior handle',
    () async {
      final first = Completer<http.Response>();
      final requests = <http.Request>[];
      var creates = 0;
      final facade = ArangoSingleton.withClient(
        client(
          MockClient((request) async {
            requests.add(request);
            if (request.method == 'POST') {
              creates++;
              if (creates == 1) return first.future;
              return http.Response('', 403);
            }
            return http.Response('{"handle":"signed"}', 200);
          }),
          timeout: const Duration(seconds: 2),
        ),
      );
      final forecast = OneCallResponse(
        lat: -35.3,
        lon: 149.1,
        daily: [Daily(dt: 1791158400)],
      );
      final historical = OneCallResponse(
        lat: -35.3,
        lon: 149.1,
        hourly: [Hourly(dt: 1791154800)],
      );
      final current = CurrentWeatherResponse(
        coord: Coordinates(lat: -35.3, lon: 149.1),
        dt: 1791158400,
      );
      final creating = facade.createWeather(
        '2.29.0',
        '164',
        forecast,
        historical,
        current,
        leadUpDays: 0,
      );
      final reporting = facade.updateWeather(
        '2.29.0',
        '164',
        'medium',
        forecast,
        historical,
        current,
        leadUpDays: 0,
      );
      await Future<void>.delayed(Duration.zero);
      expect(requests.where((r) => r.method == 'PUT'), isEmpty);
      first.complete(http.Response('{"handle":"signed"}', 201));
      await Future.wait([creating, reporting]);
      expect(requests.where((r) => r.method == 'PUT'), hasLength(1));
      final postBody =
          jsonDecode(requests.firstWhere((r) => r.method == 'POST').body)
              as Map<String, dynamic>;
      final putBody =
          jsonDecode(requests.firstWhere((r) => r.method == 'PUT').body)
              as Map<String, dynamic>;
      expect(postBody['version'], '2.29.0+164');
      expect(postBody['forecast']['daily'][0]['dt'], 1791158400);
      expect(postBody['historical']['hourly'][0]['dt'], 1791154800);
      expect(postBody['current']['coord'], {'lat': -35.3, 'lon': 149.1});
      expect(postBody['device_id'], isNull);
      expect(postBody.keys, isNot(contains('install_id')));
      expect(putBody['size'], 'medium');
      final failedCreate = facade.createWeather(
        '2.29.0',
        '164',
        forecast,
        historical,
        current,
        leadUpDays: 0,
      );
      final laterReport = facade.updateWeather(
        '2.29.0',
        '164',
        'medium',
        forecast,
        historical,
        current,
        leadUpDays: 0,
      );
      await Future.wait([failedCreate, laterReport]);
      expect(requests.where((r) => r.method == 'PUT'), hasLength(1));
    },
  );

  test('report keeps its captured snapshot during a newer create', () async {
    final first = Completer<http.Response>();
    final second = Completer<http.Response>();
    final requests = <http.Request>[];
    var creates = 0;
    final facade = ArangoSingleton.withClient(
      client(
        MockClient((request) async {
          requests.add(request);
          if (request.method == 'POST') {
            return ++creates == 1 ? first.future : second.future;
          }
          return http.Response('{"handle":"new"}', 200);
        }),
        timeout: const Duration(seconds: 2),
      ),
    );
    final forecast = OneCallResponse(lat: -35.3, lon: 149.1);
    final historical = OneCallResponse(lat: -35.3, lon: 149.1);
    final current = CurrentWeatherResponse(
      coord: Coordinates(lat: -35.3, lon: 149.1),
      dt: 1791158400,
    );
    final oldCreate = facade.createWeather(
      '2.29.0',
      '164',
      forecast,
      historical,
      current,
      leadUpDays: 0,
    );
    final oldReport = facade.updateWeather(
      '2.29.0',
      '164',
      'medium',
      forecast,
      historical,
      current,
      leadUpDays: 0,
    );
    final newForecast = OneCallResponse(lat: -34.0, lon: 150.0);
    final newCurrent = CurrentWeatherResponse(
      coord: Coordinates(lat: -34.0, lon: 150.0),
      dt: 1791158500,
    );
    final newCreate = facade.createWeather(
      '2.29.0',
      '164',
      newForecast,
      historical,
      newCurrent,
      leadUpDays: 0,
    );
    second.complete(http.Response('{"handle":"new"}', 201));
    await newCreate;
    first.complete(http.Response('{"handle":"old"}', 201));
    await Future.wait([oldCreate, oldReport]);
    final puts = requests.where((r) => r.method == 'PUT').toList();
    expect(puts, hasLength(1));
    expect(puts.single.url.path, '/nuptialflight/v1/snapshots/old/sighting');
    final body = jsonDecode(puts.single.body) as Map<String, dynamic>;
    expect(body['forecast']['lat'], -35.3);
    expect(body['current']['coord']['lat'], -35.3);
    expect(body['size'], 'medium');
  });

  test('representative full snapshot fits the server body limit', () async {
    final timeline =
        jsonDecode(
              File(
                'test/fixtures/historical_today_utc.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final historicalSlots = (timeline['hourly'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final startUtc = historicalSlots.first['dt'] as int;
    expect(startUtc, fixture['reference_time']);
    expect(startUtc % 86400, 0);
    expect(historicalSlots, hasLength(24));
    expect(
      historicalSlots.map((slot) => slot['dt']),
      List.generate(24, (index) => startUtc + index * 3600),
    );
    http.Request? sent;
    final facade = ArangoSingleton.withClient(
      client(
        MockClient((request) async {
          sent = request;
          return http.Response('{"handle":"signed"}', 201);
        }),
      ),
    );
    Hourly hourAt(int dt) => Hourly.fromJson({
      'dt': dt,
      'temp': 26.4,
      'feels_like': 26.3,
      'pressure': 1012,
      'humidity': 60,
      'dew_point': 19.0,
      'uvi': 1.3,
      'clouds': 30,
      'visibility': 10000,
      'wind_speed': 2.1,
      'wind_deg': 180,
      'wind_gust': 3.2,
      'weather': [
        {'id': 800, 'main': 'Clear', 'description': 'clear sky', 'icon': '01d'},
      ],
      'pop': 0.1,
      'rain': {'1h': 0.2},
    });
    Hourly hour(int offset) => hourAt(1791158400 + offset * 3600);
    Daily day(int offset) => Daily.fromJson({
      'dt': 1791158400 + offset * 86400,
      'sunrise': 1791138000 + offset * 86400,
      'sunset': 1791180000 + offset * 86400,
      'moonrise': 1791130000 + offset * 86400,
      'moonset': 1791183000 + offset * 86400,
      'moon_phase': 0.4,
      'summary': 'Mostly clear through the day',
      'temp': {
        'day': 26.4,
        'min': 15.2,
        'max': 27.1,
        'night': 17.2,
        'eve': 21.0,
        'morn': 15.5,
      },
      'feels_like': {'day': 26.3, 'night': 17.0, 'eve': 21.0, 'morn': 15.3},
      'pressure': 1012,
      'humidity': 60,
      'dew_point': 19.0,
      'wind_speed': 2.1,
      'wind_deg': 180,
      'wind_gust': 3.2,
      'weather': [
        {'id': 800, 'main': 'Clear', 'description': 'clear sky', 'icon': '01d'},
      ],
      'clouds': 30,
      'pop': 0.1,
      'uvi': 1.3,
      'rain': 0.2,
    });
    final forecast = OneCallResponse(
      lat: -35.3,
      lon: 149.1,
      timezone: 'Australia/Sydney',
      timezoneOffset: 39600,
      hourly: List.generate(48, hour),
      daily: List.generate(8, day),
    );
    final historical = OneCallResponse(
      lat: timeline['lat'] as double,
      lon: timeline['lon'] as double,
      timezone: timeline['timezone'] as String,
      timezoneOffset: timeline['timezone_offset'] as int,
      hourly: [for (final slot in historicalSlots) hourAt(slot['dt'] as int)],
    );
    final leadUp = OneCallResponse(
      lat: -35.3,
      lon: 149.1,
      timezone: 'Australia/Sydney',
      timezoneOffset: 39600,
      daily: List.generate(2, (index) => day(index - 2)),
    );
    final current = CurrentWeatherResponse.fromJson({
      'coord': {'lat': -35.3, 'lon': 149.1},
      'weather': [
        {'id': 800, 'main': 'Clear', 'description': 'clear sky', 'icon': '01d'},
      ],
      'base': 'stations',
      'main': {
        'temp': 26.4,
        'feels_like': 26.3,
        'temp_min': 15.2,
        'temp_max': 27.1,
        'pressure': 1012,
        'humidity': 60,
      },
      'visibility': 10000,
      'wind': {'speed': 2.1, 'deg': 180, 'gust': 3.2},
      'clouds': {'all': 30},
      'dt': 1791158400,
      'sys': {'country': 'AU', 'sunrise': 1791138000, 'sunset': 1791180000},
      'timezone': 39600,
      'id': 2172517,
      'name': 'Canberra',
      'cod': 200,
    });
    await facade.createWeather(
      '2.29.0',
      '164',
      forecast,
      historical,
      current,
      leadUp: leadUp,
      leadUpDays: 2,
    );
    final body = sent!.body;
    final parsed = jsonDecode(body) as Map<String, dynamic>;
    expect(parsed['forecast']['hourly'], hasLength(48));
    expect(parsed['forecast']['daily'], hasLength(8));
    expect(parsed['historical']['hourly'], hasLength(24));
    for (final key in ['lat', 'lon', 'timezone', 'timezone_offset']) {
      expect(parsed['historical'][key], timeline[key]);
    }
    expect(
      (parsed['historical']['hourly'] as List<dynamic>).map(
        (slot) => (slot as Map<String, dynamic>)['dt'],
      ),
      historicalSlots.map((slot) => slot['dt']),
    );
    expect(parsed['leadup']['daily'], hasLength(2));
    final bytes = utf8.encode(body).length;
    print('Representative REST snapshot UTF-8 bytes: $bytes');
    expect(bytes, lessThan(256 * 1024));
  });
}
