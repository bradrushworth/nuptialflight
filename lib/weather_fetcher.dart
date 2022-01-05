import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:nuptialflight/responses/reverse_geocoding_response.dart';
import 'package:nuptialflight/responses/weather_response.dart';

class WeatherFetcher {
  late bool _mockLocation;
  String? _lat;
  String? _lon;

  WeatherFetcher({bool mockLocation = false}) {
    _mockLocation = mockLocation;
  }

  Future getLocation() async {
    if (!_mockLocation) {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 5));
        } catch (exception) {
          developer.log("Can't get current position: exception=$exception",
              name: 'WeatherFetcher');
          if (!kIsWeb) position = await Geolocator.getLastKnownPosition();
        }
        if (position != null) {
          _lat = position.latitude.toStringAsFixed(4);
          _lon = position.longitude.toStringAsFixed(4);
        } else {
          throw Exception('Failed to get location');
        }
      }
    } else {
      _lat = '-35.7600';
      _lon = '150.2053';
    }
  }

  Future<ReverseGeocodingResponse> fetchReverseGeocoding() async {
    if (_lat == null || _lon == null) throw Exception('Failed to get location');

    String url =
        'https://api.openweathermap.org/geo/1.0/reverse?lat=$_lat&lon=$_lon&appid=${dotenv.env['OPENWEATHERMAP_API_KEY']}&limit=1';
    developer.log("url=$url", name: 'weather');
    if (!kIsWeb) stdout.writeln("url=$url");

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      List json = jsonDecode(response.body);
      if (json.length != 1) {
        throw Exception('Unexpected reverse geocoding response');
      }
      return ReverseGeocodingResponse.fromJson(json.first);
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load reverse geocoding');
    }
  }

  Future<String> fetchNearestWeatherLocation() async {
    if (_lat == null || _lon == null) throw Exception('Failed to get location');

    String url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$_lat&lon=$_lon&appid=${dotenv.env['OPENWEATHERMAP_API_KEY']}&units=metric&mode=json';
    developer.log("url=$url", name: 'WeatherFetcher');
    if (!kIsWeb) stdout.writeln("url=$url");

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map json = jsonDecode(response.body);
      if (!json.containsKey('name')) {
        //throw Exception('Unexpected reverse geocoding response');
        developer.log("Unexpected reverse geocoding response",
            name: 'WeatherFetcher');
        return "Unknown Location";
      }
      return json['name'];
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      //throw Exception('Failed to load reverse geocoding');
      developer.log("Failed to load reverse geocoding", name: 'WeatherFetcher');
      return "Unknown Location";
    }
  }

  Future<WeatherResponse> fetchWeather() async {
    if (_lat == null || _lon == null) throw Exception('Failed to get location');

    String url =
        'https://api.openweathermap.org/data/2.5/onecall?lat=$_lat&lon=$_lon&appid=${dotenv.env['OPENWEATHERMAP_API_KEY']}&units=metric&exclude=minutely,hourly,current';
    developer.log("url=$url", name: 'WeatherFetcher');
    if (!kIsWeb) stdout.writeln("url=$url");

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return WeatherResponse.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load weather');
    }
  }
}
