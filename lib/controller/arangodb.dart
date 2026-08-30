import 'dart:developer' as developer;
import 'dart:io';

import 'package:darango/darango.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_device_identifier/mobile_device_identifier.dart';

import 'install_id.dart';
import '../responses/onecall_response.dart';
import '../responses/weather_response.dart';

/// Singleton wrapper around the ArangoDB backend that stores crowd-sourced
/// weather snapshots and nuptial-flight reports.
///
/// Every fetch writes three linked documents — one per collection:
///   * `current`    — a single present-conditions OWM snapshot
///   * `historical` — the 24h history of the flight day (timemachine)
///   * `flights`    — the 8-day One Call forecast
///
/// `createWeather` inserts the three, `updateWeather` edits the same three
/// documents once the user reports whether they saw a flight (flipping
/// `flight` from 'unknown' to 'yes' and tagging `size`). The `_weather*Key`
/// fields cache the document handles from `createWeather` so `updateWeather`
/// can target them.
class ArangoSingleton {
  static final ArangoSingleton _singleton = ArangoSingleton._privateConstructor();

  // Create client for Arango database
  Database? _arangoClient;
  Future<void>? _connectFuture;
  // Cached ArangoDB document handles for the three documents created by the
  // most recent createWeather() call (see class doc). Used by updateWeather().
  var _weatherCurrentKey;
  var _weatherHistoricalKey;
  var _weatherFlightsKey;
  var _weatherLeadUpKey;
  // Collections we've already attempted to create this session (best-effort,
  // once each) so the new ML-training table exists before we write to it.
  final Set<String> _ensuredCollections = <String>{};

  factory ArangoSingleton() {
    return _singleton;
  }

  ArangoSingleton._privateConstructor() {
    _connectFuture = init();
  }

  Future<void> init() async {
    // Ensure dotenv is loaded before accessing env keys
    if (!dotenv.isInitialized) {
      try {
        await dotenv.load(fileName: 'assets/.env');
      } catch (e) {
        debugPrint("Failed to load .env in ArangoSingleton: $e");
      }
    }

    final String url = dotenv.env['ARANGO_URL'] ?? 'https://api.bitbot.com.au:8530';
    final String dbName = dotenv.env['ARANGO_DB_NAME'] ?? 'nuptialFlight';
    final String user = dotenv.env['ARANGO_USER'] ?? 'nuptialflight';
    final String password = dotenv.env['ARANGO_PASSWORD'] ?? 'fdggdsgdfstg34wfwfwff';

    _arangoClient = Database(url);
    await _arangoClient!.connect(dbName, user, password);
  }

  Future<void> _ensureConnected() async {
    if (_connectFuture != null) {
      await _connectFuture;
    }
  }

  /// Best-effort creation of a collection (e.g. the ML-training `leadup` table)
  /// so the app can upload to a fresh table without manual DB provisioning.
  /// Tolerates an already-existing collection; returns whether the collection
  /// is verifiably present afterwards, and only caches the name once that is
  /// confirmed (#24) so a failed create doesn't get remembered as "ensured".
  Future<bool> _ensureCollection(String name) async {
    if (_ensuredCollections.contains(name)) return true;
    try {
      await _arangoClient!.createCollection({'name': name});
    } catch (_) {
      // darango generally swallows failures itself; the existence check below
      // is the real success signal either way.
    }
    final exists = await _arangoClient!.collection(name) != null;
    if (exists) _ensuredCollections.add(name); // only cache success (#24)
    return exists;
  }

  /// Builds the enriched ML-training document for the `leadup` collection,
  /// shared by [createWeather] and [updateWeather] so the schema can't drift
  /// between the insert and update paths.
  Map<String, dynamic> _leadUpDoc(
          String flight,
          String? size,
          String? version,
          String? buildNumber,
          String? deviceId,
          String? installId,
          OneCallResponse weather,
          CurrentWeatherResponse current,
          OneCallResponse leadUp,
          int leadUpDays) =>
      {
        'flight': flight,
        if (size != null) 'size': size,
        'version': '$version+$buildNumber',
        'device_id': deviceId,
        'install_id': installId,
        'source': 'app',
        'lat': weather.lat,
        'lon': weather.lon,
        'lead_up_days': leadUpDays,
        'collected_at': DateTime.now().toUtc().millisecondsSinceEpoch,
        'weather': {
          'current': current.toJson(),
          'forecast': weather.toJson(),
          'leadup': leadUp.toJson(),
        },
      };

