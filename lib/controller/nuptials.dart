import 'dart:math';

//import 'dart:developer' as developer;
import 'package:intl/intl.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:nuptialflight/models/forest_model.dart';
import 'package:nuptialflight/responses/onecall_response.dart';

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
  ForestModel? _dailyModel;
  ForestModel? _hourlyModel;
  static Future<void>? _loading;

  // using a factory is important
  // because it promises to return _an_ object of this type
  // but it doesn't promise to make a new one.
  factory Nuptials() {
    return _instance;
  }

  Nuptials._internal();

  /// Loads both forest models from the bundled sklite JSON assets. Safe to
  /// call repeatedly; the models are only parsed once. MUST complete before
  /// any scoring/gauge function is used.
  static Future<void> ensureLoaded() => _loading ??= _load();

  static Future<void> _load() async {
    _instance._dailyModel = ForestModel.fromJsonString(
        await rootBundle.loadString('assets/final_model.json'));
    _instance._hourlyModel = ForestModel.fromJsonString(
        await rootBundle.loadString('assets/hour_model.json'));
  }

  /// Test hook: inject models parsed from raw JSON strings (used by plain
  /// package:test tests that cannot use rootBundle).
  static void loadFromStrings(String dailyJson, String hourlyJson) {
    _instance._dailyModel = ForestModel.fromJsonString(dailyJson);
    _instance._hourlyModel = ForestModel.fromJsonString(hourlyJson);
    _loading = Future.value();
  }

  ForestModel get daily => _dailyModel!;
  ForestModel get hourly => _hourlyModel!;
}

// ---------------------------------------------------------------------------
// Per-size seasonal prior.
//
// Queen ants of different sizes fly at slightly different times of year. The
// shared weather model captures the *conditions* but not this seasonal timing,
// so we layer on a data-derived seasonal multiplier per size class.
//
// Derived from the ArangoDB `flights` collection (10,125 sized positives):
// counts of confirmed flights per (hemisphere, size, calendar month), 3-month
// smoothed and normalised so each size's peak month == 1.0. Index 0 = January.
// See docs/model_training_findings.md and lib/models/*.ipynb.
// ---------------------------------------------------------------------------
const Map<String, List<double>> _sizeSeasonalN = {
  'small': [0.1129, 0.1667, 0.2505, 0.4015, 0.6841, 0.9962, 1.0, 0.7401, 0.3809, 0.2304, 0.1539, 0.1171],
  'medium': [0.1449, 0.2049, 0.346, 0.5357, 0.8247, 1.0, 0.9378, 0.6571, 0.3839, 0.2625, 0.1942, 0.151],
  'large': [0.2362, 0.3106, 0.4904, 0.7266, 0.9448, 1.0, 0.8945, 0.6391, 0.4568, 0.3321, 0.295, 0.2422],
};

const Map<String, List<double>> _sizeSeasonalS = {
  'small': [0.8522, 0.7581, 0.5618, 0.5323, 0.4301, 0.3253, 0.2903, 0.4973, 0.6801, 0.8925, 0.8817, 1.0],
  'medium': [0.9702, 0.8214, 0.7262, 0.5952, 0.5119, 0.4048, 0.4345, 0.4643, 0.5536, 0.6845, 0.8869, 1.0],
  'large': [0.9159, 0.9626, 1.0, 0.785, 0.5981, 0.3738, 0.4206, 0.5607, 0.757, 0.9907, 0.9907, 0.9813],
};

/// Seasonal likelihood multiplier in [0.0, 1.0] that a queen of the given
/// [size] ('small' | 'medium' | 'large') is flying at the given [dateUtc] and
/// latitude [lat]. 1.0 = this size's peak flight month; lower = out of season.
/// Returns 1.0 for an unknown/null size (no seasonal adjustment).
double sizeSeasonalMultiplier(String? size, num lat, DateTime dateUtc) {
  if (size == null) return 1.0;
  final table = lat > 0 ? _sizeSeasonalN : _sizeSeasonalS;
  final row = table[size];
  if (row == null) return 1.0;
  final monthIndex = dateUtc.month - 1; // DateTime.month is 1..12
  return row[monthIndex];
}

