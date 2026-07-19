import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:memory_info/memory_info.dart';

import '../controller/arangodb.dart';
import '../controller/weather_fetcher.dart';
import '../main.dart';
import '../utils.dart';

Future<void> main() async {
  await dotenv.load(fileName: 'assets/.env');

  runApp(MyMapApp());
}

class MyMapApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenWeatherMap Layers',
      theme: ThemeData(brightness: Brightness.light, primarySwatch: Colors.blueGrey),
      darkTheme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.blueGrey),
      themeMode: ThemeMode.system,
      home: MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  MapPage();

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  WeatherFetcher _weatherFetcher = WeatherFetcher();
  MapController _mapController = MapController();
  final double defaultZoom = 3;
  List<Marker> _markers = <Marker>[];
  Memory? _memory;

  // Weather overlays are expensive (extra WMS fetches + color filters). Throttle
  // their tile load/prune work during pan/zoom so the base map stays responsive.
  // Each layer needs its own transformer instance (internal timer state); keep
  // them as fields so rebuilds do not allocate new timers.
  static const Duration _weatherTileThrottle = Duration(milliseconds: 300);
  final TileUpdateTransformer _cloudsTileUpdateTransformer =
      TileUpdateTransformers.throttle(_weatherTileThrottle);
  final TileUpdateTransformer _windTileUpdateTransformer =
      TileUpdateTransformers.throttle(_weatherTileThrottle);
  final TileUpdateTransformer _tempTileUpdateTransformer =
      TileUpdateTransformers.throttle(_weatherTileThrottle);

  // Previous visual used Opacity(0.165) over the filtered tiles. Fold that into
  // the alpha row so we avoid an extra Opacity compositing layer per weather layer.
  static const double _weatherOpacity = 0.165;

  // Solid red where clouds exist; alpha from source (boosted), then opacity.
  static final ColorFilter _cloudsFilter = ColorFilter.matrix(<double>[
    0, 0, 0, 0, 255, // R
    0, 0, 0, 0, 0, // G
    0, 0, 0, 0, 0, // B
    0, 0, 0, 2 * _weatherOpacity, 0, // A = 0.33 * sourceA (0 stays 0)
  ]);

  // Solid red where wind is drawn; alpha from source (boosted), then opacity.
  static final ColorFilter _windFilter = ColorFilter.matrix(<double>[
    0, 0, 0, 0, 255, // R
    0, 0, 0, 0, 0, // G
    0, 0, 0, 0, 0, // B
    0, 0, 0, 2 * _weatherOpacity, 0, // A = 0.33 * sourceA (0 stays 0)
  ]);

  // Keep the original red extraction; drive alpha from the same signal so
  // non-matching temps stay transparent, with opacity folded into A.
  static final ColorFilter _tempFilter = ColorFilter.matrix(<double>[
    1, -2, 6, 0, -255, // R
    0, 0, 0, 0, 0, // G
    0, 0, 0, 0, 0, // B
    1 * _weatherOpacity, -2 * _weatherOpacity, 6 * _weatherOpacity, 0, -255 * _weatherOpacity, // A
  ]);

  @override
  void initState() {
    super.initState();
    _loadData();
    _getMemoryInfo();
  }

  void _loadData() async {
    ArangoSingleton().getRecentFlights().then((value) {
      if (!mounted) return;
      setState(() {
        _markers = value
            .map(
              (row) => Marker(
                point: LatLng(row['lat'], row['lon']),
                child: _MarkerIcon(key: row['key'], size: row['size'], weather: row['weather']),
              ),
            )
            .toList();
      });
    });

    try {
      //debugPrint("_loadData: Before findLocation()");
      await _weatherFetcher.findLocation(false).then((value) => _moveMap());
      //debugPrint("_loadData: After findLocation()");
    } catch (e) {
      print(e);
    }
  }

  void _moveMap() {
    LatLng? latLng = _weatherFetcher.getLocation();
    if (latLng != LatLng(0, 0)) {
      //debugPrint("_moveMap: Before latLng=$latLng");
      _mapController.moveAndRotate(latLng, defaultZoom, 0.0);
      //debugPrint("_moveMap: After latLng=$latLng");
    }
  }

  bool get _showClouds =>
      kIsWeb ||
      !Platform.isAndroid ||
      (Platform.isAndroid &&
          _memory != null &&
          _memory!.totalMem != null &&
          _memory!.totalMem! >= 10000);

  bool get _showWind =>
      kIsWeb ||
      !Platform.isAndroid ||
      (Platform.isAndroid &&
          _memory != null &&
          _memory!.totalMem != null &&
          _memory!.totalMem! >= 4000);

  bool get _showTemp =>
      kIsWeb ||
      !Platform.isAndroid ||
      (Platform.isAndroid &&
          _memory != null &&
          _memory!.totalMem != null &&
          _memory!.totalMem! >= 8000);

  @override
  Widget build(BuildContext context) {
    //debugPrint("build: context=$context");
    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            _moveMap();
          }
        },
        mini: true,
        child: Icon(Icons.arrow_back),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _weatherFetcher.getLocation(),
          initialZoom: defaultZoom,
          minZoom: 2,
          maxZoom: 9,
          // Match MapTiler backdrop charcoal so unloaded tiles aren't stark black.
          backgroundColor: const Color(0xFF2A2A2A),

          onLongPress: (position, latLng) {
            _weatherFetcher.setLocation(latLng);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MyHomePage(fixedLocation: true, weatherFetcher: _weatherFetcher),
                fullscreenDialog: true,
                maintainState: true,
              ),
            );
          },
          interactionOptions: InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            cursorKeyboardRotationOptions: CursorKeyboardRotationOptions.disabled(),
          ),
        ),
        children: <Widget>[
          // OSM/Google-compatible tile service (not /tms — that inverts Y).
          // Requires `tiles:` under services in mapproxy.yaml. Weather stays on WMS.
          TileLayer(
            urlTemplate:
                'https://maps.bitbot.com.au/tiles/1.0.0/backdrop/EPSG3857/{z}/{x}/{y}.png',
            userAgentPackageName: 'au.com.bitbot.nuptialflight',

            minZoom: 0,
            maxZoom: 20,
            // Instant show avoids fade animations fighting pan/zoom.
            tileDisplay: const TileDisplay.instantaneous(),
            // Slightly tighter than defaults (keep=2, pan=1) to cut retained tiles.
            keepBuffer: 1,
            panBuffer: 0,
          ),

          // Weather tiles are RGBA with partial alpha. Matrices must keep
          // source A==0 fully transparent; opacity is folded into the A row.
          if (_showClouds)
            _openWeatherMapWidget(
              'clouds_new',
              _cloudsFilter,
              _cloudsTileUpdateTransformer,
            ),
          if (_showWind)
            _openWeatherMapWidget(
              'wind_new',
              _windFilter,
              _windTileUpdateTransformer,
            ),
          if (_showTemp)
            _openWeatherMapWidget(
              'temp_new',
              _tempFilter,
              _tempTileUpdateTransformer,
            ),

          MarkerLayer(markers: _markers),
          const _MapAttribution(),
        ],
      ),
    );
  }

  /// One [ColorFiltered] around the whole layer (not per-tile) is much cheaper
  /// during pan/zoom than a [tileBuilder] wrapping every tile.
  Widget _openWeatherMapWidget(
    String layer,
    ColorFilter colorFilter,
    TileUpdateTransformer tileUpdateTransformer,
  ) {
    return ColorFiltered(
      colorFilter: colorFilter,
      child: TileLayer(
        wmsOptions: WMSTileLayerOptions(
          baseUrl: 'https://maps.bitbot.com.au/service?',
          layers: [layer],
        ),
        // urlTemplate:
        //     //'https://tile.openweathermap.org/map/{layer}/{z}/{x}/{y}.{ext}?appid={apiKey}',
        //     'https://maps.bitbot.com.au/tiles/{layer}/{z}/{x}/{y}.{ext}?origin=nw',
        // //'https://maps.bitbot.com.au/tms/1.0.0/{layer}/EPSG900913/{z}/{x}/{y}.{ext}',
        subdomains: ['a', 'b', 'c'],
        userAgentPackageName: 'au.com.bitbot.nuptialflight',
        minZoom: 0,
        maxZoom: 19,
        tileDisplay: const TileDisplay.instantaneous(),
        // Weather overlays can lag the camera a bit; prefer fewer tile churn events.
        tileUpdateTransformer: tileUpdateTransformer,
        keepBuffer: 1,
        panBuffer: 0,
        additionalOptions: {
          'ext': 'png',
          'layer': layer,
          //'apiKey': dotenv.env['OPENWEATHERMAP_MAP_KEY']!,
        },
      ),
    );
  }

  Widget _MarkerIcon({required key, required size, required weather}) {
    //return Text("Key: ${key}\,Size: ${size}\nWeather: ${weather}");

    double sizeDouble = 15;
    switch (size) {
      case 'small':
        sizeDouble = 20;
        break;
      case 'medium':
        sizeDouble = 27;
        break;
      case 'large':
        sizeDouble = 34;
        break;
    }
    return Icon(
      Icons.location_pin,
      color: Colors.cyanAccent,
      size: sizeDouble,
      semanticLabel: size,
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _getMemoryInfo() async {
    // memory_info has no web (or desktop) implementation, so skip it there to
    // avoid a MissingPluginException. The web/desktop tiles don't depend on
    // _memory (the show* getters short-circuit on kIsWeb / non-Android).
    if (kIsWeb) return;

    Memory? memory;

    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      memory = await MemoryInfoPlugin().memoryInfo;
    } catch (e) {
      print('error $e');
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    if (memory != null) {
      setState(() {
        _memory = memory;
      });
      debugPrint("_getMemoryInfo: totalMem=${memory.totalMem}");
    }
  }
}

/// Lightweight attribution (no flutter_html parsing on every map rebuild).
class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  static const TextStyle _style = TextStyle(
    color: Color(0xFF00FFFF),
    fontSize: 11,
    height: 1.25,
  );

  static const TextStyle _linkStyle = TextStyle(
    color: Color(0xFF00FFFF),
    fontSize: 11,
    height: 1.25,
    decoration: TextDecoration.underline,
  );

  @override
  Widget build(BuildContext context) {
    // Keep the attribution clear of the Android system navigation bar
    // (3-button / gesture). MediaQuery.padding.bottom is the system
    // UI inset, so the text no longer sits under the nav buttons.
    final double navInset = MediaQuery.of(context).padding.bottom;
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.fromLTRB(6, 0, 6, 28 + navInset),
        child: DefaultTextStyle(
          style: _style,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Markers show last 48hr nuptial flights.'),
              const Text('Marker size indicates species size.'),
              _linkLine('Weather ', '© OpenWeatherMap', 'http://openweathermap.org'),
              _linkLine('Tiles ', '© MapTiler', 'https://www.maptiler.com/copyright/'),
              _linkLine('Map data ', '© OpenStreetMap', 'https://www.openstreetmap.org/copyright'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linkLine(String prefix, String label, String url) {
    return Text.rich(
      TextSpan(
        text: prefix,
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => Utils.launchURL(url),
              child: Text(label, style: _linkStyle),
            ),
          ),
        ],
      ),
    );
  }
}
