import 'package:flutter_test/flutter_test.dart';
import 'package:nuptialflight/controller/nuptials.dart';
import 'package:nuptialflight/responses/onecall_response.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Perfect day', () {
    Daily daily = Daily();
    daily.dt = 1665190800;
    daily.temp = Temp(day: TEMP_AVG, max: TEMP_AVG);
    daily.humidity = HUMIDITY_AVG.round();
    daily.windSpeed = WIND_AVG;
    daily.windGust = WIND_AVG;
    daily.pop = 0.0;
    daily.dewPoint = 12.43;
    daily.clouds = 73; //CLOUD_AVG.round(); // Workaround for model limitation
    daily.pressure = PRESSURE_AVG.round();
    daily.uvi = UVI_STD.round();
    double lat = -35.2;
    double lon = 149.1;

    test('Temperature', () {
      expect(temperatureContribution(daily.temp!.max!), closeTo(1.00, 0.01));
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
      expect(cloudinessContribution(daily.clouds!), closeTo(0.92, 0.01));
    });

    test('Pressure', () {
      expect(pressureContribution(daily.pressure!), closeTo(1.00, 0.01));
    });

    test('Total', () {
      expect(nuptialDailyPercentage(daily), closeTo(1.00, 0.01));
    });

    test('Model', () {
      expect(nuptialDailyPercentageModel(lat, lon, daily), closeTo(0.38, 0.01));
    });
  });

  group('Worst day', () {
    Daily daily = Daily();
    daily.dt = 1665190800;
    daily.temp = Temp(day: 5.0, min: 5.0, max: 5.0, night: 5.0, eve: 5.0, morn: 5.0);
    daily.humidity = 10;
    daily.windSpeed = 30.0;
    daily.windGust = 31.0;
    daily.pop = 1.0;
    daily.dewPoint = 6.43;
    daily.clouds = 20;
    daily.pressure = 995;
    daily.uvi = 3;
    double lat = -35.2;
    double lon = 149.1;

    test('Temperature', () {
      expect(temperatureContribution(daily.temp!.max!), closeTo(0.25, 0.01));
    });

    test('Humidity', () {
      expect(humidityContribution(daily.humidity!), closeTo(0.02, 0.01));
    });

    test('Wind', () {
      expect(windContribution(daily.windSpeed!), closeTo(0.00, 0.01));
    });

    test('Rain', () {
      expect(rainContribution(daily.pop!), closeTo(0.00, 0.01));
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily.clouds!), closeTo(0.09, 0.01));
    });

    test('Pressure', () {
      expect(pressureContribution(daily.pressure!), closeTo(0.20, 0.01));
    });

    test('Total', () {
      expect(nuptialDailyPercentage(daily), closeTo(0.07, 0.01));
    });

    test('Model', () {
      expect(nuptialDailyPercentageModel(lat, lon, daily), closeTo(0.01, 0.01));
    });
  });

  group('Great day', () {
    Daily daily = Daily();
    daily.dt = 1665190800;
    daily.temp = Temp(
        day: 21.53,
        min: 16.97,
        max: 23.65,
        night: 21.53,
        eve: 22.65,
        morn: 18.54);
    daily.humidity = 80;
    daily.windSpeed = WIND_AVG + 2;
    daily.windGust = WIND_AVG + 2;
    daily.pop = 0.05;
    daily.dewPoint = 18.43;
    daily.clouds = 75;
    daily.pressure = 1013;
    daily.uvi = 5;
    double lat = -35.2;
    double lon = 149.1;

    test('Temperature', () {
      expect(temperatureContribution(daily.temp!.max!), closeTo(0.47, 0.01));
    });

    test('Humidity', () {
      expect(humidityContribution(daily.humidity!), closeTo(0.92, 0.01));
    });

    test('Wind', () {
      expect(windContribution(daily.windSpeed!), closeTo(0.69, 0.01));
    });

    test('Rain', () {
      expect(rainContribution(daily.pop!), closeTo(0.95, 0.01));
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily.clouds!), closeTo(0.87, 0.01));
    });

    test('Pressure', () {
      expect(pressureContribution(daily.pressure!), closeTo(0.95, 0.01));
    });

    test('Total', () {
      expect(nuptialDailyPercentage(daily), closeTo(0.82, 0.01));
    });

    test('Model', () {
      expect(nuptialDailyPercentageModel(lat, lon, daily), closeTo(0.44, 0.01));
    });
  });

  group('Ordinary day', () {
    Daily daily = Daily();
    daily.dt = 1665190800;
    daily.temp = Temp(
        day: 22.84,
        min: 16.97,
        max: 26.84,
        night: 21.53,
        eve: 25.65,
        morn: 18.54);
    daily.humidity = 51;
    daily.windSpeed = 4.37;
    daily.windGust = 5.37;
    daily.pop = 0.30;
    daily.dewPoint = 15.43;
    daily.clouds = 80;
    daily.pressure = 1015;
    daily.uvi = 1;
    double lat = -35.2;
    double lon = 149.1;

    test('Temperature', () {
      expect(temperatureContribution(daily.temp!.max!), closeTo(0.30, 0.01));
    });

    test('Humidity', () {
      expect(humidityContribution(daily.humidity!), closeTo(0.38, 0.01));
    });

    test('Wind', () {
      expect(windContribution(daily.windSpeed!), closeTo(0.79, 0.01));
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
      expect(nuptialDailyPercentage(daily), closeTo(0.60, 0.01));
    });

    test('Model', () {
      expect(nuptialDailyPercentageModel(lat, lon, daily), closeTo(0.51, 0.01));
    });
  });

  group('Bad day', () {
    Daily daily = Daily();
    daily.dt = 1665190800;
    daily.temp = Temp(
        day: 6.84, min: 6.97, max: 6.84, night: 1.53, eve: 5.65, morn: 3.54);
    daily.humidity = 40;
    daily.windSpeed = 14.37;
    daily.windGust = 17.37;
    daily.pop = 0.70;
    daily.dewPoint = 3.43;
    daily.clouds = 99;
    daily.pressure = 995;
    daily.uvi = 12;
    double lat = -35.2;
    double lon = 149.1;

    test('Temperature', () {
      expect(temperatureContribution(daily.temp!.max!), closeTo(0.33, 0.01));
    });

    test('Humidity', () {
      expect(humidityContribution(daily.humidity!), closeTo(0.22, 0.01));
    });

    test('Wind', () {
      expect(windContribution(daily.windSpeed!), closeTo(0.08, 0.01));
    });

    test('Rain', () {
      expect(rainContribution(daily.pop!), closeTo(0.30, 0.01));
    });

    test('Cloud Coverage', () {
      expect(cloudinessContribution(daily.clouds!), closeTo(0.33, 0.01));
    });

    test('Pressure', () {
      expect(pressureContribution(daily.pressure!), closeTo(0.20, 0.01));
    });

    test('Total', () {
      expect(nuptialDailyPercentage(daily), closeTo(0.22, 0.01));
    });

    test('Model', () {
      expect(nuptialDailyPercentageModel(lat, lon, daily), closeTo(0.39, 0.01));
    });
  });
}
