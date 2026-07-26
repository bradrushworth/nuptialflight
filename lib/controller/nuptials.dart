import 'dart:convert';
import 'dart:math';

//import 'dart:developer' as developer;
import 'package:intl/intl.dart';

import 'package:nuptialflight/models/final_model.dart' as DailyModel;
import 'package:nuptialflight/models/hour_model.dart' as HourlyModel;
import 'package:nuptialflight/responses/onecall_response.dart';
import 'package:sklite/base.dart';
import 'package:sklite/ensemble/forest.dart';
import 'package:sklite/utils/io.dart';

///
/// https://www.antwiki.org/wiki/images/d/dd/Boomsma%2C_J.J.%2C_Leusink%2C_A._1981._Weather_conditions_during_nuptial_flights_of_four_European_ant_species_.pdf
/// https://antwiki.org/wiki/images/5/50/Depa%2C_L._2006._Weather_conditions_during_nuptial_flight_of_Manica_rubida.pdf
/// https://onlinelibrary.wiley.com/doi/epdf/10.1111/ecog.03140
///
const double TEMP_AVG = 16.5; // 24.00;
const double TEMP_STD = 10; // 3.96;
const double HUMIDITY_AVG = 77.00; // 62.00;
const double HUMIDITY_STD = 30; // 7.99;
const double WIND_AVG = 5.7; // 3.96;
const double WIND_STD = 5; // 0.78;
const double RAIN_AVG = 0;
const double RAIN_STD = 0;
const double CLOUD_AVG = 70;
const double CLOUD_STD = 30;
const double PRESSURE_AVG = 1014; // 1020;
const double PRESSURE_STD = 14.85;
const double RADIATION_AVG = 225.7; // (J.cm-2.h-1)
const double RADIATION_STD = 19.5; // SE not SD
const double UVI_AVG = 6.1;
const double UVI_STD = 6;

final DateFormat dayOfYearFormat = DateFormat("D");
final DateFormat hourFormat = DateFormat("HH");

class Nuptials {
  static final Nuptials _instance = Nuptials._internal();
  late RandomForestClassifier _dailyModel;
  late RandomForestClassifier _hourlyModel;

  // using a factory is important
  // because it promises to return _an_ object of this type
  // but it doesn't promise to make a new one.
  factory Nuptials() {
    return _instance;
  }

  // This named constructor is the "real" constructor
  // It'll be called exactly once, by the static property assignment above
  // it's also private, so it can only be called in this class
  Nuptials._internal() {
    loadModel('assets/final_model.json').then((value) {
      //print("value=$value");
      this._dailyModel = RandomForestClassifier.fromMap(json.decode(value));
    });

    loadModel('assets/hour_model.json').then((value) {
      //print("value=$value");
      this._hourlyModel = RandomForestClassifier.fromMap(json.decode(value));
    });
  }

  Classifier getDailyModel() {
    return _dailyModel;
  }

  Classifier getHourlyModel() {
    return _hourlyModel;
  }
}

double nuptialHourlyPercentage(Hourly hourly) {
  double temp = temperatureContribution(hourly.temp!);
  double windSpeed = windContribution(hourly.windSpeed!);
  //double windGust = windContribution(hourly.windGust?.toDouble() ?? hourly.windSpeed!.toDouble());
  double rain = rainContribution(hourly.pop!);
  double humid = humidityContribution(hourly.humidity!);
  double cloud = cloudinessContribution(hourly.clouds!);
  double press = pressureContribution(hourly.pressure!);
  double uvi = uviContribution(hourly.uvi!);
  var values = [
    {'percentage': temp, 'weighting': 1},
    {'percentage': windSpeed, 'weighting': 2},
    {'percentage': rain, 'weighting': 1},
    {'percentage': humid, 'weighting': 3},
    {'percentage': cloud, 'weighting': 1},
    {'percentage': press, 'weighting': 1},
    {'percentage': uvi, 'weighting': 0},
  ];
  return nuptialCalculator(values);
}

double nuptialDailyPercentage(Daily daily, {bool nocturnal = false}) {
  //double temp = temperatureContribution(nocturnal ? daily.temp!.eve! : daily.temp!.day!);
  double temp = temperatureContribution(daily.temp!.max!);
  double windSpeed = windContribution(daily.windSpeed!);
  //double windGust = windContribution(daily.windGust?.toDouble() ?? daily.windSpeed!.toDouble());
  double rain = rainContribution(daily.pop!);
  double humid = humidityContribution(daily.humidity!);
  double cloud = cloudinessContribution(daily.clouds!);
  double press = pressureContribution(daily.pressure!);
  double uvi = uviContribution(daily.uvi!);
  var values = [
    {'percentage': temp, 'weighting': 1},
    {'percentage': windSpeed, 'weighting': 2},
    {'percentage': rain, 'weighting': 1},
    {'percentage': humid, 'weighting': 3},
    {'percentage': cloud, 'weighting': 1},
    {'percentage': press, 'weighting': 1},
    {'percentage': uvi, 'weighting': 0},
  ];
  return nuptialCalculator(values);
}

