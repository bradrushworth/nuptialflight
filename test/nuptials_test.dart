import 'package:nuptialflight/responses/weather_response.dart';
import 'package:nuptialflight/nuptials.dart';
import 'package:test/test.dart';

void main() {
  group('Perfect day', () {
    Daily daily = Daily();
    daily.temp = Temp(eve: TEMP_AVG);
    daily.humidity = HUMIDITY_AVG.round();
    daily.windSpeed = WIND_AVG;
    daily.pop = 0.0;
    daily.dewPoint = 18.43;
    daily.clouds = 0;
    daily.pressure = PRESSURE_AVG.round();

    test('Temperature', () {
      expect(temperatureContribution(daily), closeTo(1.00, 0.01));
    });

    test('Humidity', () {
      expect(humidityContribution(daily), closeTo(1.00, 0.01));
    });

    test('Wind', () {
      expect(windContribution(daily), closeTo(1.00, 0.01));
    });

    test('Rain', () {
      expect(rainContribution(daily), closeTo(1.00, 0.01));
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily), closeTo(1.00, 0.01));
    });

    test('Pressure', () {
      expect(pressureContribution(daily), closeTo(1.00, 0.01));
    });

    test('Total', () {
      expect(nuptialPercentage(daily), closeTo(1.00, 0.01));
    });
  });

  group('Worst day', () {
    Daily daily = Daily();
    daily.temp = Temp(
        day: 10.0, min: 10.0, max: 10.0, night: 10.0, eve: 10.0, morn: 10.0);
    daily.humidity = 0;
    daily.windSpeed = 30.0;
    daily.pop = 1.0;
    daily.dewPoint = 35;
    daily.clouds = 100;
    daily.pressure = 970;

    test('Temperature', () {
      expect(temperatureContribution(daily), closeTo(0.00, 0.01));
    });

    test('Humidity', () {
      expect(humidityContribution(daily), closeTo(0.00, 0.01));
    });

    test('Wind', () {
      expect(windContribution(daily), closeTo(0.00, 0.01));
    });

    test('Rain', () {
      expect(rainContribution(daily), closeTo(0.00, 0.01));
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily), closeTo(0.00, 0.01));
    });

    test('Pressure', () {
      expect(pressureContribution(daily), closeTo(0.00, 0.01));
    });

    test('Total', () {
      expect(nuptialPercentage(daily), closeTo(0.00, 0.01));
    });
  });

  group('Great day', () {
    Daily daily = Daily();
    daily.temp = Temp(
        day: 29.84,
        min: 16.97,
        max: 29.84,
        night: 21.53,
        eve: 23.65,
        morn: 18.54);
    daily.humidity = 55;
    daily.windSpeed = 0.37;
    daily.pop = 0.05;
    daily.dewPoint = 15;
    daily.clouds = 20;
    daily.pressure = 1023;

    test('Temperature', () {
      expect(temperatureContribution(daily), closeTo(0.93, 0.01));
    });

    test('Humidity', () {
      expect(humidityContribution(daily), closeTo(0.38, 0.01));
    });

    test('Wind', () {
      expect(windContribution(daily), closeTo(1.00, 0.01));
    });

    test('Rain', () {
      expect(rainContribution(daily), closeTo(0.95, 0.01));
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily), closeTo(0.80, 0.01));
    });

    test('Pressure', () {
      expect(pressureContribution(daily), closeTo(0.84, 0.01));
    });

    test('Total', () {
      expect(nuptialPercentage(daily), closeTo(0.69, 0.01));
    });
  });

  group('Ordinary day', () {
    Daily daily = Daily();
    daily.temp = Temp(
        day: 26.84,
        min: 16.97,
        max: 26.84,
        night: 21.53,
        eve: 25.65,
        morn: 18.54);
    daily.humidity = 51;
    daily.windSpeed = 1.37;
    daily.pop = 0.30;
    daily.dewPoint = 15;
    daily.clouds = 20;
    daily.pressure = 1015;

    test('Temperature', () {
      expect(temperatureContribution(daily), closeTo(1.00, 0.01));
    });

    test('Humidity', () {
      expect(humidityContribution(daily), closeTo(0.17, 0.01));
    });

    test('Wind', () {
      expect(windContribution(daily), closeTo(1.00, 0.01));
    });

    test('Rain', () {
      expect(rainContribution(daily), closeTo(0.70, 0.01));
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily), closeTo(0.80, 0.01));
    });

    test('Pressure', () {
      expect(pressureContribution(daily), closeTo(0.74, 0.01));
    });

    test('Total', () {
      expect(nuptialPercentage(daily), closeTo(0.60, 0.01));
    });
  });

  group('Bad day', () {
    Daily daily = Daily();
    daily.temp = Temp(
        day: 16.84,
        min: 6.97,
        max: 16.84,
        night: 11.53,
        eve: 15.65,
        morn: 8.54);
    daily.humidity = 25;
    daily.windSpeed = 6.37;
    daily.pop = 0.70;
    daily.dewPoint = 25;
    daily.clouds = 65;
    daily.pressure = 1005;

    test('Temperature', () {
      expect(temperatureContribution(daily), closeTo(0.03, 0.01));
    });

    test('Humidity', () {
      expect(humidityContribution(daily), closeTo(0.00, 0.01));
    });

    test('Wind', () {
      expect(windContribution(daily), closeTo(0.01, 0.01));
    });

    test('Rain', () {
      expect(rainContribution(daily), closeTo(0.30, 0.01));
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily), closeTo(0.35, 0.01));
    });

    test('Pressure', () {
      expect(pressureContribution(daily), closeTo(0.31, 0.01));
    });

    test('Total', () {
      expect(nuptialPercentage(daily), closeTo(0.01, 0.01));
    });
  });
}
