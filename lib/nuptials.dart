import 'dart:math';

//import 'dart:developer' as developer;
import 'package:normal/normal.dart';
import 'package:nuptialflight/responses/weather_response.dart';
//import 'package:collection/collection.dart';

///
/// https://www.antwiki.org/wiki/images/d/dd/Boomsma%2C_J.J.%2C_Leusink%2C_A._1981._Weather_conditions_during_nuptial_flights_of_four_European_ant_species_.pdf
/// https://antwiki.org/wiki/images/5/50/Depa%2C_L._2006._Weather_conditions_during_nuptial_flight_of_Manica_rubida.pdf
/// https://onlinelibrary.wiley.com/doi/epdf/10.1111/ecog.03140
///
const double TEMP_AVG = 24.00;
const double TEMP_STD = 3.96;
const double HUMIDITY_AVG = 62.00;
const double HUMIDITY_STD = 7.99;
const double WIND_AVG = 3.96;
const double WIND_STD = 0.78;
const double RAIN_AVG = 0;
const double RAIN_STD = 0;
const double CLOUD_AVG = 0;
const double CLOUD_STD = 0;
const double PRESSURE_AVG = 1020;
const double PRESSURE_STD = 14.85;
const double RADIATION_AVG = 225.7; // (J.cm-2.h-1)
const double RADIATION_STD = 19.5; // SE not SD

double nuptialHourlyPercentage(Hourly hourly) {
  double temp = temperatureContribution(hourly.temp!);
  double wind = windContribution(hourly.windSpeed!);
  double rain = rainContribution(hourly.pop!);
  double humid = humidityContribution(hourly.humidity!);
  double cloud = cloudinessContribution(hourly.clouds!);
  double press = pressureContribution(hourly.pressure!);
  // developer.log("dt=" + daily.dt.toString(), name: 'nuptialPercentage');
  // developer.log("temp=$temp", name: 'nuptialPercentage');
  // developer.log("wind=$wind", name: 'nuptialPercentage');
  // developer.log("humid=$humid", name: 'nuptialPercentage');
  // developer.log("rain=$rain", name: 'nuptialPercentage');
  // developer.log("cloud=$cloud", name: 'nuptialPercentage');
  // developer.log("press=$press", name: 'nuptialPercentage');
  var values = [
    {'percentage': temp * wind * rain, 'weighting': 1},
    {'percentage': temp * wind * humid, 'weighting': 1},
    {'percentage': temp * wind * cloud, 'weighting': 1},
    {'percentage': temp * wind * press, 'weighting': 1},
  ];
  return nuptialCalculator(values);
}

double nuptialDailyPercentage(Daily daily, {bool nocturnal = false}) {
  double temp =
      temperatureContribution(nocturnal ? daily.temp!.eve! : daily.temp!.day!);
  double windSpeed = windContribution(daily.windSpeed!);
  double windGust = windContribution(daily.windGust!);
  double rain = rainContribution(daily.pop!);
  double humid = humidityContribution(daily.humidity!);
  double cloud = cloudinessContribution(daily.clouds!);
  double press = pressureContribution(daily.pressure!);
  // developer.log("dt=" + daily.dt.toString(), name: 'nuptialPercentage');
  // developer.log("temp=$temp", name: 'nuptialPercentage');
  // developer.log("windSpeed=windSpeed", name: 'nuptialPercentage');
  // developer.log("windGust=windGust", name: 'nuptialPercentage');
  // developer.log("humid=$humid", name: 'nuptialPercentage');
  // developer.log("rain=$rain", name: 'nuptialPercentage');
  // developer.log("cloud=$cloud", name: 'nuptialPercentage');
  // developer.log("press=$press", name: 'nuptialPercentage');
  var values = [
    {'percentage': temp * windGust * rain, 'weighting': 1},
    {'percentage': temp * windSpeed * humid, 'weighting': 1},
    {'percentage': temp * windSpeed * cloud, 'weighting': 1},
    {'percentage': temp * windSpeed * press, 'weighting': 1},
  ];
  return nuptialCalculator(values);
}

///
/// Returns a value from 0.0 to 1.0 indicating the percentage likeness of
/// a nuptial flight today.
///
double nuptialCalculator(List<Map<String, num>> values) {
  var sum = values
      .map((m) => m['percentage']! * m['weighting']!)
      .reduce((a, b) => a + b);
  var count = values.map((e) => e['weighting']!).reduce((a, b) => a + b);
  var result = sum / count;
  // developer.log("sum=$sum", name: 'nuptialPercentage');
  // developer.log("count=$count", name: 'nuptialPercentage');
  // developer.log("result=$result", name: 'nuptialPercentage');
  return max(0.01, min(1.0, result));
}

/// Evening temperature. Celsius.
double temperatureContribution(num temp) {
  // z = (x – μ (mean)) / σ (standard deviation)
  if (temp > TEMP_AVG) return 1.0;
  return max(0, min(0.5, Normal.cdf(-(temp - TEMP_AVG).abs() / TEMP_STD))) * 2;
}

/// Humidity, %
double humidityContribution(num humidity) {
  return max(
          0,
          min(0.5,
              Normal.cdf(-(humidity - HUMIDITY_AVG).abs() / HUMIDITY_STD))) *
      2;
}

/// Wind speed. Units metre/sec
double windContribution(num windSpeed) {
  //return max(0.01, min(3, 3 - daily.windSpeed!) / 3.0);
  if (windSpeed < WIND_AVG) return 1.0;
  return max(
          0, min(0.5, Normal.cdf(-(windSpeed - WIND_AVG).abs() / WIND_STD))) *
      2;
}

/// Probability of precipitation
double rainContribution(num pop) {
  return 1.0 - pop;
}

/// Atmospheric temperature (varying according to pressure and humidity) below
/// which water droplets begin to condense and dew can form.
// double dewPointContribution(num dewPoint) {
//   return max(0, min(10, daily.temp!.eve! - dewPoint) / 10.0);
// }

/// Cloudiness, %
double cloudinessContribution(num clouds) {
  return (100 - clouds) / 100.0;
}

/// Air pressure (hPa)
double pressureContribution(num pressure) {
  return max(
          0,
          min(0.5,
              Normal.cdf(-(pressure - PRESSURE_AVG).abs() / PRESSURE_STD))) *
      2;
}
