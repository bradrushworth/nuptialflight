import 'package:appwidgetflutter/WeatherResponse.dart';
import 'dart:math';

///
/// Returns a value from 0.0 to 1.0 indicating the percentage likeness of
/// a nuptial flight today.
///
double nuptialPercentage(Daily daily) {
  double temp = temperatureContribution(daily);
  double humid = humidityContribution(daily);
  double wind = windContribution(daily);
  double rain = rainContribution(daily);
  double dewP = dewPointContribution(daily);
  double cloud = cloudinessContribution(daily);
  return max(0.01, min(1.0, temp * humid * wind * rain * dewP * cloud));
}

/// Evening temperature. Celsius.
double temperatureContribution(Daily daily) {
  return max(0, min(10, daily.temp!.eve! - 15) / 10.0);
}

/// Humidity, %
double humidityContribution(Daily daily) {
  return max(0, min(100, daily.humidity!) / 100.0);
}

/// Wind speed. Units metre/sec
double windContribution(Daily daily) {
  return max(0.01, min(3, 3 - daily.windSpeed!) / 3.0);
}

/// Probability of precipitation
double rainContribution(Daily daily) {
  return 1.0 - daily.pop!;
}

/// Atmospheric temperature (varying according to pressure and humidity) below
/// which water droplets begin to condense and dew can form.
double dewPointContribution(Daily daily) {
  return max(0, min(10, daily.temp!.eve! - daily.dewPoint!) / 10.0);
}

/// Cloudiness, %
double cloudinessContribution(Daily daily) {
  return (100 - daily.clouds!) / 100.0;
}
