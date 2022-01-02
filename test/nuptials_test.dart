// Import the test package and Counter class
import 'package:appwidgetflutter/WeatherResponse.dart';
import 'package:test/test.dart';
import 'package:appwidgetflutter/nuptials.dart';

void main() {
  group('Perfect day', () {
    Daily daily = Daily();
    daily.temp = Temp(
        day: 30.0, min: 30.0, max: 30.0, night: 30.0, eve: 30.0, morn: 30.0);
    daily.humidity = 100;
    daily.windSpeed = 0.0;
    daily.pop = 0.0;
    daily.dewPoint = 18.43;
    daily.clouds = 0;

    test('Temperature', () {
      expect(temperatureContribution(daily), 1.0);
    });

    test('Humidity', () {
      expect(humidityContribution(daily), 1.0);
    });

    test('Wind', () {
      expect(windContribution(daily), 1.0);
    });

    test('Rain', () {
      expect(rainContribution(daily), 1.0);
    });

    test('Dew Point', () {
      expect(dewPointContribution(daily), 1.0);
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily), 1.0);
    });

    test('Total', () {
      expect(nuptialPercentage(daily), 1.0);
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

    test('Temperature', () {
      expect(temperatureContribution(daily), 0.0);
    });

    test('Humidity', () {
      expect(humidityContribution(daily), 0.0);
    });

    test('Wind', () {
      expect(windContribution(daily), 0.0);
    });

    test('Rain', () {
      expect(rainContribution(daily), 0.0);
    });

    test('Dew Point', () {
      expect(dewPointContribution(daily), 0.0);
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily), 0.0);
    });

    test('Total', () {
      expect(nuptialPercentage(daily), 0.0);
    });
  });

  group('Great day', () {
    Daily daily = Daily();
    daily.temp = Temp(
        day: 29.84,
        min: 16.97,
        max: 29.84,
        night: 21.53,
        eve: 29.65,
        morn: 18.54);
    daily.humidity = 85;
    daily.windSpeed = 0.37;
    daily.pop = 0.05;
    daily.dewPoint = 15;
    daily.clouds = 20;

    test('Temperature', () {
      expect(temperatureContribution(daily), 1.0);
    });

    test('Humidity', () {
      expect(humidityContribution(daily), 0.85);
    });

    test('Wind', () {
      expect(windContribution(daily), 0.8766666666666666);
    });

    test('Rain', () {
      expect(rainContribution(daily), 0.95);
    });

    test('Dew Point', () {
      expect(dewPointContribution(daily), 1.0);
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily), 0.8);
    });

    test('Total', () {
      expect(nuptialPercentage(daily), 0.5663266666666665);
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
    daily.humidity = 61;
    daily.windSpeed = 1.37;
    daily.pop = 0.30;
    daily.dewPoint = 15;
    daily.clouds = 20;

    test('Temperature', () {
      expect(temperatureContribution(daily), 1.0);
    });

    test('Humidity', () {
      expect(humidityContribution(daily), 0.61);
    });

    test('Wind', () {
      expect(windContribution(daily), 0.5433333333333333);
    });

    test('Rain', () {
      expect(rainContribution(daily), 0.7);
    });

    test('Dew Point', () {
      expect(dewPointContribution(daily), 1.0);
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily), 0.8);
    });

    test('Total', () {
      expect(nuptialPercentage(daily), 0.18560266666666664);
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
    daily.humidity = 11;
    daily.windSpeed = 6.37;
    daily.pop = 0.70;
    daily.dewPoint = 25;
    daily.clouds = 65;

    test('Temperature', () {
      expect(temperatureContribution(daily), 0.06500000000000003);
    });

    test('Humidity', () {
      expect(humidityContribution(daily), 0.11);
    });

    test('Wind', () {
      expect(windContribution(daily), 0.0);
    });

    test('Rain', () {
      expect(rainContribution(daily), 0.30000000000000004);
    });

    test('Dew Point', () {
      expect(dewPointContribution(daily), 0.0);
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily), 0.35);
    });

    test('Total', () {
      expect(nuptialPercentage(daily), 0.0);
    });
  });
}
