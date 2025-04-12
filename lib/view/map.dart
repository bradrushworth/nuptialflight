import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    ArangoSingleton().getRecentFlights().then((value) => value.forEach((row) {
          //print("v=$row");
          _markers.add(
            Marker(
              point: new LatLng(row['lat'], row['lon']),
              child: _MarkerIcon(
                key: row['key'],
                size: row['size'],
                weather: row['weather'],
              ),
            ),
          );
        }));

    await _weatherFetcher.findLocation(false).then((value) => _moveMap());
  }

  void _moveMap() {
    LatLng? latLng = _weatherFetcher.getLocation();
    if (latLng != LatLng(0, 0)) {
      _mapController.moveAndRotate(latLng, defaultZoom, 0.0);
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
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _weatherFetcher.getLocation(),
          initialZoom: defaultZoom,
          minZoom: 2,
          maxZoom: 9,
          onLongPress: (position, latLng) {
            _weatherFetcher.setLocation(latLng);
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => MyHomePage(
                        fixedLocation: true,
                        weatherFetcher: _weatherFetcher,
                      ),
                  fullscreenDialog: true,
                  maintainState: true),
            );
          },
          interactionOptions: InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            cursorKeyboardRotationOptions: CursorKeyboardRotationOptions.disabled(),
          ),
        ),
        children: <Widget>[
          TileLayer(
              wmsOptions: WMSTileLayerOptions(
                  baseUrl: 'https://maps.bitbot.com.au/service?', layers: ['backdrop']),
              // urlTemplate:
              // //'https://stamen-tiles-{s}.a.ssl.fastly.net/toner/{z}/{x}/{y}{r}.{ext}',
              // //'https://maps.bitbot.com.au/tiles/backdrop/{z}/{x}/{y}.{ext}?origin=sw',
              // 'https://maps.bitbot.com.au/tms/1.0.0/backdrop/EPSG3857/{z}/{x}/{y}.{ext}?origin=nw',
              // //'https://api.maptiler.com/maps/backdrop/{z}/{x}/{y}.png?key={apiKey}',
              subdomains: ['a', 'b', 'c'],
              userAgentPackageName: 'au.com.bitbot.nuptialflight',
              minZoom: 0,
              maxZoom: 20,
              additionalOptions: {
                'ext': 'png',
                //'apiKey': dotenv.env['MAPTILER_MAP_KEY']!,
              }),

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
          MarkerLayer(markers: _markers),
          Align(
            alignment: Alignment.bottomLeft,
            child: html.Html(
              data:
                  '<div style="color: #00ffff;">Markers show last 48hr nuptial flights.<br/>Marker size indicates species size.<br/>Weather <a href="http://openweathermap.org">&copy; OpenWeatherMap</a><br/>Tiles <a href="https://www.maptiler.com/copyright/" target="_blank">&copy; MapTiler</a><br/>Map data <a href="https://www.openstreetmap.org/copyright" target="_blank">&copy; OpenStreetMap</a></div>',
              onLinkTap: (url, attributes, element) => Utils.launchURL(url!),
            ),
          ),
        ],
      ),
    );
  }

  SingleChildRenderObjectWidget _openWeatherMapWidget(String layer, ColorFilter colorFilter) {
    return Opacity(
      opacity: 0.165,
      child: TileLayer(
        wmsOptions:
            WMSTileLayerOptions(baseUrl: 'https://maps.bitbot.com.au/service?', layers: [layer]),
        // urlTemplate:
        //     //'https://tile.openweathermap.org/map/{layer}/{z}/{x}/{y}.{ext}?appid={apiKey}',
        //     'https://maps.bitbot.com.au/tiles/{layer}/{z}/{x}/{y}.{ext}?origin=nw',
        // //'https://maps.bitbot.com.au/tms/1.0.0/{layer}/EPSG900913/{z}/{x}/{y}.{ext}',
        subdomains: ['a', 'b', 'c'],
        userAgentPackageName: 'au.com.bitbot.nuptialflight',
        minZoom: 0,
        maxZoom: 19,
        additionalOptions: {
          'ext': 'png',
          'layer': layer,
          //'apiKey': dotenv.env['OPENWEATHERMAP_MAP_KEY']!,
        },
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
}
