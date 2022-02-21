//import 'package:nuptialflight/responses/reverse_geocoding_response.dart';
//import 'dart:developer' as developer;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:intl/intl.dart';
import 'package:nuptialflight/map.dart';
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
final DateFormat timeOfDayFormat = DateFormat("ha");

const String kGoogleApiKey = 'AIzaSyDNaPQ01hKnTmVRQoT_FM1ZTTxDnw6GoOU';

const int greenThreshold = 75;
const int amberThreshold = 50;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initialiseWidget();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode && kIsWeb,
      builder: (context) => MyMaterialApp(), // Wrap your app
      tools: kIsWeb
          ? [...DevicePreview.defaultTools, simpleScreenShotModesPlugin]
          : [],
    ),
  );
}

class MyMaterialApp extends StatefulWidget {
  MyMaterialApp({Key? key}) : super(key: key);

  @override
  _MyMaterialAppState createState() => _MyMaterialAppState();
}

class _MyMaterialAppState extends State<MyMaterialApp> {
  MaterialColor primarySwatch = Colors.blueGrey;

  @override
  Widget build(BuildContext context) {
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
            brightness: Brightness.light, primarySwatch: primarySwatch),
        darkTheme: ThemeData(
            brightness: Brightness.dark, primarySwatch: primarySwatch),
        themeMode: ThemeMode.system,
        home: MyHomePage(
          primarySwatch: setPrimarySwatch,
          weatherFetcher: WeatherFetcher(),
        ));
  }

  void setPrimarySwatch(MaterialColor s) {
    setState(() {
      primarySwatch = s;
    });
  }
}

class MyHomePage extends StatefulWidget {
  final void Function(MaterialColor s)? primarySwatch;
  final bool fixedLocation;
  final WeatherFetcher weatherFetcher;

  MyHomePage(
      {Key? key,
      void Function(MaterialColor s)? this.primarySwatch,
      this.fixedLocation = false,
      required this.weatherFetcher})
      : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();

