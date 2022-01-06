//import 'package:nuptialflight/responses/reverse_geocoding_response.dart';
//import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:nuptialflight/responses/weather_response.dart';
import 'package:nuptialflight/weather_fetcher.dart';
import 'package:nuptialflight/widgets_other.dart'
    if (dart.library.io) 'package:nuptialflight/widgets_mobile.dart'
    if (dart.library.js) 'package:nuptialflight/widgets_other.dart';

import 'nuptials.dart';
import 'utils.dart';

DateFormat dateFormat = DateFormat("yyyy-MM-dd");
DateFormat weekdayFormat = DateFormat("E");

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initialiseWidget();
  await dotenv.load(fileName: 'assets/.env');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ant Nuptial Flight Predictor',
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
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: MyHomePage(title: 'Ant Nuptial Flight Predictor'),
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
  String? _geocoding;
  WeatherResponse? _weather;
  bool loaded = false;
  String? errorMessage;
  List<int> _percentage = [0, 0, 0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    widgetInitState(loadData);
    loadData(); // This will load data from widget every time app is opened
  }

  void loadData() async {
    WeatherFetcher weatherFetcher = WeatherFetcher();
    await weatherFetcher
        .getLocation()
        .then((o) => Future.wait([
              weatherFetcher.fetchNearestWeatherLocation(),
              weatherFetcher.fetchWeather()
            ])
                .then((List responses) =>
                    _updateWeather(responses[0], responses[1]))
                .catchError((e) => handleError(e)))
        .catchError((e) => handleError(e));
    print("loadData: _percentage=" + _percentage.toString());
    setState(() {});
    updateAppWidget(_percentage);
  }

  void _updateWeather(String geocoding, WeatherResponse value) {
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
    updateAppWidget(_percentage);
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
        toolbarHeight: 45,
        actions: <Widget>[
          // overflow menu
          PopupMenuButton<Choice>(
            onSelected: (Choice c) {
              Utils.launchURL('${c.url}');
            },
            itemBuilder: (BuildContext context) {
              return choices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                  value: choice,
                  child: Row(children: [
                    Icon(choice.icon, size: 20, color: Theme.of(context).primaryColor),
                    Text('    '),
                    Text('${choice.title}'),
                  ]),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return errorMessage != null
              ? _buildErrorMessage()
              : !loaded
                  ? _buildCircularProgressIndicator()
                  : Column(
                      //mainAxisAlignment: MainAxisAlignment.end,
                      //crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Spacer(flex: 2),
                        GridView.count(
                          crossAxisCount:
                              orientation == Orientation.portrait ? 1 : 3,
                          childAspectRatio:
                              orientation == Orientation.portrait ? 8 : 6,
                          padding: orientation == Orientation.portrait
                              ? const EdgeInsets.symmetric(vertical: 0)
                              : const EdgeInsets.symmetric(horizontal: 0),
                          shrinkWrap: true,
                          children: [
                            _buildNuptialHeading(orientation),
                            _buildTodayPercentage(orientation),
                            _buildTodayWeather(orientation),
                          ],
                        ),
                        Spacer(flex: 2),
                        GridView.count(
                          crossAxisCount:
                              orientation == Orientation.portrait ? 3 : 6,
                          childAspectRatio: 1.6,
                          padding: orientation == Orientation.portrait
                              ? const EdgeInsets.symmetric(vertical: 0)
                              : const EdgeInsets.symmetric(horizontal: 0),
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
                        Spacer(flex: 2),
                      ],
                    );
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
    return TextStyle(
        color: (percentage < 50
            ? Colors.red
            : (percentage < 75 ? Colors.orange : Colors.green)));
  }

  Widget _buildErrorMessage() {
    return Center(
        child: Text(
      '$errorMessage',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
      textAlign: TextAlign.center,
    ));
  }

  Widget _buildCircularProgressIndicator() {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [CircularProgressIndicator()]));
  }

  Widget _buildNuptialHeading(Orientation orientation) {
    return Text(
      'Likelihood of Ant Nuptial Flight Today',
      style: TextStyle(
        height: orientation == Orientation.portrait ? 2.0 : 1.0,
        fontSize: 21,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
      softWrap: true,
      maxLines: 2,
    );
  }

  Widget _buildTodayPercentage(Orientation orientation) {
    return Text(
      '${_percentage[0]}%',
      style: TextStyle(
        color: (_percentage[0] < 50
            ? Colors.red
            : (_percentage[0] < 75 ? Colors.deepOrange : Colors.green)),
        height: orientation == Orientation.portrait ? 1.1 : 1.0,
        fontSize: 37,
        fontWeight: FontWeight.w900,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTodayWeather(Orientation orientation) {
    return Column(
      children: [
        Text(
          (_geocoding == null ? 'Today\'s Weather' : '$_geocoding Weather'),
          style: TextStyle(
            height: orientation == Orientation.portrait ? 1.6 : 1.0,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Text(
        //   dateFormat.format(DateTime.fromMillisecondsSinceEpoch(
        //       (_weather!.daily!.first.dt! + _weather!.timezoneOffset!) * 1000,
        //       isUtc: true)),
        //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        // ),
        Text(
          '${_weather?.daily?.first.weather?.first.description}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
            style: TextStyle(fontSize: 14),
          ),
          Text(
            (_weather == null
                    ? ""
                    : (_weather?.daily?.first.temp?.eve!)!.toStringAsFixed(1)) +
                "°C",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
          ),
          Text(
            (_weather == null
                ? ""
                : "Suitability: " +
                    (temperatureContribution(_weather!.daily!.first) * 100)
                        .toStringAsFixed(0) +
                    "%"),
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.caption!.color),
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
            style: TextStyle(fontSize: 14),
          ),
          Text(
            '${_weather?.daily?.first.windSpeed!.toStringAsFixed(1)}\u{00A0}m/s',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
          ),
          Text(
            (_weather == null
                ? ""
                : "Suitability: " +
                    (windContribution(_weather!.daily!.first) * 100)
                        .toStringAsFixed(0) +
                    "%"),
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.caption!.color),
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
            style: TextStyle(fontSize: 14),
          ),
          Text(
            (_weather == null
                    ? ""
                    : (_weather!.daily!.first.pop! * 100).toStringAsFixed(0)) +
                "%",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
          ),
          Text(
            (_weather == null
                ? ""
                : "Suitability: " +
                    (rainContribution(_weather!.daily!.first) * 100)
                        .toStringAsFixed(0) +
                    "%"),
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.caption!.color),
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
            style: TextStyle(fontSize: 14),
          ),
          Text(
            '${_weather?.daily?.first.humidity}%',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
          ),
          Text(
            (_weather == null
                ? ""
                : "Suitability: " +
                    (humidityContribution(_weather!.daily!.first) * 100)
                        .toStringAsFixed(0) +
                    "%"),
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.caption!.color),
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
            style: TextStyle(fontSize: 14),
          ),
          Text(
            '${_weather?.daily?.first.clouds}%',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
          ),
          Text(
            (_weather == null
                ? ""
                : "Suitability: " +
                    (cloudinessContribution(_weather!.daily!.first) * 100)
                        .toStringAsFixed(0) +
                    "%"),
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.caption!.color),
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
            style: TextStyle(fontSize: 14),
          ),
          Text(
            (_weather == null
                    ? ""
                    : (_weather!.daily!.first.pressure!).toStringAsFixed(0)) +
                "\u{00A0}hPa",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
          ),
          Text(
            (_weather == null
                ? ""
                : "Suitability: " +
                    (pressureContribution(_weather!.daily!.first) * 100)
                        .toStringAsFixed(0) +
                    "%"),
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.caption!.color),
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
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
                  : ' ${_weather!.daily!.elementAt(i).windSpeed!.toStringAsFixed(1)}\u{00A0}m/s'),
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
    errorMessage = e.toString();
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

class Choice {
  const Choice({required this.title, required this.url, required this.icon});

  final String title;
  final String url;
  final IconData icon;
}

const List<Choice> choices = const <Choice>[
  const Choice(
      title: 'Report Issue',
      url: 'mailto:bitbot@bitbot.com.au?subject=Help with Ant Flight',
      icon: Icons.email),
  const Choice(
      title: 'Web App',
      url: 'https://nuptialflight.codemagic.app/#/',
      icon: Icons.web),
  const Choice(
      title: 'Android',
      url:
          'https://play.google.com/store/apps/details?id=au.com.bitbot.nuptialflight',
      icon: Icons.android),
  const Choice(
      title: 'IOS',
      url:
          'https://apps.apple.com/us/app/ant-nuptial-flight-predictor/id1603373687',
      icon: Icons.phone_iphone),
  const Choice(
      title: 'Source Code',
      url: 'https://github.com/bradrushworth/nuptialflight',
      icon: Icons.source),
  const Choice(
      title: 'Buy Brad Coffee',
      url: 'https://www.buymeacoffee.com/bitbot',
      icon: Icons.coffee),
];
