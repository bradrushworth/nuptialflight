import 'package:appwidgetflutter/WeatherResponse.dart';
import 'dart:math';

const double WEIGHT_TEMPERATURE = 0.40;
const double WEIGHT_HUMIDITY = 0.30;
const double WEIGHT_WIND = 0.30;

///
/// Returns a value from 0.0 to 1.0 indicating the percentage likeness of
/// a nuptial flight today.
///
double nuptialPercentage(Daily daily) {
  return temperatureContribution(daily) *
      humidityContribution(daily) *
      windContribution(daily) *
      rainContribution(daily) *
      dewPointContribution(daily) *
      cloudinessContribution(daily);
}

/// Evening temperature. Celsius.
double temperatureContribution(Daily daily) {
  return max(0, min(10, daily.temp!.eve! - 15)) / 10.0;
}

/// Humidity, %
double humidityContribution(Daily daily) {
  return (max(0, min(100, daily.humidity!)) / 100.0);
}

/// Wind speed. Units metre/sec
double windContribution(Daily daily) {
  return max(0, min(3, 3 - daily.windSpeed!)) / 3.0;
}

/// Probability of precipitation
double rainContribution(Daily daily) {
  return 1.0 - daily.pop!;
}

/// Atmospheric temperature (varying according to pressure and humidity) below
/// which water droplets begin to condense and dew can form.
double dewPointContribution(Daily daily) {
  return max(0, min(10, daily.temp!.eve! - daily.dewPoint!)) / 10.0;
}

/// Cloudiness, %
double cloudinessContribution(Daily daily) {
  return (100 - daily.clouds!) / 100.0;
}
