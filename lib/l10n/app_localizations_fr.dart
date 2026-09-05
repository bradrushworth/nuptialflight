// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Prédicteur de Vol Nuptial des Fourmis';

  @override
  String get locating => 'Localisation…';

  @override
  String get unknownLocation => 'Lieu inconnu';

  @override
  String get fetchingWeather => 'Récupération de la météo locale…';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get chooseALocation => 'Choisir un lieu';

  @override
  String get unexpectedError =>
      'Une erreur inattendue s\'est produite. Signalez-la à bitbot@bitbot.com.au ';

  @override
  String get locationFailedError =>
      'Impossible d\'obtenir votre position !\n\nVeuillez la saisir manuellement.';

  @override
  String get locationDeniedError =>
      'Autorisation de localisation refusée !\n\nVeuillez saisir votre position manuellement.';

  @override
  String get menuReportIssue => 'Signaler un problème';

  @override
  String get menuWebApp => 'Application web';

  @override
  String get menuAndroid => 'Android';

  @override
  String get menuIos => 'iOS';

  @override
  String get menuSourceCode => 'Code source';

  @override
  String get menuCoffee => 'Offrir un café à Brad';

  @override
  String get menuUseMetric => 'Utiliser °C · m/s';

  @override
  String get menuUseImperial => 'Utiliser °F · mph';

  @override
  String get tooltipShowMap => 'Afficher la carte';

  @override
  String get tooltipMoreOptions => 'Plus d\'options';

  @override
  String get tooltipReportFlight => 'Signaler un vol nuptial observé';

  @override
  String todayDate(String date) {
    return 'Aujourd\'hui · $date';
  }

  @override
  String get next24Hours => 'Prochaines 24 heures';

  @override
  String get chartCaption => 'confiance de vol par heure';

  @override
  String get nowTick => 'Maintenant';

  @override
  String get upcomingWeek => 'Semaine à venir';

  @override
  String get bandNoFly => 'Aucun vol';

  @override
  String get bandQuiet => 'Calme';

  @override
  String get bandWatchful => 'Moyen';

  @override
  String get bandPromising => 'Prometteur';

  @override
  String get bandPrime => 'Idéal';

  @override
  String get headlineNoFly => 'Pas de vols aujourd\'hui';

  @override
  String get headlineQuiet => 'Journée calme';

  @override
  String get headlineWatchful => 'Un peu mieux que la moyenne';

  @override
  String get headlinePromising => 'Journée prometteuse';

  @override
  String get headlinePrime => 'Conditions idéales';

  @override
  String get actionNoFly => 'Par ce temps, les fourmis restent au nid';

  @override
  String get actionQuiet => 'Ne vaut pas un déplacement';

  @override
  String get actionWatchful => 'Gardez l\'œil ouvert si vous sortez';

  @override
  String get actionPromising => 'Un coup d\'œil au meilleur créneau s\'impose';

  @override
  String get actionPrime => 'Sortez vite - ces conditions sont rares';

  @override
  String oneInN(int n) {
    return '1 sur $n';
  }

  @override
  String get daysLikeThisSeeFlights => 'jours comme celui-ci\nvoient des vols';

  @override
  String bestWindow(String start, String end) {
    return 'Meilleur créneau $start–$end';
  }

  @override
  String likelySizeSpecies(String size) {
    return 'Espèce $size probable';
  }

  @override
  String get sizeSmall => 'petite';

  @override
  String get sizeMedium => 'moyenne';

  @override
  String get sizeLarge => 'grande';

  @override
  String get whyShort => 'Pourquoi ?';

  @override
  String get whyTitle => 'Pourquoi cette prévision ?';

  @override
  String get whyExplainer =>
      'Chaque courbe montre ce que le modèle a appris d\'une condition. Le point marque la valeur de ce jour — être haut sur la courbe signifie que cette condition aide la prévision.';

  @override
  String get whyFooter =>
      'Les courbes sont la réponse marginale du modèle entraîné, pas des règles fixes — elles évoluent quand le modèle est réentraîné sur de nouveaux signalements.';

  @override
  String get tagHelps => 'Aide';

  @override
  String get tagSlightlyHelps => 'Aide un peu';

  @override
  String get tagNeutral => 'Sans effet notable';

  @override
  String get tagHurtsALittle => 'Nuit un peu';

  @override
  String get tagHurts => 'Nuit';

  @override
  String get featTemperature => 'Température';

  @override
  String get featTemperatureNote =>
      'La chaleur est le signal le plus fort du modèle';

  @override
  String get featWind => 'Vent';

  @override
  String get featWindNote =>
      'L\'air calme est idéal ; le vent fort cloue les reines au sol';

  @override
  String get featHumidity => 'Humidité';

  @override
  String get featHumidityNote => 'L\'air humide après la pluie aide en général';

  @override
  String get featCloud => 'Nébulosité';

  @override
  String get featCloudNote => 'La réponse apprise du modèle aux nuages';

  @override
  String get featRain => 'Risque de pluie';

  @override
  String get featRainNote => 'Probabilité de précipitations de ce jour';

  @override
  String get featPressure => 'Pression atmosphérique';

  @override
  String get featPressureNote => 'La pression influe rarement beaucoup';

  @override
  String driverTemp(String value) {
    return 'Temp $value';
  }

  @override
  String driverWind(String value) {
    return 'Vent $value';
  }

  @override
  String driverHumidity(String value) {
    return 'Humidité $value%';
  }

  @override
  String driverCloud(String value) {
    return 'Nuages $value%';
  }

  @override
  String driverRain(String value) {
    return 'Pluie $value%';
  }

  @override
  String get driverPressure => 'Pression';

  @override
  String condWind(String value) {
    return 'vent $value';
  }

  @override
  String condHumidity(String value) {
    return '$value% d\'humidité';
  }

  @override
  String condDewPoint(String value) {
    return 'Point de rosée $value';
  }

  @override
  String honestyBand(String band, int percentile) {
    return 'Indice de Vol : $band - meilleur que $percentile% des jours à votre latitude ce mois-ci.';
  }

  @override
  String honestyOdds(int n) {
    return 'Environ 1 jour comme celui-ci sur $n donne lieu à un vol signalé.';
  }

  @override
  String honestyScore(String score) {
    return 'Score brut du modèle : $score (part de la forêt votant « vol » - pas une probabilité).';
  }

  @override
  String get sizeSeasonTitle => 'Quelle taille est de saison ?';

  @override
  String get sizeSeasonExplainer =>
      'Chaque taille de reine culmine à des mois différents. Par rapport à la confiance du jour :';

  @override
  String get sizeRowSmall => 'Petite (~10 mm)';

  @override
  String get sizeRowMedium => 'Moyenne (~20 mm)';

  @override
  String get sizeRowLarge => 'Grande (~30 mm)';

  @override
  String get reportFlightButton => 'Signaler un vol';

  @override
  String get reportTitle => 'Signaler un vol nuptial';

  @override
  String get reportBlurb =>
      'Des reines ailées près de chez vous ? Choisissez la taille la plus proche. Les vrais signalements entraînent la prévision pour tous.';

  @override
  String get reportSmall => 'Petite';

  @override
  String get reportMedium => 'Moyenne';

  @override
  String get reportLarge => 'Grande';

  @override
  String get reportAbout10mm => 'environ 10 mm';

  @override
  String get reportAbout20mm => 'environ 20 mm';

  @override
  String get reportAbout30mm => 'environ 30 mm';

  @override
  String reportingFrom(String location) {
    return 'Signalement depuis votre position actuelle · $location';
  }

  @override
  String get submitSighting => 'Envoyer l\'observation';

  @override
  String get noFlightsButton => 'J\'ai regardé — aucun vol';

  @override
  String get cancel => 'Annuler';

  @override
  String get snackFixedLocation =>
      'Les signalements doivent venir de votre position réelle et actuelle.';

  @override
  String get snackDebugMode => 'Le signalement est désactivé en mode débogage.';

  @override
  String get snackThanksNoFlight =>
      'Merci — les signalements « aucun vol » améliorent aussi le modèle.';

  @override
  String get snackThanksSighting =>
      'Merci ! Votre observation aide à entraîner la prévision.';

  @override
  String snackNearbyFlights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n vols signalés à moins de 500 km ces dernières 24 h — voyez la carte !',
      one:
          '1 vol signalé à moins de 500 km ces dernières 24 h — voyez la carte !',
    );
    return '$_temp0';
  }

  @override
  String get notifReportTitle => 'Vol nuptial signalé près de chez vous !';

  @override
  String notifReportBody(int n, int minutes, int distance) {
    return '$n vols signalés au cours des $minutes dernières minutes, le plus proche à $distance km...';
  }

  @override
  String get notifPrimeTitle => 'Conditions idéales pour les vols nuptiaux !';

  @override
  String notifPrimeBody(int n) {
    return 'Un jour rare pour votre saison - environ 1 jour sur $n comme celui-ci voit des vols signalés.';
  }
}
