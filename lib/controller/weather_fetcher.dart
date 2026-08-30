import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, visibleForTesting;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:nuptialflight/responses/onecall_response.dart';
import 'package:nuptialflight/responses/reverse_geocoding_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nuptialflight/responses/weather_response.dart';

class DailySplit {
  final List<Daily> forecast;
  final List<Daily> leadUp;
  DailySplit(this.forecast, this.leadUp);
}

class WeatherFetcher {
  late bool _mockLocation;
  // True only when mock mode was auto-enabled for a debug web launch (as opposed
  // to a caller explicitly passing mockLocation: true, e.g. the test suite).
  late bool _debugWebLocation;
  double? _lat;
  double? _lon;
  final http.Client? _httpClient;

  WeatherFetcher({bool mockLocation = false, http.Client? httpClient})
      : _httpClient = httpClient {
    // In debug WEB builds, default to a hardwired (mock) location so the first
    // page renders without the slow/blocking browser geolocation prompt. Mobile
    // debug builds and all release builds still use real GPS. Callers can also
    // force mock mode explicitly via the constructor argument.
    _debugWebLocation = !mockLocation && kDebugMode && kIsWeb;
    _mockLocation = mockLocation || _debugWebLocation;
  }

  Future<bool> findLocation(bool waitForPosition) async {
    print("findLocation: _mockLocation=$_mockLocation waitForPosition=$waitForPosition ");
    if (!_mockLocation) {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position? position;
        if (kIsWeb || waitForPosition) {
          try {
            // NOTE: geolocator's web backend ignores `timeLimit` inside
            // LocationSettings (it only maps to enableHighAccuracy), so a
            // blocked/dismissed browser geolocation prompt can hang forever
            // and leave the app on a permanent spinner. Enforce a real
            // Dart-level timeout so we always fall through to the error path.
            final Future<Position> positionFuture = Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                    accuracy: LocationAccuracy.low,
                    timeLimit: Duration(seconds: 10)));
            // The timeout below abandons positionFuture. Without its own
            // listener, a late failure (e.g. the browser permission prompt
            // denied after our timeout, which errors inside the geolocator
            // web plugin) surfaces as an unhandled exception in the console.
            positionFuture.then<void>((_) {}, onError: (Object e) {
              developer.log('Late geolocation failure (ignored): $e',
                  name: 'WeatherFetcher');
            });
            position = await positionFuture.timeout(const Duration(seconds: 8));
          } on TimeoutException {
            developer.log(
                "Timed out waiting for current position (web geolocation "
                "may be blocked or requires a user gesture).",
                name: 'WeatherFetcher');
            position = null;
          } catch (exception) {
            developer.log("Can't get current position: exception=$exception",
                name: 'WeatherFetcher', error: exception);
          }
        } else if (!kIsWeb) {
          position = await Geolocator.getLastKnownPosition();
        }
        if (position != null) {
          if (!kIsWeb) {
            try {
              await HomeWidget.saveWidgetData<double>('last_latitude', position.latitude);
              await HomeWidget.saveWidgetData<double>('last_longitude', position.longitude);
            } catch (e) {
              print("Failed to save location to HomeWidget: $e");
            }
          }
          if (_lat == null ||
              _lon == null ||
              _lat!.toStringAsFixed(2) !=
                  position.latitude.toStringAsFixed(2) ||
              _lon!.toStringAsFixed(2) !=
                  position.longitude.toStringAsFixed(2)) {
            // Position has changed
            _lat = position.latitude;
            _lon = position.longitude;
            print("findLocation: return true _lat=$_lat _lon=$_lon ");
            return true;
          }
        }
        if (_lat == null || _lon == null) {
          print("findLocation: _lat=$_lat _lon=$_lon ");
          throw Exception(
              'Failed to get your location!\n\nPlease manually enter your location.');
        }
        return false;
      } else {
        print("findLocation: _lat=$_lat _lon=$_lon ");
        throw Exception(
            'Location permissions are denied!\n\nPlease manually enter your location.');
      }
    } else if (_debugWebLocation) {
      // Debug web launch: hardwire Canberra, ACT and report it as a change so the
      // first page actually fetches weather (instead of spinning forever).
      _lat = -35.2809;
      _lon = 149.1300;
      print('findLocation(debug-web): hardwired Canberra _lat=' + _lat.toString() + ' _lon=' + _lon.toString());
      return true;
    } else {
      // Explicit mock (e.g. the test suite): Batemans Bay fixture.
      _lat = -35.7600;
      _lon = 150.2053;
    }
    print("findLocation: return false _lat=$_lat _lon=$_lon ");
    return false;
  }

  /// Returns the current lat/lon as a [LatLng], or (0,0) before a location has
  /// been resolved.
  LatLng getLocation() {
    if (_lat == null || _lon == null) return LatLng(0, 0);
    print("getLocation: _lat=$_lat _lon=$_lon ");
    return LatLng(_lat!, _lon!);
  }

  /// Sets the location from a raw [LatLng] (e.g. a long-press on the map page)
  /// and caches it to the home widget.
  void setLocation(LatLng latLng) {
    _lat = latLng.latitude;
    _lon = latLng.longitude;
    print('setLocation: _lat=$_lat _lon=$_lon');
    if (!kIsWeb) {
      try {
        HomeWidget.saveWidgetData<double>('last_latitude', _lat!);
        HomeWidget.saveWidgetData<double>('last_longitude', _lon!);
      } catch (e) {
        print("Failed to save location to HomeWidget: $e");
      }
    }
  }

  /// Sets the location from a resolved [Position] and caches it to the home widget.
  void setPosition(Position position) {
    _lat = position.latitude;
    _lon = position.longitude;
    print('setLocation: _lat=$_lat _lon=$_lon');
    if (!kIsWeb) {
      try {
        HomeWidget.saveWidgetData<double>('last_latitude', _lat!);
        HomeWidget.saveWidgetData<double>('last_longitude', _lon!);
      } catch (e) {
        print("Failed to save location to HomeWidget: $e");
      }
    }
  }

  /// Sets the location from a Google Places autocomplete result and caches it to
  /// the home widget (used when the user picks a place from the search dialog).
  void setLocationPlace(PlacesDetailsResponse detail) {
    _lat = detail.result.geometry!.location.lat;
    _lon = detail.result.geometry!.location.lng;
    print('setLocation: _lat=$_lat _lon=$_lon');
    if (!kIsWeb) {
      try {
        HomeWidget.saveWidgetData<double>('last_latitude', _lat!);
        HomeWidget.saveWidgetData<double>('last_longitude', _lon!);
      } catch (e) {
        print("Failed to save location to HomeWidget: $e");
      }
    }
  }

  // --- OpenWeatherMap response caching (shared_preferences) ---
  // Cuts paid OWM API calls: repeat launches and the 15-min background
  // fetch reuse a recent response while it is still fresh. The cache key
  // is scoped to the rounded lat/lon so a real move invalidates it.
  static const Duration _ttlForecast = Duration(minutes: 30);
  static const Duration _ttlReverseGeocode = Duration(hours: 24);
  static const Duration _ttlHistorical = Duration(days: 30);

  String _cacheKey(String endpoint, {int? dt}) {
    final lat = (_lat ?? 0).toStringAsFixed(2);
    final lon = (_lon ?? 0).toStringAsFixed(2);
    var key = 'owm_' + endpoint + '_' + lat + '_' + lon;
    if (dt != null) key += '_' + dt.toString();
    return key;
  }

  @visibleForTesting
  String cacheKeyFor(String endpoint, {int? dt}) => _cacheKey(endpoint, dt: dt);

  @visibleForTesting
  void setTestPosition(double lat, double lon) {
    _lat = lat;
    _lon = lon;
  }

  Future<T> _fetchCached<T>({
    required String url,
    required String endpoint,
    required Duration ttl,
    required String errorPrefix,
    required T Function(String body) parse,
    String? rateLimitMessage,
    int? dt,
  }) async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      // The plugin can be unimplemented on some platforms (e.g. the flutter
      // test runner or web). Degrade gracefully to no caching instead of
      // crashing -- this mirrors how memory_info is guarded elsewhere.
      prefs = null;
    }
    final key = _cacheKey(endpoint, dt: dt);
    final raw = prefs?.getString(key);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final ts = (map['ts'] as int?) ?? 0;
        if (DateTime.now().millisecondsSinceEpoch - ts < ttl.inMilliseconds) {
          return parse(map['body'] as String);
        }
      } catch (_) {
        // Corrupt entry - fall through to a fresh network fetch.
      }
    }
    final response = await (_httpClient?.get(Uri.parse(url)) ?? http.get(Uri.parse(url)));
    if (response.statusCode == 429 && rateLimitMessage != null) {
      throw Exception(rateLimitMessage);
    }
    if (response.statusCode != 200) {
      throw Exception(errorPrefix + '!\n\n' + response.body);
    }
    final body = response.body;
    try {
      await prefs?.setString(
        key,
        jsonEncode({'ts': DateTime.now().millisecondsSinceEpoch, 'body': body}),
      );
    } catch (_) {
      // Persistence is best-effort; never block the UI on a write failure.
    }
    return parse(body);
  }
  Future<ReverseGeocodingResponse> fetchReverseGeocoding() async {
    if (_lat == null || _lon == null)
      throw Exception(
          'Location is unknown! Perhaps you didn\'t allow location permissions?');

    String url =
        'https://api.openweathermap.org/geo/1.0/reverse?lat=${_lat!.toStringAsFixed(4)}&lon=${_lon!.toStringAsFixed(4)}&appid=${dotenv.env['OPENWEATHERMAP_API_KEY']}&limit=1';
    print("url=$url");

    return _fetchCached<ReverseGeocodingResponse>(
      url: url,
      endpoint: 'reverse',
      ttl: _ttlReverseGeocode,
      errorPrefix: 'Failed to load reverse geocoding',
      parse: (b) {
        final json = jsonDecode(b) as List;
        if (json.length != 1) {
          throw Exception('Unexpected reverse geocoding response!');
        }
        return ReverseGeocodingResponse.fromJson(json.first);
      },
    );
  }

  Future<CurrentWeatherResponse> fetchNearestWeatherLocation() async {
    if (_lat == null || _lon == null)
      throw Exception(
          'Location is unknown! Perhaps you didn\'t allow location permissions?');

    String url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$_lat&lon=$_lon&appid=${dotenv.env['OPENWEATHERMAP_API_KEY']}&units=metric&mode=json';
    print("url=$url");

    return _fetchCached<CurrentWeatherResponse>(
      url: url,
      endpoint: 'nearest',
      ttl: _ttlForecast,
      errorPrefix: 'Failed to download current weather',
      parse: (b) => CurrentWeatherResponse.fromJson(jsonDecode(b)),
    );
  }

  /// Number of antecedent ("lead-up") days to collect alongside the forecast.
  /// The daily-timeline endpoint caps a single page at 10 records, so this is
  /// sized so leadUpDays + 8 forecast days (today..+7) fits one response ->
  /// one paid call -> zero *extra* One Call calls versus the pre-lead-up path.
  /// Raise beyond 2 and the combined window spills past the 10-record page,
  /// requiring an extra paginated request.
  static const int leadUpDays = 2;

  /// Splits a combined daily-timeline page at the LOCATION-LOCAL "today":
  /// a record belongs to leadUp iff its local day bucket is before now's
  /// local day bucket. One boundary definition; no UTC/local mixing (#20).
  static DailySplit splitDaily(List<Daily> all, int tzOffsetSeconds, int nowUtcSeconds) {
    final today = (nowUtcSeconds + tzOffsetSeconds) ~/ 86400;
    final forecast = <Daily>[];
    final leadUp = <Daily>[];
    for (final d in all) {
      final dt = d.dt;
      if (dt != null && (dt + tzOffsetSeconds) ~/ 86400 < today) {
        leadUp.add(d);
      } else {
        forecast.add(d);
      }
    }
    return DailySplit(forecast, leadUp);
  }

  /// Daily forecast + lead-up only - ONE paid call. Used by the background
  /// service (which never reads hourly, #33) and composed by fetchWeather().
  ///
  /// Split-and-route: the daily timeline is anchored `leadUpDays` into the
  /// past (start = today UTC midnight - leadUpDays) and sized so a single
  /// page holds the antecedent days AND the 8-day forecast (leadUpDays + 8
  /// <= 10 records = the 4.0 page cap). We then split the combined `data`
  /// array at the LOCATION-LOCAL day boundary via splitDaily() (see its doc
  /// comment): records whose local day bucket is before local "today" become
  /// antecedent / "lead-up" days (training features); the rest become the
  /// forecast, in order, so daily[0] is still *local today*.
  /// This collects the lead-up weather that docs/model_training_findings.md
  /// (Part 4 #3) named as the main accuracy lever - at ZERO extra One Call
  /// calls: the daily request the app already makes simply reaches a little
  /// into the past. The legacy `flights.weather.daily` schema is unchanged
  /// (daily[0] == today), so years of stored training history stay valid.
  Future<OneCallResponse> fetchDailyWeather() async {
    if (_lat == null || _lon == null)
      throw Exception('Location is unknown! Perhaps you didn\'t allow location permissions?');
    final nowUtcSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final todayUtcDay = nowUtcSeconds ~/ 86400;
    final pastStart = (todayUtcDay - leadUpDays) * 86400;
    final cnt = leadUpDays + 8; // 10 -> fits one daily-timeline page
    final key = dotenv.env['OPENWEATHERMAP_API_KEY'];
    final dailyUrl =
        'https://api.openweathermap.org/data/4.0/onecall/timeline/1day?lat=$_lat&lon=$_lon&appid=$key&units=metric&start=$pastStart&cnt=$cnt';
    print("dailyUrl=$dailyUrl");
    final resp = await _fetchCached<OneCallResponse>(
      url: dailyUrl,
      endpoint: 'onecall_daily',
      dt: todayUtcDay,
      ttl: _ttlForecast,
      errorPrefix: 'Failed to download daily weather',
      parse: (b) => OneCallResponse.fromTimelineJson(jsonDecode(b), TimelineKind.daily),
    );
    final split = splitDaily(resp.daily ?? const <Daily>[], resp.timezoneOffset ?? 0, nowUtcSeconds);
    resp.daily = split.forecast;
    resp.leadUpDaily = split.leadUp;
    return resp;
  }

  Future<OneCallResponse> fetchWeather() async {
    if (_lat == null || _lon == null)
      throw Exception('Location is unknown! Perhaps you didn\'t allow location permissions?');

    // One Call API 4.0 splits the forecast across two timeline endpoints:
    //   - hourly -> /data/4.0/onecall/timeline/1h
    //   - daily  -> /data/4.0/onecall/timeline/1day
    // Each returns a flat `data` array that OneCallResponse parses into the
    // matching list; we fetch both and merge them into a single response so
    // the rest of the app keeps working unchanged. The daily leg (plus the
    // lead-up split) lives in fetchDailyWeather() - see its doc comment.
    final hourlyUrl =
        'https://api.openweathermap.org/data/4.0/onecall/timeline/1h?lat=$_lat&lon=$_lon&appid=${dotenv.env['OPENWEATHERMAP_API_KEY']}&units=metric&cnt=48';
    print("hourlyUrl=$hourlyUrl");

    final results = await Future.wait([
      _fetchCached<OneCallResponse>(
        url: hourlyUrl,
        endpoint: 'onecall_hourly',
        ttl: _ttlForecast,
        errorPrefix: 'Failed to download hourly weather',
        parse: (b) => OneCallResponse.fromTimelineJson(jsonDecode(b), TimelineKind.hourly),
      ),
      fetchDailyWeather(),
    ]);
    // Merge: keep the hourly list and attach the (split) daily list.
    final merged = results[0];
    final dailyResp = results[1];
    merged.daily = dailyResp.daily;
    merged.leadUpDaily = dailyResp.leadUpDaily;
    return merged;
  }

  Future<OneCallResponse> fetchHistoricalWeather(int dt) async {
    if (_lat == null || _lon == null)
      throw Exception(
          'Location is unknown! Perhaps you didn\'t allow location permissions?');

    // One Call API 4.0 removed the dedicated /timemachine endpoint. Historical
    // data is now served by the same hourly timeline: anchor `start` at the
    // requested timestamp (today's UTC midnight) and pull enough hourly steps
    // to cover the diurnal (11AM) / nocturnal (7PM) lookups done in main.dart.
    final key = dotenv.env['OPENWEATHERMAP_API_KEY'];
    final url =
        'https://api.openweathermap.org/data/4.0/onecall/timeline/1h?lat=$_lat&lon=$_lon&appid=$key&units=metric&start=$dt&cnt=24';
    print("url=$url");

    return _fetchCached<OneCallResponse>(
      url: url,
      endpoint: 'timemachine4',
      ttl: _ttlHistorical,
      dt: dt,
      errorPrefix: 'Failed to download historical weather',
      parse: (b) => OneCallResponse.fromTimelineJson(jsonDecode(b), TimelineKind.hourly),
    );
  }
}
