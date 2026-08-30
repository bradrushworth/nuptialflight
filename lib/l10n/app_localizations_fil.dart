// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get appTitle => 'Tagahula ng Nuptial Flight ng mga Langgam';

  @override
  String get locating => 'Hinahanap ang lokasyon…';

  @override
  String get unknownLocation => 'Hindi kilalang lokasyon';

  @override
  String get fetchingWeather => 'Kinukuha ang lokal na panahon…';

  @override
  String get tryAgain => 'Subukan muli';

  @override
  String get chooseALocation => 'Pumili ng lokasyon';

  @override
  String get unexpectedError =>
      'May hindi inaasahang error. I-report sa bitbot@bitbot.com.au ';

  @override
  String get locationFailedError =>
      'Hindi makuha ang iyong lokasyon!\n\nPaki-type na lang ito nang manu-mano.';

  @override
  String get locationDeniedError =>
      'Tinanggihan ang pahintulot sa lokasyon!\n\nPaki-type ang lokasyon nang manu-mano.';

  @override
  String get menuReportIssue => 'Mag-ulat ng Problema';

  @override
  String get menuWebApp => 'Web App';

  @override
  String get menuAndroid => 'Android';

  @override
  String get menuIos => 'iOS';

  @override
  String get menuSourceCode => 'Source Code';

  @override
  String get menuCoffee => 'Ilibre si Brad ng Kape';

  @override
  String get menuUseMetric => 'Gamitin ang °C · m/s';

  @override
  String get menuUseImperial => 'Gamitin ang °F · mph';

  @override
  String get tooltipShowMap => 'Ipakita ang mapa';

  @override
  String get tooltipMoreOptions => 'Iba pang opsyon';

  @override
  String get tooltipReportFlight => 'I-report ang nakitang nuptial flight';

  @override
  String todayDate(String date) {
    return 'Ngayon · $date';
  }

  @override
  String get next24Hours => 'Susunod na 24 oras';

  @override
  String get chartCaption => 'kumpiyansa ng paglipad kada oras';

  @override
  String get nowTick => 'Ngayon';

  @override
  String get upcomingWeek => 'Susunod na linggo';

  @override
  String get bandNoFly => 'Walang lipad';

  @override
  String get bandQuiet => 'Tahimik';

  @override
  String get bandWatchful => 'Katamtaman';

  @override
  String get bandPromising => 'Promising';

  @override
  String get bandPrime => 'Prime';

  @override
  String get headlineNoFly => 'Walang lipad ngayon';

  @override
  String get headlineQuiet => 'Tahimik na araw';

  @override
  String get headlineWatchful => 'Bahagyang mas mataas sa karaniwan';

  @override
  String get headlinePromising => 'Promising na araw';

  @override
  String get headlinePrime => 'Prime na kondisyon';

  @override
  String get actionNoFly =>
      'Sa ganitong panahon, nasa pugad lang ang mga langgam';

  @override
  String get actionQuiet => 'Hindi sulit ang espesyal na labas';

  @override
  String get actionWatchful => 'Magmasid kung nasa labas ka';

  @override
  String get actionPromising => 'Sulit tingnan sa pinakamagandang oras';

  @override
  String get actionPrime => 'Lumabas ka na - bihira ang ganitong kondisyon';

  @override
  String oneInN(int n) {
    return '1 sa $n';
  }

  @override
  String get daysLikeThisSeeFlights => 'araw na ganito\nmay lipad';

  @override
  String bestWindow(String start, String end) {
    return 'Pinakamagandang oras $start–$end';
  }

  @override
  String likelySizeSpecies(String size) {
    return 'Malamang $size na species';
  }

  @override
  String get sizeSmall => 'maliit';

  @override
  String get sizeMedium => 'katamtaman';

  @override
  String get sizeLarge => 'malaki';

  @override
  String get whyShort => 'Bakit?';

  @override
  String get whyTitle => 'Bakit ganito ang hula?';

  @override
  String get whyExplainer =>
      'Ipinapakita ng bawat curve ang natutunan ng model sa isang kondisyon. Ang tuldok ang kasalukuyan — kapag mataas sa curve, tumutulong ang kondisyong iyon sa hula ngayon.';

  @override
  String get whyFooter =>
      'Ang mga curve ay marginal na tugon ng trained model, hindi pirmihang panuntunan — nagbabago ito kapag ni-retrain ang model sa mga bagong ulat.';

  @override
  String get tagHelps => 'Nakakatulong ngayon';

  @override
  String get tagSlightlyHelps => 'Bahagyang nakakatulong';

  @override
  String get tagNeutral => 'Walang malinaw na epekto';

  @override
  String get tagHurtsALittle => 'Bahagyang nakakasama';

  @override
  String get tagHurts => 'Nakakasama ngayon';

  @override
  String get featTemperature => 'Temperatura';

  @override
  String get featTemperatureNote =>
      'Ang init ang pinakamalakas na senyales ng model';

  @override
  String get featWind => 'Hangin';

  @override
  String get featWindNote =>
      'Pinakamainam ang kalmadong hangin; pinipigilan ng malakas na hangin ang mga reyna';

  @override
  String get featHumidity => 'Halumigmig';

  @override
  String get featHumidityNote =>
      'Karaniwang nakakatulong ang mahalumigmig na hangin pagkatapos ng ulan';

  @override
  String get featCloud => 'Ulap';

  @override
  String get featCloudNote => 'Ang natutunang tugon ng model sa ulap';

  @override
  String get featRain => 'Tsansa ng ulan';

  @override
  String get featRainNote => 'Posibilidad ng ulan ngayon';

  @override
  String get featPressure => 'Presyon ng hangin';

  @override
  String get featPressureNote => 'Bihirang malaki ang epekto ng presyon';

  @override
  String driverTemp(String value) {
    return 'Temp $value';
  }

  @override
  String driverWind(String value) {
    return 'Hangin $value';
  }

  @override
  String driverHumidity(String value) {
    return 'Halumigmig $value%';
  }

  @override
  String driverCloud(String value) {
    return 'Ulap $value%';
  }

  @override
  String driverRain(String value) {
    return 'Ulan $value%';
  }

  @override
  String get driverPressure => 'Presyon';

  @override
  String condWind(String value) {
    return 'hangin $value';
  }

  @override
  String condHumidity(String value) {
    return '$value% halumigmig';
  }

  @override
  String condDewPoint(String value) {
    return 'Dew point $value';
  }

  @override
  String honestyBand(String band, int percentile) {
    return 'Ant Flight Index: $band - mas maganda ang araw na ito kaysa $percentile% ng mga araw sa inyong latitude ngayong buwan.';
  }

  @override
  String honestyOdds(int n) {
    return 'Humigit-kumulang 1 sa $n araw na ganito ang may naiulat na lipad.';
  }

  @override
  String honestyScore(String score) {
    return 'Raw na score ng model: $score (bahagi ng forest na bumoto ng \"lipad\" - hindi ito probabilidad).';
  }

  @override
  String get sizeSeasonTitle => 'Aling laki ang nasa season?';

  @override
  String get sizeSeasonExplainer =>
      'Iba-ibang buwan ang rurok ng iba\'t ibang laki ng reyna. Kaugnay ng kabuuang kumpiyansa ngayon:';

  @override
  String get sizeRowSmall => 'Maliit (~10 mm)';

  @override
  String get sizeRowMedium => 'Katamtaman (~20 mm)';

  @override
  String get sizeRowLarge => 'Malaki (~30 mm)';

  @override
  String get reportFlightButton => 'I-report';

  @override
  String get reportTitle => 'Mag-ulat ng nuptial flight';

  @override
  String get reportBlurb =>
      'Nakakita ng mga may pakpak na reyna malapit sa iyo? Piliin ang pinakamalapit na laki. Ang totoong ulat ay nagpapahusay ng hula para sa lahat.';

  @override
  String get reportSmall => 'Maliit';

  @override
  String get reportMedium => 'Katamtaman';

  @override
  String get reportLarge => 'Malaki';

  @override
  String get reportAbout10mm => 'mga 10 mm';

  @override
  String get reportAbout20mm => 'mga 20 mm';

  @override
  String get reportAbout30mm => 'mga 30 mm';

  @override
  String reportingFrom(String location) {
    return 'Nag-uulat mula sa kasalukuyang lokasyon · $location';
  }

  @override
  String get submitSighting => 'Ipasa ang ulat';

  @override
  String get noFlightsButton => 'Tumingin ako — walang lipad';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get snackFixedLocation =>
      'Ang mga ulat ay dapat mula sa iyong totoo at kasalukuyang lokasyon.';

  @override
  String get snackDebugMode => 'Naka-disable ang pag-uulat sa mga debug build.';

  @override
  String get snackThanksNoFlight =>
      'Salamat — nakakatulong din sa model ang mga ulat na walang lipad.';

  @override
  String get snackThanksSighting =>
      'Salamat! Nakakatulong ang iyong ulat sa pagsasanay ng hula.';

  @override
  String snackNearbyFlights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n lipad ang naiulat sa loob ng 500 km sa nakaraang 24 oras — tingnan ang mapa!',
      one:
          '1 lipad ang naiulat sa loob ng 500 km sa nakaraang 24 oras — tingnan ang mapa!',
    );
    return '$_temp0';
  }

  @override
  String get notifReportTitle =>
      'May naiulat na nuptial flight malapit sa iyo!';

  @override
  String notifReportBody(int n, int minutes, int distance) {
    return 'May $n lipad na naiulat sa nakaraang $minutes minuto, ang pinakamalapit ay $distance km ang layo...';
  }

  @override
  String get notifPrimeTitle => 'Prime na kondisyon para sa nuptial flights!';

  @override
  String notifPrimeBody(int n) {
    return 'Bihirang araw para sa inyong season - humigit-kumulang 1 sa $n araw na ganito ang may naiulat na lipad.';
  }
}
