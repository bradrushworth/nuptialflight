import 'dart:io';

import 'package:home_widget/home_widget.dart';

void initialiseWidget() {
  if (Platform.isAndroid) {
    HomeWidget.registerBackgroundCallback(backgroundCallback);
  }
  if (Platform.isIOS) {
    // The iOS widget extension (ios/NuptialWidget) reads the percentage from
    // this shared App Group — must match appGroupId in NuptialWidget.swift
    // and both entitlements files.
    HomeWidget.setAppGroupId('group.au.com.bitbot.nuptialflight');
  }
}

void widgetInitState(Function function) {
  // NB: must invoke the callback — passing the bare reference silently did
  // nothing when the home-screen widget was tapped.
  HomeWidget.widgetClicked.listen((Uri? uri) => function());
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
          name: 'AppWidgetProvider', iOSName: 'NuptialWidget');
    });
    //print("backgroundCallback: _percentage=" + _percentage.toString());
  }
}

/// Pushes today's outlook to the home-screen widget. [percentage] keeps the
/// legacy key the iOS widget reads; the Android widget prefers the Ant Flight
/// Index fields — [bandKey] is the FlightBand enum name, [bandLabel] and
/// [oddsText] arrive pre-localized because the RemoteViews side has no access
/// to the Flutter localizations.
Future<void> updateAppWidget(
  int percentage, {
  String bandKey = '',
  String bandLabel = '',
  String oddsText = '',
}) async {
  await HomeWidget.saveWidgetData<int>('_percentage', percentage);
  await HomeWidget.saveWidgetData<String>('_band', bandKey);
  await HomeWidget.saveWidgetData<String>('_band_label', bandLabel);
  await HomeWidget.saveWidgetData<String>('_odds', oddsText);
  await HomeWidget.updateWidget(
      name: 'AppWidgetProvider', iOSName: 'NuptialWidget');
}

Future<void> clearAppWidget() async {
  await updateAppWidget(0);
}
