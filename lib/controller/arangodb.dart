import 'dart:io';

import 'package:darango/darango.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_device_identifier/mobile_device_identifier.dart';

import '../responses/onecall_response.dart';
import '../responses/weather_response.dart';

class ArangoSingleton {
  static final ArangoSingleton _singleton = ArangoSingleton._privateConstructor();

  // Create client for Arango database
  Database? _arangoClient;
  Future<void>? _connectFuture;
  var _weatherCurrentKey;
  var _weatherHistoricalKey;
  var _weatherFlightsKey;

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

  void createWeather(String? version, String? buildNumber, OneCallResponse? _weather,
      OneCallResponse? _historical, CurrentWeatherResponse? _currentWeather) async {
    await _ensureConnected();

    String? deviceId;
    if (kIsWeb) {
      deviceId = 'web';
    } else if (Platform.isAndroid || Platform.isIOS) {
      deviceId = await MobileDeviceIdentifier().getDeviceId();
    } else {
      deviceId = Platform.localHostname;
    }

    {
      // Let's create a new database post
      Collection? collection = await _arangoClient!.collection('flights');
      Document createResult = await collection!.document().add({
        'flight': 'unknown',
        'version': '$version+$buildNumber',
        'device_id': deviceId,
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
        'weather': _currentWeather!.toJson()
      });
      _weatherCurrentKey = createResult.key;
    }
  }

  void updateWeather(String? version, String? buildNumber, String? size, OneCallResponse? _weather,
      OneCallResponse? _historical, CurrentWeatherResponse? _currentWeather) async {
    await _ensureConnected();

    String? deviceId;
    if (kIsWeb) {
      deviceId = 'web';
    } else if (Platform.isAndroid || Platform.isIOS) {
      deviceId = await MobileDeviceIdentifier().getDeviceId();
    } else {
      deviceId = Platform.localHostname;
    }

    {
      // Let's update the existing database entry
      Collection? collection = await _arangoClient!.collection('flights');
      await collection!.document(document_handle: _weatherFlightsKey).update({
        'flight': size == null ? 'unknown' : 'yes',
        'size': size,
        'version': '$version+$buildNumber',
        'device_id': deviceId,
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
        'weather': _currentWeather!.toJson()
      });
    }
  }

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
