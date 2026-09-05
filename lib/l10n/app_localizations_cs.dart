// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'Predikce svatebních letů mravenců';

  @override
  String get locating => 'Zjišťování polohy…';

  @override
  String get unknownLocation => 'Neznámá poloha';

  @override
  String get fetchingWeather => 'Načítání místního počasí…';

  @override
  String get tryAgain => 'Zkusit znovu';

  @override
  String get chooseALocation => 'Vybrat polohu';

  @override
  String get unexpectedError =>
      'Došlo k neočekávané chybě. Nahlaste ji na bitbot@bitbot.com.au ';

  @override
  String get locationFailedError =>
      'Nepodařilo se zjistit vaši polohu!\n\nZadejte ji prosím ručně.';

  @override
  String get locationDeniedError =>
      'Přístup k poloze byl odepřen!\n\nZadejte polohu ručně.';

  @override
  String get menuReportIssue => 'Nahlásit problém';

  @override
  String get menuWebApp => 'Webová aplikace';

  @override
  String get menuAndroid => 'Android';

  @override
  String get menuIos => 'iOS';

  @override
  String get menuSourceCode => 'Zdrojový kód';

  @override
  String get menuCoffee => 'Kup Bradovi kávu';

  @override
  String get menuUseMetric => 'Používat °C · m/s';

  @override
  String get menuUseImperial => 'Používat °F · mph';

  @override
  String get tooltipShowMap => 'Zobrazit mapu';

  @override
  String get tooltipMoreOptions => 'Další možnosti';

  @override
  String get tooltipReportFlight => 'Nahlásit pozorovaný svatební let';

  @override
  String todayDate(String date) {
    return 'Dnes · $date';
  }

  @override
  String get next24Hours => 'Příštích 24 hodin';

  @override
  String get chartCaption => 'důvěra v let po hodinách';

  @override
  String get nowTick => 'Teď';

  @override
  String get upcomingWeek => 'Nadcházející týden';

  @override
  String get bandNoFly => 'Bez letů';

  @override
  String get bandQuiet => 'Klid';

  @override
  String get bandWatchful => 'Průměrný';

  @override
  String get bandPromising => 'Nadějné';

  @override
  String get bandPrime => 'Vynikající';

  @override
  String get headlineNoFly => 'Dnes žádné lety';

  @override
  String get headlineQuiet => 'Klidný den';

  @override
  String get headlineWatchful => 'Mírně nad průměrem';

  @override
  String get headlinePromising => 'Nadějný den';

  @override
  String get headlinePrime => 'Vynikající podmínky';

  @override
  String get actionNoFly => 'V tomhle počasí mravenci zůstávají doma';

  @override
  String get actionQuiet => 'Nestojí za zvláštní cestu';

  @override
  String get actionWatchful => 'Venku mějte oči otevřené';

  @override
  String get actionPromising => 'V nejlepším okně stojí za pohled';

  @override
  String get actionPrime => 'Vyrazte ven - takové podmínky jsou vzácné';

  @override
  String oneInN(int n) {
    return '1 z $n';
  }

  @override
  String get daysLikeThisSeeFlights => 'takových dní\ns lety';

  @override
  String bestWindow(String start, String end) {
    return 'Nejlepší okno $start–$end';
  }

  @override
  String likelySizeSpecies(String size) {
    return 'Pravděpodobně $size druh';
  }

  @override
  String get sizeSmall => 'malý';

  @override
  String get sizeMedium => 'střední';

  @override
  String get sizeLarge => 'velký';

  @override
  String get whyShort => 'Proč?';

  @override
  String get whyTitle => 'Proč tato předpověď?';

  @override
  String get whyExplainer =>
      'Každá křivka ukazuje, co se model o dané podmínce naučil. Tečka označuje hodnotu daného dne — vysoko na křivce znamená, že podmínka předpovědi pomáhá.';

  @override
  String get whyFooter =>
      'Křivky jsou marginální odezva natrénovaného modelu, ne pevná pravidla — mění se při přetrénování na nových hlášeních.';

  @override
  String get tagHelps => 'Pomáhá';

  @override
  String get tagSlightlyHelps => 'Trochu pomáhá';

  @override
  String get tagNeutral => 'Bez výrazného vlivu';

  @override
  String get tagHurtsALittle => 'Trochu škodí';

  @override
  String get tagHurts => 'Škodí';

  @override
  String get featTemperature => 'Teplota';

  @override
  String get featTemperatureNote => 'Teplo je nejsilnější signál modelu';

  @override
  String get featWind => 'Vítr';

  @override
  String get featWindNote => 'Bezvětří je nejlepší; silný vítr královny uzemní';

  @override
  String get featHumidity => 'Vlhkost';

  @override
  String get featHumidityNote => 'Vlhký vzduch po dešti obvykle pomáhá';

  @override
  String get featCloud => 'Oblačnost';

  @override
  String get featCloudNote => 'Naučená odezva modelu na oblačnost';

  @override
  String get featRain => 'Šance deště';

  @override
  String get featRainNote => 'Pravděpodobnost srážek daného dne';

  @override
  String get featPressure => 'Tlak vzduchu';

  @override
  String get featPressureNote => 'Tlak předpověď mění jen zřídka';

  @override
  String driverTemp(String value) {
    return 'Teplota $value';
  }

  @override
  String driverWind(String value) {
    return 'Vítr $value';
  }

  @override
  String driverHumidity(String value) {
    return 'Vlhkost $value%';
  }

  @override
  String driverCloud(String value) {
    return 'Oblačnost $value%';
  }

  @override
  String driverRain(String value) {
    return 'Déšť $value%';
  }

  @override
  String get driverPressure => 'Tlak';

  @override
  String condWind(String value) {
    return 'vítr $value';
  }

  @override
  String condHumidity(String value) {
    return '$value% vlhkost';
  }

  @override
  String condDewPoint(String value) {
    return 'Rosný bod $value';
  }

  @override
  String honestyBand(String band, int percentile) {
    return 'Index letů mravenců: $band - lepší než $percentile% dní na vaší šířce v tomto měsíci.';
  }

  @override
  String honestyOdds(int n) {
    return 'Zhruba v 1 z $n takových dní uživatelé nahlásí let.';
  }

  @override
  String honestyScore(String score) {
    return 'Hrubé skóre modelu: $score (podíl lesa hlasujícího pro \"let\" - není to pravděpodobnost).';
  }

  @override
  String get sizeSeasonTitle => 'Která velikost má sezónu?';

  @override
  String get sizeSeasonExplainer =>
      'Různé velikosti královen vrcholí v různých měsících. Vzhledem k celkové důvěře pro tento den:';

  @override
  String get sizeRowSmall => 'Malé (~10 mm)';

  @override
  String get sizeRowMedium => 'Střední (~20 mm)';

  @override
  String get sizeRowLarge => 'Velké (~30 mm)';

  @override
  String get reportFlightButton => 'Nahlásit let';

  @override
  String get reportTitle => 'Nahlásit svatební let';

  @override
  String get reportBlurb =>
      'Viděli jste poblíž okřídlené královny? Vyberte nejbližší velikost. Skutečná pozorování trénují předpověď pro všechny.';

  @override
  String get reportSmall => 'Malé';

  @override
  String get reportMedium => 'Střední';

  @override
  String get reportLarge => 'Velké';

  @override
  String get reportAbout10mm => 'asi 10 mm';

  @override
  String get reportAbout20mm => 'asi 20 mm';

  @override
  String get reportAbout30mm => 'asi 30 mm';

  @override
  String reportingFrom(String location) {
    return 'Hlášení z aktuální polohy · $location';
  }

  @override
  String get submitSighting => 'Odeslat pozorování';

  @override
  String get noFlightsButton => 'Díval jsem se — žádné lety';

  @override
  String get cancel => 'Zrušit';

  @override
  String get snackFixedLocation =>
      'Hlášení musí pocházet z vaší skutečné aktuální polohy.';

  @override
  String get snackDebugMode => 'V ladicích sestaveních je hlášení vypnuto.';

  @override
  String get snackThanksNoFlight => 'Díky — i hlášení bez letu zlepšují model.';

  @override
  String get snackThanksSighting =>
      'Děkujeme! Vaše pozorování pomáhá trénovat předpověď.';

  @override
  String snackNearbyFlights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n letů nahlášeno do 500 km za posledních 24 h — mrkněte na mapu!',
      few: '$n lety nahlášeny do 500 km za posledních 24 h — mrkněte na mapu!',
      one: '1 let nahlášen do 500 km za posledních 24 h — mrkněte na mapu!',
    );
    return '$_temp0';
  }

  @override
  String get notifReportTitle => 'Poblíž nahlášen svatební let!';

  @override
  String notifReportBody(int n, int minutes, int distance) {
    return 'Za posledních $minutes minut bylo nahlášeno $n letů, nejbližší $distance km daleko...';
  }

  @override
  String get notifPrimeTitle => 'Vynikající podmínky pro svatební lety!';

  @override
  String notifPrimeBody(int n) {
    return 'Vzácný den vaší sezóny - lety se hlásí zhruba v 1 z $n takových dní.';
  }
}