  void setPrimarySwatch(MaterialColor swatch) {
    if (primarySwatch != null) {
      primarySwatch!(swatch);
    }
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final String corsProxyUrl =
      'https://api.bitbot.com.au/cors/https://maps.googleapis.com/maps/api';

  final AutoSizeGroup headingGroup = AutoSizeGroup();
  final AutoSizeGroup parameterGroup = AutoSizeGroup();
  final AutoSizeGroup suitabilityGroup = AutoSizeGroup();

  late final List<Choice> choices;
  late final bool fixedLocation;
  late final WeatherFetcher weatherFetcher;

  String? appName, packageName, version, buildNumber;
  String? _geocoding;
  WeatherResponse? _weather;
  bool loaded = false;
  String? errorMessage;

  //int _diurnalPercentage = 0;
  //int _nocturnalPercentage = 0;
  Hourly? _indexOfDiurnalHour;
  Hourly? _indexOfNocturnalHour;
  List<int> _hourlyPercentage = [0, 0];
  List<int> _dailyPercentage = [0, 0, 0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    this.fixedLocation = widget.fixedLocation;
    this.weatherFetcher = widget.weatherFetcher;
    createMenu();
    widgetInitState(_loadData);
    _loadData(); // This will load data every time app is opened
  }

  void createMenu() {
    choices = <Choice>[];
    choices.add(const Choice(
        title: 'Select Location', url: '', icon: Icons.add_location_alt));
    choices.add(const Choice(title: 'Show Map', url: '', icon: Icons.map));
    choices.add(const Choice(
        title: 'Report Issue',
        url: 'mailto:bitbot@bitbot.com.au?subject=Help with Ant Flight',
        icon: Icons.email));
    if (!kIsWeb) {
      choices.add(const Choice(
          title: 'Web App',
          url: 'https://nuptialflight.codemagic.app/',
          icon: Icons.web));
    }
    if (kIsWeb || Platform.isAndroid) {
      choices.add(const Choice(
          title: 'Android',
          url:
              'https://play.google.com/store/apps/details?id=au.com.bitbot.nuptialflight',
          icon: Icons.android));
    }
    if (kIsWeb || Platform.isIOS || Platform.isMacOS) {
      choices.add(const Choice(
          title: 'IOS',
          url:
              'https://apps.apple.com/us/app/ant-nuptial-flight-predictor/id1603373687',
          icon: Icons.phone_iphone));
    }
    choices.add(const Choice(
        title: 'Source Code',
        url: 'https://github.com/bradrushworth/nuptialflight',
        icon: Icons.source));
    if (kIsWeb) {
      choices.add(const Choice(
          title: 'Buy Brad Coffee',
          url: 'https://www.buymeacoffee.com/bitbot',
          icon: Icons.coffee));
    }
  }

  void _loadData() async {
    await dotenv.load(fileName: 'assets/.env');

    _getLocation();

    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        appName = packageInfo.appName;
        packageName = packageInfo.packageName;
        version = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
      });
    });
  }

  void _getLocation() {
    setState(() {
      errorMessage = null;
    });

    if (fixedLocation) {
      _getWeather()
          .then((nothing) => print("findLocation(fixed): _dailyPercentage=" +
              _dailyPercentage.toString()))
          .catchError((e) => handleError(e));
    } else {
      // Try to passively then actively determine the location.
      // Only update the Android widget for the current location.
      weatherFetcher
          .findLocation(false)
          .then((updated) => updated ? _getWeather() : Future.value())
          .then((nothing) => updateAppWidget(_dailyPercentage))
          .then((nothing) => print("findLocation(passive): _percentage=" +
              _dailyPercentage.toString()))
          .then((nothing) => weatherFetcher.findLocation(true))
          .then((updated) => updated ? _getWeather() : Future.value())
          .then((nothing) => updateAppWidget(_dailyPercentage))
          .then((nothing) => print("findLocation(active): _percentage=" +
              _dailyPercentage.toString()))
          .catchError((e) => handleLocationError(e));
    }
  }

  Future<void> _getWeather() {
    return Future.wait([
      weatherFetcher.fetchNearestWeatherLocation(),
      weatherFetcher.fetchWeather()
    ])
        .then((List responses) => _updateWeather(responses[0], responses[1]))
        .catchError((e) => handleError(e));
  }

  void _findPlaceName() {
    PlacesAutocomplete.show(
      context: context,
      //location: weatherFetcher.getLatLng(),
      apiKey: kGoogleApiKey,
      proxyBaseUrl: corsProxyUrl,
      mode: Mode.fullscreen,
      components: [],
      types: [],
      strictbounds: false,
    )
        .then((Prediction? prediction) => _lookupPlace(prediction))
        .then((PlacesDetailsResponse? place) => _setPlaceName(place));
  }

  void _setPlaceName(PlacesDetailsResponse? place) {
    if (place != null) {
      WeatherFetcher newWeatherFetcher = WeatherFetcher();
      newWeatherFetcher.setLocationPlace(place);
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => MyHomePage(
                  fixedLocation: true,
                  weatherFetcher: newWeatherFetcher,
                ),
            fullscreenDialog: true,
            maintainState: true),
      );
    } else {
      print('_findPlaceName: User cancelled search!');
      handleSearchError(Exception('User cancelled search!'));
    }
  }

  Future<PlacesDetailsResponse?> _lookupPlace(Prediction? prediction) {
    if (prediction != null) {
      return GoogleMapsPlaces(
        apiKey: kGoogleApiKey,
        baseUrl: corsProxyUrl,
      ).getDetailsByPlaceId(prediction.placeId!);
    }
    return Future.value();
  }

  void _showMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => MapPage(),
          fullscreenDialog: true,
          maintainState: true),
    );
  }

  void _updateWeather(String geocoding, WeatherResponse value) {
    print('_updateWeather: geocoding=$geocoding');
    setState(() {
      _geocoding = geocoding;
      _weather = value;
      _indexOfDiurnalHour = value.hourly!.firstWhere((e) =>
          timeOfDayFormat.format(DateTime.fromMillisecondsSinceEpoch(
              (e.dt! + _weather!.timezoneOffset!) * 1000,
              isUtc: true)) ==
          '12PM');
      _indexOfNocturnalHour = value.hourly!.firstWhere((e) =>
          timeOfDayFormat.format(DateTime.fromMillisecondsSinceEpoch(
              (e.dt! + _weather!.timezoneOffset!) * 1000,
              isUtc: true)) ==
          '9PM');
      _hourlyPercentage[0] =
          (nuptialHourlyPercentage(_indexOfDiurnalHour!) * 100.0).toInt();
      _hourlyPercentage[1] =
          (nuptialHourlyPercentage(_indexOfNocturnalHour!) * 100.0).toInt();
      // _hourlyPercentage[0] =
      //     (nuptialDailyPercentage(value.daily!.elementAt(0)) * 100.0).toInt();
      // _hourlyPercentage[1] =
      //     (nuptialDailyPercentage(value.daily!.elementAt(0), nocturnal: true) * 100.0).toInt();
      _dailyPercentage[0] =
          (nuptialDailyPercentage(value.daily!.elementAt(0)) * 100.0).toInt();
      _dailyPercentage[1] =
          (nuptialDailyPercentage(value.daily!.elementAt(1)) * 100.0).toInt();
      _dailyPercentage[2] =
          (nuptialDailyPercentage(value.daily!.elementAt(2)) * 100.0).toInt();
      _dailyPercentage[3] =
          (nuptialDailyPercentage(value.daily!.elementAt(3)) * 100.0).toInt();
      _dailyPercentage[4] =
          (nuptialDailyPercentage(value.daily!.elementAt(4)) * 100.0).toInt();
      _dailyPercentage[5] =
          (nuptialDailyPercentage(value.daily!.elementAt(5)) * 100.0).toInt();
      _dailyPercentage[6] =
          (nuptialDailyPercentage(value.daily!.elementAt(6)) * 100.0).toInt();
      _dailyPercentage[7] =
          (nuptialDailyPercentage(value.daily!.elementAt(7)) * 100.0).toInt();
      if (_dailyPercentage[0] >= greenThreshold) {
        widget.setPrimarySwatch(Colors.lightGreen);
      } else if (_dailyPercentage[0] >= 50) {
        widget.setPrimarySwatch(Colors.amber);
      } else {
        widget.setPrimarySwatch(Colors.red);
      }
      loaded = true;
      print("_updateWeather: _dailyPercentage=" + _dailyPercentage.toString());
    });
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
    return buildUI('Ant Nuptial Flight Predictor');
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
              if (c.icon == Icons.add_location_alt) {
                _findPlaceName();
              } else if (c.icon == Icons.map) {
                _showMap();
              } else {
                Utils.launchURL('${c.url}');
              }
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
                      mainAxisAlignment: orientation == Orientation.portrait
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.spaceAround,
                      //crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        GridView.count(
                          crossAxisCount:
                              orientation == Orientation.portrait ? 1 : 3,
                          childAspectRatio:
                              orientation == Orientation.portrait ? 8 : 6,
                          shrinkWrap: true,
                          children: [
                            _buildNuptialHeading(orientation),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                _buildTodayPercentage(orientation, 'Diurnal',
                                    _hourlyPercentage[0]),
                                _buildTodayPercentage(orientation, 'Nocturnal',
                                    _hourlyPercentage[1]),
                              ],
                            ),
                            _buildTodayWeather(orientation),
                          ],
                        ),
                        GridView.count(
                          crossAxisCount:
                              orientation == Orientation.portrait ? 3 : 9,
                          childAspectRatio: 2.0,
                          padding: orientation == Orientation.portrait
                              ? const EdgeInsets.symmetric(vertical: 0)
                              : const EdgeInsets.symmetric(horizontal: 0),
                          shrinkWrap: true,
                          children: [
                            // _buildTemperature(
                            //     'Day Temp', _weather!.daily!.first.temp!.day!),
                            // _buildTemperature(
                            //     'Max Temp', _weather!.daily!.first.temp!.max!),
                            // _buildTemperature(
                            //     'Eve Temp', _weather!.daily!.first.temp!.eve!),

                            _buildTemperature(
                                timeOfDayFormat
                                        .format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                (_indexOfDiurnalHour!.dt! +
                                                        _weather!
                                                            .timezoneOffset!) *
                                                    1000,
                                                isUtc: true))
                                        .toLowerCase() +
                                    ' Temp',
                                _indexOfDiurnalHour!.temp!),
                            _buildTemperature(
                                'Max Temp', _weather!.daily!.first.temp!.max!),
                            _buildTemperature(
                                timeOfDayFormat
                                        .format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                (_indexOfNocturnalHour!.dt! +
                                                        _weather!
                                                            .timezoneOffset!) *
                                                    1000,
                                                isUtc: true))
                                        .toLowerCase() +
                                    ' Temp',
                                _indexOfNocturnalHour!.temp!),
                            _buildWindSpeed(),
                            _buildWindGust(),
                            _buildPrecipitation(),
                            _buildHumidity(),
                            _buildCloudiness(),
                            _buildAirPressure(),
                          ],
                        ),
                        _buildUpcomingWeek(orientation),
                        if (orientation == Orientation.portrait)
                          Text(
                              (kIsWeb
                                      ? 'Web'
                                      : toBeginningOfSentenceCase(
                                          Platform.operatingSystem)!) +
                                  ' Version $version+$buildNumber',
                              style:
                                  TextStyle(fontSize: 8, color: Colors.grey)),
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

  static TextStyle getColorTextStyle(int percentage) {
    return TextStyle(
        color: getColorGradient(percentage), fontWeight: FontWeight.w600);
  }

  static Color? getColorGradient(int percentage) {
    Color? color = (percentage < amberThreshold
        ? Colors.red[800]
        : (percentage < greenThreshold
            ? Colors.orange[800]
            : Colors.green[700]));

    return color;
  }

  static Color? getContinuousColorGradient(int percentage) {
    // Bias towards red and green and away from the middle
    int r = max(0, (1.0 * 255 * (100 - percentage * 1.2)) ~/ 100);
    int g = min(255, (1.0 * 255 * percentage * 1.2) ~/ 100);
    int b = 0;
    Color color = Color.fromARGB(255, r, g, b);

    return color;
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
          ? 'Likelihood of Ant Nuptial Flight'
          : 'Likelihood of Ant\nNuptial Flight',
      style: TextStyle(
        height: orientation == Orientation.portrait ? 2.0 : 1.0,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      minFontSize: 16,
      maxFontSize: 24,
      textAlign: TextAlign.center,
      softWrap: true,
      maxLines: 2,
    );
  }

  Widget _buildTodayPercentage(
      Orientation orientation, String heading, int percentage) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AutoSizeText(
          heading,
          group: headingGroup,
          style: TextStyle(
            fontSize: 14,
            height: orientation == Orientation.portrait ? 0.95 : 0.90,
          ),
          minFontSize: 14,
          maxFontSize: 22,
          stepGranularity: 1.0,
          textAlign: TextAlign.center,
        ),
        AutoSizeText(
          '${percentage}%',
          style: TextStyle(
            color: getColorGradient(percentage),
            height: orientation == Orientation.portrait ? 0.95 : 0.90,
            fontSize: 37,
            fontWeight: FontWeight.w900,
          ),
          minFontSize: 37,
          maxFontSize: 48,
          stepGranularity: 1.0,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTodayWeather(Orientation orientation) {
    return Column(
      children: [
        AutoSizeText(
          (_geocoding == null ? 'Today\'s Weather' : '$_geocoding Weather'),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          minFontSize: 17,
          maxFontSize: 26,
          stepGranularity: 1.0,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        AutoSizeText(
          toBeginningOfSentenceCase(
              _weather!.daily!.first.weather!.first.description)!,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w300),
          minFontSize: 17,
          maxFontSize: 20,
          stepGranularity: 1.0,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildTemperature(String heading, num temp) {
    return SizedBox(
      child: Column(
        children: [
          AutoSizeText(
            heading,
            style: TextStyle(fontSize: 14),
            stepGranularity: 1.0,
            group: headingGroup,
          ),
          AutoSizeText(
            (temp).toStringAsFixed(1) + "°C",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            stepGranularity: 1.0,
            group: parameterGroup,
          ),
          AutoSizeText(
            "Suitability: " +
                (temperatureContribution(temp) * 100).toStringAsFixed(0) +
                "%",
            style: TextStyle(
              fontSize: 12,
            ),
            stepGranularity: 1.0,
            group: suitabilityGroup,
          ),
        ],
      ),
    );
  }

  Widget _buildWindSpeed() {
    return SizedBox(
      child: Column(
        children: [
          AutoSizeText(
            'Wind Speed',
            style: TextStyle(fontSize: 14),
            group: headingGroup,
          ),
          AutoSizeText(
            '${_weather!.daily!.first.windSpeed!.toStringAsFixed(1)}\u{00A0}m/s',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            group: parameterGroup,
          ),
          AutoSizeText(
            "Suitability: " +
                (windContribution(_weather!.daily!.first.windSpeed!) * 100)
                    .toStringAsFixed(0) +
                "%",
            style: TextStyle(
              fontSize: 12,
            ),
            group: suitabilityGroup,
          ),
        ],
      ),
    );
  }

  Widget _buildWindGust() {
    return SizedBox(
      child: Column(
        children: [
          AutoSizeText(
            'Wind Gust',
            style: TextStyle(fontSize: 14),
            group: headingGroup,
          ),
          AutoSizeText(
            '${_weather!.daily!.first.windGust!.toStringAsFixed(1)}\u{00A0}m/s',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            group: parameterGroup,
          ),
          AutoSizeText(
            "Suitability: " +
                (windContribution(_weather!.daily!.first.windGust!) * 100)
                    .toStringAsFixed(0) +
                "%",
            style: TextStyle(
              fontSize: 12,
            ),
            group: suitabilityGroup,
          ),
        ],
      ),
    );
  }

  Widget _buildPrecipitation() {
    return SizedBox(
      child: Column(
        children: [
          AutoSizeText(
            'Precipitation',
            style: TextStyle(fontSize: 14),
            group: headingGroup,
          ),
          AutoSizeText(
            (_weather!.daily!.first.pop! * 100).toStringAsFixed(0) + "%",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            group: parameterGroup,
          ),
          AutoSizeText(
            "Suitability: " +
                (rainContribution(_weather!.daily!.first.pop!) * 100)
                    .toStringAsFixed(0) +
                "%",
            style: TextStyle(
              fontSize: 12,
            ),
            group: suitabilityGroup,
          ),
        ],
      ),
    );
  }

  Widget _buildHumidity() {
    return SizedBox(
      child: Column(
        children: [
          AutoSizeText(
            'Humidity',
            style: TextStyle(fontSize: 14),
            group: headingGroup,
          ),
          AutoSizeText(
            '${_weather!.daily!.first.humidity!}%',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            group: parameterGroup,
          ),
          AutoSizeText(
            "Suitability: " +
                (humidityContribution(_weather!.daily!.first.humidity!) * 100)
                    .toStringAsFixed(0) +
                "%",
            style: TextStyle(
              fontSize: 12,
            ),
            group: suitabilityGroup,
          ),
        ],
      ),
    );
  }

  Widget _buildCloudiness() {
    return SizedBox(
      child: Column(
        children: [
          AutoSizeText(
            'Cloudiness',
            style: TextStyle(fontSize: 14),
            group: headingGroup,
          ),
          AutoSizeText(
            '${_weather!.daily!.first.clouds!}%',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            group: parameterGroup,
          ),
          AutoSizeText(
            "Suitability: " +
                (cloudinessContribution(_weather!.daily!.first.clouds!) * 100)
                    .toStringAsFixed(0) +
                "%",
            style: TextStyle(fontSize: 12),
            group: suitabilityGroup,
          ),
        ],
      ),
    );
  }

  Widget _buildAirPressure() {
    return SizedBox(
      child: Column(
        children: [
          AutoSizeText(
            'Air Pressure',
            style: TextStyle(fontSize: 14),
            group: headingGroup,
          ),
          AutoSizeText(
            (_weather!.daily!.first.pressure!).toStringAsFixed(0) +
                "\u{00A0}hPa",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            group: parameterGroup,
          ),
          AutoSizeText(
            "Suitability: " +
                (pressureContribution(_weather!.daily!.first.pressure!) * 100)
                    .toStringAsFixed(0) +
                "%",
            style: TextStyle(
              fontSize: 12,
            ),
            group: suitabilityGroup,
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
            _buildFuturePercentage(0),
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
          Text(
            weekdayFormat.format(DateTime.fromMillisecondsSinceEpoch(
                (_weather!.daily!.elementAt(i).dt! +
                        _weather!.timezoneOffset!) *
                    1000,
                isUtc: true)),
            style: getColorTextStyle(_dailyPercentage[i]),
          ),
        ),
        DataCell(
          Text(
            ' ${_weather!.daily!.elementAt(i).temp!.day!.toStringAsFixed(1)}°C',
            style: getColorTextStyle(_dailyPercentage[i]),
          ),
        ),
        DataCell(
          Text(
            ' ${_weather!.daily!.elementAt(i).windSpeed!.toStringAsFixed(1)}\u{00A0}m/s',
            style: getColorTextStyle(_dailyPercentage[i]),
          ),
        ),
        DataCell(
          Text(
            ' ${_dailyPercentage[i]}%',
            style: getColorTextStyle(_dailyPercentage[i]),
          ),
        ),
      ],
    );
  }

  void handleLocationError(e) {
    if (e != null && e.toString().startsWith('Exception: ')) {
      handleError(e);

      // Remove the percentage from the Android widget
      clearAppWidget();

      // Wait then show location search dialog
      Future.delayed(const Duration(milliseconds: 3000), () {
        _findPlaceName();
      });
    } else {
      print('unhandledError: $e');
    }
  }

  void handleSearchError(e) {
    handleError(e);

    // Wait then try to get weather again
    Future.delayed(const Duration(milliseconds: 3000), () {
      _getLocation();
    });
  }

  void handleError(e) {
    setState(() {
      errorMessage = e.toString().replaceFirst('^Exception: ', '');
      print('handleError: $e');
    });
    //throw e;
  }

/*
  FutureBuilder<WeatherResponse> weatherText() {
    return FutureBuilder<WeatherResponse>(
      future: _futureWeather,
      builder: (context, weather) {
        if (weather.hasData) {
          return Text(
            '${weather.requireData.daily?.first.temp?.max}',
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
