import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nuptialflight/controller/nuptials.dart';
import 'package:nuptialflight/controller/weather_fetcher.dart';
import 'package:nuptialflight/controller/widgets_mobile.dart';
import 'package:nuptialflight/main.dart';
import 'package:nuptialflight/responses/onecall_response.dart';

// this will be used as notification channel id
const notificationChannelId = 'percentage';

// this will be used for notification id, So you can update your custom notification with this id.
const notificationId = 101;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId, // id
    'Nuptial Flight Percentage', // title
    description: 'Update widget and notify for high nuptial flight percentage.', // description
    importance: Importance.high, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      autoStartOnBoot: true,
      isForegroundMode: false,

      notificationChannelId: notificationChannelId,
      foregroundServiceNotificationId: notificationId,
      initialNotificationTitle: 'Nuptial Flight Percentage',
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

  // bring to foreground
  Timer.periodic(const Duration(hours: 12), (timer) async {
    // Get nuptial updates
    if (true /*service is AndroidServiceInstance*/) {
      if (true /*await service.isForegroundService()*/) {
        WeatherFetcher weatherFetcher = WeatherFetcher();
        Position? position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          debugPrint('Last known position is null');
        } else {
          weatherFetcher.setPosition(position!);
          OneCallResponse weather = await weatherFetcher.fetchWeather();
          int percentage =
          (nuptialDailyPercentageModel(weather.lat!, weather.lon!, weather.daily!.elementAt(0)) *
              100.0)
              .toInt();
          debugPrint('Percentage for nuptial flights: $percentage');
          updateAppWidget([percentage]);

          if (percentage >= greenThreshold) {
            flutterLocalNotificationsPlugin.show(
              notificationId,
              'Good weather for a nuptial flight!',
              'The confidence for nuptial flight is $percentage% today...',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  notificationChannelId,
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
