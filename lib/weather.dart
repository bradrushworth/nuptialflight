import 'dart:async';
import 'dart:convert';

import 'package:appwidgetflutter/WeatherResponse.dart';
import 'package:http/http.dart' as http;

Future<WeatherResponse> fetchWeather() async {
  final response = await http
      .get(Uri.parse('https://api.openweathermap.org/data/2.5/onecall?lat=-35.7600&lon=150.2053&appid=23237726d847507a463472930ed2a5d8&units=metric&exclude=minutely,hourly,current'));

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