  /// Persists a fresh weather snapshot as three linked documents (see the class
  /// doc): `flights` (the 8-day forecast), `historical` (24h history) and
  /// `current` (present snapshot). Each starts with `flight: 'unknown'`; the
  /// `_weather*Key` handles are cached so [updateWeather] can later mark the
  /// report confirmed. Called passively on every first-page load (unless in
  /// debug mode or a fixed/manual location, see main._recordWeather).
  void createWeather(String? version, String? buildNumber, OneCallResponse? _weather,
      OneCallResponse? _historical, CurrentWeatherResponse? _currentWeather,
      {OneCallResponse? leadUp, required int leadUpDays}) async {
    await _ensureConnected();

    String? deviceId;
    if (kIsWeb) {
      deviceId = 'web';
    } else if (Platform.isAndroid || Platform.isIOS) {
      deviceId = await MobileDeviceIdentifier().getDeviceId();
    } else {
      deviceId = Platform.localHostname;
    }

    final String installId = await InstallId.get();

    {
      // Let's create a new database post
      Collection? collection = await _arangoClient!.collection('flights');
      Document createResult = await collection!.document().add({
        'flight': 'unknown',
        'version': '$version+$buildNumber',
        'device_id': deviceId,
        'install_id': installId,
        'weather': _weather!.toJson()
      });
      _weatherFlightsKey = createResult.key;
    }
    {
      // Let's create a new database post
      Collection? collection = await _arangoClient!.collection('historical');
      Document createResult = await collection!.document().add({
        'flight': 'unknown',
        'version': '$version+$buildNumber',
        'device_id': deviceId,
        'install_id': installId,
        'weather': _historical!.toJson()
      });
      _weatherHistoricalKey = createResult.key;
    }
    {
      // Let's create a new database post
      Collection? collection = await _arangoClient!.collection('current');
      Document createResult = await collection!.document().add({
        'flight': 'unknown',
        'version': '$version+$buildNumber',
        'device_id': deviceId,
        'install_id': installId,
        'weather': _currentWeather!.toJson()
      });
      _weatherCurrentKey = createResult.key;
    }
    {
      // New schema (One Call 4.0, lead-up antecedent weather) for ML training.
      // Stores the full weather context - current + forecast + the N days of
      // daily weather *before* the report - in one enriched document with
      // lat/lon at the top level so training can filter by location without
      // digging into nested weather (see docs/model_training_findings.md
      // Part 4 #3).
      // _weather/_currentWeather are already non-null here (promoted by the
      // `!.toJson()` dereferences in the flights/current blocks above, which
      // would have thrown first if either were actually null at runtime), so
      // only leadUp needs an explicit null guard.
      if (leadUp != null) {
        try {
          if (!await _ensureCollection('leadup')) return;
          final collection = await _arangoClient!.collection('leadup');
          final createResult = await collection!.document().add(_leadUpDoc(
              'unknown', null, version, buildNumber, deviceId, installId,
              _weather, _currentWeather, leadUp, leadUpDays));
          _weatherLeadUpKey = createResult.key;
        } catch (e) {
          developer.log('leadup create failed: $e', name: 'ArangoSingleton');
        }
      }
    }
  }

