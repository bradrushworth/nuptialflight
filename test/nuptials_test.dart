import 'package:nuptialflight/nuptials.dart';
import 'package:nuptialflight/responses/weather_response.dart';
import 'package:test/test.dart';

void main() {
  group('Perfect day', () {
    Daily daily = Daily();
    daily.temp = Temp(day: TEMP_AVG);
    daily.humidity = HUMIDITY_AVG.round();
    daily.windSpeed = WIND_AVG;
    daily.windGust = WIND_AVG;
    daily.pop = 0.0;
    daily.dewPoint = 18.43;
    daily.clouds = CLOUD_AVG.round();
    daily.pressure = PRESSURE_AVG.round();

    test('Temperature', () {
      expect(temperatureContribution(daily.temp!.day!), closeTo(1.00, 0.01));
    });

    test('Humidity', () {
      expect(humidityContribution(daily.humidity!), closeTo(1.00, 0.01));
    });

    test('Wind', () {
      expect(windContribution(daily.windSpeed!), closeTo(1.00, 0.01));
    });

    test('Rain', () {
      expect(rainContribution(daily.pop!), closeTo(1.00, 0.01));
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily.clouds!), closeTo(1.00, 0.01));
    });

    test('Pressure', () {
      expect(pressureContribution(daily.pressure!), closeTo(1.00, 0.01));
    });

    test('Total', () {
      expect(nuptialDailyPercentage(daily), closeTo(1.00, 0.01));
    });
  });

  group('Worst day', () {
    Daily daily = Daily();
    daily.temp =
        Temp(day: 5.0, min: 5.0, max: 5.0, night: 5.0, eve: 5.0, morn: 5.0);
    daily.humidity = 0;
    daily.windSpeed = 30.0;
    daily.windGust = 31.0;
    daily.pop = 1.0;
    daily.dewPoint = 35;
    daily.clouds = 10;
    daily.pressure = 970;

    test('Temperature', () {
      expect(temperatureContribution(daily.temp!.day!), closeTo(0.27, 0.01));
    });

    test('Humidity', () {
      expect(humidityContribution(daily.humidity!), closeTo(0.01, 0.01));
    });

    test('Wind', () {
      expect(windContribution(daily.windSpeed!), closeTo(0.00, 0.01));
    });

    test('Rain', () {
      expect(rainContribution(daily.pop!), closeTo(0.00, 0.01));
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily.clouds!), closeTo(0.05, 0.01));
    });

    test('Pressure', () {
      expect(pressureContribution(daily.pressure!), closeTo(0.00, 0.01));
    });

    test('Total', () {
      expect(nuptialDailyPercentage(daily), closeTo(0.00, 0.01));
    });
  });

  group('Great day', () {
    Daily daily = Daily();
    daily.temp = Temp(
        day: 18.65,
        min: 16.97,
        max: 23.65,
        night: 21.53,
        eve: 22.65,
        morn: 18.54);
    daily.humidity = 55;
    daily.windSpeed = 5.37;
    daily.windGust = 6.37;
    daily.pop = 0.05;
    daily.dewPoint = 15;
    daily.clouds = 80;
    daily.pressure = 1015;

    test('Temperature', () {
      expect(temperatureContribution(daily.temp!.day!), closeTo(0.79, 0.01));
    });

    test('Humidity', () {
      expect(humidityContribution(daily.humidity!), closeTo(0.50, 0.01));
    });

    test('Wind', () {
      expect(windContribution(daily.windSpeed!), closeTo(0.95, 0.01));
    });

    test('Rain', () {
      expect(rainContribution(daily.pop!), closeTo(0.95, 0.01));
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily.clouds!), closeTo(0.74, 0.01));
    });

    test('Pressure', () {
      expect(pressureContribution(daily.pressure!), closeTo(0.95, 0.01));
    });

    test('Total', () {
      expect(nuptialDailyPercentage(daily), closeTo(0.54, 0.01));
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
    daily.windGust = 2.37;
    daily.pop = 0.30;
    daily.dewPoint = 15;
    daily.clouds = 80;
    daily.pressure = 1015;

    test('Temperature', () {
      expect(temperatureContribution(daily.temp!.day!), closeTo(0.27, 0.01));
    });

    test('Humidity', () {
      expect(humidityContribution(daily.humidity!), closeTo(0.42, 0.01));
    });

    test('Wind', () {
      expect(windContribution(daily.windSpeed!), closeTo(0.38, 0.01));
    });

    test('Rain', () {
      expect(rainContribution(daily.pop!), closeTo(0.70, 0.01));
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily.clouds!), closeTo(0.73, 0.01));
    });

    test('Pressure', () {
      expect(pressureContribution(daily.pressure!), closeTo(0.95, 0.01));
    });

    test('Total', () {
      expect(nuptialDailyPercentage(daily), closeTo(0.07, 0.01));
    });
  });

  group('Bad day', () {
    Daily daily = Daily();
    daily.temp = Temp(
        day: 6.84, min: 6.97, max: 6.84, night: 1.53, eve: 5.65, morn: 3.54);
    daily.humidity = 25;
    daily.windSpeed = 16.37;
    daily.windGust = 17.37;
    daily.pop = 0.70;
    daily.dewPoint = 25;
    daily.clouds = 95;
    daily.pressure = 995;

    test('Temperature', () {
      expect(temperatureContribution(daily.temp!.day!), closeTo(0.35, 0.01));
    });

    test('Humidity', () {
      expect(humidityContribution(daily.humidity!), closeTo(0.09, 0.01));
    });

    test('Wind', () {
      expect(windContribution(daily.windSpeed!), closeTo(0.03, 0.01));
    });

    test('Rain', () {
      expect(rainContribution(daily.pop!), closeTo(0.30, 0.01));
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily.clouds!), closeTo(0.40, 0.01));
    });

    test('Pressure', () {
      expect(pressureContribution(daily.pressure!), closeTo(0.20, 0.01));
    });

    test('Total', () {
      expect(nuptialDailyPercentage(daily), closeTo(0.01, 0.01));
    });
  });
}