/// Returns the per-size seasonal likelihood for all three size classes at the
/// given location/date, expressed as integer percentages (0..100) relative to
/// the base daily flight [basePercentage]. Used by the UI to show, e.g.,
/// "Large 48% / Medium 30% / Small 12%" so keepers hunting a specific species
/// get species-appropriate timing.
Map<String, int> sizeSeasonalPercentages(int basePercentage, num lat, DateTime dateUtc) {
  final result = <String, int>{};
  for (final size in const ['small', 'medium', 'large']) {
    result[size] = (basePercentage * sizeSeasonalMultiplier(size, lat, dateUtc)).round();
  }
  return result;
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
  double hemisphere = lat > 0 ? 1.0 : 0.0;
  int dayOfYear = int.parse(dayOfYearFormat
      .format(DateTime.fromMillisecondsSinceEpoch((hourly.dt!) * 1000, isUtc: true)));
  int hour = int.parse(
      hourFormat.format(DateTime.fromMillisecondsSinceEpoch((hourly.dt!) * 1000, isUtc: true)));
  // Cyclical encoding of the day of year (replaces daysSinceSpring).
  double sinDoy = sin(2 * pi * dayOfYear / 365.25);
  double cosDoy = cos(2 * pi * dayOfYear / 365.25);
  // Dew-point depression: how far the air is from saturation.
  double dewDep = temp - dewPoint;

  if (temp < 5) return 0.01;
  if (wind > 15) return 0.01;
  if (gust > 20) return 0.01;

  return min(
      0.99,
      max(
          0.01,
          // hour_model (retrained 2026-07-26) expects these 12 features in
          // this exact order - keep in sync with the training pipeline
          // (see docs/model_training_findings.md). No rain/cloud, as before.
          Nuptials().hourly.scorePositive([
            lat.toDouble(),
            lon.toDouble(),
            hemisphere,
            sinDoy,
            cosDoy,
            hour.toDouble(),
            temp,
            wind,
            humid,
            press,
            dewPoint,
            dewDep,
          ])));
}
double nuptialDailyPercentageModel(num lat, num lon, Daily daily,
    {bool nocturnal = false, num? pop1, num? pop2}) {
  double temp = daily.temp!.day!.toDouble();
  double wind = daily.windSpeed!.toDouble();
  double gust = daily.windGust?.toDouble() ?? daily.windSpeed!.toDouble();
  double rain = daily.pop!.toDouble();
  double humid = daily.humidity!.toDouble();
  double cloud = daily.clouds!.toDouble();
  double press = daily.pressure!.toDouble();
  double dewPoint = daily.dewPoint!.toDouble();
  double hemisphere = lat > 0 ? 1.0 : 0.0;
  int dayOfYear = int.parse(
      dayOfYearFormat.format(DateTime.fromMillisecondsSinceEpoch((daily.dt!) * 1000, isUtc: true)));
  // Cyclical encoding of the day of year (replaces daysSinceSpring).
  double sinDoy = sin(2 * pi * dayOfYear / 365.25);
  double cosDoy = cos(2 * pi * dayOfYear / 365.25);
  // Dew-point depression: how far the air is from saturation.
  double dewDep = temp - dewPoint;
  // Antecedent rain: probability of precipitation on the next two days
  // (daily[i+1]/daily[i+2].pop). Missing values default to 0, matching the
  // training pipeline (fillna(0)).
  double rain1 = pop1?.toDouble() ?? 0.0;
  double rain2 = pop2?.toDouble() ?? 0.0;

  if (temp < 5) return 0.01;
  if (wind > 15) return 0.01;
  if (gust > 20) return 0.01;

  return min(
      0.99,
      max(
          0.01,
          // final_model.dart (retrained 2026-07-26) expects these 15 features
          // in this exact order - keep in sync with the training pipeline
          // (see docs/model_training_findings.md).
          Nuptials().daily.scorePositive([
            lat.toDouble(),
            lon.toDouble(),
            hemisphere,
            sinDoy,
            cosDoy,
            temp,
            wind,
            rain,
            humid,
            cloud,
            press,
            dewPoint,
            dewDep,
            rain1,
            rain2,
          ])));
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
/// 15-element daily-model input vector:
/// [lat, lon, hemisphere, sin_doy, cos_doy, temp, wind, rain0, humid, cloud,
///  press, dewPoint, dew_dep, rain1, rain2].
/// The target feature is overwritten per query, so only the non-target values
/// matter.
List<List<double>> _buildPdContexts() {
  // Geography x season anchors (lat, lon, dayOfYear): early/mid/late flight
  // season for each hemisphere.
  const anchors = <List<double>>[
    [50, 10, 122], // NH Europe, early season (May)
    [50, 10, 212], // NH Europe, mid season (Jul/Aug)
    [50, 10, 302], // NH Europe, late season (Oct)
    [40, -90, 122], // NH North America, early
    [40, -90, 212], // NH North America, mid
    [40, -90, 302], // NH North America, late
    [-33, 151, 273], // SH Australia, early (Sep/Oct)
    [-33, 151, 363], // SH Australia, mid (Dec)
    [-33, 151, 88], // SH Australia, late (Mar)
    [-30, -60, 273], // SH South America, early
    [-30, -60, 363], // SH South America, mid
    [-30, -60, 88], // SH South America, late
  ];
  // Representative weather states:
  // [wind, rain0, humid, cloud, press, dew, temp, rain1, rain2].
  const states = <List<double>>[
    [3.0, 0.0, 65.0, 35.0, 1016.0, 12.0, 22.0, 0.0, 0.0], // ideal
    [5.7, 0.0, 77.0, 70.0, 1014.0, 12.0, 16.5, 0.2, 0.2], // typical
    [8.0, 0.15, 88.0, 85.0, 1006.0, 15.0, 14.0, 0.5, 0.4], // marginal
  ];
  final contexts = <List<double>>[];
  for (final a in anchors) {
    for (final s in states) {
      contexts.add([
        a[0], // 0 lat
        a[1], // 1 lon
        a[0] > 0 ? 1.0 : 0.0, // 2 hemisphere
        sin(2 * pi * a[2] / 365.25), // 3 sin_doy
        cos(2 * pi * a[2] / 365.25), // 4 cos_doy
        s[6], // 5 temp (overwritten by temperature queries)
        s[0], // 6 wind
        s[1], // 7 rain0
        s[2], // 8 humidity
        s[3], // 9 cloud
        s[4], // 10 pressure
        s[5], // 11 dewPoint
        s[6] - s[5], // 12 dew_dep (baseline; held constant per context)
        s[7], // 13 rain1
        s[8], // 14 rain2
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
    sum += Nuptials().daily.scorePositive(input);
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

late final _PdCurve _tempCurve = _PdCurve(5, 0, 40, 1);
late final _PdCurve _windCurve = _PdCurve(6, 0, 32, 0.5);
late final _PdCurve _rainCurve = _PdCurve(7, 0, 1, 0.05);
late final _PdCurve _humidCurve = _PdCurve(8, 0, 100, 2.5);
late final _PdCurve _cloudCurve = _PdCurve(9, 0, 100, 2.5);
late final _PdCurve _pressCurve = _PdCurve(10, 980, 1040, 1.5);

/// Daytime temperature (Celsius). Model marginal response to feature index 5.
double temperatureContribution(num temp) =>
    _tempCurve.valueAt(temp.toDouble());

/// Humidity (%). Model marginal response to feature 8.
double humidityContribution(num humidity) =>
    _humidCurve.valueAt(humidity.toDouble());

/// Wind speed (m/s). Model marginal response to feature 6.
double windContribution(num windSpeed) =>
    _windCurve.valueAt(windSpeed.toDouble());

/// Probability of precipitation (0..1). Model marginal response to feature 7.
double rainContribution(num pop) => _rainCurve.valueAt(pop.toDouble());

/// Atmospheric temperature (varying according to pressure and humidity) below
/// which water droplets begin to condense and dew can form.
// double dewPointContribution(num dewPoint) {
//   return max(0, min(10, daily.temp!.eve! - dewPoint) / 10.0);
// }

/// Cloudiness (%). Model marginal response to feature 9.
double cloudinessContribution(num clouds) =>
    _cloudCurve.valueAt(clouds.toDouble());

/// Air pressure (hPa). Model marginal response to feature 10.
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
