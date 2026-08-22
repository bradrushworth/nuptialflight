// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Mieren Bruidsvlucht Voorspeller';

  @override
  String get locating => 'Locatie bepalen…';

  @override
  String get unknownLocation => 'Onbekende locatie';

  @override
  String get fetchingWeather => 'Lokaal weer ophalen…';

  @override
  String get tryAgain => 'Opnieuw proberen';

  @override
  String get chooseALocation => 'Kies een locatie';

  @override
  String get unexpectedError =>
      'Onverwachte fout. Meld dit aan bitbot@bitbot.com.au ';

  @override
  String get locationFailedError =>
      'Kon je locatie niet bepalen!\n\nVoer je locatie handmatig in.';

  @override
  String get locationDeniedError =>
      'Locatietoestemming geweigerd!\n\nVoer je locatie handmatig in.';

  @override
  String get menuReportIssue => 'Probleem melden';

  @override
  String get menuWebApp => 'Webapp';

  @override
  String get menuAndroid => 'Android';

  @override
  String get menuIos => 'iOS';

  @override
  String get menuSourceCode => 'Broncode';

  @override
  String get menuCoffee => 'Trakteer Brad op koffie';

  @override
  String get menuUseMetric => 'Gebruik °C · m/s';

  @override
  String get menuUseImperial => 'Gebruik °F · mph';

  @override
  String get tooltipShowMap => 'Kaart tonen';

  @override
  String get tooltipMoreOptions => 'Meer opties';

  @override
  String get tooltipReportFlight => 'Meld een geziene bruidsvlucht';

  @override
  String todayDate(String date) {
    return 'Vandaag · $date';
  }

  @override
  String get next24Hours => 'Komende 24 uur';

  @override
  String get chartCaption => 'vluchtvertrouwen per uur';

  @override
  String get nowTick => 'Nu';

  @override
  String get upcomingWeek => 'Komende week';

  @override
  String get bandNoFly => 'Geen vlucht';

  @override
  String get bandQuiet => 'Rustig';

  @override
  String get bandWatchful => 'Opletten';

  @override
  String get bandPromising => 'Veelbelovend';

  @override
  String get bandPrime => 'Uitstekend';

  @override
  String get headlineNoFly => 'Vandaag geen vluchten';

  @override
  String get headlineQuiet => 'Rustige dag';

  @override
  String get headlineWatchful => 'Het volgen waard';

  @override
  String get headlinePromising => 'Veelbelovende dag';

  @override
  String get headlinePrime => 'Uitstekende omstandigheden';

  @override
  String get actionNoFly => 'Met dit weer blijven mieren thuis';

  @override
  String get actionQuiet => 'Geen aparte tocht waard';

  @override
  String get actionWatchful => 'Houd je ogen open als je buiten bent';

  @override
  String get actionPromising => 'Een kijkje waard op het beste moment';

  @override
  String get actionPrime => 'Ga naar buiten - dit is zeldzaam';

  @override
  String oneInN(int n) {
    return '1 op $n';
  }

  @override
  String get daysLikeThisSeeFlights => 'dagen zoals deze\nzien vluchten';

  @override
  String bestWindow(String start, String end) {
    return 'Beste venster $start–$end';
  }

  @override
  String likelySizeSpecies(String size) {
    return 'Waarschijnlijk $size soort';
  }

  @override
  String get sizeSmall => 'kleine';

  @override
  String get sizeMedium => 'middelgrote';

  @override
  String get sizeLarge => 'grote';

  @override
  String get whyShort => 'Waarom?';

  @override
  String get whyTitle => 'Waarom deze voorspelling?';

  @override
  String get whyExplainer =>
      'Elke curve toont wat het model over één conditie leerde. De stip markeert nu — hoog op de curve betekent dat die conditie de voorspelling van vandaag helpt.';

  @override
  String get whyFooter =>
      'De curves zijn de marginale respons van het getrainde model, geen vaste regels — ze veranderen wanneer het model opnieuw wordt getraind met nieuwe meldingen.';

  @override
  String get tagHelps => 'Helpt vandaag';

  @override
  String get tagSlightlyHelps => 'Helpt een beetje';

  @override
  String get tagNeutral => 'Geen duidelijk effect';

  @override
  String get tagHurtsALittle => 'Hindert een beetje';

  @override
  String get tagHurts => 'Hindert vandaag';

  @override
  String get featTemperature => 'Temperatuur';

  @override
  String get featTemperatureNote =>
      'Warmte is het sterkste signaal van het model';

  @override
  String get featWind => 'Wind';

  @override
  String get featWindNote =>
      'Windstil is ideaal; harde wind houdt koninginnen aan de grond';

  @override
  String get featHumidity => 'Luchtvochtigheid';

  @override
  String get featHumidityNote => 'Vochtige lucht na regen helpt meestal';

  @override
  String get featCloud => 'Bewolking';

  @override
  String get featCloudNote => 'De geleerde respons van het model op bewolking';

  @override
  String get featRain => 'Regenkans';

  @override
  String get featRainNote => 'De neerslagkans van vandaag';

  @override
  String get featPressure => 'Luchtdruk';

  @override
  String get featPressureNote =>
      'Luchtdruk verandert de voorspelling zelden veel';

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
    return 'Vocht $value%';
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
  String get driverPressure => 'Druk';

  @override
  String condWind(String value) {
    return '$value wind';
  }

  @override
  String condHumidity(String value) {
    return '$value% luchtvochtigheid';
  }

  @override
  String condDewPoint(String value) {
    return 'Dauwpunt $value';
  }

  @override
  String honestyBand(String band, int percentile) {
    return 'Mierenvlucht-index: $band - vandaag is beter dan $percentile% van de dagen op jouw breedtegraad deze maand.';
  }

  @override
  String honestyOdds(int n) {
    return 'Ongeveer 1 op $n dagen zoals deze krijgt een gemelde vlucht.';
  }

  @override
  String honestyScore(String score) {
    return 'Ruwe modelscore: $score (aandeel van het bos dat \"vlucht\" stemt - geen kans).';
  }

  @override
  String get sizeSeasonTitle => 'Welke maat is in het seizoen?';

  @override
  String get sizeSeasonExplainer =>
      'Verschillende koninginnenmaten pieken in verschillende maanden. Ten opzichte van het totaalvertrouwen van vandaag:';

  @override
  String get sizeRowSmall => 'Klein (~10 mm)';

  @override
  String get sizeRowMedium => 'Middel (~20 mm)';

  @override
  String get sizeRowLarge => 'Groot (~30 mm)';

  @override
  String get reportFlightButton => 'Vlucht melden';

  @override
  String get reportTitle => 'Bruidsvlucht melden';

  @override
  String get reportBlurb =>
      'Gevleugelde koninginnen in de buurt gezien? Kies de dichtstbijzijnde maat. Echte waarnemingen trainen de voorspelling voor iedereen.';

  @override
  String get reportSmall => 'Klein';

  @override
  String get reportMedium => 'Middel';

  @override
  String get reportLarge => 'Groot';

  @override
  String get reportAbout10mm => 'ongeveer 10 mm';

  @override
  String get reportAbout20mm => 'ongeveer 20 mm';

  @override
  String get reportAbout30mm => 'ongeveer 30 mm';

  @override
  String reportingFrom(String location) {
    return 'Melding vanaf je huidige locatie · $location';
  }

  @override
  String get submitSighting => 'Waarneming versturen';

  @override
  String get noFlightsButton => 'Gekeken — geen vluchten';

  @override
  String get cancel => 'Annuleren';

  @override
  String get snackFixedLocation =>
      'Meldingen moeten van je echte, huidige locatie komen.';

  @override
  String get snackDebugMode => 'Melden is uitgeschakeld in debug-builds.';

  @override
  String get snackThanksNoFlight =>
      'Bedankt — meldingen zonder vlucht verbeteren het model ook.';

  @override
  String get snackThanksSighting =>
      'Bedankt! Je waarneming helpt de voorspelling te trainen.';

  @override
  String snackNearbyFlights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n vluchten gemeld binnen 500 km in de laatste 24 u — bekijk de kaart!',
      one:
          '1 vlucht gemeld binnen 500 km in de laatste 24 u — bekijk de kaart!',
    );
    return '$_temp0';
  }

  @override
  String get notifReportTitle => 'Bruidsvlucht in de buurt gemeld!';

  @override
  String notifReportBody(int n, int minutes, int distance) {
    return 'Er zijn $n vluchten gemeld in de laatste $minutes minuten, de dichtstbijzijnde op $distance km...';
  }

  @override
  String get notifPrimeTitle =>
      'Uitstekende omstandigheden voor bruidsvluchten!';

  @override
  String notifPrimeBody(int n) {
    return 'Een zeldzame dag voor jouw seizoen - ongeveer 1 op $n dagen zoals deze ziet gemelde vluchten.';
  }
}
