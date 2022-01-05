import 'dart:ui';

import 'package:appwidgetflutter/responses/reverse_geocoding_response.dart';
import 'package:appwidgetflutter/responses/weather_response.dart';
import 'package:appwidgetflutter/weather_fetcher.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import 'nuptials.dart';

DateFormat dateFormat = DateFormat("yyyy-MM-dd");
DateFormat weekdayFormat = DateFormat("E");

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
  ReverseGeocodingResponse? _geocoding;
  WeatherResponse? _weather;
  bool loaded = false;
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
      WeatherFetcher weatherFetcher = WeatherFetcher();
      weatherFetcher.getLocation().then((o) => Future.wait([
            weatherFetcher.fetchReverseGeocoding(),
            weatherFetcher.fetchWeather()
          ])
              .then((List responses) =>
                  _updateWeather(responses[0], responses[1]))
              .catchError((e) => handleError(e)));
      print("loadData: _percentage=" + _percentage.toString());
    });
    setState(() {});
    updateAppWidget();
  }

  void _updateWeather(
      ReverseGeocodingResponse geocoding, WeatherResponse value) {
    setState(() {
      _geocoding = geocoding;
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
      loaded = true;
      print("_updateWeather: _percentage=" + _percentage.toString());
    });
    updateAppWidget();
  }

  Future<void> updateAppWidget() async {
    await HomeWidget.saveWidgetData<int>('_percentage', _percentage[0]);
    await HomeWidget.updateWidget(
        name: 'AppWidgetProvider', iOSName: 'AppWidgetProvider');
  }

  /// Future feature to record user saw a nuptial flight
  void _foundNuptialFlight() {}

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
        toolbarHeight: 50,
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return loaded
              ? Column(
                  //mainAxisAlignment: MainAxisAlignment.end,
                  //crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Spacer(flex: 1),
                    GridView.count(
                      crossAxisCount:
                          orientation == Orientation.portrait ? 1 : 3,
                      childAspectRatio:
                          orientation == Orientation.portrait ? 5 : 5,
                      padding: orientation == Orientation.portrait
                          ? const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 0)
                          : const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 0),
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 0,
                      shrinkWrap: true,
                      children: [
                        _buildNuptialHeading(orientation),
                        _buildTodayPercentage(orientation),
                        _buildTodayWeather(),
                      ],
                    ),
                    Spacer(flex: 1),
                    GridView.count(
                      crossAxisCount:
                          orientation == Orientation.portrait ? 3 : 6,
                      childAspectRatio: 1.6,
                      padding: orientation == Orientation.portrait
                          ? const EdgeInsets.symmetric(vertical: 4)
                          : const EdgeInsets.symmetric(horizontal: 4),
                      shrinkWrap: true,
                      children: [
                        _buildTemperature(),
                        _buildWindSpeed(),
                        _buildPrecipitation(),
                        _buildHumidity(),
                        _buildCloudiness(),
                        _buildAirPressure(),
                      ],
                    ),
                    Spacer(flex: 1),
                    _buildUpcomingWeek(orientation),
                    Spacer(flex: 3),
                  ],
                )
              : Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [CircularProgressIndicator()]));
        },
      ),

      /// Future feature to record that the user saw a nuptial flight today
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _foundNuptialFlight,
      //   tooltip: 'Found Nuptial Flight',
      //   child: Icon(Icons.add),
      //), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  TextStyle? getColorGradient(int percentage) {
    return Theme.of(context).textTheme.subtitle1?.merge(TextStyle(
        color: (percentage < 50
            ? Colors.red
            : (percentage < 75 ? Colors.orange : Colors.green))));
  }

  Widget _buildNuptialHeading(Orientation orientation) {
    return Text(
      'Likelihood of Nuptial Flight Today',
      style: Theme.of(context).textTheme.headline6!.merge(TextStyle(
            height: orientation == Orientation.portrait ? 3 : 1,
          )),
      textAlign: TextAlign.center,
      softWrap: true,
      maxLines: 2,
    );
  }

  Widget _buildTodayPercentage(Orientation orientation) {
    return Text(
      '${_percentage[0]}%',
      style: Theme.of(context).textTheme.headline3!.merge(TextStyle(
            color: (_percentage[0] < 50
                ? Colors.red
                : (_percentage[0] < 75 ? Colors.deepOrange : Colors.green)),
            height: orientation == Orientation.portrait ? 0.75 : 1,
          )),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTodayWeather() {
    return Column(
      children: [
        Text(
          (_geocoding == null
              ? 'Today\'s Weather'
              : '${_geocoding!.name} Weather'),
          style: Theme.of(context).textTheme.bodyText1!.merge(TextStyle(
                height: 1.5,
              )),
        ),
        // Text(
        //   dateFormat.format(DateTime.fromMillisecondsSinceEpoch(
        //       (_weather!.daily!.first.dt! + _weather!.timezoneOffset!) * 1000,
        //       isUtc: true)),
        //   style: Theme.of(context).textTheme.bodyText2,
        // ),
        Text(
          '${_weather?.daily?.first.weather?.first.description}',
          style: Theme.of(context)
              .textTheme
              .bodyText2!
              .merge(TextStyle(fontSize: 18)),
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildTemperature() {
    return SizedBox(
      child: Column(
        children: [
          Text(
            'Temperature',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          Text(
            (_weather == null
                    ? ""
                    : (_weather?.daily?.first.temp?.eve!)!.toStringAsFixed(1)) +
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
        ],
      ),
    );
  }

  Widget _buildWindSpeed() {
    return SizedBox(
      child: Column(
        children: [
          Text(
            'Wind Speed',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          Text(
            '${_weather?.daily?.first.windSpeed!.toStringAsFixed(1)} m/s',
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
        ],
      ),
    );
  }

  Widget _buildPrecipitation() {
    return SizedBox(
      child: Column(
        children: [
          Text(
            'Precipitation',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          Text(
            (_weather == null
                    ? ""
                    : (_weather!.daily!.first.pop! * 100).toStringAsFixed(0)) +
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
        ],
      ),
    );
  }

  Widget _buildHumidity() {
    return SizedBox(
      child: Column(
        children: [
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
        ],
      ),
    );
  }

  Widget _buildCloudiness() {
    return SizedBox(
      child: Column(
        children: [
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
        ],
      ),
    );
  }

  Widget _buildAirPressure() {
    return SizedBox(
      child: Column(
        children: [
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
        ],
      ),
    );
  }

  Widget _buildUpcomingWeek(Orientation orientation) {
    return Column(
      children: [
        Text(
          'Upcoming Week',
          style: Theme.of(context).textTheme.bodyText1,
        ),
        DataTable(
          headingRowHeight: 22,
          dataRowHeight: 22,
          horizontalMargin: 22,
          columnSpacing: 22,
          dividerThickness: 0,
          columns: [
            DataColumn(label: Text('Day'), numeric: true),
            DataColumn(label: Text('Temperature'), numeric: true),
            DataColumn(label: Text('Wind Speed'), numeric: true),
            DataColumn(label: Text('Likelihood'), numeric: true),
          ],
          rows: [
            _buildFuturePercentage(1),
            _buildFuturePercentage(2),
            _buildFuturePercentage(3),
            _buildFuturePercentage(4),
            _buildFuturePercentage(5),
            _buildFuturePercentage(6),
            _buildFuturePercentage(7),
          ],
        ),
      ],
    );
  }

  DataRow _buildFuturePercentage(int i) {
    return DataRow(
      cells: [
        DataCell(
          Container(
            child: Text(
              (_weather == null
                  ? ''
                  : weekdayFormat.format(DateTime.fromMillisecondsSinceEpoch(
                      (_weather!.daily!.elementAt(i).dt! +
                              _weather!.timezoneOffset!) *
                          1000,
                      isUtc: true))),
              style: getColorGradient(_percentage[i]),
            ),
          ),
        ),
        DataCell(
          Container(
            child: Text(
              (_weather == null
                  ? ''
                  : ' ${_weather!.daily!.elementAt(i).temp!.eve!.toStringAsFixed(1)}°C'),
              style: getColorGradient(_percentage[i]),
            ),
          ),
        ),
        DataCell(
          Container(
            child: Text(
              (_weather == null
                  ? ''
                  : ' ${_weather!.daily!.elementAt(i).windSpeed!.toStringAsFixed(1)} m/s'),
              style: getColorGradient(_percentage[i]),
            ),
          ),
        ),
        DataCell(
          Container(
            child: Text(
              (_weather == null ? '' : ' ${_percentage[i]}%'),
              style: getColorGradient(_percentage[i]),
            ),
          ),
        ),
      ],
    );
  }

  handleError(e) {
    // Not implemented yet!
    throw e;
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
