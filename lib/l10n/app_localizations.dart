import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fil.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('cs'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('fil'),
    Locale('fr'),
    Locale('id'),
    Locale('ms'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Ant Nuptial Flight Predictor'**
  String get appTitle;

  /// No description provided for @locating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get locating;

  /// No description provided for @unknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown Location'**
  String get unknownLocation;

  /// No description provided for @fetchingWeather.
  ///
  /// In en, this message translates to:
  /// **'Fetching your local weather…'**
  String get fetchingWeather;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @chooseALocation.
  ///
  /// In en, this message translates to:
  /// **'Choose a location'**
  String get chooseALocation;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error occurred. Please report to bitbot@bitbot.com.au '**
  String get unexpectedError;

  /// No description provided for @locationFailedError.
  ///
  /// In en, this message translates to:
  /// **'Failed to get your location!\n\nPlease manually enter your location.'**
  String get locationFailedError;

  /// No description provided for @locationDeniedError.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are denied!\n\nPlease manually enter your location.'**
  String get locationDeniedError;

  /// No description provided for @menuReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get menuReportIssue;

  /// No description provided for @menuWebApp.
  ///
  /// In en, this message translates to:
  /// **'Web App'**
  String get menuWebApp;

  /// No description provided for @menuAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get menuAndroid;

  /// No description provided for @menuIos.
  ///
  /// In en, this message translates to:
  /// **'iOS'**
  String get menuIos;

  /// No description provided for @menuSourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get menuSourceCode;

  /// No description provided for @menuCoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy Brad Coffee'**
  String get menuCoffee;

  /// No description provided for @menuUseMetric.
  ///
  /// In en, this message translates to:
  /// **'Use °C · m/s'**
  String get menuUseMetric;

  /// No description provided for @menuUseImperial.
  ///
  /// In en, this message translates to:
  /// **'Use °F · mph'**
  String get menuUseImperial;

  /// No description provided for @tooltipShowMap.
  ///
  /// In en, this message translates to:
  /// **'Show map'**
  String get tooltipShowMap;

  /// No description provided for @tooltipMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get tooltipMoreOptions;

  /// No description provided for @tooltipReportFlight.
  ///
  /// In en, this message translates to:
  /// **'Report a nuptial flight you saw'**
  String get tooltipReportFlight;

  /// No description provided for @todayDate.
  ///
  /// In en, this message translates to:
  /// **'Today · {date}'**
  String todayDate(String date);

  /// No description provided for @next24Hours.
  ///
  /// In en, this message translates to:
  /// **'Next 24 hours'**
  String get next24Hours;

  /// No description provided for @chartCaption.
  ///
  /// In en, this message translates to:
  /// **'flight confidence by hour'**
  String get chartCaption;

  /// No description provided for @nowTick.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get nowTick;

  /// No description provided for @upcomingWeek.
  ///
  /// In en, this message translates to:
  /// **'Upcoming week'**
  String get upcomingWeek;

  /// No description provided for @bandNoFly.
  ///
  /// In en, this message translates to:
  /// **'No-fly'**
  String get bandNoFly;

  /// No description provided for @bandQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get bandQuiet;

  /// No description provided for @bandWatchful.
  ///
  /// In en, this message translates to:
  /// **'Watchful'**
  String get bandWatchful;

  /// No description provided for @bandPromising.
  ///
  /// In en, this message translates to:
  /// **'Promising'**
  String get bandPromising;

  /// No description provided for @bandPrime.
  ///
  /// In en, this message translates to:
  /// **'Prime'**
  String get bandPrime;

  /// No description provided for @headlineNoFly.
  ///
  /// In en, this message translates to:
  /// **'No flights today'**
  String get headlineNoFly;

  /// No description provided for @headlineQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet day'**
  String get headlineQuiet;

  /// No description provided for @headlineWatchful.
  ///
  /// In en, this message translates to:
  /// **'Worth watching'**
  String get headlineWatchful;

  /// No description provided for @headlinePromising.
  ///
  /// In en, this message translates to:
  /// **'Promising day'**
  String get headlinePromising;

  /// No description provided for @headlinePrime.
  ///
  /// In en, this message translates to:
  /// **'Prime conditions'**
  String get headlinePrime;

  /// No description provided for @actionNoFly.
  ///
  /// In en, this message translates to:
  /// **'Ants stay home in this weather'**
  String get actionNoFly;

  /// No description provided for @actionQuiet.
  ///
  /// In en, this message translates to:
  /// **'Not worth a special trip'**
  String get actionQuiet;

  /// No description provided for @actionWatchful.
  ///
  /// In en, this message translates to:
  /// **'Keep an eye out if you\'re outside'**
  String get actionWatchful;

  /// No description provided for @actionPromising.
  ///
  /// In en, this message translates to:
  /// **'Worth a look at the best window'**
  String get actionPromising;

  /// No description provided for @actionPrime.
  ///
  /// In en, this message translates to:
  /// **'Get out there - conditions are rare'**
  String get actionPrime;

  /// No description provided for @oneInN.
  ///
  /// In en, this message translates to:
  /// **'1 in {n}'**
  String oneInN(int n);

  /// No description provided for @daysLikeThisSeeFlights.
  ///
  /// In en, this message translates to:
  /// **'days like this\nsee flights'**
  String get daysLikeThisSeeFlights;

  /// No description provided for @bestWindow.
  ///
  /// In en, this message translates to:
  /// **'Best window {start}–{end}'**
  String bestWindow(String start, String end);

  /// No description provided for @likelySizeSpecies.
  ///
  /// In en, this message translates to:
  /// **'Likely {size} species'**
  String likelySizeSpecies(String size);

  /// No description provided for @sizeSmall.
  ///
  /// In en, this message translates to:
  /// **'small'**
  String get sizeSmall;

  /// No description provided for @sizeMedium.
  ///
  /// In en, this message translates to:
  /// **'medium'**
  String get sizeMedium;

  /// No description provided for @sizeLarge.
  ///
  /// In en, this message translates to:
  /// **'large'**
  String get sizeLarge;

  /// No description provided for @whyShort.
  ///
  /// In en, this message translates to:
  /// **'Why?'**
  String get whyShort;

  /// No description provided for @whyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why this forecast?'**
  String get whyTitle;

  /// No description provided for @whyExplainer.
  ///
  /// In en, this message translates to:
  /// **'Each curve is what the model learned about one condition. The dot marks right now — high on the curve means that condition is helping today\'s forecast.'**
  String get whyExplainer;

  /// No description provided for @whyFooter.
  ///
  /// In en, this message translates to:
  /// **'Curves are the trained model\'s marginal response, not fixed rules — they update when the model is retrained on new sighting reports.'**
  String get whyFooter;

  /// No description provided for @tagHelps.
  ///
  /// In en, this message translates to:
  /// **'Helps today'**
  String get tagHelps;

  /// No description provided for @tagSlightlyHelps.
  ///
  /// In en, this message translates to:
  /// **'Slightly helps'**
  String get tagSlightlyHelps;

  /// No description provided for @tagNeutral.
  ///
  /// In en, this message translates to:
  /// **'No strong effect'**
  String get tagNeutral;

  /// No description provided for @tagHurtsALittle.
  ///
  /// In en, this message translates to:
  /// **'Hurts a little'**
  String get tagHurtsALittle;

  /// No description provided for @tagHurts.
  ///
  /// In en, this message translates to:
  /// **'Hurts today'**
  String get tagHurts;

  /// No description provided for @featTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get featTemperature;

  /// No description provided for @featTemperatureNote.
  ///
  /// In en, this message translates to:
  /// **'Warmth is the model\'s strongest signal'**
  String get featTemperatureNote;

  /// No description provided for @featWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get featWind;

  /// No description provided for @featWindNote.
  ///
  /// In en, this message translates to:
  /// **'Calm air scores best; strong wind grounds queens'**
  String get featWindNote;

  /// No description provided for @featHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get featHumidity;

  /// No description provided for @featHumidityNote.
  ///
  /// In en, this message translates to:
  /// **'Moist air after rain generally helps'**
  String get featHumidityNote;

  /// No description provided for @featCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud cover'**
  String get featCloud;

  /// No description provided for @featCloudNote.
  ///
  /// In en, this message translates to:
  /// **'The model\'s learned response to cloudiness'**
  String get featCloudNote;

  /// No description provided for @featRain.
  ///
  /// In en, this message translates to:
  /// **'Rain chance'**
  String get featRain;

  /// No description provided for @featRainNote.
  ///
  /// In en, this message translates to:
  /// **'Today\'s probability of precipitation'**
  String get featRainNote;

  /// No description provided for @featPressure.
  ///
  /// In en, this message translates to:
  /// **'Air pressure'**
  String get featPressure;

  /// No description provided for @featPressureNote.
  ///
  /// In en, this message translates to:
  /// **'Pressure rarely moves the forecast much'**
  String get featPressureNote;

  /// No description provided for @driverTemp.
  ///
  /// In en, this message translates to:
  /// **'Temp {value}'**
  String driverTemp(String value);

  /// No description provided for @driverWind.
  ///
  /// In en, this message translates to:
  /// **'Wind {value}'**
  String driverWind(String value);

  /// No description provided for @driverHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity {value}%'**
  String driverHumidity(String value);

  /// No description provided for @driverCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud {value}%'**
  String driverCloud(String value);

  /// No description provided for @driverRain.
  ///
  /// In en, this message translates to:
  /// **'Rain {value}%'**
  String driverRain(String value);

  /// No description provided for @driverPressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get driverPressure;

  /// No description provided for @condWind.
  ///
  /// In en, this message translates to:
  /// **'{value} wind'**
  String condWind(String value);

  /// No description provided for @condHumidity.
  ///
  /// In en, this message translates to:
  /// **'{value}% humidity'**
  String condHumidity(String value);

  /// No description provided for @condDewPoint.
  ///
  /// In en, this message translates to:
  /// **'Dew point {value}'**
  String condDewPoint(String value);

  /// No description provided for @honestyBand.
  ///
  /// In en, this message translates to:
  /// **'Ant Flight Index: {band} - today is better than {percentile}% of days at your latitude this month.'**
  String honestyBand(String band, int percentile);

  /// No description provided for @honestyOdds.
  ///
  /// In en, this message translates to:
  /// **'About 1 in {n} days like this get a flight reported by users.'**
  String honestyOdds(int n);

  /// No description provided for @honestyScore.
  ///
  /// In en, this message translates to:
  /// **'Raw model score: {score} (the share of the forest voting \"flight\" - not a probability).'**
  String honestyScore(String score);

  /// No description provided for @sizeSeasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Which size is in season?'**
  String get sizeSeasonTitle;

  /// No description provided for @sizeSeasonExplainer.
  ///
  /// In en, this message translates to:
  /// **'Different queen sizes peak in different months. Relative to today\'s overall confidence:'**
  String get sizeSeasonExplainer;

  /// No description provided for @sizeRowSmall.
  ///
  /// In en, this message translates to:
  /// **'Small (~10 mm)'**
  String get sizeRowSmall;

  /// No description provided for @sizeRowMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium (~20 mm)'**
  String get sizeRowMedium;

  /// No description provided for @sizeRowLarge.
  ///
  /// In en, this message translates to:
  /// **'Large (~30 mm)'**
  String get sizeRowLarge;

  /// No description provided for @reportFlightButton.
  ///
  /// In en, this message translates to:
  /// **'Report flight'**
  String get reportFlightButton;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a nuptial flight'**
  String get reportTitle;

  /// No description provided for @reportBlurb.
  ///
  /// In en, this message translates to:
  /// **'Saw winged queens flying near you? Pick the closest size. Real sightings train the forecast for everyone.'**
  String get reportBlurb;

  /// No description provided for @reportSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get reportSmall;

  /// No description provided for @reportMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get reportMedium;

  /// No description provided for @reportLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get reportLarge;

  /// No description provided for @reportAbout10mm.
  ///
  /// In en, this message translates to:
  /// **'about 10 mm'**
  String get reportAbout10mm;

  /// No description provided for @reportAbout20mm.
  ///
  /// In en, this message translates to:
  /// **'about 20 mm'**
  String get reportAbout20mm;

  /// No description provided for @reportAbout30mm.
  ///
  /// In en, this message translates to:
  /// **'about 30 mm'**
  String get reportAbout30mm;

  /// No description provided for @reportingFrom.
  ///
  /// In en, this message translates to:
  /// **'Reporting from your current location · {location}'**
  String reportingFrom(String location);

  /// No description provided for @submitSighting.
  ///
  /// In en, this message translates to:
  /// **'Submit sighting'**
  String get submitSighting;

  /// No description provided for @noFlightsButton.
  ///
  /// In en, this message translates to:
  /// **'I looked — no flights'**
  String get noFlightsButton;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @snackFixedLocation.
  ///
  /// In en, this message translates to:
  /// **'Reports must come from your real, current location.'**
  String get snackFixedLocation;

  /// No description provided for @snackDebugMode.
  ///
  /// In en, this message translates to:
  /// **'Reporting is disabled in debug builds.'**
  String get snackDebugMode;

  /// No description provided for @snackThanksNoFlight.
  ///
  /// In en, this message translates to:
  /// **'Thanks — no-flight reports improve the model too.'**
  String get snackThanksNoFlight;

  /// No description provided for @snackThanksSighting.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your sighting helps train the forecast.'**
  String get snackThanksSighting;

  /// No description provided for @snackNearbyFlights.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 flight reported within 500 km in the last 24 h — see the map!} other{{n} flights reported within 500 km in the last 24 h — see the map!}}'**
  String snackNearbyFlights(int n);

  /// No description provided for @notifReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Current reported local nuptial flight!'**
  String get notifReportTitle;

  /// No description provided for @notifReportBody.
  ///
  /// In en, this message translates to:
  /// **'There are {n} reported flights in the last {minutes} minutes with the nearest {distance} km away...'**
  String notifReportBody(int n, int minutes, int distance);

  /// No description provided for @notifPrimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Prime conditions for nuptial flights!'**
  String get notifPrimeTitle;

  /// No description provided for @notifPrimeBody.
  ///
  /// In en, this message translates to:
  /// **'A rare day for your season - about 1 in {n} days like this see reported flights.'**
  String notifPrimeBody(int n);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'cs',
    'de',
    'el',
    'en',
    'es',
    'fil',
    'fr',
    'id',
    'ms',
    'nl',
    'pl',
    'pt',
    'tr',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs':
      return AppLocalizationsCs();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fil':
      return AppLocalizationsFil();
    case 'fr':
      return AppLocalizationsFr();
    case 'id':
      return AppLocalizationsId();
    case 'ms':
      return AppLocalizationsMs();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
