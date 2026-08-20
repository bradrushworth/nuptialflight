import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'controller/arangodb.dart';
import 'controller/nuptials.dart';
import 'controller/screenshots_mobile.dart'
    if (dart.library.io) 'controller/screenshots_mobile.dart'
    if (dart.library.js) 'controller/screenshots_other.dart';
import 'controller/services.dart';
import 'controller/units.dart';
import 'controller/widgets_other.dart'
    if (dart.library.io) 'controller/widgets_mobile.dart'
    if (dart.library.js) 'controller/widgets_other.dart';
import 'controller/weather_fetcher.dart';
import 'responses/onecall_response.dart';
import 'responses/weather_response.dart';
import 'utils.dart';
import 'view/app_icons.dart';
import 'view/hero_card.dart';
import 'view/hourly_chart.dart';
import 'view/map.dart';
import 'view/report_sheet.dart';
import 'view/verdict.dart';
import 'view/week_list.dart';
import 'view/why_panel.dart';

// The verdict thresholds moved to view/verdict.dart; re-exported so existing
// importers (services.dart) keep working.
export 'view/verdict.dart' show greenThreshold, amberThreshold;

final DateFormat longDateFormat = DateFormat.MMMEd();
final DateFormat weekdayFormat = DateFormat("E");
final DateFormat timeOfDayFormat = DateFormat("ha");

const String kGoogleApiKey = 'AIzaSyDNaPQ01hKnTmVRQoT_FM1ZTTxDnw6GoOU';

/// The stable brand seed (eucalypt green). The whole-app red/amber retint is
/// gone — verdict colours now appear only on the data itself (hero card,
/// pills, chart bars), never on the chrome.
const Color kSeedColor = Color(0xFF3D6B4F);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initialiseWidget();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode && kIsWeb,
      builder: (context) => MyMaterialApp(), // Wrap your app
      tools: kIsWeb ? [...DevicePreview.defaultTools, simpleScreenShotModesPlugin] : [],
    ),
  );
  // Start parsing the forest-model JSON assets without blocking the first
  // frame; _getWeather() awaits Nuptials.ensureLoaded() before scoring.
  unawaited(Nuptials.ensureLoaded());
  // Load the metric/imperial display preference.
  unawaited(Units.load());
  // Initialise background services without blocking the first frame.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    unawaited(initializeService());
  }
}

