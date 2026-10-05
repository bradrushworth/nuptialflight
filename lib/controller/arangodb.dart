import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'install_id.dart';
import '../responses/onecall_response.dart';
import '../responses/weather_response.dart';

/// Authenticated REST transport for crowd reports. All failures are bounded.
class ApiClient {
  static const defaultUrl = 'https://api.bitbot.com.au/nuptialflight/v1';
  final http.Client _http;
  final Uri? _base;
  final String _key;
  final Future<String> Function() _installId;

  /// The limit for one attempt, covering both sending the request and
  /// reading the response body.
  final Duration timeout;
  final Duration retryDelay;

  /// The budget for a whole read, its retry included. Reads run inside the
  /// background task ahead of the widget refresh, so they must be short.
  final Duration readDeadline;

  /// The budget for a whole write, its retry included: two full attempts.
  final Duration writeDeadline;

  ApiClient({
    required String baseUrl,
    required String apiKey,
    http.Client? httpClient,
    Future<String> Function()? installId,
    this.timeout = const Duration(seconds: 8),
    this.retryDelay = const Duration(milliseconds: 250),
    this.readDeadline = const Duration(seconds: 10),
    this.writeDeadline = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client(),
       _base = _validBase(baseUrl),
       _key = apiKey.trim(),
       _installId = installId ?? InstallId.get;

  bool get enabled => _base != null && _key.isNotEmpty;

  static Uri? _validBase(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty)
      return null;
    final loopback =
        uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.host == '[::1]' ||
        uri.host == '::1';
    if (uri.scheme != 'https' && !(uri.scheme == 'http' && loopback))
      return null;
    if (uri.port == 8530) return null;
    return uri.replace(path: uri.path.replaceAll(RegExp(r'/+$'), ''));
  }

  Uri _url(String path, [Map<String, String>? query]) {
    final base = _base!;
    return base.replace(path: '${base.path}$path', queryParameters: query);
  }

  Future<http.Response?> _send(String method, Uri url, {Object? body}) async {
    if (!enabled) return null;
    // One budget for the whole call. Without it the worst case was the sum of
    // every individual wait: about 40 s for something a background task runs.
    final expired = Completer<void>();
    final budget = Timer(
      method == 'GET' ? readDeadline : writeDeadline,
      expired.complete,
    );
    try {
      final install = await _installId().timeout(timeout);
      if (!Uuid.isValidUUID(fromString: install)) return null;
      final requestId = method == 'GET' ? null : const Uuid().v4();
      final headers = <String, String>{
        'X-NF-Key': _key,
        'X-NF-Install': install,
        if (requestId != null) 'X-NF-Request': requestId,
        if (body != null) 'Content-Type': 'application/json',
      };
      final payload = body == null ? null : jsonEncode(body);
      for (var attempt = 0; attempt < 2 && !expired.isCompleted; attempt++) {
        // Completing this aborts the request on the wire, so an attempt we
        // have given up on is not still uploading behind its own retry.
        final abort = Completer<void>();
        void stop([void _]) {
          if (!abort.isCompleted) abort.complete();
        }

        final limit = Timer(timeout, stop);
        unawaited(expired.future.then(stop));
        try {
          final request =
              http.AbortableRequest(method, url, abortTrigger: abort.future)
                ..followRedirects = false
                ..headers.addAll(headers);
          if (payload != null) request.body = payload;
          final response = await Future.any([
            _exchange(request),
            abort.future.then<http.Response>(
              (_) => throw TimeoutException('request abandoned'),
            ),
          ]);
          if (response.statusCode >= 200 && response.statusCode < 300)
            return response;
          // 429 and client errors are final. A retry would amplify rate limits.
          if (response.statusCode == 429 ||
              (response.statusCode != 408 && response.statusCode < 500))
            return null;
        } catch (_) {
          // Timeout and transport failures are retried at most once.
        } finally {
          limit.cancel();
        }
        if (attempt == 0) {
          await Future.any([
            Future<void>.delayed(retryDelay),
            expired.future,
          ]);
        }
      }
    } catch (_) {
      // Includes install ID and serialization failures. Never log request data.
    } finally {
      budget.cancel();
    }
    return null;
  }

  /// Sends [request] and reads the whole response body.
  Future<http.Response> _exchange(http.BaseRequest request) async =>
      http.Response.fromStream(await _http.send(request));

  Future<String?> createSnapshot(Map<String, dynamic> payload) async {
    if (!enabled) return null;
    final response = await _send('POST', _url('/snapshots'), body: payload);
    return response?.statusCode == 201 ? _handle(response!) : null;
  }

  Future<bool> confirmSighting(
    String handle,
    Map<String, dynamic> payload,
  ) async {
    if (!enabled || handle.isEmpty || handle.contains('/')) return false;
    final response = await _send(
      'PUT',
      _url('/snapshots/${Uri.encodeComponent(handle)}/sighting'),
      body: payload,
    );
    return response?.statusCode == 200 && _handle(response!) == handle;
  }

  String? _handle(http.Response response) {
    try {
      final value = jsonDecode(response.body);
      final handle = value is Map ? value['handle'] : null;
      return handle is String && handle.isNotEmpty ? handle : null;
    } catch (_) {
      return null;
    }
  }

  Future<List> recentFlights() => enabled
      ? _rows(_url('/flights/recent'), nearby: false)
      : Future.value([]);

  /// Flights reported within 500 km of ([lat], [lon]).
  ///
  /// The coordinates are rounded to two decimals (about a kilometre) before
  /// they go into the URL. The server buckets to 0.1 degree and answers in
  /// whole kilometres, so more precision would only expose a location.
  Future<List> nearbyFlights(num lat, num lon, int minutes) => enabled
      ? _rows(
          _url('/flights/nearby', {
            'lat': lat.toStringAsFixed(2),
            'lon': lon.toStringAsFixed(2),
            'minutes': '${normalizeMinutes(minutes)}',
          }),
          nearby: true,
        )
      : Future.value([]);

  static int normalizeMinutes(int value) =>
      value == 0 ? 30 : value.abs().clamp(1, 1440);

  Future<List> _rows(Uri url, {required bool nearby}) async {
    final response = await _send('GET', url);
    if (response == null) return [];
    try {
      final value = jsonDecode(response.body);
      if (value is! List) return [];
      // Row by row: the server returns documents as stored, and older clients
      // still write to the database directly. One odd document must cost one
      // marker, not every marker on every map.
      return [
        for (final item in value)
          if (_validRow(item, nearby: nearby))
            <String, dynamic>{
              ...(item as Map<String, dynamic>),
              'lat': (item['lat'] as num).toDouble(),
              'lon': (item['lon'] as num).toDouble(),
              if (nearby) 'distance': (item['distance'] as num).toInt(),
            },
      ];
    } catch (_) {
      return [];
    }
  }

  static bool _validRow(Object? value, {required bool nearby}) {
    if (value is! Map<String, dynamic>) return false;
    final key = value['key'];
    final lat = value['lat'];
    final lon = value['lon'];
    final weather = value['weather'];
    final size = value['size'];
    if (key is! String ||
        key.isEmpty ||
        lat is! num ||
        !lat.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lon is! num ||
        !lon.isFinite ||
        lon < -180 ||
        lon > 180 ||
        (weather != null && weather is! String) ||
        (size != null && !const ['small', 'medium', 'large'].contains(size))) {
      return false;
    }
    if (nearby) {
      final distance = value['distance'];
      if (distance is! num ||
          !distance.isFinite ||
          distance < 0 ||
          distance != distance.roundToDouble())
        return false;
    }
    return true;
  }
}

/// Compatibility facade for existing UI and background service callers.
/// The signed handle lives only in this isolate, never on disk.
class ArangoSingleton {
  static final ArangoSingleton _singleton = ArangoSingleton._internal();
  final ApiClient? _injected;
  final Map<String, String>? _testConfig;
  final http.Client? _testHttpClient;
  final Future<String> Function()? _testInstallId;
  Future<ApiClient?>? _clientFuture;
  Future<String?>? _latestSnapshot;