double nuptialHourlyPercentageModel(num lat, num lon, Hourly hourly) {
  double temp = hourly.temp!.toDouble();
  double wind = hourly.windSpeed!.toDouble();
  double gust = hourly.windGust?.toDouble() ?? hourly.windSpeed!.toDouble();
  double humid = hourly.humidity!.toDouble();
  double press = hourly.pressure!.toDouble();
  double dewPoint = hourly.dewPoint!.toDouble();
  double northern = lat > 0 ? 1.0 : 0.0;
  int dayOfYear = int.parse(dayOfYearFormat
      .format(DateTime.fromMillisecondsSinceEpoch((hourly.dt!) * 1000, isUtc: true)));
  double daysSinceSpring = (dayOfYear - (31 + 28 + 31 + 30 + 31 + 30 + 31 + 31)) % 365;
  int hour = int.parse(
      hourFormat.format(DateTime.fromMillisecondsSinceEpoch((hourly.dt!) * 1000, isUtc: true)));
  if (northern == 1.0) daysSinceSpring = (daysSinceSpring - (31 + 30 + 31 + 30 + 31 + 31)) % 365;

  if (temp < 5) return 0.01;
  if (wind > 15) return 0.01;
  if (gust > 20) return 0.01;
  //if (humid < 40) return 0.01;
  //if (press < 995) return 0.01;

  // Classifier? model = Nuptials._instance.getHourlyModel();
  // if (model == null) return 0.00;
  // return min(
  //     0.99,
  //     max(
  //         0.01,
  //         model.predict([
  //               lat.toDouble(),
  //               lon.toDouble(),
  //               hour.toDouble(),
  //               temp, //temperatureContribution(temp),
  //               //morn,
  //               wind, //windContribution(wind),
  //               //gust,
  //               //windDeg,
  //               rain,
  //               humid, //humidityContribution(humid),
  //               cloud, //cloudinessContribution(cloud),
  //               press, //pressureContribution(press),
  //               //dewPoint,
  //               //northern,
  //               daysSinceSpring,
  //             ]) /
  //             100.0));

  return min(
      0.99,
      max(
          0.01,
          // hour_model.dart was trained (see autosklearn_classification-hourly.ipynb)
          // on these 9 features in this exact order. It does NOT use rain or
          // cloud, which is why they are not passed here.
          HourlyModel.score([
            lat.toDouble(),
            lon.toDouble(),
            hour.toDouble(),
            temp,
            wind,
            humid,
            press,
            dewPoint,
            daysSinceSpring,
          ])[1]));
}

double nuptialDailyPercentageModel(num lat, num lon, Daily daily, {bool nocturnal = false}) {
  //double temp = nocturnal ? daily.temp!.eve!.toDouble() : daily.temp!.day!.toDouble();
  double temp = daily.temp!.day!.toDouble();
  //double morn = daily.temp!.morn!.toDouble();
  double wind = daily.windSpeed!.toDouble();
  double gust = daily.windGust?.toDouble() ?? daily.windSpeed!.toDouble();
  double rain = daily.pop!.toDouble();
  double humid = daily.humidity!.toDouble();
  double cloud = daily.clouds!.toDouble();
  double press = daily.pressure!.toDouble();
  double dewPoint = daily.dewPoint!.toDouble();
  double northern = lat > 0 ? 1.0 : 0.0;
  int dayOfYear = int.parse(
      dayOfYearFormat.format(DateTime.fromMillisecondsSinceEpoch((daily.dt!) * 1000, isUtc: true)));
  double daysSinceSpring = (dayOfYear - (31 + 28 + 31 + 30 + 31 + 30 + 31 + 31)) % 365;
  if (northern == 1.0) daysSinceSpring = (daysSinceSpring - (31 + 30 + 31 + 30 + 31 + 31)) % 365;

  if (temp < 5) return 0.01;
  if (wind > 15) return 0.01;
  if (gust > 20) return 0.01;
  //if (humid < 40) return 0.01;
  //if (press < 995) return 0.01;

  // Classifier? model = Nuptials._instance.getDailyModel();
  // if (model == null) return 0.00;
  // return min(
  //     0.99,
  //     max(
  //         0.01,
  //         model.predict([
  //               lat.toDouble(),
  //               lon.toDouble(),
  //               temp, //temperatureContribution(temp),
  //               //morn,
  //               wind, //windContribution(wind),
  //               //gust,
  //               rain,
  //               humid, //humidityContribution(humid),
  //               cloud, //cloudinessContribution(cloud),
  //               press, //pressureContribution(press),
  //               //dewPoint,
  //               //northern,
  //               daysSinceSpring,
  //             ]) /
  //             100.0));

  return min(
      0.99,
      max(
          0.01,
          DailyModel.score([
            lat.toDouble(),
            lon.toDouble(),
            temp, //temperatureContribution(temp),
            //morn,
            wind, //windContribution(wind),
            //gust,
            rain,
            humid, //humidityContribution(humid),
            cloud, //cloudinessContribution(cloud),
            press, //pressureContribution(press),
            dewPoint,
            //northern,
            daysSinceSpring,
          ])[1]));
}