class MyMaterialApp extends StatelessWidget {
  MyMaterialApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ColorScheme lightScheme = ColorScheme.fromSeed(seedColor: kSeedColor);
    final ColorScheme darkScheme =
        ColorScheme.fromSeed(seedColor: kSeedColor, brightness: Brightness.dark);
    return MaterialApp(
      title: 'Ant Nuptial Flight Predictor',
      // Hide the dev banner
      debugShowCheckedModeBanner: false,
      // For DevicePreview
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
      darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
      themeMode: ThemeMode.system,
      home: MyHomePage(weatherFetcher: WeatherFetcher()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  // When true the page shows a manually chosen location and disables reporting
  // (reports must come from the user's real, current location).
  final bool fixedLocation;
  final WeatherFetcher weatherFetcher;

  MyHomePage({
    Key? key,
    this.fixedLocation = false,
    required this.weatherFetcher,
  }) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String corsProxyUrl = 'https://api.bitbot.com.au/cors/https://maps.googleapis.com/maps/api';

  List<Choice> choices = <Choice>[];
  late final bool fixedLocation;
  late final WeatherFetcher weatherFetcher;

  // App/package metadata shown in the menu (populated from PackageInfo).
  String? appName, packageName, version, buildNumber;
  // Reverse-geocoded place label for the current location (or "Unknown Location").
  String? _geocoding;
  // The three OWM payloads: present snapshot, 24h history, and the 8-day forecast.
  CurrentWeatherResponse? _currentWeather;
  OneCallResponse? _historical;
  OneCallResponse? _weather;
  // `loaded` gates the first-paint spinner; `errorMessage` drives the error screen.
  bool loaded = false;
  String? errorMessage;
  // Refreshes the location + weather every hour while the app is open.
  Timer? _everyHour;

  // Rolling 48-slot hourly probability list (the API can return fewer entries;
  // _updateWeather zero-fills the tail so the list length is always safe).
  final List<int> _hourlyPercentage = List<int>.filled(48, 0);
  // Today + next 7 days daily probabilities (indices 1..7 used in the week list).
  final List<int> _dailyPercentage = List<int>.filled(8, 0);

  @override
  void initState() {
    super.initState();
    this.fixedLocation = widget.fixedLocation;
    this.weatherFetcher = widget.weatherFetcher;
    createMenu();
    widgetInitState(_loadData);
    _loadData(); // This will load data every time app is opened
  }

  @override
  void dispose() {
    super.dispose();
    _everyHour?.cancel();
  }

  /// Builds the overflow-menu entries (links + report issue). Location search
  /// and the map moved out of the overflow into the app bar; the exact set of
  /// store links depends on the platform.
  void createMenu() {
    choices = <Choice>[];
    choices.add(
      Choice(
        title: 'Report Issue',
        url:
            'mailto:bitbot@bitbot.com.au?subject=Help with Ant Flight (' +
            (kIsWeb ? 'Web' : toBeginningOfSentenceCase(Platform.operatingSystem)!) +
            ' Version ' +
            (version ?? '?') +
            '+' +
            (buildNumber ?? '?') +
            ')',
        icon: Icons.email,
      ),
    );
    if (!kIsWeb) {
      choices.add(
        const Choice(title: 'Web App', url: 'https://nuptialflight.app/', icon: Icons.web),
      );
    }
    if (kIsWeb || Platform.isAndroid || Platform.isFuchsia) {
      choices.add(
        const Choice(
          title: 'Android',
          url: 'https://play.google.com/store/apps/details?id=au.com.bitbot.nuptialflight',
          icon: Icons.android,
        ),
      );
    }
    if (kIsWeb || Platform.isIOS || Platform.isMacOS) {
      choices.add(
        const Choice(
          title: 'IOS',
          url: 'https://apps.apple.com/us/app/ant-nuptial-flight-predictor/id1603373687',
          icon: Icons.phone_iphone,
        ),
      );
    }
    choices.add(
      const Choice(
        title: 'Source Code',
        url: 'https://github.com/bradrushworth/nuptialflight',
        icon: Icons.source,
      ),
    );
    if (kIsWeb) {
      choices.add(
        const Choice(
          title: 'Buy Brad Coffee',
          url: 'https://www.buymeacoffee.com/bitbot',
          icon: Icons.coffee,
        ),
      );
    }
  }

  void _loadData() async {
    await dotenv.load(fileName: 'assets/.env');

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Requesting notification permission can block the first data fetch, so do
    // not await it. The permission prompt resolves in parallel with the network
    // calls that actually fill the first page.
    unawaited(
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission(),
    );

    // Get location data now and every hour
    _getLocation(false);
    _everyHour = Timer.periodic(Duration(hours: 1), (Timer t) {
      debugPrint('Periodic state refresh...');
      _getLocation(true);
    });

    // Get platform information and then rebuild the menu
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        appName = packageInfo.appName;
        packageName = packageInfo.packageName;
        version = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
        createMenu(); // After version and buildNumber is loaded
      });
    });
  }

  void _getLocation(bool forceUpdate) {
    setState(() {
      errorMessage = null;
    });

    if (fixedLocation) {
      _getWeather()
          .then(
            (nothing) =>
                debugPrint("findLocation(fixed): _dailyPercentage=" + _dailyPercentage.toString()),
          )
          .catchError((e) => handleError(e));
    } else {
      // Get a fast passive location first and render the page. Only fall back to
      // an active GPS fix (with a short timeout) if the passive lookup failed,
      // which avoids doing the whole 3-call weather fetch twice on every launch.
      weatherFetcher.findLocation(false).then((updated) {
        if (updated || forceUpdate) {
          return _getWeather().then((_) => updateAppWidget(_dailyPercentage));
        }
        debugPrint("findLocation(passive): no update _percentage=" + _dailyPercentage.toString());
        // Passive location unavailable (e.g. first launch) - try active GPS.
        return weatherFetcher
            .findLocation(true)
            .then((updated2) => updated2 ? _getWeather() : Future.value())
            .then((_) => updateAppWidget(_dailyPercentage))
            .then(
              (nothing) =>
                  debugPrint("findLocation(active): _percentage=" + _dailyPercentage.toString()),
            );
      }).catchError((e) => handleLocationError(e));
    }
  }

  /// Fetches the three weather payloads in parallel, waits for the forest models
  /// to be ready, then scores them via [_updateWeather]. Safe to call once the
  /// location is known.
  Future<void> _getWeather() {
    DateTime now = new DateTime.now().toUtc();
    DateTime today = new DateTime.utc(now.year, now.month, now.day);
    int dt = today.millisecondsSinceEpoch ~/ 1000;

    return Future.wait([
          weatherFetcher.fetchNearestWeatherLocation(),
          weatherFetcher.fetchHistoricalWeather(dt),
          weatherFetcher.fetchWeather(),
          // Ensure the forest models are parsed before _updateWeather scores.
          Nuptials.ensureLoaded(),
        ])
        .then((List responses) => _updateWeather(responses[0], responses[1], responses[2]))
        .catchError((e) => handleError(e));
  }

  void _findPlaceName() {
    PlacesAutocomplete.show(
          context: context,
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
          builder: (_) => MyHomePage(fixedLocation: true, weatherFetcher: newWeatherFetcher),
          fullscreenDialog: true,
          maintainState: true,
        ),
      );
    } else {
      // User dismissed the search: stay on the current page.
      debugPrint('_findPlaceName: user cancelled search');
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

  /// Consumes the three fetched payloads, resolves the place label, scores
  /// every hour/day through the forest models, and finally records the weather
  /// to the backend. Runs inside setState so the UI updates in one pass.
  void _updateWeather(
    CurrentWeatherResponse current,
    OneCallResponse historical,
    OneCallResponse weather,
  ) {
    setState(() {
      _currentWeather = current;
      _historical = historical;
      _weather = weather;

      if (current.name == null) {
        developer.log("Unexpected reverse geocoding response", name: 'WeatherFetcher');
        _geocoding = "Unknown Location";
      } else {
        _geocoding = current.name;
      }
      debugPrint('_updateWeather: geocoding=$_geocoding');

      // The API can return fewer hourly entries than our rolling window;
      // guard the index and zero-fill the tail instead of crashing.
      final List<Hourly> hourly = weather.hourly ?? <Hourly>[];
      final int hourlyCount = min(_hourlyPercentage.length, hourly.length);
      for (int i = 0; i < _hourlyPercentage.length; i++) {
        _hourlyPercentage[i] = i < hourlyCount
            ? (nuptialHourlyPercentageModel(weather.lat!, weather.lon!, hourly[i]) * 100.0).toInt()
            : 0;
      }

      final List<Daily> daily = weather.daily ?? <Daily>[];
      final int dailyCount = min(_dailyPercentage.length, daily.length);
      for (int i = 0; i < _dailyPercentage.length; i++) {
        _dailyPercentage[i] = i < dailyCount
            ? (nuptialDailyPercentageModel(weather.lat!, weather.lon!, daily[i],
                        pop1: i + 1 < daily.length ? daily[i + 1].pop : null,
                        pop2: i + 2 < daily.length ? daily[i + 2].pop : null) *
                    100.0)
                .toInt()
            : 0;
      }

      loaded = true;
    });
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

  /// The best three-hour flight window in the next 24 hours, computed from the
  /// hourly model scores (replaces the old hardcoded 11am/7pm tiles). Null
  /// when no window clears the "possible" bar.
  String? _bestWindowLabel() {
    final List<Hourly>? hourly = _weather?.hourly;
    final int? offset = _weather?.timezoneOffset;
    if (hourly == null || offset == null) return null;
    final int n = min(24, min(hourly.length, _hourlyPercentage.length));
    if (n < 3) return null;
    int bestStart = 0;
    double bestAvg = -1;
    for (int i = 0; i + 3 <= n; i++) {
      final double avg =
          (_hourlyPercentage[i] + _hourlyPercentage[i + 1] + _hourlyPercentage[i + 2]) / 3.0;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestStart = i;
      }
    }
    if (bestAvg < amberThreshold) return null;
    String fmt(int dt) => timeOfDayFormat
        .format(DateTime.fromMillisecondsSinceEpoch((dt + offset) * 1000, isUtc: true))
        .toLowerCase();
    final String start = fmt(hourly[bestStart].dt!);
    final String end = fmt(hourly[bestStart + 2].dt! + 3600);
    return 'Best window $start–$end';
  }

  /// "Likely small species" — which queen-size class is most in season right
  /// now (from the per-size seasonal prior). Null when a flight is unlikely.
  String? _sizeLine() {
    final int pct = _dailyPercentage[0];
    if (pct < amberThreshold || _weather?.lat == null) return null;
    final Map<String, int> sizePct =
        sizeSeasonalPercentages(pct, _weather!.lat!, DateTime.now().toUtc());
    String bestSize = 'small';
    int best = -1;
    for (final MapEntry<String, int> e in sizePct.entries) {
      if (e.value > best) {
        best = e.value;
        bestSize = e.key;
      }
    }
    return 'Likely $bestSize species';
  }

  /// The three strongest drivers of today's forecast, from the model's own
  /// per-attribute gauges (0.5 = the model is indifferent).
  List<WhyDriver> _drivers() {
    final Daily? d = _weather?.daily?.isNotEmpty == true ? _weather!.daily!.first : null;
    if (d == null) return const <WhyDriver>[];
    final List<MapEntry<String, double>> entries = <MapEntry<String, double>>[
      if (d.temp?.day != null)
        MapEntry('Temp ${Units.temp(d.temp!.day!, decimals: 0, withUnit: false)}',
            temperatureContribution(d.temp!.day!)),
      if (d.windSpeed != null)
        MapEntry('Wind ${Units.speed(d.windSpeed!, decimals: 0)}', windContribution(d.windSpeed!)),
      if (d.humidity != null)
        MapEntry('Humidity ${d.humidity}%', humidityContribution(d.humidity!)),
      if (d.clouds != null) MapEntry('Cloud ${d.clouds}%', cloudinessContribution(d.clouds!)),
      if (d.pop != null)
        MapEntry('Rain ${(d.pop! * 100).round()}%', rainContribution(d.pop!)),
      if (d.pressure != null) MapEntry('Pressure', pressureContribution(d.pressure!)),
    ];
    entries.sort((a, b) => (b.value - 0.5).abs().compareTo((a.value - 0.5).abs()));
    return entries
        .take(3)
        .map((e) => WhyDriver(
              label: e.key,
              direction: e.value >= 0.55 ? 1 : e.value <= 0.45 ? -1 : 0,
            ))
        .toList();
  }

  void _openWhySheet() {
    final Daily d = _weather!.daily!.first;
    showWhySheet(
      context,
      conditions: <String>[
        if (d.temp?.day != null) Units.temp(d.temp!.day!),
        if (d.windSpeed != null) '${Units.speed(d.windSpeed!)} wind',
        if (d.humidity != null) '${d.humidity}% humidity',
        if (d.pressure != null) '${d.pressure!.toStringAsFixed(0)}\u{00A0}hPa',
        if (d.dewPoint != null)
          'Dew point ${Units.temp(d.dewPoint!, decimals: 0, withUnit: false)}',
      ],
      features: <WhyFeature>[
        if (d.temp?.day != null)
          WhyFeature(
            name: 'Temperature',
            note: 'Warmth is the model\'s strongest signal',
            fn: temperatureContribution,
            lo: 0,
            hi: 40,
            current: d.temp!.day!.toDouble(),
          ),
        if (d.windSpeed != null)
          WhyFeature(
            name: 'Wind',
            note: 'Calm air scores best; strong wind grounds queens',
            fn: windContribution,
            lo: 0,
            hi: 20,
            current: d.windSpeed!.toDouble(),
          ),
        if (d.humidity != null)
          WhyFeature(
            name: 'Humidity',
            note: 'Moist air after rain generally helps',
            fn: humidityContribution,
            lo: 0,
            hi: 100,
            current: d.humidity!.toDouble(),
          ),
        if (d.clouds != null)
          WhyFeature(
            name: 'Cloud cover',
            note: 'The model\'s learned response to cloudiness',
            fn: cloudinessContribution,
            lo: 0,
            hi: 100,
            current: d.clouds!.toDouble(),
          ),
        if (d.pop != null)
          WhyFeature(
            name: 'Rain chance',
            note: 'Today\'s probability of precipitation',
            fn: rainContribution,
            lo: 0,
            hi: 1,
            current: d.pop!.toDouble(),
          ),
        if (d.pressure != null)
          WhyFeature(
            name: 'Air pressure',
            note: 'Pressure rarely moves the forecast much',
            fn: pressureContribution,
            lo: 980,
            hi: 1040,
            current: d.pressure!.toDouble(),
          ),
      ],
      sizePercentages: _weather?.lat != null
          ? sizeSeasonalPercentages(_dailyPercentage[0], _weather!.lat!, DateTime.now().toUtc())
          : const <String, int>{},
    );
  }

  /// Opens the report bottom sheet and submits the result. After a real
  /// sighting, follows up with how many other flights were reported nearby —
  /// the reward that closes the crowd-sourcing loop.
  Future<void> _openReportSheet() async {
    final ReportResult? result =
        await showReportSheet(context, locationLabel: _geocoding ?? 'your location');
    if (result == null || !mounted) return;

    if (fixedLocation) {
      _showSnack('Reports must come from your real, current location.');
      return;
    }
    if (kDebugMode) {
      _showSnack('Reporting is disabled in debug builds.');
      return;
    }

    ArangoSingleton().updateWeather(
      version,
      buildNumber,
      result.size,
      _weather,
      _historical,
      _currentWeather,
    );
    _showSnack(result.sawNothing
        ? 'Thanks — no-flight reports improve the model too.'
        : 'Thank you! Your sighting helps train the forecast.');
    if (!result.sawNothing) {
      unawaited(_showNearbyReports());
    }
  }

  /// Fetches confirmed flights within 500 km in the last 24 h and surfaces the
  /// count, so reporters immediately see they are part of a bigger event.
  Future<void> _showNearbyReports() async {
    try {
      final latLng = weatherFetcher.getLocation();
      final Position position = Position(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
      final List flights =
          await ArangoSingleton().getRecentFlightsNearMe(position, -24 * 60);
      if (!mounted || flights.isEmpty) return;
      final int n = flights.length;
      _showSnack(
          '$n flight${n == 1 ? '' : 's'} reported within 500 km in the last 24 h — see the map!');
    } catch (e) {
      debugPrint('_showNearbyReports: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: Units.imperial,
      builder: (context, imperial, _) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            titleSpacing: 12,
            title: Align(alignment: Alignment.centerLeft, child: _locationChip(scheme)),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.map_outlined),
                tooltip: 'Show map',
                onPressed: _showMap,
              ),
              PopupMenuButton<Choice>(
                tooltip: 'More options',
                onSelected: (Choice c) {
                  if (c.url == '_units') {
                    Units.toggle();
                  } else {
                    Utils.launchURL('${c.url}');
                  }
                },
                itemBuilder: (BuildContext context) {
                  final List<PopupMenuEntry<Choice>> items = <PopupMenuEntry<Choice>>[
                    PopupMenuItem<Choice>(
                      value: Choice(
                        title: imperial ? 'Use °C · m/s' : 'Use °F · mph',
                        url: '_units',
                        icon: Icons.thermostat,
                      ),
                      child: _menuRow(
                          Icons.thermostat, imperial ? 'Use °C · m/s' : 'Use °F · mph'),
                    ),
                    const PopupMenuDivider(),
                  ];
                  items.addAll(choices.map((Choice choice) {
                    return PopupMenuItem<Choice>(
                      value: choice,
                      child: _menuRow(choice.icon, choice.title),
                    );
                  }));
                  return items;
                },
              ),
            ],
          ),
          body: errorMessage != null
              ? _buildErrorMessage()
              : !loaded
                  ? _buildLoading()
                  : _buildContent(context),

          /// Report a nuptial flight at the current location.
          floatingActionButton: fixedLocation || !loaded || errorMessage != null
              ? null
              : FloatingActionButton.extended(
                  onPressed: _openReportSheet,
                  tooltip: 'Report a nuptial flight you saw',
                  icon: const Icon(AppIcons.wingedAnt, size: 26),
                  label: const Text('Report flight'),
                ),
        );
      },
    );
  }

  Widget _menuRow(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 14),
        Text(title),
      ],
    );
  }

  Widget _locationChip(ColorScheme scheme) {
    return Semantics(
      button: true,
      label: 'Location: ${_geocoding ?? 'locating'}. Tap to choose another place.',
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: _findPlaceName,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.place_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _geocoding ?? 'Locating…',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 18, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final OneCallResponse weather = _weather!;
    final List<Hourly> hourly = weather.hourly ?? <Hourly>[];
    final int hourlyCount = min(24, min(hourly.length, _hourlyPercentage.length));

    final String dateLine = hourly.isNotEmpty
        ? 'Today · ' +
            longDateFormat.format(DateTime.fromMillisecondsSinceEpoch(
                (hourly.first.dt! + weather.timezoneOffset!) * 1000,
                isUtc: true))
        : 'Today';
    final String? description = hourly.isNotEmpty && hourly.first.weather?.isNotEmpty == true
        ? toBeginningOfSentenceCase(hourly.first.weather!.first.description)
        : null;
    final num? dayTemp = weather.daily?.isNotEmpty == true ? weather.daily!.first.temp?.day : null;
    final String conditionLine = [
      if (description != null) description,
      if (dayTemp != null) Units.temp(dayTemp, decimals: 0),
    ].join(' · ');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeroVerdictCard(
                percentage: _dailyPercentage[0],
                dateLine: dateLine,
                conditionLine: conditionLine,
                bestWindow: _bestWindowLabel(),
                sizeLine: _sizeLine(),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Next 24 hours',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    'flight confidence by hour',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              HourlyChart(
                points: [
                  for (int i = 0; i < hourlyCount; i++)
                    HourlyPoint(hourly[i].dt!, _hourlyPercentage[i]),
                ],
                timezoneOffsetSeconds: weather.timezoneOffset ?? 0,
              ),
              const SizedBox(height: 14),
              WhyChipsRow(drivers: _drivers(), onTap: _openWhySheet),
              const SizedBox(height: 22),
              Text('Upcoming week',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              WeekList(days: _weekDays()),
              const SizedBox(height: 16),
              Text(
                (kIsWeb ? 'Web' : toBeginningOfSentenceCase(Platform.operatingSystem)) +
                    ' Version $version+$buildNumber',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: scheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<WeekDay> _weekDays() {
    final List<Daily> daily = _weather?.daily ?? <Daily>[];
    final int offset = _weather?.timezoneOffset ?? 0;
    final int n = min(_dailyPercentage.length, daily.length);
    return [
      for (int i = 1; i < n; i++)
        WeekDay(
          day: weekdayFormat.format(DateTime.fromMillisecondsSinceEpoch(
              (daily[i].dt! + offset) * 1000,
              isUtc: true)),
          temp: daily[i].temp?.day != null
              ? Units.temp(daily[i].temp!.day!, decimals: 0, withUnit: false)
              : '–',
          wind: daily[i].windGust != null || daily[i].windSpeed != null
              ? Units.speed(daily[i].windGust ?? daily[i].windSpeed!)
              : '–',
          percentage: _dailyPercentage[i],
        ),
    ];
  }

  Widget _buildErrorMessage() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.cloud_off, size: 44, color: scheme.onSurfaceVariant),
              const SizedBox(height: 14),
              Text(
                '$errorMessage',
                style: const TextStyle(fontSize: 17, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => _getLocation(true),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Try again'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _findPlaceName,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Choose a location'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Fetching your local weather…',
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void handleLocationError(e) {
    if (e != null && e.toString().startsWith('Exception: ')) {
      handleError(e);

      // Remove the percentage from the Android widget
      clearAppWidget();
    } else {
      developer.log('unhandledError: $e', error: e);
      throw e;
    }
  }

  void handleError(e) {
    if (e != null && e.toString().startsWith('Exception: ')) {
      setState(() {
        loaded = true;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        developer.log('handleError: $e', error: e);
      });
    } else {
      setState(() {
        loaded = true;
        errorMessage =
            'Unexpected error occurred. Please report to bitbot@bitbot.com.au ' + e.toString();
        developer.log('unhandledError: $e', error: e);
      });
      throw e;
    }
  }
}

/// A single overflow-menu / action item. [title] is the displayed label, [url]
/// the target (opened via Utils.launchURL for http(s)/mailto, or the special
/// '_units' marker for the units toggle), and [icon] the leading glyph.
class Choice {
  const Choice({required this.title, required this.url, required this.icon});

  final String title;
  final String url;
  final IconData icon;
}
