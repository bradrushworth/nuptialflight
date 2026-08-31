// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ant Nuptial Flight Predictor';

  @override
  String get locating => 'Locating…';

  @override
  String get unknownLocation => 'Unknown Location';

  @override
  String get fetchingWeather => 'Fetching your local weather…';

  @override
  String get tryAgain => 'Try again';

  @override
  String get chooseALocation => 'Choose a location';

  @override
  String get unexpectedError =>
      'Unexpected error occurred. Please report to bitbot@bitbot.com.au ';

  @override
  String get locationFailedError =>
      'Failed to get your location!\n\nPlease manually enter your location.';

  @override
  String get locationDeniedError =>
      'Location permissions are denied!\n\nPlease manually enter your location.';

  @override
  String get menuReportIssue => 'Report Issue';

  @override
  String get menuWebApp => 'Web App';

  @override
  String get menuAndroid => 'Android';

  @override
  String get menuIos => 'iOS';

  @override
  String get menuSourceCode => 'Source Code';

  @override
  String get menuCoffee => 'Buy Brad Coffee';

  @override
  String get menuUseMetric => 'Use °C · m/s';

  @override
  String get menuUseImperial => 'Use °F · mph';

  @override
  String get tooltipShowMap => 'Show map';

  @override
  String get tooltipMoreOptions => 'More options';

  @override
  String get tooltipReportFlight => 'Report a nuptial flight you saw';

  @override
  String todayDate(String date) {
    return 'Today · $date';
  }

  @override
  String get next24Hours => 'Next 24 hours';

  @override
  String get chartCaption => 'flight confidence by hour';

  @override
  String get nowTick => 'Now';

  @override
  String get upcomingWeek => 'Upcoming week';

  @override
  String get bandNoFly => 'No-fly';

  @override
  String get bandQuiet => 'Quiet';

  @override
  String get bandWatchful => 'Fair';

  @override
  String get bandPromising => 'Promising';

  @override
  String get bandPrime => 'Prime';

  @override
  String get headlineNoFly => 'No flights today';

  @override
  String get headlineQuiet => 'Quiet day';

  @override
  String get headlineWatchful => 'Slightly better than average';

  @override
  String get headlinePromising => 'Promising day';

  @override
  String get headlinePrime => 'Prime conditions';

  @override
  String get actionNoFly => 'Ants stay home in this weather';

  @override
  String get actionQuiet => 'Not worth a special trip';

  @override
  String get actionWatchful => 'Keep an eye out if you\'re outside';

  @override
  String get actionPromising => 'Worth a look at the best window';

  @override
  String get actionPrime => 'Get out there - conditions are rare';

  @override
  String oneInN(int n) {
    return '1 in $n';
  }

  @override
  String get daysLikeThisSeeFlights => 'days like this\nsee flights';

  @override
  String bestWindow(String start, String end) {
    return 'Best window $start–$end';
  }

  @override
  String likelySizeSpecies(String size) {
    return 'Likely $size species';
  }

  @override
  String get sizeSmall => 'small';

  @override
  String get sizeMedium => 'medium';

  @override
  String get sizeLarge => 'large';

  @override
  String get whyShort => 'Why?';

  @override
  String get whyTitle => 'Why this forecast?';

  @override
  String get whyExplainer =>
      'Each curve is what the model learned about one condition. The dot marks right now — high on the curve means that condition is helping today\'s forecast.';

  @override
  String get whyFooter =>
      'Curves are the trained model\'s marginal response, not fixed rules — they update when the model is retrained on new sighting reports.';

  @override
  String get tagHelps => 'Helps today';

  @override
  String get tagSlightlyHelps => 'Slightly helps';

  @override
  String get tagNeutral => 'No strong effect';

  @override
  String get tagHurtsALittle => 'Hurts a little';

  @override
  String get tagHurts => 'Hurts today';

  @override
  String get featTemperature => 'Temperature';

  @override
  String get featTemperatureNote => 'Warmth is the model\'s strongest signal';

  @override
  String get featWind => 'Wind';

  @override
  String get featWindNote => 'Calm air scores best; strong wind grounds queens';

  @override
  String get featHumidity => 'Humidity';

  @override
  String get featHumidityNote => 'Moist air after rain generally helps';

  @override
  String get featCloud => 'Cloud cover';

  @override
  String get featCloudNote => 'The model\'s learned response to cloudiness';

  @override
  String get featRain => 'Rain chance';

  @override
  String get featRainNote => 'Today\'s probability of precipitation';

  @override
  String get featPressure => 'Air pressure';

  @override
  String get featPressureNote => 'Pressure rarely moves the forecast much';

  @override
  String driverTemp(String value) {
    return 'Temp $value';
  }

  @override
  String driverWind(String value) {
    return 'Wind $value';
  }

  @override
  String driverHumidity(String value) {
    return 'Humidity $value%';
  }

  @override
  String driverCloud(String value) {
    return 'Cloud $value%';
  }

  @override
  String driverRain(String value) {
    return 'Rain $value%';
  }

  @override
  String get driverPressure => 'Pressure';

  @override
  String condWind(String value) {
    return '$value wind';
  }

  @override
  String condHumidity(String value) {
    return '$value% humidity';
  }

  @override
  String condDewPoint(String value) {
    return 'Dew point $value';
  }

  @override
  String honestyBand(String band, int percentile) {
    return 'Ant Flight Index: $band - today is better than $percentile% of days at your latitude this month.';
  }

  @override
  String honestyOdds(int n) {
    return 'About 1 in $n days like this get a flight reported by users.';
  }

  @override
  String honestyScore(String score) {
    return 'Raw model score: $score (the share of the forest voting \"flight\" - not a probability).';
  }

  @override
  String get sizeSeasonTitle => 'Which size is in season?';

  @override
  String get sizeSeasonExplainer =>
      'Different queen sizes peak in different months. Relative to today\'s overall confidence:';

  @override
  String get sizeRowSmall => 'Small (~10 mm)';

  @override
  String get sizeRowMedium => 'Medium (~20 mm)';

  @override
  String get sizeRowLarge => 'Large (~30 mm)';

  @override
  String get reportFlightButton => 'Report flight';

  @override
  String get reportTitle => 'Report a nuptial flight';

  @override
  String get reportBlurb =>
      'Saw winged queens flying near you? Pick the closest size. Real sightings train the forecast for everyone.';

  @override
  String get reportSmall => 'Small';

  @override
  String get reportMedium => 'Medium';

  @override
  String get reportLarge => 'Large';

  @override
  String get reportAbout10mm => 'about 10 mm';

  @override
  String get reportAbout20mm => 'about 20 mm';

  @override
  String get reportAbout30mm => 'about 30 mm';

  @override
  String reportingFrom(String location) {
    return 'Reporting from your current location · $location';
  }

  @override
  String get submitSighting => 'Submit sighting';

  @override
  String get noFlightsButton => 'I looked — no flights';

  @override
  String get cancel => 'Cancel';

  @override
  String get snackFixedLocation =>
      'Reports must come from your real, current location.';

  @override
  String get snackDebugMode => 'Reporting is disabled in debug builds.';

  @override
  String get snackThanksNoFlight =>
      'Thanks — no-flight reports improve the model too.';

  @override
  String get snackThanksSighting =>
      'Thank you! Your sighting helps train the forecast.';

  @override
  String snackNearbyFlights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n flights reported within 500 km in the last 24 h — see the map!',
      one: '1 flight reported within 500 km in the last 24 h — see the map!',
    );
    return '$_temp0';
  }

  @override
  String get notifReportTitle => 'Current reported local nuptial flight!';

  @override
  String notifReportBody(int n, int minutes, int distance) {
    return 'There are $n reported flights in the last $minutes minutes with the nearest $distance km away...';
  }

  @override
  String get notifPrimeTitle => 'Prime conditions for nuptial flights!';

  @override
  String notifPrimeBody(int n) {
    return 'A rare day for your season - about 1 in $n days like this see reported flights.';
  }
}
