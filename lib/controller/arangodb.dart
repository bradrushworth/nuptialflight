import 'dart:io';

import 'package:darango/darango.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_device_identifier/mobile_device_identifier.dart';

import '../responses/onecall_response.dart';
import '../responses/weather_response.dart';

class ArangoSingleton {
  static final ArangoSingleton _singleton = ArangoSingleton._privateConstructor();

  // Create client for Arango database
  Database? _arangoClient;
  var _weatherCurrentKey;
  var _weatherHistoricalKey;
  var _weatherFlightsKey;

  factory ArangoSingleton() {
    return _singleton;
  }

  ArangoSingleton._privateConstructor() {
    init();
  }

  void init() async {
    _arangoClient = Database('https://api.bitbot.com.au:8530');
    await _arangoClient!.connect('nuptialFlight', 'nuptialflight', 'fdggdsgdfstg34wfwfwff');
  }

  void createWeather(String? version, String? buildNumber, OneCallResponse? _weather,
      OneCallResponse? _historical, CurrentWeatherResponse? _currentWeather) async {

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

  void updateWeather(String? version, String? buildNumber, String size, OneCallResponse? _weather,
      OneCallResponse? _historical, CurrentWeatherResponse? _currentWeather) async {
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
        'flight': 'yes',
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
        'flight': 'yes',
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
        'flight': 'yes',
        'size': size,
        'version': '$version+$buildNumber',
        'device_id': deviceId,
        'weather': _currentWeather!.toJson()
      });
    }
  }

  Future<List> getRecentFlights() async {
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

  Future<List> getRecentFlightsNearMe(Position? position) async {
    if (position == null) {
      debugPrint("Could not find last known position!");
      return [];
    }
    Aql aql = _arangoClient!.aql();
    String query = """
FOR f IN current
FILTER f.`flight` == 'yes'
&& DATE_ISO8601(TO_NUMBER(f.weather.dt) * 1000) >= DATE_ADD(DATE_NOW(), -30, "minutes")
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