  /// Marks the three documents previously created by [createWeather] as a
  /// confirmed sighting: `flight` becomes `'yes'` (or stays `'unknown'` when the
  /// user reports *no* flight, [size] == null) and the chosen queen [size]
  /// ('small'/'medium'/'large') is tagged on each. Called when the user taps a
  /// report button on the home page (see main._sawNuptialFlight).
  void updateWeather(String? version, String? buildNumber, String? size, OneCallResponse? _weather,
      OneCallResponse? _historical, CurrentWeatherResponse? _currentWeather,
      {OneCallResponse? leadUp, required int leadUpDays}) async {
    await _ensureConnected();

    String? deviceId;
    if (kIsWeb) {
      deviceId = 'web';
    } else if (Platform.isAndroid || Platform.isIOS) {
      deviceId = await MobileDeviceIdentifier().getDeviceId();
    } else {
      deviceId = Platform.localHostname;
    }

    final String installId = await InstallId.get();

    {
      // Let's update the existing database entry
      Collection? collection = await _arangoClient!.collection('flights');
      await collection!.document(document_handle: _weatherFlightsKey).update({
        'flight': size == null ? 'unknown' : 'yes',
        'size': size,
        'version': '$version+$buildNumber',
        'device_id': deviceId,
        'install_id': installId,
        'weather': _weather!.toJson()
      });
    }
    {
      // Let's update the existing database entry
      Collection? collection = await _arangoClient!.collection('historical');
      await collection!.document(document_handle: _weatherHistoricalKey).update({
        'flight': size == null ? 'unknown' : 'yes',
        'size': size,
        'version': '$version+$buildNumber',
        'device_id': deviceId,
        'install_id': installId,
        'weather': _historical!.toJson()
      });
    }
    {
      // Let's update the existing database entry
      Collection? collection = await _arangoClient!.collection('current');
      await collection!.document(document_handle: _weatherCurrentKey).update({
        'flight': size == null ? 'unknown' : 'yes',
        'size': size,
        'version': '$version+$buildNumber',
        'device_id': deviceId,
        'install_id': installId,
        'weather': _currentWeather!.toJson()
      });
    }
    {
      // New schema (One Call 4.0, lead-up antecedent weather) for ML training.
      // _weather/_currentWeather are already non-null here (promoted by the
      // `!.toJson()` dereferences in the flights/current blocks above, which
      // would have thrown first if either were actually null at runtime), so
      // only leadUp needs an explicit null guard.
      if (leadUp != null) {
        try {
          if (!await _ensureCollection('leadup')) return;
          final collection = await _arangoClient!.collection('leadup');
          final doc = _leadUpDoc(size == null ? 'unknown' : 'yes', size, version,
              buildNumber, deviceId, installId, _weather, _currentWeather, leadUp, leadUpDays);
          if (_weatherLeadUpKey == null) {
            final createResult = await collection!.document().add(doc);
            _weatherLeadUpKey = createResult.key;
          } else {
            await collection!.document(document_handle: _weatherLeadUpKey).update(doc);
          }
        } catch (e) {
          developer.log('leadup update failed: $e', name: 'ArangoSingleton');
        }
      }
    }
  }

  /// Returns all confirmed flight reports (`flight == 'yes'`) from the last 48
  /// hours across the whole planet, projected to the fields the map needs
  /// (location + size + weather description). Used by MapPage to drop markers.
  Future<List> getRecentFlights() async {
    await _ensureConnected();

    Aql aql = _arangoClient!.aql();
    String query = """
FOR f IN current
FILTER f.`flight` == 'yes'
&& DATE_ISO8601(TO_NUMBER(f.weather.dt) * 1000) >= DATE_ADD(DATE_NOW(), -48, "hour")
RETURN {
    "key": f._key,
    "weather": f.weather.weather[0].description,
    "size": f.size,
    "lat": f.weather.coord.lat,
    "lon": f.weather.coord.lon,
}
""";

    Map<String, dynamic> response = await aql.run(query, batchSize: 1000);
    //print("response=${response}");
    List<dynamic> result = response['result'];
    return result;
  }

  /// Returns confirmed flight reports within ~500 km of [position] from the last
  /// [minutes] minutes (negative or zero normalised to a 30-minute window), with
  /// each row carrying a rounded `distance` in km. Used by the background fetch
  /// to raise "flights near you" notifications.
  Future<List> getRecentFlightsNearMe(Position? position, int minutes) async {
    if (position == null) {
      debugPrint("Could not find last known position!");
      return [];
    }
    if (minutes == 0) {
      minutes = -30;
    }
    if (minutes > 0) {
      minutes = -minutes;
    }

    await _ensureConnected();

    Aql aql = _arangoClient!.aql();
    String query = """
FOR f IN current
FILTER f.`flight` == 'yes'
&& DATE_ISO8601(TO_NUMBER(f.weather.dt) * 1000) >= DATE_ADD(DATE_NOW(), ${minutes}, "minutes")
&& DISTANCE(f.weather.coord.lat, f.weather.coord.lon, ${position.latitude}, ${position.longitude}) < 500 * 1000
RETURN {
    "key": f._key,
    "weather": f.weather.weather[0].description,
    "size": f.size,
    "lat": f.weather.coord.lat,
    "lon": f.weather.coord.lon,
    "distance": ROUND(DISTANCE(f.weather.coord.lat, f.weather.coord.lon, ${position.latitude}, ${position.longitude}) / 1000),
}
""";

    print("getRecentFlightsNearMe: query=${query}");
    Map<String, dynamic> response = await aql.run(query, batchSize: 1000);
    //print("getRecentFlightsNearMe: response=${response}");
    List<dynamic> result = response['result'];
    return result;
  }
}
