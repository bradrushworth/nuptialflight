import 'dart:async';
import 'dart:ui';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_widget/home_widget.dart';

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

bool _isServiceInitialized = false;

Future<void> _ensureInitialized() async {
  if (_isServiceInitialized) return;

  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (e) {
    debugPrint("Failed to load dotenv in background: $e");
  }

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

  // Initialize Flutter Local Notifications Plugin
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_launcher_foreground');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?..createNotificationChannel(channelReport)
    ..createNotificationChannel(channelPercentage);

  _isServiceInitialized = true;
}

Future<void> initializeService() async {
  await _ensureInitialized();

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

Future<void> _updatePosition() async {
  try {
    _lastKnownPosition = await Geolocator.getLastKnownPosition();
  } catch (e) {
    debugPrint("Failed to get last known position: $e");
  }

  if (_lastKnownPosition == null) {
    try {
      _lastKnownPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 10)));
    } catch (e) {
      debugPrint("Failed to get current position actively: $e");
    }
  }

  if (_lastKnownPosition == null) {
    try {
      final double? lat = await HomeWidget.getWidgetData<double>('last_latitude');
      final double? lon = await HomeWidget.getWidgetData<double>('last_longitude');
      if (lat != null && lon != null) {
        _lastKnownPosition = Position(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
        debugPrint("Restored last known location from cache: $_lastKnownPosition");
      }
    } catch (e) {
      debugPrint("Failed to read location cache: $e");
    }
  } else {
    try {
      await HomeWidget.saveWidgetData<double>('last_latitude', _lastKnownPosition!.latitude);
      await HomeWidget.saveWidgetData<double>('last_longitude', _lastKnownPosition!.longitude);
    } catch (e) {
      debugPrint("Failed to save position to cache: $e");
    }
  }
}

void _onBackgroundFetch(String taskId) async {
  // This is the fetch-event callback.
  print("[BackgroundFetch] Event received: $taskId");

  await _ensureInitialized();

  if (taskId == "flutter_background_fetch" || taskId == "com.transistorsoft.customtask") {
    await _updatePosition();
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
void backgroundFetchHeadlessTask(HeadlessEvent task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  print('[BackgroundFetch] Headless event received: $taskId');

  await _ensureInitialized();

  await _updatePosition();
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
  DateTime now = DateTime.now();
  String? lastCheckStr;
  try {
    lastCheckStr = await HomeWidget.getWidgetData<String>('last_check_date');
  } catch (e) {
    debugPrint("Failed to get last_check_date: $e");
  }

  if (lastCheckStr == null) {
    minutes = 30;
  } else {
    try {
      DateTime lastCheck = DateTime.parse(lastCheckStr);
      minutes = (now.millisecondsSinceEpoch - lastCheck.millisecondsSinceEpoch) ~/ 1000 ~/ 60;
    } catch (e) {
      minutes = 30;
    }
  }

  try {
    await HomeWidget.saveWidgetData<String>('last_check_date', now.toIso8601String());
  } catch (e) {
    debugPrint("Failed to save last_check_date: $e");
  }

  if (minutes <= 0) minutes = 30;

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
      id: notificationIdReport,
      title: 'Current reported local nuptial flight!',
      body: 'There are $numFlights reported flights in the last ${minutes} minutes with the nearest ${closestDistance} km away...',
      notificationDetails: const NotificationDetails(
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
        id: notificationIdPercentage,
        title: 'Good weather for a nuptial flight!',
        body: 'The confidence for nuptial flight is $percentage% today...',
        notificationDetails: const NotificationDetails(
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
