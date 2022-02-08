import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nuptialflight/utils.dart';
import 'package:nuptialflight/weather_fetcher.dart';

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
      theme: ThemeData(
          brightness: Brightness.light, primarySwatch: Colors.blueGrey),
      darkTheme: ThemeData(
          brightness: Brightness.dark, primarySwatch: Colors.blueGrey),
      themeMode: ThemeMode.system,
      home: MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  WeatherFetcher weatherFetcher = WeatherFetcher();
  MapController mapController = MapController();
  final double defaultZoom = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    await weatherFetcher.findLocation(false).then((value) => _moveMap());
  }

  void _moveMap() {
    LatLng? latLng = weatherFetcher.getLocation();
    if (latLng != null) {
      mapController.moveAndRotate(latLng, defaultZoom, 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        mapController: mapController,
        options: MapOptions(
          center: weatherFetcher.getLocation(),
          zoom: defaultZoom,
          minZoom: 2,
          maxZoom: 9,
          rotationWinGestures:
              MultiFingerGesture.pinchMove | MultiFingerGesture.pinchZoom,
        ),
        children: <Widget>[
          TileLayerWidget(
            options: TileLayerOptions(
                urlTemplate:
                    //'https://stamen-tiles-{s}.a.ssl.fastly.net/toner/{z}/{x}/{y}{r}.{ext}',
                    'https://maps.bitbot.com.au/tiles/toner/{z}/{x}/{y}.{ext}?origin=nw',
                subdomains: ['a', 'b', 'c'],
                attributionBuilder: (_) {
                  return Html(
                    data:
                        '<div style="color: #00ffff;">Weather &copy; <a href="http://openweathermap.org">OpenWeatherMap</a><br/>Tiles by <a href="http://stamen.com">Stamen Design</a> - <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a><br/>Map data &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors</div>',
                    onLinkTap: (url, context, attributes, element) =>
                        Utils.launchURL(url!),
                  );
                },
                opacity: 1.0,
                minZoom: 0,
                maxZoom: 20,
                additionalOptions: {
                  'ext': 'png',
                }),
          ),
          // _openWeatherMapWidget('precipitation_new'),
          // _openWeatherMapWidget('pressure_new'),
          _openWeatherMapWidget(
            'clouds_new',
            const ColorFilter.matrix(<double>[
              0, 0, 0, 510, 0, // R
              0, 0, 0, 0, 0, // G
              0, 0, 0, 0, 0, // B
              0, 0, 0, -2, 510, // A
            ]),
          ),
          _openWeatherMapWidget(
              'wind_new',
              const ColorFilter.matrix(<double>[
                0, 0, 0, 637, 0, // R
                0, 0, 0, 0, 0, // G
                0, 0, 0, 0, 0, // B
                0, 0, 0, 637, 0, // A
              ])),
          _openWeatherMapWidget(
              'temp_new',
              const ColorFilter.matrix(<double>[
                1, -2, 6, 0, -255, // R
                0, 0, 0, 0, 0, // G
                0, 0, 0, 0, 0, // B
                0, 0, 2, 0, -60, // A
              ])),
        ],
      ),
    );
  }

  TileLayerWidget _openWeatherMapWidget(String layer, ColorFilter colorFilter) {
    return TileLayerWidget(
      options: TileLayerOptions(
        urlTemplate:
            //'https://tile.openweathermap.org/map/{layer}/{z}/{x}/{y}.{ext}?appid={apiKey}',
            'https://maps.bitbot.com.au/tiles/{layer}/{z}/{x}/{y}.{ext}?origin=nw',
        subdomains: ['a', 'b', 'c'],
        minZoom: 0,
        maxZoom: 19,
        additionalOptions: {
          'ext': 'png',
          'layer': layer,
          //'apiKey': dotenv.env['OPENWEATHERMAP_MAP_KEY']!,
        },
        opacity: 0.165,
        //backgroundColor: Colors.black,
        tileBuilder: (context, tileWidget, tile) {
          return ColorFiltered(
            colorFilter: colorFilter,
            child: tileWidget,
          );
        },
      ),
    );
  }
}
