import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nuptialflight/controller/arangodb.dart';

// this will be used as notification channel id
const notificationChannelId = 'report_flight';

// this will be used for notification id, So you can update your custom notification with this id.
const notificationId = 100;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId, // id
    'Local Nuptial Flight Reports', // title
    description: 'Notify when nearby users report a nuptial flight.', // description
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
      initialNotificationTitle: 'Local Nuptial Flight Reports',
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

  // bring to foreground
  Timer.periodic(const Duration(minutes: 30), (timer) async {
    // Get nuptial updates
    if (true) { //service is AndroidServiceInstance) {
      if (true) { //await service.isForegroundService()) {
        int numFlights = 0;
        int closestDistance = 0;
        await ArangoSingleton().getRecentFlightsNearMe().then((values) {
          debugPrint('values=$values');
          numFlights = values.length;
          if (numFlights > 0) {
            closestDistance = values.reduce((current, next) =>
                current['distance'] > next['distance'] ? current : next)['distance'];
          }
        });
        debugPrint('Reported local nuptial flights: $numFlights');

        if (numFlights > 0) {
          flutterLocalNotificationsPlugin.show(
            notificationId,
            'Current reported local nuptial flight!',
            'There are $numFlights reported flights in the last 30 minutes with the nearest ${closestDistance} km away...',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                notificationChannelId,
                'Local Nuptial Flight Reports',
                icon: 'ic_launcher_foreground',
                ongoing: false,
              ),
            ),
          );
        }
      }
    }
  });
}
