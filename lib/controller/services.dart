import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

import '../main.dart';
import '../responses/onecall_response.dart';
import 'arangodb.dart';
import 'nuptials.dart';
import 'weather_fetcher.dart';
import 'widgets_mobile.dart';

// this will be used as notification channel id
const notificationChannelIdReport = 'report_flight';

// this will be used for notification id, So you can update your custom notification with this id.
const notificationIdReport = 100;

// this will be used as notification channel id
const notificationChannelIdPercentage = 'percentage';

// this will be used for notification id, So you can update your custom notification with this id.
const notificationIdPercentage = 101;

// not allowed to get position in the background
Position? _lastKnownPosition;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channelReport = AndroidNotificationChannel(
    notificationChannelIdReport, // id
    'Nuptial Flight Reports', // title
    description: 'Notify when nearby users report a nuptial flight.', // description
    importance: Importance.high, // importance must be at low or higher level
  );

  const AndroidNotificationChannel channelPercentage = AndroidNotificationChannel(
    notificationChannelIdPercentage, // id
    'Nuptial Flight Percentage', // title
    description: 'Update widget and notify for high nuptial flight percentage.', // description
    importance: Importance.high, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?..createNotificationChannel(channelReport)
    ..createNotificationChannel(channelPercentage);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      autoStartOnBoot: true,
      isForegroundMode: false,

      notificationChannelId: notificationChannelIdReport,
      foregroundServiceNotificationId: notificationIdReport,
      initialNotificationTitle: 'Nuptial Flight Reports',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await dotenv.load(fileName: 'assets/.env');

  _lastKnownPosition = await Geolocator.getLastKnownPosition();

  // bring to foreground
  Timer.periodic(const Duration(minutes: 30), (timer) async {
    // Get nuptial updates
    if (true /*service is AndroidServiceInstance*/) {
      if (true /*await service.isForegroundService()*/) {
        int numFlights = 0;
        int closestDistance = 0;
        Position? position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          position = _lastKnownPosition;
        } else {
          _lastKnownPosition = position;
        }
        await ArangoSingleton().getRecentFlightsNearMe(position).then((values) {
          debugPrint('getRecentFlightsNearMe: values=$values');
          numFlights = values.length;
          if (numFlights > 0) {
            closestDistance = values.reduce((current, next) =>
                current['distance'] > next['distance'] ? current : next)['distance'];
          }
        });
        debugPrint('getRecentFlightsNearMe: Reported local nuptial flights: $numFlights');

        if (numFlights > 0) {
          flutterLocalNotificationsPlugin.show(
            notificationIdReport,
            'Current reported local nuptial flight!',
            'There are $numFlights reported flights in the last 30 minutes with the nearest ${closestDistance} km away...',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                notificationChannelIdReport,
                'Nuptial Flight Reports',
                icon: 'ic_launcher_foreground',
                ongoing: false,
              ),
            ),
          );
        }
      }
    }
  });

  // bring to foreground
  Timer.periodic(const Duration(hours: 8), (timer) async {
    // Get nuptial updates
    if (true /*service is AndroidServiceInstance*/) {
      if (true /*await service.isForegroundService()*/) {
        Position? position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          position = _lastKnownPosition;
        } else {
          _lastKnownPosition = position;
        }
        if (position == null) {
          debugPrint('getServicePercentage: Last known position is null');
        } else {
          debugPrint('getServicePercentage: Last known position is ' + position.toString());
          WeatherFetcher weatherFetcher = WeatherFetcher();
          weatherFetcher.setPosition(position);
          OneCallResponse weather = await weatherFetcher.fetchWeather();
          int percentage = (nuptialDailyPercentageModel(
                      weather.lat!, weather.lon!, weather.daily!.elementAt(0)) *
                  100.0)
              .toInt();
          debugPrint('getServicePercentage: Percentage for nuptial flights: $percentage');
          updateAppWidget([percentage]);

          if (percentage >= greenThreshold) {
            flutterLocalNotificationsPlugin.show(
              notificationIdPercentage,
              'Good weather for a nuptial flight!',
              'The confidence for nuptial flight is $percentage% today...',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  notificationChannelIdPercentage,
                  'Nuptial Flight Percentage',
                  icon: 'ic_launcher_foreground',
                  ongoing: false,
                ),
              ),
            );
          }
        }
      }
    }
  });
}
