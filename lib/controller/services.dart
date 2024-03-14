import 'dart:async';
import 'dart:ui';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
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

// when did we check the last time
DateTime? _lastCheckDate;

Future<void> initializeService() async {
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

  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  await dotenv.load(fileName: 'assets/.env');

  // Register to receive BackgroundFetch events after app is terminated.
  // Requires {stopOnTerminate: false, enableHeadless: true}
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

  // Configure BackgroundFetch.
  try {
    var status = await BackgroundFetch.configure(BackgroundFetchConfig(
        minimumFetchInterval: 15,
        forceAlarmManager: false,
        stopOnTerminate: false,
        startOnBoot: true,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.NONE
    ), _onBackgroundFetch, _onBackgroundFetchTimeout);
    print('[BackgroundFetch] configure success: $status');

    // Schedule a "one-shot" custom-task in 10000ms.
    // These are fairly reliable on Android (particularly with forceAlarmManager) but not iOS,
    // where device must be powered (and delay will be throttled by the OS).
    BackgroundFetch.scheduleTask(TaskConfig(
        taskId: "com.transistorsoft.customtask",
        delay: 10000,
        periodic: false,
        forceAlarmManager: true,
        stopOnTerminate: false,
        enableHeadless: true
    ));
  } on Exception catch(e) {
    print("[BackgroundFetch] configure ERROR: $e");
  }
}

void _onBackgroundFetch(String taskId) async {
  var timestamp = DateTime.now();
  // This is the fetch-event callback.
  print("[BackgroundFetch] Event received: $taskId");

  if (taskId == "flutter_background_fetch") {
    _lastKnownPosition = await Geolocator.getLastKnownPosition();
    await getReportedFlightsNearMe();
    await getServicePercentage();
  }

  // IMPORTANT:  You must signal completion of your fetch task or the OS can punish your app
  // for taking too long in the background.
  BackgroundFetch.finish(taskId);
}

// This event fires shortly before your task is about to timeout.
// You must finish any outstanding work and call BackgroundFetch.finish(taskId).
void _onBackgroundFetchTimeout(String taskId) {
  print("[BackgroundFetch] TIMEOUT: $taskId");
  BackgroundFetch.finish(taskId);
}

// [Android-only] This "Headless Task" is run when the Android app is terminated with `enableHeadless: true`
// Be sure to annotate your callback function to avoid issues in release mode on Flutter >= 3.3.0
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  print('[BackgroundFetch] Headless event received.');

  _lastKnownPosition = await Geolocator.getLastKnownPosition();
  await getReportedFlightsNearMe();
  await getServicePercentage();

  if (taskId == 'flutter_background_fetch') {
    BackgroundFetch.scheduleTask(TaskConfig(
        taskId: "com.transistorsoft.customtask",
        delay: 5000,
        periodic: false,
        forceAlarmManager: false,
        stopOnTerminate: false,
        enableHeadless: true,
    ));
  }
  BackgroundFetch.finish(taskId);
}

Future<void> getReportedFlightsNearMe() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  int minutes;
  if (_lastCheckDate == null) {
    minutes = 30;
  } else {
    DateTime now = DateTime.now();
    minutes = (now.millisecondsSinceEpoch - _lastCheckDate!.millisecondsSinceEpoch) ~/ 1000 ~/ 60;
    _lastCheckDate = now;
  }

  int numFlights = 0;
  int closestDistance = 0;
  await ArangoSingleton().getRecentFlightsNearMe(_lastKnownPosition, -minutes).then((values) {
    debugPrint('getRecentFlightsNearMe: values=$values');
    numFlights = values.length;
    if (numFlights > 0) {
      closestDistance = values.reduce(
          (current, next) => current['distance'] > next['distance'] ? current : next)['distance'];
    }
  });
  debugPrint('getRecentFlightsNearMe: Reported local nuptial flights: $numFlights in $minutes mins');

  if (numFlights > 0) {
    flutterLocalNotificationsPlugin.show(
      notificationIdReport,
      'Current reported local nuptial flight!',
      'There are $numFlights reported flights in the last ${minutes} minutes with the nearest ${closestDistance} km away...',
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

Future<void> getServicePercentage() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (_lastKnownPosition == null) {
    debugPrint('getServicePercentage: Last known position is null');
  } else {
    debugPrint('getServicePercentage: Last known position is ' + _lastKnownPosition.toString());
    WeatherFetcher weatherFetcher = WeatherFetcher();
    weatherFetcher.setPosition(_lastKnownPosition!);
    int percentage = 0;
    await weatherFetcher.fetchWeather().then((OneCallResponse weather) {
      percentage =
          (nuptialDailyPercentageModel(weather.lat!, weather.lon!, weather.daily!.elementAt(0)) *
              100.0)
              .toInt();
    });
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
