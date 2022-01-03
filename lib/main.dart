import 'package:appwidgetflutter/WeatherResponse.dart';
import 'package:appwidgetflutter/weather.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
//import 'package:spectrum/spectrum.dart';

import 'nuptials.dart';

DateFormat dateFormat = DateFormat("yyyy-MM-dd");

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerBackgroundCallback(backgroundCallback);
  runApp(MyApp());
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

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nuptial Flight Predictor',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blueGrey,
      ),
      home: MyHomePage(title: 'Nuptial Flight Predictor'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<WeatherResponse>? _futureWeather;
  WeatherResponse? _weather;
  List<int> _percentage = [0, 0, 0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    HomeWidget.widgetClicked.listen((Uri? uri) => loadData());
    loadData(); // This will load data from widget every time app is opened
  }

  void loadData() async {
    await HomeWidget.getWidgetData<int>('_percentage', defaultValue: 0)
        .then((value) {
      _futureWeather = fetchWeather();
      _futureWeather!.then((weather) => _updateWeather(weather));
      print("loadData: _percentage=" + _percentage.toString());
    });
    setState(() {});
    updateAppWidget();
  }

  Future<void> updateAppWidget() async {
    await HomeWidget.saveWidgetData<int>('_percentage', _percentage[0]);
    await HomeWidget.updateWidget(
        name: 'AppWidgetProvider', iOSName: 'AppWidgetProvider');
  }

  void _foundNuptialFlight() {}

  void _updateWeather(WeatherResponse value) {
    setState(() {
      _weather = value;
      _percentage[0] =
          (nuptialPercentage(value.daily!.elementAt(0)) * 100.0).toInt();
      _percentage[1] =
          (nuptialPercentage(value.daily!.elementAt(1)) * 100.0).toInt();
      _percentage[2] =
          (nuptialPercentage(value.daily!.elementAt(2)) * 100.0).toInt();
      _percentage[3] =
          (nuptialPercentage(value.daily!.elementAt(3)) * 100.0).toInt();
      _percentage[4] =
          (nuptialPercentage(value.daily!.elementAt(4)) * 100.0).toInt();
      _percentage[5] =
          (nuptialPercentage(value.daily!.elementAt(5)) * 100.0).toInt();
      _percentage[6] =
          (nuptialPercentage(value.daily!.elementAt(6)) * 100.0).toInt();
      _percentage[7] =
          (nuptialPercentage(value.daily!.elementAt(7)) * 100.0).toInt();
      print("_updateWeather: _percentage=" + _percentage.toString());
    });
    updateAppWidget();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title!),
        centerTitle: true,
        toolbarHeight: 40,
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Likelihood of Nuptial Flight',
              style: Theme.of(context).textTheme.headline6,
            ),
            Text(
              '${_percentage[0]}%',
              style: Theme.of(context).textTheme.headline3?.merge(TextStyle(
                  color: (_percentage[0] < 50
                      ? Colors.red
                      : (_percentage[0] < 75
                          ? Colors.deepOrange
                          : Colors.green)))),
            ),
            Text(
              '',
            ),
            Text(
              (_weather == null ? '' : 'Today\'s Weather'
              // + dateFormat.format(DateTime.fromMillisecondsSinceEpoch(
              //     (_weather!.daily!.first.dt! + _weather!.timezoneOffset!) *
              //         1000,
              //     isUtc: true)) + ''
              ),
              style: Theme.of(context).textTheme.bodyText1,
            ),
            Text(
              '${_weather?.daily?.first.weather?.first.description}',
              style: Theme.of(context).textTheme.bodyText2,
            ),
            Text(
              '',
            ),
            Text(
              'Temperature',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            Text(
              (_weather == null
                      ? ""
                      : (_weather?.daily?.first.temp?.eve!)!
                          .toStringAsFixed(1)) +
                  "°C",
              style: Theme.of(context).textTheme.headline5,
            ),
            Text(
              (_weather == null
                  ? ""
                  : "Suitability: " +
                      (temperatureContribution(_weather!.daily!.first) * 100)
                          .toStringAsFixed(0) +
                      "%"),
              style: Theme.of(context).textTheme.caption,
            ),
            Text(
              '',
            ),
            Text(
              'Wind Speed',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            Text(
              '${_weather?.daily?.first.windSpeed} m/s',
              style: Theme.of(context).textTheme.headline5,
            ),
            Text(
              (_weather == null
                  ? ""
                  : "Suitability: " +
                      (windContribution(_weather!.daily!.first) * 100)
                          .toStringAsFixed(0) +
                      "%"),
              style: Theme.of(context).textTheme.caption,
            ),
            Text(
              '',
            ),
            Text(
              'Humidity',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            Text(
              '${_weather?.daily?.first.humidity}%',
              style: Theme.of(context).textTheme.headline5,
            ),
            Text(
              (_weather == null
                  ? ""
                  : "Suitability: " +
                  (humidityContribution(_weather!.daily!.first) * 100)
                      .toStringAsFixed(0) +
                  "%"),
              style: Theme.of(context).textTheme.caption,
            ),
            Text(
              '',
            ),
            Text(
              'Probability of Precipitation',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            Text(
              (_weather == null
                      ? ""
                      : (_weather!.daily!.first.pop! * 100)
                          .toStringAsFixed(0)) +
                  "%",
              style: Theme.of(context).textTheme.headline5,
            ),
            Text(
              (_weather == null
                  ? ""
                  : "Suitability: " +
                      (rainContribution(_weather!.daily!.first) * 100)
                          .toStringAsFixed(0) +
                      "%"),
              style: Theme.of(context).textTheme.caption,
            ),
            Text(
              '',
            ),
            Text(
              'Cloudiness',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            Text(
              '${_weather?.daily?.first.clouds}%',
              style: Theme.of(context).textTheme.headline5,
            ),
            Text(
              (_weather == null
                  ? ""
                  : "Suitability: " +
                      (cloudinessContribution(_weather!.daily!.first) * 100)
                          .toStringAsFixed(0) +
                      "%"),
              style: Theme.of(context).textTheme.caption,
            ),
            Text(
              '',
            ),
            Text(
              'Air Pressure',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            Text(
              (_weather == null
                      ? ""
                      : (_weather!.daily!.first.pressure!).toStringAsFixed(0)) +
                  " hPa",
              style: Theme.of(context).textTheme.headline5,
            ),
            Text(
              (_weather == null
                  ? ""
                  : "Suitability: " +
                      (pressureContribution(_weather!.daily!.first) * 100)
                          .toStringAsFixed(0) +
                      "%"),
              style: Theme.of(context).textTheme.caption,
            ),
            Text(
              '',
            ),
            Text(
              'Upcoming Week',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (_weather == null ? "" : '${_percentage[1]}%'),
                  style: getColorGradient(_percentage[1]),
                ),
                Text(
                  '  ',
                ),
                Text(
                  (_weather == null ? "" : '${_percentage[2]}%'),
                  style: getColorGradient(_percentage[2]),
                ),
                Text(
                  '  ',
                ),
                Text(
                  (_weather == null ? "" : '${_percentage[3]}%'),
                  style: getColorGradient(_percentage[3]),
                ),
                Text(
                  '  ',
                ),
                Text(
                  (_weather == null ? "" : '${_percentage[4]}%'),
                  style: getColorGradient(_percentage[4]),
                ),
                Text(
                  '  ',
                ),
                Text(
                  (_weather == null ? "" : '${_percentage[5]}%'),
                  style: getColorGradient(_percentage[5]),
                ),
                Text(
                  '  ',
                ),
                Text(
                  (_weather == null ? "" : '${_percentage[6]}%'),
                  style: getColorGradient(_percentage[6]),
                ),
                Text(
                  '  ',
                ),
                Text(
                  (_weather == null ? "" : '${_percentage[7]}%'),
                  style: getColorGradient(_percentage[7]),
                ),
              ],
            ),
            Text( // Push up the text away from the button
              '',
            ),
            Text( // Push up the text away from the button
              '',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _foundNuptialFlight,
        tooltip: 'Found Nuptial Flight',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  TextStyle? getColorGradient(int percentage) {
    return Theme.of(context).textTheme.subtitle1?.merge(TextStyle(
        color: (percentage < 50
            ? Colors.red
            : (percentage < 75 ? Colors.orange : Colors.green))));
  }

/*
  FutureBuilder<WeatherResponse> weatherText() {
    return FutureBuilder<WeatherResponse>(
      future: _futureWeather,
      builder: (context, weather) {
        if (weather.hasData) {
          return Text(
            '${weather.requireData.daily?.first.temp?.day}',
            style: Theme.of(context).textTheme.headline4,
          );
        } else if (weather.hasError) {
          return Text(
            '${weather.error}',
            style: Theme.of(context).textTheme.headline6,
          );
        }

        // By default, show a loading spinner.
        return const CircularProgressIndicator();
      },
    );
  }
*/
}
