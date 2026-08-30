// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Prognoza Lotów Godowych Mrówek';

  @override
  String get locating => 'Ustalanie lokalizacji…';

  @override
  String get unknownLocation => 'Nieznana lokalizacja';

  @override
  String get fetchingWeather => 'Pobieranie lokalnej pogody…';

  @override
  String get tryAgain => 'Spróbuj ponownie';

  @override
  String get chooseALocation => 'Wybierz lokalizację';

  @override
  String get unexpectedError =>
      'Wystąpił nieoczekiwany błąd. Zgłoś go na bitbot@bitbot.com.au ';

  @override
  String get locationFailedError =>
      'Nie udało się ustalić lokalizacji!\n\nWprowadź ją ręcznie.';

  @override
  String get locationDeniedError =>
      'Odmówiono uprawnień lokalizacji!\n\nWprowadź lokalizację ręcznie.';

  @override
  String get menuReportIssue => 'Zgłoś problem';

  @override
  String get menuWebApp => 'Aplikacja webowa';

  @override
  String get menuAndroid => 'Android';

  @override
  String get menuIos => 'iOS';

  @override
  String get menuSourceCode => 'Kod źródłowy';

  @override
  String get menuCoffee => 'Postaw Bradowi kawę';

  @override
  String get menuUseMetric => 'Używaj °C · m/s';

  @override
  String get menuUseImperial => 'Używaj °F · mph';

  @override
  String get tooltipShowMap => 'Pokaż mapę';

  @override
  String get tooltipMoreOptions => 'Więcej opcji';

  @override
  String get tooltipReportFlight => 'Zgłoś zaobserwowany lot godowy';

  @override
  String todayDate(String date) {
    return 'Dziś · $date';
  }

  @override
  String get next24Hours => 'Najbliższe 24 godziny';

  @override
  String get chartCaption => 'pewność lotu wg godzin';

  @override
  String get nowTick => 'Teraz';

  @override
  String get upcomingWeek => 'Nadchodzący tydzień';

  @override
  String get bandNoFly => 'Brak lotów';

  @override
  String get bandQuiet => 'Spokojnie';

  @override
  String get bandWatchful => 'Przeciętny';

  @override
  String get bandPromising => 'Obiecująco';

  @override
  String get bandPrime => 'Znakomicie';

  @override
  String get headlineNoFly => 'Dziś bez lotów';

  @override
  String get headlineQuiet => 'Spokojny dzień';

  @override
  String get headlineWatchful => 'Nieco lepiej niż przeciętnie';

  @override
  String get headlinePromising => 'Obiecujący dzień';

  @override
  String get headlinePrime => 'Znakomite warunki';

  @override
  String get actionNoFly => 'W taką pogodę mrówki zostają w gnieździe';

  @override
  String get actionQuiet => 'Nie warto specjalnie wychodzić';

  @override
  String get actionWatchful => 'Miej oczy otwarte, gdy jesteś na dworze';

  @override
  String get actionPromising => 'Warto zerknąć w najlepszym oknie';

  @override
  String get actionPrime => 'Wychodź - takie warunki są rzadkie';

  @override
  String oneInN(int n) {
    return '1 na $n';
  }

  @override
  String get daysLikeThisSeeFlights => 'takich dni\nz lotami';

  @override
  String bestWindow(String start, String end) {
    return 'Najlepsze okno $start–$end';
  }

  @override
  String likelySizeSpecies(String size) {
    return 'Prawdopodobnie $size gatunek';
  }

  @override
  String get sizeSmall => 'mały';

  @override
  String get sizeMedium => 'średni';

  @override
  String get sizeLarge => 'duży';

  @override
  String get whyShort => 'Dlaczego?';

  @override
  String get whyTitle => 'Skąd ta prognoza?';

  @override
  String get whyExplainer =>
      'Każda krzywa pokazuje, czego model nauczył się o danym warunku. Kropka oznacza teraz — wysoko na krzywej znaczy, że ten warunek pomaga dzisiejszej prognozie.';

  @override
  String get whyFooter =>
      'Krzywe to marginalna odpowiedź wytrenowanego modelu, nie sztywne reguły — zmieniają się przy ponownym treningu na nowych zgłoszeniach.';

  @override
  String get tagHelps => 'Dziś pomaga';

  @override
  String get tagSlightlyHelps => 'Trochę pomaga';

  @override
  String get tagNeutral => 'Bez wyraźnego wpływu';

  @override
  String get tagHurtsALittle => 'Trochę szkodzi';

  @override
  String get tagHurts => 'Dziś szkodzi';

  @override
  String get featTemperature => 'Temperatura';

  @override
  String get featTemperatureNote => 'Ciepło to najsilniejszy sygnał modelu';

  @override
  String get featWind => 'Wiatr';

  @override
  String get featWindNote =>
      'Bezwietrznie jest najlepiej; silny wiatr uziemia królowe';

  @override
  String get featHumidity => 'Wilgotność';

  @override
  String get featHumidityNote => 'Wilgotne powietrze po deszczu zwykle pomaga';

  @override
  String get featCloud => 'Zachmurzenie';

  @override
  String get featCloudNote => 'Wyuczona odpowiedź modelu na zachmurzenie';

  @override
  String get featRain => 'Szansa deszczu';

  @override
  String get featRainNote => 'Dzisiejsze prawdopodobieństwo opadów';

  @override
  String get featPressure => 'Ciśnienie';

  @override
  String get featPressureNote => 'Ciśnienie rzadko mocno zmienia prognozę';

  @override
  String driverTemp(String value) {
    return 'Temp. $value';
  }

  @override
  String driverWind(String value) {
    return 'Wiatr $value';
  }

  @override
  String driverHumidity(String value) {
    return 'Wilg. $value%';
  }

  @override
  String driverCloud(String value) {
    return 'Chmury $value%';
  }

  @override
  String driverRain(String value) {
    return 'Deszcz $value%';
  }

  @override
  String get driverPressure => 'Ciśnienie';

  @override
  String condWind(String value) {
    return 'wiatr $value';
  }

  @override
  String condHumidity(String value) {
    return '$value% wilgotności';
  }

  @override
  String condDewPoint(String value) {
    return 'Punkt rosy $value';
  }

  @override
  String honestyBand(String band, int percentile) {
    return 'Indeks Lotów Mrówek: $band - dziś jest lepiej niż w $percentile% dni na tej szerokości w tym miesiącu.';
  }

  @override
  String honestyOdds(int n) {
    return 'Mniej więcej w 1 na $n takich dni użytkownicy zgłaszają lot.';
  }

  @override
  String honestyScore(String score) {
    return 'Surowy wynik modelu: $score (odsetek lasu głosującego za \"lotem\" - to nie prawdopodobieństwo).';
  }

  @override
  String get sizeSeasonTitle => 'Który rozmiar ma sezon?';

  @override
  String get sizeSeasonExplainer =>
      'Różne rozmiary królowych szczytują w różnych miesiącach. Względem dzisiejszej ogólnej pewności:';

  @override
  String get sizeRowSmall => 'Małe (~10 mm)';

  @override
  String get sizeRowMedium => 'Średnie (~20 mm)';

  @override
  String get sizeRowLarge => 'Duże (~30 mm)';

  @override
  String get reportFlightButton => 'Zgłoś lot';

  @override
  String get reportTitle => 'Zgłoś lot godowy';

  @override
  String get reportBlurb =>
      'Widzisz uskrzydlone królowe w pobliżu? Wybierz najbliższy rozmiar. Prawdziwe obserwacje trenują prognozę dla wszystkich.';

  @override
  String get reportSmall => 'Małe';

  @override
  String get reportMedium => 'Średnie';

  @override
  String get reportLarge => 'Duże';

  @override
  String get reportAbout10mm => 'około 10 mm';

  @override
  String get reportAbout20mm => 'około 20 mm';

  @override
  String get reportAbout30mm => 'około 30 mm';

  @override
  String reportingFrom(String location) {
    return 'Zgłoszenie z bieżącej lokalizacji · $location';
  }

  @override
  String get submitSighting => 'Wyślij obserwację';

  @override
  String get noFlightsButton => 'Sprawdziłem — brak lotów';

  @override
  String get cancel => 'Anuluj';

  @override
  String get snackFixedLocation =>
      'Zgłoszenia muszą pochodzić z Twojej rzeczywistej, bieżącej lokalizacji.';

  @override
  String get snackDebugMode =>
      'Zgłaszanie jest wyłączone w kompilacjach debug.';

  @override
  String get snackThanksNoFlight =>
      'Dzięki — zgłoszenia braku lotów też ulepszają model.';

  @override
  String get snackThanksSighting =>
      'Dziękujemy! Twoja obserwacja pomaga trenować prognozę.';

  @override
  String snackNearbyFlights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n lotów zgłoszonych w promieniu 500 km w ciągu 24 h — zobacz mapę!',
      few: '$n loty zgłoszone w promieniu 500 km w ciągu 24 h — zobacz mapę!',
      one: '1 lot zgłoszony w promieniu 500 km w ciągu 24 h — zobacz mapę!',
    );
    return '$_temp0';
  }

  @override
  String get notifReportTitle => 'Zgłoszono lot godowy w pobliżu!';

  @override
  String notifReportBody(int n, int minutes, int distance) {
    return '$n zgłoszonych lotów w ciągu ostatnich $minutes minut, najbliższy $distance km stąd...';
  }

  @override
  String get notifPrimeTitle => 'Znakomite warunki na loty godowe!';

  @override
  String notifPrimeBody(int n) {
    return 'Rzadki dzień w Twoim sezonie - loty zgłaszane są mniej więcej w 1 na $n takich dni.';
  }
}