///
/// Returns a value from 0.0 to 1.0 indicating the percentage likeness of
/// a nuptial flight today.
///
double nuptialCalculator(List<Map<String, num>> values) {
  var sum = values.map((m) => m['percentage']! * m['weighting']!).reduce((a, b) => a + b);
  var count = values.map((e) => e['weighting']!).reduce((a, b) => a + b);
  var result = sum / count;
  // developer.log("sum=$sum", name: 'nuptialPercentage');
  // developer.log("count=$count", name: 'nuptialPercentage');
  // developer.log("result=$result", name: 'nuptialPercentage');
  return max(0.01, min(1.0, result));
}

// ---------------------------------------------------------------------------
// Per-attribute "suitability" gauges.
//
// These used to be hand-tuned Normal-distribution CDFs centred on literature
// means. They are now derived directly from the trained model in
// `lib/models/final_model.dart` so each gauge reflects the *actual* marginal
// relationship the RandomForest learned for that weather attribute.
//
// For each model feature we build a partial-dependence curve: the model's
// average predicted flight probability as that one feature is swept across
// its plausible range, with every other feature held at a set of
// representative flight-season baseline contexts (a spread of geographies,
// seasonal offsets and weather states). The raw probability is normalised to
// the feature's own [min, max] response, so the gauge reads 0.00 (model's
// worst value for this attribute) .. 1.00 (model's best).
//
// Features the model barely uses (e.g. rain, pressure) therefore produce a
// near-flat curve and resolve to a neutral 0.5, which honestly reflects what
// the model learned. Curves are computed lazily once on first use and cached.
// ---------------------------------------------------------------------------

/// Representative baseline contexts used to marginalise the non-target
/// features when computing a partial-dependence curve. Each entry is a full
/// 10-element daily-model input vector:
/// [lat, lon, temp, wind, rain, humid, cloud, press, dewPoint, daysSinceSpring].
/// The target feature is overwritten per query, so only the non-target values
/// matter.
List<List<double>> _buildPdContexts() {
  // Geography x seasonal-offset anchors (lat, lon, daysSinceSpring).
  const anchors = <List<double>>[
    [50, 10, 30], // NH Europe, early season
    [50, 10, 120], // NH Europe, mid season
    [50, 10, 210], // NH Europe, late season
    [40, -90, 30], // NH North America, early
    [40, -90, 120], // NH North America, mid
    [40, -90, 210], // NH North America, late
    [-33, 151, 30], // SH Australia, early
    [-33, 151, 120], // SH Australia, mid
    [-33, 151, 210], // SH Australia, late
    [-30, -60, 30], // SH South America, early
    [-30, -60, 120], // SH South America, mid
    [-30, -60, 210], // SH South America, late
  ];
  // Representative weather states: [wind, rain, humid, cloud, press, dew, temp].
  // temp only matters as a baseline for non-temperature curves.
  const states = <List<double>>[
    [3.0, 0.0, 65.0, 35.0, 1016.0, 12.0, 22.0], // ideal
    [5.7, 0.0, 77.0, 70.0, 1014.0, 12.0, 16.5], // typical (matches AVG consts)
    [8.0, 0.15, 88.0, 85.0, 1006.0, 15.0, 14.0], // marginal
  ];
  final contexts = <List<double>>[];
  for (final a in anchors) {
    for (final s in states) {
      contexts.add([
        a[0], // 0 lat
        a[1], // 1 lon
        s[6], // 2 temp (overwritten by temperature queries)
        s[0], // 3 wind
        s[1], // 4 rain
        s[2], // 5 humidity
        s[3], // 6 cloud
        s[4], // 7 pressure
        s[5], // 8 dewPoint
        a[2], // 9 daysSinceSpring
      ]);
    }
  }
  return contexts;
}

