// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Ameisen-Hochzeitsflug-Vorhersage';

  @override
  String get locating => 'Standort wird ermittelt…';

  @override
  String get unknownLocation => 'Unbekannter Ort';

  @override
  String get fetchingWeather => 'Lokales Wetter wird geladen…';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get chooseALocation => 'Ort wählen';

  @override
  String get unexpectedError =>
      'Unerwarteter Fehler. Bitte an bitbot@bitbot.com.au melden ';

  @override
  String get locationFailedError =>
      'Standort konnte nicht ermittelt werden!\n\nBitte manuell eingeben.';

  @override
  String get locationDeniedError =>
      'Standortberechtigung verweigert!\n\nBitte Standort manuell eingeben.';

  @override
  String get menuReportIssue => 'Problem melden';

  @override
  String get menuWebApp => 'Web-App';

  @override
  String get menuAndroid => 'Android';

  @override
  String get menuIos => 'iOS';

  @override
  String get menuSourceCode => 'Quellcode';

  @override
  String get menuCoffee => 'Brad einen Kaffee spendieren';

  @override
  String get menuUseMetric => '°C · m/s verwenden';

  @override
  String get menuUseImperial => '°F · mph verwenden';

  @override
  String get tooltipShowMap => 'Karte anzeigen';

  @override
  String get tooltipMoreOptions => 'Weitere Optionen';

  @override
  String get tooltipReportFlight => 'Beobachteten Hochzeitsflug melden';

  @override
  String todayDate(String date) {
    return 'Heute · $date';
  }

  @override
  String get next24Hours => 'Nächste 24 Stunden';

  @override
  String get chartCaption => 'Flugwahrscheinlichkeit je Stunde';

  @override
  String get nowTick => 'Jetzt';

  @override
  String get upcomingWeek => 'Kommende Woche';

  @override
  String get bandNoFly => 'Kein Flug';

  @override
  String get bandQuiet => 'Ruhig';

  @override
  String get bandWatchful => 'Wachsam';

  @override
  String get bandPromising => 'Vielversprechend';

  @override
  String get bandPrime => 'Erstklassig';

  @override
  String get headlineNoFly => 'Heute keine Flüge';

  @override
  String get headlineQuiet => 'Ruhiger Tag';

  @override
  String get headlineWatchful => 'Augen offen halten';

  @override
  String get headlinePromising => 'Vielversprechender Tag';

  @override
  String get headlinePrime => 'Erstklassige Bedingungen';

  @override
  String get actionNoFly => 'Bei diesem Wetter bleiben Ameisen im Nest';

  @override
  String get actionQuiet => 'Keinen Extraweg wert';

  @override
  String get actionWatchful => 'Draußen die Augen offen halten';

  @override
  String get actionPromising => 'Zum besten Zeitfenster einen Blick wert';

  @override
  String get actionPrime => 'Raus mit dir - solche Bedingungen sind selten';

  @override
  String oneInN(int n) {
    return '1 von $n';
  }

  @override
  String get daysLikeThisSeeFlights => 'Tagen wie diesem\nmit Flügen';

  @override
  String bestWindow(String start, String end) {
    return 'Bestes Zeitfenster $start–$end';
  }

  @override
  String likelySizeSpecies(String size) {
    return 'Wahrscheinlich $size Art';
  }

  @override
  String get sizeSmall => 'kleine';

  @override
  String get sizeMedium => 'mittlere';

  @override
  String get sizeLarge => 'große';

  @override
  String get whyShort => 'Warum?';

  @override
  String get whyTitle => 'Warum diese Vorhersage?';

  @override
  String get whyExplainer =>
      'Jede Kurve zeigt, was das Modell über eine Bedingung gelernt hat. Der Punkt markiert das Jetzt — hoch auf der Kurve heißt, diese Bedingung hilft der heutigen Vorhersage.';

  @override
  String get whyFooter =>
      'Die Kurven sind die marginale Antwort des trainierten Modells, keine festen Regeln — sie ändern sich, wenn das Modell mit neuen Meldungen neu trainiert wird.';

  @override
  String get tagHelps => 'Hilft heute';

  @override
  String get tagSlightlyHelps => 'Hilft etwas';

  @override
  String get tagNeutral => 'Kein starker Effekt';

  @override
  String get tagHurtsALittle => 'Schadet etwas';

  @override
  String get tagHurts => 'Schadet heute';

  @override
  String get featTemperature => 'Temperatur';

  @override
  String get featTemperatureNote => 'Wärme ist das stärkste Signal des Modells';

  @override
  String get featWind => 'Wind';

  @override
  String get featWindNote =>
      'Windstille ist ideal; starker Wind hält Königinnen am Boden';

  @override
  String get featHumidity => 'Luftfeuchte';

  @override
  String get featHumidityNote => 'Feuchte Luft nach Regen hilft meist';

  @override
  String get featCloud => 'Bewölkung';

  @override
  String get featCloudNote => 'Die gelernte Antwort des Modells auf Bewölkung';

  @override
  String get featRain => 'Regenrisiko';

  @override
  String get featRainNote => 'Heutige Niederschlagswahrscheinlichkeit';

  @override
  String get featPressure => 'Luftdruck';

  @override
  String get featPressureNote =>
      'Der Luftdruck ändert die Vorhersage selten stark';

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
    return 'Feuchte $value%';
  }

  @override
  String driverCloud(String value) {
    return 'Wolken $value%';
  }

  @override
  String driverRain(String value) {
    return 'Regen $value%';
  }

  @override
  String get driverPressure => 'Druck';

  @override
  String condWind(String value) {
    return '$value Wind';
  }

  @override
  String condHumidity(String value) {
    return '$value% Luftfeuchte';
  }

  @override
  String condDewPoint(String value) {
    return 'Taupunkt $value';
  }

  @override
  String honestyBand(String band, int percentile) {
    return 'Ameisenflug-Index: $band - heute ist besser als $percentile% der Tage auf Ihrem Breitengrad in diesem Monat.';
  }

  @override
  String honestyOdds(int n) {
    return 'Etwa an 1 von $n Tagen wie diesem wird ein Flug gemeldet.';
  }

  @override
  String honestyScore(String score) {
    return 'Roher Modellwert: $score (Anteil des Waldes, der für \"Flug\" stimmt - keine Wahrscheinlichkeit).';
  }

  @override
  String get sizeSeasonTitle => 'Welche Größe hat Saison?';

  @override
  String get sizeSeasonExplainer =>
      'Verschiedene Königinnengrößen haben ihren Höhepunkt in verschiedenen Monaten. Relativ zur heutigen Gesamteinschätzung:';

  @override
  String get sizeRowSmall => 'Klein (~10 mm)';

  @override
  String get sizeRowMedium => 'Mittel (~20 mm)';

  @override
  String get sizeRowLarge => 'Groß (~30 mm)';

  @override
  String get reportFlightButton => 'Flug melden';

  @override
  String get reportTitle => 'Hochzeitsflug melden';

  @override
  String get reportBlurb =>
      'Geflügelte Königinnen in Ihrer Nähe gesehen? Wählen Sie die passendste Größe. Echte Sichtungen trainieren die Vorhersage für alle.';

  @override
  String get reportSmall => 'Klein';

  @override
  String get reportMedium => 'Mittel';

  @override
  String get reportLarge => 'Groß';

  @override
  String get reportAbout10mm => 'etwa 10 mm';

  @override
  String get reportAbout20mm => 'etwa 20 mm';

  @override
  String get reportAbout30mm => 'etwa 30 mm';

  @override
  String reportingFrom(String location) {
    return 'Meldung von Ihrem aktuellen Standort · $location';
  }

  @override
  String get submitSighting => 'Sichtung senden';

  @override
  String get noFlightsButton => 'Nachgesehen — keine Flüge';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get snackFixedLocation =>
      'Meldungen müssen von Ihrem echten, aktuellen Standort kommen.';

  @override
  String get snackDebugMode => 'Melden ist in Debug-Builds deaktiviert.';

  @override
  String get snackThanksNoFlight =>
      'Danke — auch Meldungen ohne Flug verbessern das Modell.';

  @override
  String get snackThanksSighting =>
      'Danke! Ihre Sichtung hilft, die Vorhersage zu trainieren.';

  @override
  String snackNearbyFlights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n Flüge in den letzten 24 h im Umkreis von 500 km gemeldet — zur Karte!',
      one:
          '1 Flug in den letzten 24 h im Umkreis von 500 km gemeldet — zur Karte!',
    );
    return '$_temp0';
  }

  @override
  String get notifReportTitle => 'Hochzeitsflug in Ihrer Nähe gemeldet!';

  @override
  String notifReportBody(int n, int minutes, int distance) {
    return '$n gemeldete Flüge in den letzten $minutes Minuten, der nächste $distance km entfernt...';
  }

  @override
  String get notifPrimeTitle => 'Erstklassige Bedingungen für Hochzeitsflüge!';

  @override
  String notifPrimeBody(int n) {
    return 'Ein seltener Tag für Ihre Saison - etwa an 1 von $n Tagen wie diesem werden Flüge gemeldet.';
  }
}
