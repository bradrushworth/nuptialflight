import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/src/places.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:nuptialflight/responses/onecall_response.dart';
import 'package:nuptialflight/responses/reverse_geocoding_response.dart';
import 'package:nuptialflight/responses/weather_response.dart';

class WeatherFetcher {
  late bool _mockLocation;
  double? _lat;
  double? _lon;

  WeatherFetcher({bool mockLocation = false}) {
    _mockLocation = mockLocation;
  }

  Future<bool> findLocation(bool waitForPosition) async {
    if (!_mockLocation) {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position? position;
        if (kIsWeb || waitForPosition) {
          try {
            position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 30));
          } catch (exception) {
            developer.log("Can't get current position: exception=$exception",
                name: 'WeatherFetcher', error: exception);
          }
        } else if (!kIsWeb) {
          position = await Geolocator.getLastKnownPosition();
        }
        if (position != null) {
          if (_lat == null ||
              _lon == null ||
              _lat!.toStringAsFixed(2) !=
                  position.latitude.toStringAsFixed(2) ||
              _lon!.toStringAsFixed(2) !=
                  position.longitude.toStringAsFixed(2)) {
            // Position has changed
            _lat = position.latitude;
            _lon = position.longitude;
            return true;
          }
        }
        if (_lat == null || _lon == null) {
          throw Exception(
              'Failed to get your location!\n\nPlease manually enter your location.');
        }
        return false;
      } else {
        throw Exception(
            'Location permissions are denied!\n\nPlease manually enter your location.');
      }
    } else {
      _lat = -35.7600;
      _lon = 150.2053;
    }
    return false;
  }

  LatLng? getLocation() {
    if (_lat == null || _lon == null) return null;
    return LatLng(_lat!, _lon!);
  }

  void setLocation(LatLng latLng) {
    _lat = latLng.latitude;
    _lon = latLng.longitude;
    print('setLocation: _lat=$_lat _lon=$_lon');
  }

  void setPosition(Position position) {
    _lat = position.latitude;
    _lon = position.longitude;
    print('setLocation: _lat=$_lat _lon=$_lon');
  }

  void setLocationPlace(PlacesDetailsResponse detail) {
    _lat = detail.result.geometry!.location.lat;
    _lon = detail.result.geometry!.location.lng;
    print('setLocation: _lat=$_lat _lon=$_lon');
  }

  Future<ReverseGeocodingResponse> fetchReverseGeocoding() async {
    if (_lat == null || _lon == null)
      throw Exception(
          'Location is unknown! Perhaps you didn\'t allow location permissions?');

    String url =
        'https://api.openweathermap.org/geo/1.0/reverse?lat=${_lat!.toStringAsFixed(4)}&lon=${_lon!.toStringAsFixed(4)}&appid=${dotenv.env['OPENWEATHERMAP_API_KEY']}&limit=1';
    print("url=$url");

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      List json = jsonDecode(response.body);
      if (json.length != 1) {
        throw Exception('Unexpected reverse geocoding response!');
      }
      return ReverseGeocodingResponse.fromJson(json.first);
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load reverse geocoding!\n\n' + response.body);
    }
  }

  Future<CurrentWeatherResponse> fetchNearestWeatherLocation() async {
    if (_lat == null || _lon == null)
      throw Exception(
          'Location is unknown! Perhaps you didn\'t allow location permissions?');

    String url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$_lat&lon=$_lon&appid=${dotenv.env['OPENWEATHERMAP_API_KEY']}&units=metric&mode=json';
    print("url=$url");

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return CurrentWeatherResponse.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to download current weather!\n\n' + response.body);
    }
  }

  Future<OneCallResponse> fetchWeather() async {
    if (_lat == null || _lon == null)
      throw Exception('Location is unknown! Perhaps you didn\'t allow location permissions?');

    String url =
        'https://api.openweathermap.org/data/3.0/onecall?lat=$_lat&lon=$_lon&appid=${dotenv.env['OPENWEATHERMAP_API_KEY']}&units=metric&exclude=minutely,current';
    print("url=$url");

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return OneCallResponse.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to download weather!\n\n' + response.body);
    }
  }

  Future<OneCallResponse> fetchHistoricalWeather(int dt) async {
    if (_lat == null || _lon == null)
      throw Exception(
          'Location is unknown! Perhaps you didn\'t allow location permissions?');

    String url =
        'https://api.openweathermap.org/data/3.0/onecall/timemachine?lat=$_lat&lon=$_lon&appid=${dotenv.env['OPENWEATHERMAP_API_KEY']}&units=metric&dt=$dt';
    print("url=$url");

    final response = await http.get(Uri.parse(url));
    print("WeatherFetcher: response=${response.body}");

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return OneCallResponse.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to download historical weather!\n\n' + response.body);
    }
  }
}
