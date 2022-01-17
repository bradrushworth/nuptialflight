//import 'package:nuptialflight/responses/reverse_geocoding_response.dart';
//import 'dart:developer' as developer;

import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:nuptialflight/responses/weather_response.dart';
import 'package:nuptialflight/screenshots_mobile.dart'
    if (dart.library.io) 'package:nuptialflight/screenshots_mobile.dart'
    if (dart.library.js) 'package:nuptialflight/screenshots_other.dart';
import 'package:nuptialflight/weather_fetcher.dart';
import 'package:nuptialflight/widgets_other.dart'
    if (dart.library.io) 'package:nuptialflight/widgets_mobile.dart'
    if (dart.library.js) 'package:nuptialflight/widgets_other.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'nuptials.dart';
import 'utils.dart';

final DateFormat dateFormat = DateFormat("yyyy-MM-dd");
final DateFormat weekdayFormat = DateFormat("E");

final int greenThreshold = 75;
final int amberThreshold = 50;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initialiseWidget();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode && kIsWeb,
      builder: (context) => MyHomePage(), // Wrap your app
      tools: kIsWeb
          ? [...DevicePreview.defaultTools, simpleScreenShotModesPlugin]
          : [],
    ),
  );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? appName, packageName, version, buildNumber;
  String? _geocoding;
  WeatherResponse? _weather;
  bool loaded = false;
  String? errorMessage;
  List<int> _percentage = [0, 0, 0, 0, 0, 0, 0, 0];
  MaterialColor primarySwatch = Colors.blueGrey;

  @override
  void initState() {
    super.initState();
    widgetInitState(loadData);
    loadData(); // This will load data every time app is opened
  }

  void loadData() async {
    await dotenv.load(fileName: 'assets/.env');

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
    setState(() {
      updateAppWidget(_percentage);
    });

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
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
      if (_percentage[0] >= greenThreshold) {
        primarySwatch = Colors.lightGreen;
      } else if (_percentage[0] >= 50) {
        primarySwatch = Colors.amber;
      } else {
        primarySwatch = Colors.red;
      }
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
    return MaterialApp(
      title: 'Ant Nuptial Flight Predictor',
      // Create space for camera cut-outs etc
      useInheritedMediaQuery: true,
      // Hide the dev banner
      debugShowCheckedModeBanner: false,
      // For DevicePreview
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: primarySwatch,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: buildUI('Ant Nuptial Flight Predictor'),
    );
  }

  Widget buildUI(String title) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(title),
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
                    Icon(choice.icon,
                        size: 20, color: Theme.of(context).primaryColor),
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
              Spacer(flex: 1),
              GridView.count(
                crossAxisCount:
                orientation == Orientation.portrait ? 1 : 3,
                childAspectRatio:
                orientation == Orientation.portrait ? 8 : 6,
                shrinkWrap: true,
                children: [
                  _buildNuptialHeading(orientation),
                  _buildTodayPercentage(orientation),
                  _buildTodayWeather(orientation),
                ],
              ),
              Spacer(flex: 1),
              GridView.count(
                crossAxisCount:
                orientation == Orientation.portrait ? 3 : 6,
                childAspectRatio: 2.0,
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
              Spacer(flex: 1),
              orientation == Orientation.portrait
                            ? Text(
                                (kIsWeb
                                        ? 'Web'
                                        : toBeginningOfSentenceCase(
                                            Platform.operatingSystem)!) +
                                    ' Version $version+$buildNumber',
                                style:
                                    TextStyle(fontSize: 8, color: Colors.grey))
                            : Container(), // Not enough room, unnecessary
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
        color: (percentage < amberThreshold
            ? Colors.red
            : (percentage < greenThreshold
                ? Colors.deepOrange
                : Colors.green)));
  }

  Widget _buildErrorMessage() {
    //                  return AlertDialog(
    //                     title: const Text('That is correct!'),
    //                     content: const Text('13 is the right answer.'),
    //                     actions: <Widget>[
    //                       TextButton(
    //                         onPressed: () {
    //                           Navigator.pop(context);
    //                         },
    //                         child: const Text('OK'),
    //                       ),
    //                     ],
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
    return AutoSizeText(
      orientation == Orientation.portrait
          ? 'Likelihood of Ant Nuptial Flight Today'
          : 'Likelihood of Ant\nNuptial Flight Today',
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
    return AutoSizeText(
      '${_percentage[0]}%',
      style: TextStyle(
        color: (_percentage[0] < amberThreshold
            ? Colors.red
            : (_percentage[0] < greenThreshold
                ? Colors.deepOrange
                : Colors.green)),
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
        AutoSizeText(
          (_geocoding == null ? 'Today\'s Weather' : '$_geocoding Weather'),
          style: TextStyle(
            height: orientation == Orientation.portrait ? 1.6 : 1.0,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // AutoSizeText(
        //   dateFormat.format(DateTime.fromMillisecondsSinceEpoch(
        //       (_weather!.daily!.first.dt! + _weather!.timezoneOffset!) * 1000,
        //       isUtc: true)),
        //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        // ),
        AutoSizeText(
          toBeginningOfSentenceCase(
              _weather!.daily!.first.weather!.first.description)!,
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
            (_weather!.daily!.first.temp!.eve!).toStringAsFixed(1) + "°C",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
          ),
          Text(
            "Suitability: " +
                (temperatureContribution(_weather!.daily!.first) * 100)
                    .toStringAsFixed(0) +
                "%",
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
            '${_weather!.daily!.first.windSpeed!.toStringAsFixed(1)}\u{00A0}m/s',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
          ),
          Text(
            "Suitability: " +
                (windContribution(_weather!.daily!.first) * 100)
                    .toStringAsFixed(0) +
                "%",
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
            (_weather!.daily!.first.pop! * 100).toStringAsFixed(0) + "%",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
          ),
          Text(
            "Suitability: " +
                (rainContribution(_weather!.daily!.first) * 100)
                    .toStringAsFixed(0) +
                "%",
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
            '${_weather!.daily!.first.humidity}%',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
          ),
          Text(
            "Suitability: " +
                (humidityContribution(_weather!.daily!.first) * 100)
                    .toStringAsFixed(0) +
                "%",
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
            '${_weather!.daily!.first.clouds}%',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
          ),
          Text(
            "Suitability: " +
                (cloudinessContribution(_weather!.daily!.first) * 100)
                    .toStringAsFixed(0) +
                "%",
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
            (_weather!.daily!.first.pressure!).toStringAsFixed(0) +
                "\u{00A0}hPa",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
          ),
          Text(
            "Suitability: " +
                (pressureContribution(_weather!.daily!.first) * 100)
                    .toStringAsFixed(0) +
                "%",
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
        AutoSizeText(
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
              weekdayFormat.format(DateTime.fromMillisecondsSinceEpoch(
                  (_weather!.daily!.elementAt(i).dt! +
                          _weather!.timezoneOffset!) *
                      1000,
                  isUtc: true)),
              style: getColorGradient(_percentage[i]),
            ),
          ),
        ),
        DataCell(
          Container(
            child: Text(
              ' ${_weather!.daily!.elementAt(i).temp!.eve!.toStringAsFixed(1)}°C',
              style: getColorGradient(_percentage[i]),
            ),
          ),
        ),
        DataCell(
          Container(
            child: Text(
              ' ${_weather!.daily!.elementAt(i).windSpeed!.toStringAsFixed(1)}\u{00A0}m/s',
              style: getColorGradient(_percentage[i]),
            ),
          ),
        ),
        DataCell(
          Container(
            child: Text(
              ' ${_percentage[i]}%',
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

///
/// Menu on the top left hand side
///
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
