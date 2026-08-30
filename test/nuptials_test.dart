import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nuptialflight/controller/nuptials.dart';
import 'package:nuptialflight/responses/onecall_response.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Load the forest models directly from the asset files (rootBundle is
    // not used so plain File IO keeps this fast and reliable in tests).
    Nuptials.loadFromStrings(
      File('assets/final_model.json').readAsStringSync(),
      File('assets/hour_model.json').readAsStringSync(),
    );
  });

  group('Perfect day', () {
    Daily daily = Daily();
    daily.dt = 1665190800;
    daily.temp = Temp(day: 30.0, min: 22.0, max: 32.0, night: 24.0, eve: 29.0, morn: 23.0);
    daily.humidity = 67;
    daily.windSpeed = 1.5;
    daily.windGust = 2.5;
    daily.pop = 0.0;
    daily.dewPoint = 22.0;
    daily.clouds = 95;
    daily.pressure = 1035;
    daily.uvi = UVI_STD.round();
    double lat = -35.2;
    double lon = 149.1;

    test('Temperature', () => expect(temperatureContribution(daily.temp!.max!), closeTo(0.93, 0.01)));
    test('Humidity', () => expect(humidityContribution(daily.humidity!), closeTo(0.88, 0.01)));
    test('Wind', () => expect(windContribution(daily.windSpeed!), closeTo(1.00, 0.01)));
    test('Rain', () => expect(rainContribution(daily.pop!), closeTo(0.34, 0.01)));
    test('Cloud Coverage', () => expect(cloudinessContribution(daily.clouds!), closeTo(0.59, 0.01)));
    test('Pressure', () => expect(pressureContribution(daily.pressure!), closeTo(1.00, 0.01)));
    test('Total', () => expect(nuptialDailyPercentage(daily), closeTo(0.83, 0.01)));
    test('Model', () => expect(nuptialDailyPercentageModel(lat, lon, daily), closeTo(0.61, 0.02)));
  });

  group('Worst day', () {
    Daily daily = Daily();
    daily.dt = 1665190800;
    daily.temp = Temp(day: 3.0, min: 1.0, max: 4.0, night: 1.0, eve: 3.0, morn: 2.0);
    daily.humidity = 10;
    daily.windSpeed = 30.0;
    daily.windGust = 31.0;
    daily.pop = 1.0;
    daily.dewPoint = 1.0;
    daily.clouds = 2;
    daily.pressure = 995;
    daily.uvi = 3;
    double lat = -35.2;
    double lon = 149.1;

    test('Temperature', () => expect(temperatureContribution(daily.temp!.max!), closeTo(0.02, 0.01)));
    test('Humidity', () => expect(humidityContribution(daily.humidity!), closeTo(0.25, 0.01)));
    test('Wind', () => expect(windContribution(daily.windSpeed!), closeTo(0.09, 0.01)));
    test('Rain', () => expect(rainContribution(daily.pop!), closeTo(0.85, 0.01)));
    test('Cloud Coverage', () => expect(cloudinessContribution(daily.clouds!), closeTo(0.95, 0.01)));
    test('Pressure', () => expect(pressureContribution(daily.pressure!), closeTo(0.50, 0.01)));
    test('Total', () => expect(nuptialDailyPercentage(daily), closeTo(0.36, 0.01)));
    test('Model', () => expect(nuptialDailyPercentageModel(lat, lon, daily), closeTo(0.01, 0.01)));
  });

  group('Great day', () {
    Daily daily = Daily();
    daily.dt = 1665190800;
    daily.temp = Temp(day: 26.0, min: 19.0, max: 28.0, night: 21.0, eve: 25.0, morn: 20.0);
    daily.humidity = 70;
    daily.windSpeed = 3.0;
    daily.windGust = 4.5;
    daily.pop = 0.10;
    daily.dewPoint = 19.0;
    daily.clouds = 85;
    daily.pressure = 1024;
    daily.uvi = 5;
    double lat = -35.2;
    double lon = 149.1;

    test('Temperature', () => expect(temperatureContribution(daily.temp!.max!), closeTo(0.84, 0.01)));
    test('Humidity', () => expect(humidityContribution(daily.humidity!), closeTo(0.88, 0.01)));
    test('Wind', () => expect(windContribution(daily.windSpeed!), closeTo(0.96, 0.01)));
    test('Rain', () => expect(rainContribution(daily.pop!), closeTo(0.00, 0.01)));
    test('Cloud Coverage', () => expect(cloudinessContribution(daily.clouds!), closeTo(0.51, 0.01)));
    test('Pressure', () => expect(pressureContribution(daily.pressure!), closeTo(0.43, 0.01)));
    test('Total', () => expect(nuptialDailyPercentage(daily), closeTo(0.70, 0.01)));
    test('Model', () => expect(nuptialDailyPercentageModel(lat, lon, daily), closeTo(0.59, 0.02)));
  });

  group('Ordinary day', () {
    Daily daily = Daily();
    daily.dt = 1665190800;
    daily.temp = Temp(day: 18.0, min: 12.0, max: 20.0, night: 14.0, eve: 17.0, morn: 13.0);
    daily.humidity = 77;
    daily.windSpeed = 5.7;
    daily.windGust = 7.0;
    daily.pop = 0.30;
    daily.dewPoint = 12.0;
    daily.clouds = 70;
    daily.pressure = 1014;
    daily.uvi = 1;
    double lat = -35.2;
    double lon = 149.1;

    test('Temperature', () => expect(temperatureContribution(daily.temp!.max!), closeTo(0.46, 0.01)));
    test('Humidity', () => expect(humidityContribution(daily.humidity!), closeTo(0.56, 0.01)));
    test('Wind', () => expect(windContribution(daily.windSpeed!), closeTo(0.40, 0.01)));
    test('Rain', () => expect(rainContribution(daily.pop!), closeTo(0.20, 0.01)));
    test('Cloud Coverage', () => expect(cloudinessContribution(daily.clouds!), closeTo(0.35, 0.01)));
    test('Pressure', () => expect(pressureContribution(daily.pressure!), closeTo(0.37, 0.01)));
    test('Total', () => expect(nuptialDailyPercentage(daily), closeTo(0.43, 0.01)));
    test('Model', () => expect(nuptialDailyPercentageModel(lat, lon, daily), closeTo(0.49, 0.02)));
  });

  group('Bad day', () {
    Daily daily = Daily();
    daily.dt = 1665190800;
    daily.temp = Temp(day: 8.0, min: 4.0, max: 10.0, night: 5.0, eve: 7.0, morn: 5.0);
    daily.humidity = 95;
    daily.windSpeed = 12.5;
    daily.windGust = 15.0;
    daily.pop = 0.60;
    daily.dewPoint = 6.5;
    daily.clouds = 5;
    daily.pressure = 1004;
    daily.uvi = 12;
    double lat = -35.2;
    double lon = 149.1;

    test('Temperature', () => expect(temperatureContribution(daily.temp!.max!), closeTo(0.04, 0.01)));
    test('Humidity', () => expect(humidityContribution(daily.humidity!), closeTo(0.17, 0.01)));
    test('Wind', () => expect(windContribution(daily.windSpeed!), closeTo(0.09, 0.01)));
    test('Rain', () => expect(rainContribution(daily.pop!), closeTo(0.97, 0.01)));
    test('Cloud Coverage', () => expect(cloudinessContribution(daily.clouds!), closeTo(0.97, 0.01)));
    test('Pressure', () => expect(pressureContribution(daily.pressure!), closeTo(0.43, 0.01)));
    test('Total', () => expect(nuptialDailyPercentage(daily), closeTo(0.34, 0.01)));
    test('Model', () => expect(nuptialDailyPercentageModel(lat, lon, daily), closeTo(0.44, 0.02)));
  });

  group('Hourly Model', () {
    Hourly hourly = Hourly();
    hourly.dt = 1665226800; // 2022-10-08 11:00 UTC -> dayOfYear 281, hour 11
    hourly.temp = 16.4;
    hourly.windSpeed = 5.7;
    hourly.windGust = 7.0;
    hourly.windDeg = 194;
    hourly.humidity = 77;
    hourly.pressure = 1015;
    hourly.dewPoint = 12.0;
    hourly.uvi = 1;
    double lat = -35.2;
    double lon = 149.1;

    test('Model', () {
      // Guards the call-site wiring: hour_model expects 14 features
      // [lat, lon, hemisphere, sin_doy, cos_doy, hour, temp, wind, humid,
      //  press, dewPoint, dew_dep, uvi, windGust] (no rain/cloud/visibility).
      expect(nuptialHourlyPercentageModel(lat, lon, hourly), closeTo(0.43, 0.02));
    });
  });
}