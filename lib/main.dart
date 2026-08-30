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
import 'controller/flight_index.dart';
import 'controller/geo.dart';
import 'controller/nuptials.dart';
import 'controller/scoring.dart';
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
import 'view/l10n_ext.dart';
import 'view/hourly_chart.dart';
import 'view/map.dart';
import 'view/report_sheet.dart';
import 'view/week_list.dart';
import 'view/why_panel.dart';

// The verdict thresholds moved to view/verdict.dart; re-exported so existing
// importers (services.dart) keep working.
export 'view/verdict.dart' show greenThreshold, amberThreshold;

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
  // Start parsing the flight-stats asset (percentiles + calibration).
  unawaited(FlightIndex.ensureLoaded());
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
      onGenerateTitle: (context) => context.l10n.appTitle,
      // Ships in the languages of the countries that report the most flights
      // (from the flights DB): en + tr, fil, es, fr, de, pl, cs, el, pt, nl,
      // id, ms. Falls back to English for everything else.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
  OneCallResponse? _leadUp;
  // Must mirror WeatherFetcher.leadUpDays: the daily-timeline page caps at 10
  // records, so leadUpDays + 8 forecast days (today..+7) fits one response.
  static const int _leadUpDays = 2;
  bool loaded = false;
  String? errorMessage;
  // Refreshes the location + weather every hour while the app is open.
  Timer? _everyHour;

  // Rolling 48-slot hourly score list, 0..1 (the API can return fewer
  // entries; _updateWeather zero-fills the tail so the length is always safe).
  final List<double> _hourlyScore = List<double>.filled(48, 0);
  // Today + next 7 days daily scores, 0..1 (indices 1..7 feed the week list).
  final List<double> _dailyScore = List<double>.filled(8, 0);
  // Convenience int percent views of the scores (chart heights, widget).
  final List<int> _hourlyPercentage = List<int>.filled(48, 0);
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

    // Location first, and the notification prompt strictly after it. Android
    // only presents one permission dialog at a time: a location request made
    // while the notification dialog is still up is dropped without ever
    // calling back, which left a fresh install spinning on "waiting for your
    // location" until the app was restarted. Asking for notifications second
    // is also the better sell — by then the forecast is on screen.
    await _getLocation(false);
    _everyHour = Timer.periodic(Duration(hours: 1), (Timer t) {
      debugPrint('Periodic state refresh...');
      _getLocation(true);
    });

    await _requestNotificationPermission();
  }

  /// Asks for the Android notification permission (no-op elsewhere, and on
  /// Android < 13). Never rethrows: a refused or unavailable prompt must not
  /// break the page that has already loaded.
  Future<void> _requestNotificationPermission() async {
    try {
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }

  /// Resolves once the location prompt (and the fetch it triggers) has
  /// settled — errors included, since they are handled inline. Callers await
  /// it to keep permission dialogs from overlapping.
  Future<void> _getLocation(bool forceUpdate) {
    setState(() {
      errorMessage = null;
    });

    if (fixedLocation) {
      return _getWeather()
          .then(
            (nothing) =>
                debugPrint("findLocation(fixed): _dailyPercentage=" + _dailyPercentage.toString()),
          )
          .catchError((e) => handleError(e));
    } else {
      // Get a fast passive location first and render the page. Only fall back to
      // an active GPS fix (with a short timeout) if the passive lookup failed,
      // which avoids doing the whole 3-call weather fetch twice on every launch.
      return weatherFetcher.findLocation(false).then((updated) {
        if (updated || forceUpdate) {
          return _getWeather().then((_) => _pushAppWidget());
        }
        debugPrint("findLocation(passive): no update _percentage=" + _dailyPercentage.toString());
        // Passive location unavailable (e.g. first launch) - try active GPS.
        return weatherFetcher
            .findLocation(true)
            .then((updated2) => updated2 ? _getWeather() : Future.value())
            .then((_) => _pushAppWidget())
            .then(
              (nothing) =>
                  debugPrint("findLocation(active): _percentage=" + _dailyPercentage.toString()),
            );
      }).catchError((e) => handleLocationError(e));
    }
  }

  /// Fetches the three weather payloads in parallel, waits for the forest models
  /// to be ready, then scores them via [_applyWeather]. Safe to call once the
  /// location is known.
  Future<void> _getWeather() async {
    DateTime now = new DateTime.now().toUtc();
    DateTime today = new DateTime.utc(now.year, now.month, now.day);
    int dt = today.millisecondsSinceEpoch ~/ 1000;

    try {
      // Fetch current + historical + forecast in parallel. The forecast call
      // (fetchWeather) now also returns the antecedent ("lead-up") daily days
      // for the days *before* today via split-and-route - anchored a couple of
      // days into the past on the same daily-timeline request, then split at
      // today's midnight. That lead-up data is what the ML training pipeline
      // needs for lead-up-change features (days-since-rain, pressure trend,
      // first warm day after rain) - see docs/model_training_findings.md
      // (Part 4, #3) - collected at ZERO extra One Call calls.
      final List<dynamic> responses = await Future.wait([
        weatherFetcher.fetchNearestWeatherLocation(),
        weatherFetcher.fetchHistoricalWeather(dt),
        weatherFetcher.fetchWeather(),
        // Ensure the forest models and stats are parsed before scoring.
        Nuptials.ensureLoaded(),
        FlightIndex.ensureLoaded(),
      ]);
      final weather = responses[2] as OneCallResponse;
      // Derive the lead-up OneCallResponse from the forecast's split-out past
      // slice so createWeather/updateWeather keep their existing signature
      // (leadUp: OneCallResponse?). Null/empty -> no leadup doc is written.
      _leadUp = (weather.leadUpDaily != null && weather.leadUpDaily!.isNotEmpty)
          ? OneCallResponse(
              lat: weather.lat,
              lon: weather.lon,
              timezone: weather.timezone,
              timezoneOffset: weather.timezoneOffset,
              daily: weather.leadUpDaily)
          : null;
      _applyWeather(
        responses[0] as CurrentWeatherResponse,
        responses[1] as OneCallResponse,
        weather,
      );
    } catch (e) {
      handleError(e);
    }
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
  void _applyWeather(
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

      // The API can return fewer hourly/daily entries than our rolling
      // windows (4.0 timeline endpoints page their responses); the score
      // functions guard every index and zero-fill the tail instead of
      // crashing (#19/#21). The model runs exactly once per slot; the
      // percentage lists are derived from the scores, not recomputed.
      final List<Hourly> hourly = weather.hourly ?? <Hourly>[];
      _hourlyScore.setAll(
          0,
          computeHourlyScores(
              weather.lat!, weather.lon!, hourly, _hourlyScore.length));
      for (int i = 0; i < _hourlyPercentage.length; i++) {
        _hourlyPercentage[i] = (_hourlyScore[i] * 100.0).toInt();
      }

      final List<Daily> daily = weather.daily ?? <Daily>[];
      _dailyScore.setAll(
          0,
          computeDailyScores(
              weather.lat!, weather.lon!, daily, _dailyScore.length));
      for (int i = 0; i < _dailyPercentage.length; i++) {
        _dailyPercentage[i] = (_dailyScore[i] * 100.0).toInt();
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

    ArangoSingleton().createWeather(version, buildNumber, _weather, _historical, _currentWeather,
        leadUp: _leadUp, leadUpDays: _leadUpDays);
  }

  int _monthOfDt(int dt) =>
      DateTime.fromMillisecondsSinceEpoch(dt * 1000, isUtc: true).month;

  /// Percentile + band for daily slot [i] (0 = today), against days at this
  /// hemisphere and that day's calendar month.
  double _dailyPercentileAt(int i) {
    final List<Daily>? daily = _weather?.daily;
    if (daily == null || i >= daily.length || _weather?.lat == null) return 0;
    return FlightIndex()
        .percentile(_dailyScore[i], _weather!.lat!, _monthOfDt(daily[i].dt!));
  }

  FlightBand _dailyBandAt(int i) =>
      bandFor(_dailyScore[i], _dailyPercentileAt(i));

  /// Sends today's outlook to the home-screen widget: legacy percentage plus
  /// the localized Ant Flight Index band and odds. Uses the device-locale
  /// localizations ([backgroundL10n]) so it also matches what the background
  /// refresh writes.
  Future<void> _pushAppWidget() {
    final FlightBand band = _dailyBandAt(0);
    final AppLocalizations t = backgroundL10n();
    return updateAppWidget(
      _dailyPercentage[0],
      bandKey: band.name,
      bandLabel: bandLabelOf(t, band),
      oddsText: t.oneInN(FlightIndex().oneInN(_dailyScore[0])),
    );
  }

  /// BCP-47 tag of the ambient locale, for intl date formats. The
  /// localizations delegates preload the matching date symbols.
  String get _localeTag => Localizations.localeOf(context).toString();

  /// Maps a menu entry to its localized label ([Choice.title] doubles as the
  /// stable key; external brand words like "Android" pass through unchanged).
  String _choiceTitle(AppLocalizations t, Choice c) {
    switch (c.title) {
      case 'Report Issue':
        return t.menuReportIssue;
      case 'Web App':
        return t.menuWebApp;
      case 'IOS':
        return t.menuIos;
      case 'Source Code':
        return t.menuSourceCode;
      case 'Buy Brad Coffee':
        return t.menuCoffee;
      default:
        return c.title;
    }
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
    // Only surface a window when it is at least "promising" for the season.
    final int month = _monthOfDt(hourly[bestStart].dt!);
    final double pct =
        FlightIndex().percentile(bestAvg / 100.0, _weather!.lat ?? 0, month);
    if (pct < 70) return null;
    String fmt(int dt) => DateFormat.j(_localeTag)
        .format(DateTime.fromMillisecondsSinceEpoch((dt + offset) * 1000, isUtc: true))
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '');
    final String start = fmt(hourly[bestStart].dt!);
    final String end = fmt(hourly[bestStart + 2].dt! + 3600);
    return context.l10n.bestWindow(start, end);
  }

  /// "Likely small species" — which queen-size class is most in season right
  /// now (from the per-size seasonal prior). Null when a flight is unlikely.
  String? _sizeLine() {
    final int pct = _dailyPercentage[0];
    final FlightBand band = _dailyBandAt(0);
    if (band == FlightBand.noFly ||
        band == FlightBand.quiet ||
        _weather?.lat == null) {
      return null;
    }
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
    final AppLocalizations t = context.l10n;
    final String sizeWord = bestSize == 'large'
        ? t.sizeLarge
        : bestSize == 'medium'
            ? t.sizeMedium
            : t.sizeSmall;
    return t.likelySizeSpecies(sizeWord);
  }

  /// The three strongest drivers of today's forecast, from the model's own
  /// per-attribute gauges (0.5 = the model is indifferent).
  List<WhyDriver> _drivers() {
    final Daily? d = _weather?.daily?.isNotEmpty == true ? _weather!.daily!.first : null;
    if (d == null) return const <WhyDriver>[];
    final AppLocalizations t = context.l10n;
    final List<MapEntry<String, double>> entries = <MapEntry<String, double>>[
      if (d.temp?.day != null)
        MapEntry(t.driverTemp(Units.temp(d.temp!.day!, decimals: 0, withUnit: false)),
            temperatureContribution(d.temp!.day!)),
      if (d.windSpeed != null)
        MapEntry(t.driverWind(Units.speed(d.windSpeed!, decimals: 0)),
            windContribution(d.windSpeed!)),
      if (d.humidity != null)
        MapEntry(t.driverHumidity('${d.humidity}'), humidityContribution(d.humidity!)),
      if (d.clouds != null)
        MapEntry(t.driverCloud('${d.clouds}'), cloudinessContribution(d.clouds!)),
      if (d.pop != null)
        MapEntry(t.driverRain('${(d.pop! * 100).round()}'), rainContribution(d.pop!)),
      if (d.pressure != null) MapEntry(t.driverPressure, pressureContribution(d.pressure!)),
    ];
    entries.sort((a, b) => (b.value - 0.5).abs().compareTo((a.value - 0.5).abs()));
    // Severity bands match the Why sheet's tags (see _FeatureCard._tagFor):
    // <=0.38 hurts strongly (-2), <=0.45 hurts a little (-1), >=0.55 helps.
    return entries
        .take(3)
        .map((e) => WhyDriver(
              label: e.key,
              direction: e.value >= 0.55
                  ? 1
                  : e.value <= 0.38
                      ? -2
                      : e.value <= 0.45
                          ? -1
                          : 0,
            ))
        .toList();
  }

  void _openWhySheet() {
    // Same API-shape defensiveness as _drivers(): the row is always rendered,
    // so a missing/empty daily list must degrade to a no-op, not a crash.
    if (_weather?.daily?.isNotEmpty != true) return;
    final Daily d = _weather!.daily!.first;
    final AppLocalizations t = context.l10n;
    showWhySheet(
      context,
      conditions: <String>[
        if (d.temp?.day != null) Units.temp(d.temp!.day!),
        if (d.windSpeed != null) t.condWind(Units.speed(d.windSpeed!)),
        if (d.humidity != null) t.condHumidity('${d.humidity}'),
        if (d.pressure != null) '${d.pressure!.toStringAsFixed(0)}\u{00A0}hPa',
        if (d.dewPoint != null)
          t.condDewPoint(Units.temp(d.dewPoint!, decimals: 0, withUnit: false)),
      ],
      features: <WhyFeature>[
        if (d.temp?.day != null)
          WhyFeature(
            name: t.featTemperature,
            note: t.featTemperatureNote,
            fn: temperatureContribution,
            lo: 0,
            hi: 40,
            current: d.temp!.day!.toDouble(),
          ),
        if (d.windSpeed != null)
          WhyFeature(
            name: t.featWind,
            note: t.featWindNote,
            fn: windContribution,
            lo: 0,
            hi: 20,
            current: d.windSpeed!.toDouble(),
          ),
        if (d.humidity != null)
          WhyFeature(
            name: t.featHumidity,
            note: t.featHumidityNote,
            fn: humidityContribution,
            lo: 0,
            hi: 100,
            current: d.humidity!.toDouble(),
          ),
        if (d.clouds != null)
          WhyFeature(
            name: t.featCloud,
            note: t.featCloudNote,
            fn: cloudinessContribution,
            lo: 0,
            hi: 100,
            current: d.clouds!.toDouble(),
          ),
        if (d.pop != null)
          WhyFeature(
            name: t.featRain,
            note: t.featRainNote,
            fn: rainContribution,
            lo: 0,
            hi: 1,
            current: d.pop!.toDouble(),
          ),
        if (d.pressure != null)
          WhyFeature(
            name: t.featPressure,
            note: t.featPressureNote,
            fn: pressureContribution,
            lo: 980,
            hi: 1040,
            current: d.pressure!.toDouble(),
          ),
      ],
      sizePercentages: _weather?.lat != null
          ? sizeSeasonalPercentages(_dailyPercentage[0], _weather!.lat!, DateTime.now().toUtc())
          : const <String, int>{},
      honesty: [
        t.honestyBand(
            bandLabelOf(t, _dailyBandAt(0)), _dailyPercentileAt(0).round()),
        t.honestyOdds(FlightIndex().oneInN(_dailyScore[0])),
        t.honestyScore(_dailyScore[0].toStringAsFixed(2)),
      ],
    );
  }

  /// Opens the report bottom sheet and submits the result. After a real
  /// sighting, follows up with how many other flights were reported nearby —
  /// the reward that closes the crowd-sourcing loop.
  Future<void> _openReportSheet() async {
    final ReportResult? result = await showReportSheet(context,
        locationLabel: _geocoding ?? context.l10n.unknownLocation);
    if (result == null || !mounted) return;

    if (fixedLocation) {
      _showSnack(context.l10n.snackFixedLocation);
      return;
    }
    if (kDebugMode) {
      _showSnack(context.l10n.snackDebugMode);
      return;
    }

    ArangoSingleton().updateWeather(
      version,
      buildNumber,
      result.size,
      _weather,
      _historical,
      _currentWeather,
      leadUp: _leadUp,
      leadUpDays: _leadUpDays,
    );
    _showSnack(result.sawNothing
        ? context.l10n.snackThanksNoFlight
        : context.l10n.snackThanksSighting);
    if (!result.sawNothing) {
      unawaited(_showNearbyReports());
    }
  }

  /// Fetches confirmed flights within 500 km in the last 24 h and surfaces the
  /// count, so reporters immediately see they are part of a bigger event.
  Future<void> _showNearbyReports() async {
    try {
      final latLng = weatherFetcher.getLocation();
      final Position position = syntheticPosition(latLng.latitude, latLng.longitude);
      final List flights =
          await ArangoSingleton().getRecentFlightsNearMe(position, -24 * 60);
      if (!mounted || flights.isEmpty) return;
      _showSnack(context.l10n.snackNearbyFlights(flights.length));
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
                tooltip: context.l10n.tooltipShowMap,
                onPressed: _showMap,
              ),
              PopupMenuButton<Choice>(
                tooltip: context.l10n.tooltipMoreOptions,
                onSelected: (Choice c) {
                  if (c.url == '_units') {
                    Units.toggle();
                  } else {
                    Utils.launchURL('${c.url}');
                  }
                },
                itemBuilder: (BuildContext context) {
                  final AppLocalizations t = context.l10n;
                  final String unitsTitle =
                      imperial ? t.menuUseMetric : t.menuUseImperial;
                  final List<PopupMenuEntry<Choice>> items = <PopupMenuEntry<Choice>>[
                    PopupMenuItem<Choice>(
                      value: Choice(
                        title: unitsTitle,
                        url: '_units',
                        icon: Icons.thermostat,
                      ),
                      child: _menuRow(Icons.thermostat, unitsTitle),
                    ),
                    const PopupMenuDivider(),
                  ];
                  items.addAll(choices.map((Choice choice) {
                    return PopupMenuItem<Choice>(
                      value: choice,
                      child: _menuRow(choice.icon, _choiceTitle(t, choice)),
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
                  tooltip: context.l10n.tooltipReportFlight,
                  icon: const Icon(AppIcons.wingedAnt, size: 26),
                  label: Text(context.l10n.reportFlightButton),
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
    final AppLocalizations t = context.l10n;
    final String label = _geocoding == null
        ? t.locating
        : _geocoding == 'Unknown Location'
            ? t.unknownLocation
            : _geocoding!;
    return Semantics(
      button: true,
      label: '$label. ${t.chooseALocation}.',
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
                    label,
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

    final AppLocalizations t = context.l10n;
    final String dateLine = hourly.isNotEmpty
        ? t.todayDate(DateFormat.MMMEd(_localeTag).format(
            DateTime.fromMillisecondsSinceEpoch(
                (hourly.first.dt! + weather.timezoneOffset!) * 1000,
                isUtc: true)))
        : t.todayDate('–');
    final String? description = hourly.isNotEmpty && hourly.first.weather?.isNotEmpty == true
        ? toBeginningOfSentenceCase(hourly.first.weather!.first.description)
        : null;
    final num? dayTemp = weather.daily?.isNotEmpty == true ? weather.daily!.first.temp?.day : null;
    final String conditionLine = [
      if (description != null) description,
      if (dayTemp != null) Units.temp(dayTemp, decimals: 0),
    ].join(' · ');

    // Bottom padding must clear the extended FAB (~56px + margins) AND the
    // Android system navigation bar (edge-to-edge draws under it), otherwise
    // the version line scrolls to rest underneath the Report flight button.
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 120 + bottomInset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeroVerdictCard(
                band: _dailyBandAt(0),
                oneInN: FlightIndex().oneInN(_dailyScore[0]),
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
                  Text(t.next24Hours,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    t.chartCaption,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              HourlyChart(
                // NB hourly bands reuse the daily score distribution: close
                // enough for colour banding, and keeps one stats table.
                points: [
                  for (int i = 0; i < hourlyCount; i++)
                    HourlyPoint(
                      hourly[i].dt!,
                      _hourlyPercentage[i],
                      bandFor(
                        _hourlyScore[i],
                        FlightIndex().percentile(_hourlyScore[i],
                            weather.lat ?? 0, _monthOfDt(hourly[i].dt!)),
                      ),
                    ),
                ],
                timezoneOffsetSeconds: weather.timezoneOffset ?? 0,
              ),
              const SizedBox(height: 14),
              WhyChipsRow(drivers: _drivers(), onTap: _openWhySheet),
              const SizedBox(height: 22),
              Text(t.upcomingWeek,
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
          day: DateFormat.E(_localeTag).format(DateTime.fromMillisecondsSinceEpoch(
              (daily[i].dt! + offset) * 1000,
              isUtc: true)),
          temp: daily[i].temp?.day != null
              ? Units.temp(daily[i].temp!.day!, decimals: 0, withUnit: false)
              : '–',
          wind: daily[i].windGust != null || daily[i].windSpeed != null
              ? Units.speed(daily[i].windGust ?? daily[i].windSpeed!)
              : '–',
          band: _dailyBandAt(i),
          percentile: _dailyPercentileAt(i),
        ),
    ];
  }

  Widget _buildErrorMessage() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations t = context.l10n;
    // The two common location failures are thrown as English exception text
    // deep in the fetcher (no context there); map them to localized copy at
    // display time. Anything else shows verbatim.
    final String message = errorMessage ?? '';
    final String displayMessage = message.startsWith('Failed to get your location')
        ? t.locationFailedError
        : message.startsWith('Location permissions are denied')
            ? t.locationDeniedError
            : message;
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
                displayMessage,
                style: const TextStyle(fontSize: 17, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => _getLocation(true),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: Text(t.tryAgain),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _findPlaceName,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: Text(t.chooseALocation),
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
            context.l10n.fetchingWeather,
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void handleLocationError(e) {
    handleError(e);

    // Remove the percentage from the Android widget
    clearAppWidget();
  }

  // NB: called from catchError handlers — never rethrow here, or the error
  // escapes as an unhandled async exception on top of the error screen.
  void handleError(e) {
    if (e != null && e.toString().startsWith('Exception: ')) {
      setState(() {
        loaded = true;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      developer.log('handleError: $e', error: e);
    } else {
      setState(() {
        loaded = true;
        errorMessage =
            'Unexpected error occurred. Please report to bitbot@bitbot.com.au ' + e.toString();
      });
      developer.log('unhandledError: $e', error: e);
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
