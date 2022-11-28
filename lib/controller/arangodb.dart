import 'package:darango/darango.dart';

import '../responses/onecall_response.dart';
import '../responses/weather_response.dart';

class ArangoSingleton {
  static final ArangoSingleton _singleton =
      ArangoSingleton._privateConstructor();

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
    await _arangoClient!
        .connect('nuptialFlight', 'nuptialflight', 'fdggdsgdfstg34wfwfwff');
  }

  void createWeather(
      String? version,
      String? buildNumber,
      OneCallResponse? _weather,
      OneCallResponse? _historical,
      CurrentWeatherResponse? _currentWeather) async {
    {
      // Let's create a new database post
      Collection? collection = await _arangoClient!.collection('flights');
      Document createResult = await collection!.document().add({
        'flight': 'unknown',
        'version': '$version+$buildNumber',
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
        'weather': _currentWeather!.toJson()
      });
      _weatherCurrentKey = createResult.key;
    }
  }

  void updateWeather(
      String? version,
      String? buildNumber,
      String size,
      OneCallResponse? _weather,
      OneCallResponse? _historical,
      CurrentWeatherResponse? _currentWeather) async {
    {
      // Let's update the existing database entry
      Collection? collection = await _arangoClient!.collection('flights');
      await collection!.document(document_handle: _weatherFlightsKey).update({
        'flight': 'yes',
        'size': size,
        'version': '$version+$buildNumber',
        'weather': _weather!.toJson()
      });
    }
    {
      // Let's update the existing database entry
      Collection? collection = await _arangoClient!.collection('historical');
      await collection!
          .document(document_handle: _weatherHistoricalKey)
          .update({
        'flight': 'yes',
        'size': size,
        'version': '$version+$buildNumber',
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
        'weather': _currentWeather!.toJson()
      });
    }
  }

  Future<List> getRecentFlights() async {
    Aql aql = _arangoClient!.aql();
    String query = """
FOR f IN flights
FILTER f.`flight` == 'yes'
&& DATE_FORMAT(TO_NUMBER(f.weather.daily[0].dt)*1000, "%yyyy-%mm-%dd") >= DATE_ADD(DATE_NOW(), -48, "hour")
RETURN {
    "key": f._key,
    "weather": f.weather.daily[0].weather[0].description,
    "size": f.size,
    "lat": f.weather.lat,
    "lon": f.weather.lon
}
""";

    Map<String, dynamic> response = await aql.run(query, batchSize: 1000);
    //print("response=${response}");
    List<dynamic> result = response['result'];
    return result;
  }
}
