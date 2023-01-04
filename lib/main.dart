//import 'package:nuptialflight/responses/reverse_geocoding_response.dart';
//import 'dart:developer' as developer;

import 'dart:async';
import 'dart:developer' as developer;
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
import 'package:nuptialflight/controller/arangodb.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'controller/nuptials.dart';
import 'controller/screenshots_mobile.dart'
    if (dart.library.io) 'controller/screenshots_mobile.dart'
    if (dart.library.js) 'controller/screenshots_other.dart';
import 'controller/weather_fetcher.dart';
import 'controller/widgets_other.dart'
    if (dart.library.io) 'controller/widgets_mobile.dart'
    if (dart.library.js) 'controller/widgets_other.dart';
import 'responses/onecall_response.dart';
import 'responses/weather_response.dart';
import 'utils.dart';
import 'view/map.dart';

final DateFormat dateFormat = DateFormat("yyyy-MM-dd");
final DateFormat longDateFormat = DateFormat.MMMEd();
final DateFormat weekdayFormat = DateFormat("E");
final DateFormat timeOfDayFormat = DateFormat("ha");

const String kGoogleApiKey = 'AIzaSyDNaPQ01hKnTmVRQoT_FM1ZTTxDnw6GoOU';

const int greenThreshold = 60;
const int amberThreshold = 40;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initialiseWidget();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode && kIsWeb,
      builder: (context) => MyMaterialApp(), // Wrap your app
      tools: kIsWeb ? [...DevicePreview.defaultTools, simpleScreenShotModesPlugin] : [],
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
        theme: ThemeData(brightness: Brightness.light, primarySwatch: primarySwatch),
        darkTheme: ThemeData(brightness: Brightness.dark, primarySwatch: primarySwatch),
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
  static const _kFontFam = 'WingedAnt';
  static const String? _kFontPkg = null;
  static const IconData winged_ant =
      IconData(0xe800, fontFamily: _kFontFam, fontPackage: _kFontPkg);
  static const IconData halictus_rubicundus_silhouette =
      IconData(0xe801, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  final String corsProxyUrl = 'https://api.bitbot.com.au/cors/https://maps.googleapis.com/maps/api';

  final AutoSizeGroup headingGroup = AutoSizeGroup();
  final AutoSizeGroup parameterGroup = AutoSizeGroup();
  final AutoSizeGroup suitabilityGroup = AutoSizeGroup();
  final AutoSizeGroup histogramGroup = AutoSizeGroup();
  final AutoSizeGroup histogramLegendGroup = AutoSizeGroup();

  late final List<Choice> choices;
  late final bool fixedLocation;
  late final WeatherFetcher weatherFetcher;

  String? appName, packageName, version, buildNumber;
  String? _geocoding;
  CurrentWeatherResponse? _currentWeather;
  OneCallResponse? _historical;
  OneCallResponse? _weather;
  bool loaded = false;
  String? errorMessage;

  //int _diurnalPercentage = 0;
  //int _nocturnalPercentage = 0;
  Hourly? _indexOfDiurnalHour;
  Hourly? _indexOfNocturnalHour;
  int _diurnalHourPercentage = 0;
  int _nocturnalHourPercentage = 0;
  List<int> _hourlyPercentage = List.generate(
    24,
    (index) {
      return 0;
    },
  );
  List<int> _dailyPercentage = [0, 0, 0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    this.fixedLocation = widget.fixedLocation;
    this.weatherFetcher = widget.weatherFetcher;
    widgetInitState(_loadData);
    _loadData(); // This will load data every time app is opened
  }

  void createMenu() {
    choices = <Choice>[];
    choices.add(const Choice(title: 'Select Location', url: '', icon: Icons.add_location_alt));
    choices.add(const Choice(title: 'Show Map', url: '', icon: Icons.map));
    choices.add(Choice(
        title: 'Report Issue',
        url: 'mailto:bitbot@bitbot.com.au?subject=Help with Ant Flight (' +
            (kIsWeb ? 'Web' : toBeginningOfSentenceCase(Platform.operatingSystem)!) +
            ' Version ' +
            (version ?? '?') +
            '+' +
            (buildNumber ?? '?') +
            ')',
        icon: Icons.email));
    if (!kIsWeb) {
      choices
          .add(const Choice(title: 'Web App', url: 'https://nuptialflight.app/', icon: Icons.web));
    }
    if (kIsWeb || Platform.isAndroid || Platform.isFuchsia) {
      choices.add(const Choice(
          title: 'Android',
          url: 'https://play.google.com/store/apps/details?id=au.com.bitbot.nuptialflight',
          icon: Icons.android));
    }
    if (kIsWeb || Platform.isIOS || Platform.isMacOS) {
      choices.add(const Choice(
          title: 'IOS',
          url: 'https://apps.apple.com/us/app/ant-nuptial-flight-predictor/id1603373687',
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
      createMenu(); // After version and buildNumber is loaded
    });
  }

  void _getLocation() {
    setState(() {
      errorMessage = null;
    });

    if (fixedLocation) {
      _getWeather()
          .then((nothing) =>
              print("findLocation(fixed): _dailyPercentage=" + _dailyPercentage.toString()))
          .catchError((e) => handleError(e));
    } else {
      // Try to passively then actively determine the location.
      // Only update the Android widget for the current location.
      weatherFetcher
          .findLocation(false)
          .then((updated) => updated ? _getWeather() : Future.value())
          .then((nothing) => updateAppWidget(_dailyPercentage))
          .then((nothing) =>
              print("findLocation(passive): _percentage=" + _dailyPercentage.toString()))
          .then((nothing) => weatherFetcher.findLocation(true))
          .then((updated) => updated ? _getWeather() : Future.value())
          .then((nothing) => updateAppWidget(_dailyPercentage))
          .then((nothing) =>
              print("findLocation(active): _percentage=" + _dailyPercentage.toString()))
          .catchError((e) => handleLocationError(e));
    }
  }

  Future<void> _getWeather() {
    DateTime now = new DateTime.now();
    DateTime today = new DateTime(now.year, now.month, now.day);
    int dt = today.millisecondsSinceEpoch ~/ 1000;

    return Future.wait([
      weatherFetcher.fetchNearestWeatherLocation(),
      weatherFetcher.fetchHistoricalWeather(dt),
      weatherFetcher.fetchWeather(),
    ])
        .then((List responses) => _updateWeather(responses[0], responses[1], responses[2]))
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
      MaterialPageRoute(builder: (_) => MapPage(), fullscreenDialog: true, maintainState: true),
    );
  }

  void _updateWeather(
      CurrentWeatherResponse current, OneCallResponse historical, OneCallResponse weather) {
    setState(() {
      _currentWeather = current;
      if (current.name == null) {
        developer.log("Unexpected reverse geocoding response", name: 'WeatherFetcher');
        _geocoding = "Unknown Location";
      } else {
        _geocoding = current.name;
      }
      print('_updateWeather: geocoding=$_geocoding');

      _historical = historical;
      _indexOfDiurnalHour = historical.hourly!.firstWhere((e) =>
          timeOfDayFormat.format(DateTime.fromMillisecondsSinceEpoch(
              (e.dt! + historical.timezoneOffset!) * 1000,
              isUtc: true)) ==
          '11AM');
      _diurnalHourPercentage =
          (nuptialHourlyPercentageModel(weather.lat!, _indexOfDiurnalHour!) * 100.0).toInt();

      _indexOfNocturnalHour = historical.hourly!.firstWhere((e) =>
          timeOfDayFormat.format(DateTime.fromMillisecondsSinceEpoch(
              (e.dt! + historical.timezoneOffset!) * 1000,
              isUtc: true)) ==
          '7PM');
      _nocturnalHourPercentage =
          (nuptialHourlyPercentageModel(weather.lat!, _indexOfNocturnalHour!) * 100.0).toInt();

      // Sometimes API returns less than 24 hours worth of data, but it is always the most recent
      int j = 0;
      for (int i = 24 - historical.hourly!.length; i < _hourlyPercentage.length; i++) {
        _hourlyPercentage[i] =
            (nuptialHourlyPercentageModel(weather.lat!, historical.hourly![j]) * 100.0).toInt();
        j++;
      }

      _weather = weather;
      for (int i = 0; i < _dailyPercentage.length; i++) {
        _dailyPercentage[i] =
            (nuptialDailyPercentageModel(weather.lat!, weather.daily!.elementAt(i)) * 100.0)
                .toInt();
      }

      if (_dailyPercentage[0] >= greenThreshold) {
        widget.setPrimarySwatch(Colors.lightGreen);
      } else if (_dailyPercentage[0] >= amberThreshold) {
        widget.setPrimarySwatch(Colors.amber);
      } else {
        widget.setPrimarySwatch(Colors.red);
      }
      loaded = true;
    });
    print("_updateWeather: _hourlyPercentage=" + _hourlyPercentage.toString());
    _recordWeather();
  }

  /// Feature to record all weather events
  void _recordWeather() async {
    if (fixedLocation) {
      return;
    }
    if (kDebugMode) {
      return;
    }

    ArangoSingleton().createWeather(version, buildNumber, _weather, _historical, _currentWeather);
  }

  /// Create an alert dialog
  Future<void> showAlert(String title, String message) async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"))
            ],
          );
        });
  }

  /// Feature to record user saw a nuptial flight
  void _sawNuptialFlight(String size) async {
    Navigator.of(context).pop();

    if (fixedLocation) {
      showAlert('Error', 'Can only report current location!');
      return;
    }

    if (kDebugMode) {
      showAlert('Error', 'Not supported in debug mode!');
      return;
    }

    ArangoSingleton()
        .updateWeather(version, buildNumber, size, _weather, _historical, _currentWeather);
    showAlert('Success', 'Thank you for submitting!');
  }

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
      resizeToAvoidBottomInset: true,
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
      body: LayoutBuilder(builder: (ctx, constraints) {
        return OrientationBuilder(
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
                            crossAxisCount: orientation == Orientation.portrait ? 1 : 3,
                            childAspectRatio: orientation == Orientation.portrait ? 6 : 4,
                            padding: orientation == Orientation.portrait
                                ? const EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 0,
                                  )
                                : const EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 0,
                                  ),
                            shrinkWrap: true,
                            children: [
                              _buildNuptialHeading(orientation),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  _buildTodayPercentage(orientation, 'Day', _diurnalHourPercentage),
                                  _buildTodayPercentage(orientation, 'Now', _dailyPercentage[0]),
                                  _buildTodayPercentage(
                                      orientation, 'Evening', _nocturnalHourPercentage),
                                ],
                              ),
                              if (orientation == Orientation.portrait)
                                _buildTodayHistogram(orientation),
                              _buildTodayWeather(orientation),
                            ],
                          ),
                          if (orientation == Orientation.landscape && constraints.maxHeight > 600)
                            SizedBox(
                              height: 120,
                              width: constraints.maxWidth,
                              child: _buildTodayHistogram(orientation),
                            ),
                          GridView.count(
                            crossAxisCount: orientation == Orientation.portrait ? 3 : 6,
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
                                          .format(DateTime.fromMillisecondsSinceEpoch(
                                              (_indexOfDiurnalHour!.dt! +
                                                      _weather!.timezoneOffset!) *
                                                  1000,
                                              isUtc: true))
                                          .toLowerCase() +
                                      ' Temp',
                                  _indexOfDiurnalHour!.temp!),
                              _buildTemperature('Max Temp', _weather!.daily!.first.temp!.max!),
                              _buildTemperature(
                                  timeOfDayFormat
                                          .format(DateTime.fromMillisecondsSinceEpoch(
                                              (_indexOfNocturnalHour!.dt! +
                                                      _weather!.timezoneOffset!) *
                                                  1000,
                                              isUtc: true))
                                          .toLowerCase() +
                                      ' Temp',
                                  _indexOfNocturnalHour!.temp!),
                              _buildWindSpeed(),
                              if (orientation == Orientation.portrait) _buildWindGust(),
                              _buildAirPressure(),
                              _buildHumidity(),
                              if (orientation == Orientation.portrait) _buildCloudiness(),
                              if (orientation == Orientation.portrait) _buildPrecipitation(),
                            ],
                          ),
                          _buildUpcomingWeek(orientation),
                          if (orientation == Orientation.portrait)
                            Container(padding: const EdgeInsets.symmetric(vertical: 35)),
                          if (orientation == Orientation.portrait ||
                              orientation == Orientation.landscape)
                            Text(
                                (kIsWeb
                                        ? 'Web'
                                        : toBeginningOfSentenceCase(Platform.operatingSystem)!) +
                                    ' Version $version+$buildNumber',
                                style: TextStyle(fontSize: 8, color: Colors.grey)),
                        ],
                      );
          },
        );
      }),

      /// Future feature to record that the user saw a nuptial flight today
      floatingActionButton: fixedLocation
          ? null
          : FloatingActionButton(
              onPressed: () async {
                // set up the buttons
                Widget smallButton = ElevatedButton(
                  child: Text("Small"),
                  style: ElevatedButton.styleFrom(alignment: Alignment.centerLeft),
                  onPressed: () {
                    _sawNuptialFlight('small');
                  },
                );
                Widget mediumButton = ElevatedButton(
                  child: Text("Medium"),
                  style: ElevatedButton.styleFrom(alignment: Alignment.center),
                  onPressed: () {
                    _sawNuptialFlight('medium');
                  },
                );
                Widget largeButton = ElevatedButton(
                  child: Text("Large"),
                  style: ElevatedButton.styleFrom(alignment: Alignment.centerRight),
                  onPressed: () {
                    _sawNuptialFlight('large');
                  },
                );
                // set up the AlertDialog
                AlertDialog alert = AlertDialog(
                  title: Center(child: Text('Report Nuptial Flight')),
                  content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    Container(
                      child: Text(
                          "What size queen ant did you see today? Please only report real sightings. This data trains the app.",
                          textAlign: TextAlign.center),
                    ),
                    Text(''),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[smallButton, mediumButton, largeButton],
                    ),
                  ]),
                );
                // show the dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return alert;
                  },
                );
              },
              tooltip: 'Saw Nuptial Flight',
              child: Icon(halictus_rubicundus_silhouette, size: 45, color: Colors.white),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,
    );
  }

  static TextStyle getColorTextStyle(int percentage) {
    return TextStyle(color: getColorGradient(percentage), fontWeight: FontWeight.w600);
  }

  static Color? getColorGradient(int percentage) {
    Color? color = (percentage < amberThreshold
        ? Colors.red[800]
        : (percentage < greenThreshold ? Colors.orange[800] : Colors.green[700]));

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

  static String getColorText(int percentage) {
    String? text =
        (percentage < amberThreshold ? 'No' : (percentage < greenThreshold ? 'Maybe' : 'Yes'));

    return text!;
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
          ? 'Confidence of Nuptial Flight'
          : 'Confidence of Ant\nNuptial Flight',
      style: TextStyle(
        height: orientation == Orientation.portrait ? 3.0 : 1.2,
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

  Widget _buildTodayPercentage(Orientation orientation, String heading, int percentage) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
          //getColorText(percentage),
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

  Widget _buildTodayHistogram(Orientation orientation) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(24, (index) => _buildTodayHistogramElement(index)),
    );
  }

  Widget _buildTodayHistogramElement(int index) {
    int percentage = _hourlyPercentage[index];
    return LayoutBuilder(builder: (ctx, constraints) {
      return Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
            height: constraints.maxHeight * 0.15,
            child: FittedBox(
              child: RotatedBox(
                quarterTurns: -1,
                child: AutoSizeText(
                  percentage > 0 ? '${percentage}%' : '???',
                  minFontSize: 2,
                  maxFontSize: 12,
                  stepGranularity: 1.0,
                  group: histogramGroup,
                  style: TextStyle(
                    color: getColorGradient(percentage),
                    fontSize: 2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          SizedBox(
            height: constraints.maxHeight * 0.05,
          ),
          Container(
            height: constraints.maxHeight * 0.6,
            width: 11,
            child: Stack(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    //border: Border.all(color: Colors.white, width: 1.0),
                    //color: Colors.white,//Color.fromRGBO(220, 220, 220, 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: percentage / 100,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: getColorGradient(percentage),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: constraints.maxHeight * 0.05,
          ),
          Container(
            height: constraints.maxHeight * 0.15,
            width: 13,
            child: FittedBox(
              child: AutoSizeText(
                index.toString().padLeft(2, '0'),
                minFontSize: 2,
                maxFontSize: 12,
                stepGranularity: 1.0,
                group: histogramLegendGroup,
                style: TextStyle(
                  fontSize: 2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          )
        ],
      );
    });
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
          longDateFormat.format(DateTime.fromMillisecondsSinceEpoch(
                  (_historical!.current!.dt! + _historical!.timezoneOffset!) * 1000,
                  isUtc: true)) +
              ' - ' +
              toBeginningOfSentenceCase(_historical!.current!.weather!.first.description)!,
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
            "Suitability: " + (temperatureContribution(temp) * 100).toStringAsFixed(0) + "%",
            style: TextStyle(
              fontSize: 12,
            ),
            minFontSize: 2,
            maxFontSize: 12,
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
            stepGranularity: 1.0,
            group: headingGroup,
          ),
          AutoSizeText(
            '${_indexOfDiurnalHour!.windSpeed!.toStringAsFixed(1)}\u{00A0}m/s',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            stepGranularity: 1.0,
            group: parameterGroup,
          ),
          AutoSizeText(
            "Suitability: " +
                (windContribution(_indexOfDiurnalHour!.windSpeed!) * 100).toStringAsFixed(0) +
                "%",
            style: TextStyle(
              fontSize: 12,
            ),
            minFontSize: 2,
            maxFontSize: 12,
            stepGranularity: 1.0,
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
            stepGranularity: 1.0,
            group: headingGroup,
          ),
          AutoSizeText(
            '${_weather!.daily!.first.windGust!.toStringAsFixed(1)}\u{00A0}m/s',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            stepGranularity: 1.0,
            group: parameterGroup,
          ),
          AutoSizeText(
            "Suitability: " +
                (windContribution(_weather!.daily!.first.windGust!) * 100).toStringAsFixed(0) +
                "%",
            style: TextStyle(
              fontSize: 12,
            ),
            minFontSize: 2,
            maxFontSize: 12,
            stepGranularity: 1.0,
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
            stepGranularity: 1.0,
            group: headingGroup,
          ),
          AutoSizeText(
            (_weather!.daily!.first.pop! * 100).toStringAsFixed(0) + "%",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            stepGranularity: 1.0,
            group: parameterGroup,
          ),
          AutoSizeText(
            "Suitability: " +
                (rainContribution(_weather!.daily!.first.pop!) * 100).toStringAsFixed(0) +
                "%",
            style: TextStyle(
              fontSize: 12,
            ),
            minFontSize: 2,
            maxFontSize: 12,
            stepGranularity: 1.0,
            group: suitabilityGroup,
          ),
        ],
      ),
    );
  }

  Widget _buildUVI() {
    return SizedBox(
      child: Column(
        children: [
          AutoSizeText(
            'UVI',
            style: TextStyle(fontSize: 14),
            stepGranularity: 1.0,
            group: headingGroup,
          ),
          AutoSizeText(
            (_weather!.daily!.first.uvi!).toStringAsFixed(1),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            stepGranularity: 1.0,
            group: parameterGroup,
          ),
          AutoSizeText(
            "Suitability: " +
                (uviContribution(_weather!.daily!.first.uvi!) * 100).toStringAsFixed(0) +
                "%",
            style: TextStyle(
              fontSize: 12,
            ),
            minFontSize: 2,
            maxFontSize: 12,
            stepGranularity: 1.0,
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
            stepGranularity: 1.0,
            group: headingGroup,
          ),
          AutoSizeText(
            '${_indexOfDiurnalHour!.humidity!}%',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            stepGranularity: 1.0,
            group: parameterGroup,
          ),
          AutoSizeText(
            "Suitability: " +
                (humidityContribution(_indexOfDiurnalHour!.humidity!) * 100).toStringAsFixed(0) +
                "%",
            style: TextStyle(
              fontSize: 12,
            ),
            minFontSize: 2,
            maxFontSize: 12,
            stepGranularity: 1.0,
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
            stepGranularity: 1.0,
            group: headingGroup,
          ),
          AutoSizeText(
            '${_indexOfDiurnalHour!.clouds!}%',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            stepGranularity: 1.0,
            group: parameterGroup,
          ),
          AutoSizeText(
            "Suitability: " +
                (cloudinessContribution(_indexOfDiurnalHour!.clouds!) * 100).toStringAsFixed(0) +
                "%",
            style: TextStyle(fontSize: 12),
            minFontSize: 2,
            maxFontSize: 12,
            stepGranularity: 1.0,
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
            stepGranularity: 1.0,
            group: headingGroup,
          ),
          AutoSizeText(
            (_indexOfDiurnalHour!.pressure!).toStringAsFixed(0) + "\u{00A0}hPa",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            stepGranularity: 1.0,
            group: parameterGroup,
          ),
          AutoSizeText(
            "Suitability: " +
                (pressureContribution(_indexOfDiurnalHour!.pressure!) * 100).toStringAsFixed(0) +
                "%",
            style: TextStyle(
              fontSize: 12,
            ),
            minFontSize: 2,
            maxFontSize: 12,
            stepGranularity: 1.0,
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
            DataColumn(label: Text('Confidence'), numeric: true),
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
          Text(
            weekdayFormat.format(DateTime.fromMillisecondsSinceEpoch(
                (_weather!.daily!.elementAt(i).dt! + _weather!.timezoneOffset!) * 1000,
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
            //' ' + getColorText(_dailyPercentage[i]),
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
      developer.log('unhandledError: $e', error: e);
      throw e;
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
    if (e != null && e.toString().startsWith('Exception: ')) {
      setState(() {
        loaded = true;
        errorMessage = e.toString().replaceFirst('^Exception: ', '');
        developer.log('handleError: $e', error: e);
      });
    } else {
      setState(() {
        loaded = true;
        errorMessage =
            'Unexpected error occurred. Please report to bitbot@bitbot.com.au ' + e.toString();
        developer.log('unhandledError: $e', error: e);
        print(e);
      });
      throw e;
    }
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