  factory ArangoSingleton() => _singleton;
  ArangoSingleton.withClient(ApiClient client)
    : _injected = client,
      _testConfig = null,
      _testHttpClient = null,
      _testInstallId = null;

  /// Exercises lazy config loading in a headless test without a live asset.
  ArangoSingleton.withConfigForTesting(
    Map<String, String> config, {
    required http.Client httpClient,
    required Future<String> Function() installId,
  }) : _injected = null,
       _testConfig = config,
       _testHttpClient = httpClient,
       _testInstallId = installId;
  ArangoSingleton._internal()
    : _injected = null,
      _testConfig = null,
      _testHttpClient = null,
      _testInstallId = null;

  Future<ApiClient?> _client() => _clientFuture ??= _injected == null
      ? _loadClient()
      : Future.value(_injected);

  Future<ApiClient?> _loadClient() async {
    try {
      if (_testConfig == null && !dotenv.isInitialized) {
        await dotenv.load(fileName: 'assets/.env');
      }
      final config = _testConfig ?? dotenv.env;
      return ApiClient(
        baseUrl: config['NF_API_URL'] ?? ApiClient.defaultUrl,
        apiKey: config['NF_API_KEY'] ?? '',
        httpClient: _testHttpClient,
        installId: _testInstallId,
      );
    } catch (_) {
      // Also safe in a headless background isolate without an available asset.
      return null;
    }
  }

