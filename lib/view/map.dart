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

  // Weather overlays are recoloured to reflect nuptial-flight SUITABILITY,
  // matching the shipped model's learned distribution. The per-attribute
  // weights below are the normalised spans of each feature's partial-
  // dependence curve (see docs/model_training_findings.md PD sweep):
  //   temperature .094  (BEST ~32C  / WORST ~0C)   -> strongest signal
  //   wind        .057  (BEST ~1.5  / WORST ~12.5 m/s)
  //   cloud       .018  (weakly FAVOURABLE when overcast)
  // Each overlay is tinted in proportion so the map's visual weight tracks how
  // much each pattern actually drives flight probability. Convention:
  // BLUE/GREEN (teal) = favourable for flights, RED = unfavourable.
  //
  // The alpha row also folds in the old Opacity(0.165) so we avoid an extra
  // Opacity compositing layer per weather layer.
  static const double _weatherOpacity = 0.165;
  static const double _tempWeight = 1.00; // .094/.094
  static const double _windWeight = 0.61; // .057/.094
  static const double _cloudWeight = 0.19; // .018/.094
  static const double _tempOpacity = _weatherOpacity * _tempWeight;
  static const double _windOpacity = _weatherOpacity * _windWeight;
  static const double _cloudOpacity = _weatherOpacity * _cloudWeight;

  // Clouds: the retrained model finds overcast conditions WEAKLY FAVOURABLE,
  // so tint them faint BLUE-GREEN/teal (not red) and keep the intensity low to
  // reflect the small importance weight.
  static final ColorFilter _cloudsFilter = ColorFilter.matrix(<double>[
    0, 0, 0, 0, 0, // R
    0, 0, 0, 0, 140, // G (faint favourable green where clouds are drawn - damped)
    0, 0, 0, 0, 80, // B (slight blue => blue-green/teal favourable)
    0, 0, 0, 2 * _cloudOpacity, 0, // A = weighted source alpha (0 stays 0)
  ]);

  // Wind: calm is favourable, strong wind is unfavourable. The OWM wind layer's
  // source alpha grows with wind speed, so painting RED with alpha driven from
  // that alpha already shows stronger (more unfavourable) winds more intensely.
  static final ColorFilter _windFilter = ColorFilter.matrix(<double>[
    0, 0, 0, 0, 255, // R (unfavourable red)
    0, 0, 0, 0, 0, // G
    0, 0, 0, 0, 0, // B
    0, 0, 0, 2 * _windOpacity, 0, // A = weighted source alpha (0 stays 0)
  ]);

  // Temperature: the OWM temp palette runs cold=blue -> cool=cyan -> mild=green
  // -> warm=yellow/orange -> hot=red. CRUCIALLY red is high across most of the
  // palette (yellow AND orange AND red all have R~255), so a naive `warm=R-B`
  // green lights up almost everywhere. The model's favourable band is NARROW
  // (BEST ~30C), which is only the *pure red* end. So gate favourable green on
  // `R - G - B`, which passes pure red (255,0,0 -> 255) but rejects yellow
  // (255,255,0 -> 0), orange (partial), green and cyan (negative -> 0). Cold
  // stays red via `B - R` (blue/purple poles). Negatives clamp to 0.
  //   R_out = B - R              (cold/blue  => red, unfavourable)
  //   G_out = (R - G - B) / 2    (only pure-red/hot => green; damped, green reads brighter)
  //   B_out = (R - G - B) / 5    (only pure-red/hot => slight blue => teal)
  // Alpha is high for both extremes (hot pure-red via R-G, cold via B) and near
  // zero for the mild yellow/green/cyan mid-range, scaled by the temp weight.
  static final ColorFilter _tempFilter = ColorFilter.matrix(<double>[
    -1, 0, 1, 0, 0, // R = B - R              (cold => red, unfavourable) - full strength
    0.5, -0.5, -0.5, 0, 0, // G = (R - G - B) / 2    (only hot pure-red => green) - damped
    0.2, -0.2, -0.2, 0, 0, // B = (R - G - B) / 5    (only hot pure-red => slight blue => teal)
    _tempOpacity, -_tempOpacity, _tempOpacity, 0, -20 * _tempOpacity, // A = op*(R - G + B) - bias
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

  // Dark body text with a soft light halo reads clearly on the white/red
  // map tiles; no background box is used.
  static const TextStyle _style = TextStyle(
    color: Colors.black87,
    fontSize: 11,
    height: 1.25,
    shadows: <Shadow>[
      Shadow(
        offset: Offset(0.5, 0.5),
        blurRadius: 2,
        color: Color(0xAAFFFFFF),
      ),
    ],
  );

  // Links use the same cyan as the map markers (underlined) so they
  // stand out from the dark body text.
  static const TextStyle _linkStyle = TextStyle(
    color: Colors.cyanAccent,
    fontSize: 11,
    height: 1.25,
    decoration: TextDecoration.underline,
    shadows: <Shadow>[
      Shadow(
        offset: Offset(0.5, 0.5),
        blurRadius: 2,
        color: Color(0xAAFFFFFF),
      ),
    ],
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
