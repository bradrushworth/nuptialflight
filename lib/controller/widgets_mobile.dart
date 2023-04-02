import 'dart:io';

import 'package:home_widget/home_widget.dart';
//import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:nuptialflight/controller/service_percentage.dart' as PercentageService;

void initialiseWidget() {
  if (Platform.isAndroid) {
    HomeWidget.registerBackgroundCallback(backgroundCallback);
  }
  PercentageService.initializeService();
}

void widgetInitState(Function function) {
  HomeWidget.widgetClicked.listen((Uri? uri) => function);
}

// Called when Doing Background Work initiated from Widget
Future<void> backgroundCallback(Uri? uri) async {
  print("backgroundCallback: uri=" + uri.toString());
  if (uri?.host == 'updateweather') {
    int _percentage = 0;
    HomeWidget.getWidgetData<int>('_percentage', defaultValue: _percentage)
        .then((value) {
      _percentage = value!; // Don't do anything for now
      print("backgroundCallback: value=" + value.toString());
      print("backgroundCallback: _percentage=" + _percentage.toString());
      HomeWidget.saveWidgetData<int>('_percentage', _percentage);
      HomeWidget.updateWidget(
          name: 'AppWidgetProvider', iOSName: 'AppWidgetProvider');
    });
    //print("backgroundCallback: _percentage=" + _percentage.toString());
  }
}

Future<void> updateAppWidget(List<int> percentage) async {
  await HomeWidget.saveWidgetData<int>('_percentage', percentage[0]);
  await HomeWidget.updateWidget(
      name: 'AppWidgetProvider', iOSName: 'AppWidgetProvider');
}

Future<void> clearAppWidget() async {
  await HomeWidget.saveWidgetData<int>('_percentage', 0);
  await HomeWidget.updateWidget(
      name: 'AppWidgetProvider', iOSName: 'AppWidgetProvider');
}