  Future<void> init() async {
    await _client();
  }

  Map<String, dynamic>? _payload(
    String? version,
    String? buildNumber,
    OneCallResponse? weather,
    OneCallResponse? historical,
    CurrentWeatherResponse? current,
    OneCallResponse? leadUp,
    int leadUpDays, {
    String? size,
    bool sighting = false,
  }) {
    if (version == null ||
        buildNumber == null ||
        weather == null ||
        historical == null ||
        current == null ||
        leadUpDays < 0 ||
        leadUpDays > 7 ||
        (sighting &&
            size != null &&
            !const ['small', 'medium', 'large'].contains(size))) {
      return null;
    }
    return {
      'version': '$version+$buildNumber',
      // Preserve the legacy web marker. Native uses null instead of a
      // hardware fingerprint; X-NF-Install carries an anonymous install UUID.
      'device_id': kIsWeb ? 'web' : null,
      'forecast': weather.toJson(),
      'historical': historical.toJson(),
      'current': current.toJson(),
      'leadup': leadUp?.toJson(),
      'lead_up_days': leadUpDays,
      if (sighting) 'size': size,
    };
  }

  Future<void> createWeather(
    String? version,
    String? buildNumber,
    OneCallResponse? weather,
    OneCallResponse? historical,
    CurrentWeatherResponse? current, {
    OneCallResponse? leadUp,
    required int leadUpDays,
  }) async {
    // Assign synchronously before the first await. A report captures exactly
    // this create, so overlapping loads cannot reuse an older handle.
    final created = _create(
      version,
      buildNumber,
      weather,
      historical,
      current,
      leadUp,
      leadUpDays,
    );
    _latestSnapshot = created;
    await created;
  }

  Future<String?> _create(
    String? version,
    String? buildNumber,
    OneCallResponse? weather,
    OneCallResponse? historical,
    CurrentWeatherResponse? current,
    OneCallResponse? leadUp,
    int leadUpDays,
  ) async {
    try {
      final client = await _client();
      final body = _payload(
        version,
        buildNumber,
        weather,
        historical,
        current,
        leadUp,
        leadUpDays,
      );
      return body == null ? null : await client?.createSnapshot(body);
    } catch (_) {
      return null;
    }
  }

  /// Sends the user's report and returns whether the server stored it.
  ///
  /// A sighting is a training label, so the caller must only thank the user
  /// when this is true. It is false for every way a report can be lost: no
  /// API configured, weather not loaded, no snapshot could be made, or the
  /// server refused the sighting (rate limit, expired handle, validation).
  Future<bool> updateWeather(
    String? version,
    String? buildNumber,
    String? size,
    OneCallResponse? weather,
    OneCallResponse? historical,
    CurrentWeatherResponse? current, {
    OneCallResponse? leadUp,
    required int leadUpDays,
  }) async {
    // Captured before the first await: a report belongs to the snapshot that
    // was current when the user sent it, even if a refresh replaces it while
    // this call is in flight.
    final captured = _latestSnapshot;
    try {
      final client = await _client();
      final body = _payload(
        version,
        buildNumber,
        weather,
        historical,
        current,
        leadUp,
        leadUpDays,
        size: size,
        sighting: true,
      );
      if (client == null || body == null) return false;
      var snapshot = captured;
      var handle = snapshot == null ? null : await snapshot;
      if (handle == null) {
        // The passive create at weather load failed or never ran (offline, a
        // slow link, a rate limit). The report carries the whole weather
        // payload, so make the snapshot now rather than drop the report.
        snapshot = _create(
          version,
          buildNumber,
          weather,
          historical,
          current,
          leadUp,
          leadUpDays,
        );
        if (identical(_latestSnapshot, captured)) _latestSnapshot = snapshot;
        handle = await snapshot;
        if (handle == null) return false;
      }
      if (await client.confirmSighting(handle, body)) return true;
      // Refused or lost. Forget this snapshot so that trying again starts
      // from a fresh one instead of failing the same way: a handle the server
      // has expired (24 h) would otherwise be offered on every retry.
      if (identical(_latestSnapshot, snapshot)) _latestSnapshot = null;
      return false;
    } catch (_) {
      // UI callers do not guard this; nothing may escape as a zone error.
      return false;
    }
  }

  Future<List> getRecentFlights() async {
    try {
      return await (await _client())?.recentFlights() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List> getRecentFlightsNearMe(Position? position, int minutes) async {
    if (position == null) return [];
    try {
      return await (await _client())?.nearbyFlights(
            position.latitude,
            position.longitude,
            minutes,
          ) ??
          [];
    } catch (_) {
      return [];
    }
  }
}