final List<List<double>> _pdContexts = _buildPdContexts();

/// Average model flight-probability when [featureIndex] is fixed to [value]
/// across all baseline contexts.
double _rawPd(int featureIndex, double value) {
  double sum = 0;
  for (final ctx in _pdContexts) {
    final input = List<double>.from(ctx);
    input[featureIndex] = value;
    sum += DailyModel.score(input)[1];
  }
  return sum / _pdContexts.length;
}

double _interp(List<double> xs, List<double> ys, double x) {
  if (x <= xs.first) return ys.first;
  if (x >= xs.last) return ys.last;
  for (int i = 0; i < xs.length - 1; i++) {
    if (x >= xs[i] && x <= xs[i + 1]) {
      final span = xs[i + 1] - xs[i];
      final t = span == 0 ? 0.0 : (x - xs[i]) / span;
      return ys[i] + t * (ys[i + 1] - ys[i]);
    }
  }
  return ys.last;
}

/// A normalised partial-dependence curve for one model feature.
class _PdCurve {
  _PdCurve(this.featureIndex, this.lo, this.hi, this.step) {
    xs = <double>[];
    pds = <double>[];
    for (double x = lo; x <= hi + 1e-9; x += step) {
      xs.add(x);
      pds.add(_rawPd(featureIndex, x));
    }
    pdMin = pds.reduce(min);
    pdMax = pds.reduce(max);
  }

  final int featureIndex;
  final double lo, hi, step;
  late final List<double> xs;
  late final List<double> pds;
  late final double pdMin;
  late final double pdMax;

  /// Normalised suitability in [0, 1] for the model's marginal response to
  /// [x]. Returns a neutral 0.5 when the model's response is effectively flat.
  double valueAt(double x) {
    final raw = _interp(xs, pds, x);
    final span = pdMax - pdMin;
    // Features the model barely uses produce a near-flat curve (span ~5e-4);
    // strong signals span ~5e-3..1.4e-1. A 0.002 threshold cleanly separates
    // them. Flat features resolve to a neutral 0.5 (the model has no opinion).
    if (span < 0.002) return 0.5;
    return ((raw - pdMin) / span).clamp(0.0, 1.0);
  }
}

late final _PdCurve _tempCurve = _PdCurve(2, 0, 40, 1);
late final _PdCurve _windCurve = _PdCurve(3, 0, 32, 0.5);
late final _PdCurve _rainCurve = _PdCurve(4, 0, 1, 0.05);
late final _PdCurve _humidCurve = _PdCurve(5, 0, 100, 2.5);
late final _PdCurve _cloudCurve = _PdCurve(6, 0, 100, 2.5);
late final _PdCurve _pressCurve = _PdCurve(7, 980, 1040, 1.5);

/// Daytime temperature (Celsius). Model marginal response to feature index 2.
double temperatureContribution(num temp) =>
    _tempCurve.valueAt(temp.toDouble());

/// Humidity (%). Model marginal response to feature 5.
double humidityContribution(num humidity) =>
    _humidCurve.valueAt(humidity.toDouble());

/// Wind speed (m/s). Model marginal response to feature 3.
double windContribution(num windSpeed) =>
    _windCurve.valueAt(windSpeed.toDouble());

/// Probability of precipitation (0..1). Model marginal response to feature 4.
double rainContribution(num pop) => _rainCurve.valueAt(pop.toDouble());

/// Atmospheric temperature (varying according to pressure and humidity) below
/// which water droplets begin to condense and dew can form.
// double dewPointContribution(num dewPoint) {
//   return max(0, min(10, daily.temp!.eve! - dewPoint) / 10.0);
// }

/// Cloudiness (%). Model marginal response to feature 6.
double cloudinessContribution(num clouds) =>
    _cloudCurve.valueAt(clouds.toDouble());

/// Air pressure (hPa). Model marginal response to feature 7.
double pressureContribution(num pressure) =>
    _pressCurve.valueAt(pressure.toDouble());

/// UV index. UVI is not a direct input to `final_model.dart`, but it is
/// strongly inversely related to cloud cover, which IS a model feature. We
/// therefore map the observed UVI to an equivalent cloud-cover value and reuse
/// the model's cloudiness partial-dependence curve, so the gauge still tracks
/// learned model logic rather than an arbitrary distribution.
double uviContribution(num uvi) {
  final u = uvi.toDouble().clamp(0.0, 11.0).toDouble();
  final equivalentCloud = (1.0 - u / 11.0) * 100.0;
  return cloudinessContribution(equivalentCloud);
}
