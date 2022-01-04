import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appwidgetflutter/weather_response.dart';
import 'package:http/http.dart' as http;

import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;

Future<WeatherResponse> fetchWeather({bool mockLocation = false}) async {
  String? lat;
  String? lon;

  if (!mockLocation) {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        lat = position.latitude.toStringAsFixed(3);
        lon = position.longitude.toStringAsFixed(3);
      }
    }
  } else {
    lat = '-35.7600';
    lon = '150.2053';
  }

  if (lat == null || lon == null) {
    throw Exception('Failed to get location');
  }

  String url =
      'https://api.openweathermap.org/data/2.5/onecall?lat=$lat&lon=$lon&appid=23237726d847507a463472930ed2a5d8&units=metric&exclude=minutely,hourly,current';
  developer.log("url=$url", name: 'weather');
  stdout.writeln("url=$url");

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
