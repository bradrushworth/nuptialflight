// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Karınca Çiftleşme Uçuşu Tahmini';

  @override
  String get locating => 'Konum bulunuyor…';

  @override
  String get unknownLocation => 'Bilinmeyen Konum';

  @override
  String get fetchingWeather => 'Bölgenizin hava durumu alınıyor…';

  @override
  String get tryAgain => 'Tekrar dene';

  @override
  String get chooseALocation => 'Konum seç';

  @override
  String get unexpectedError =>
      'Beklenmeyen bir hata oluştu. Lütfen bitbot@bitbot.com.au adresine bildirin ';

  @override
  String get locationFailedError =>
      'Konumunuz alınamadı!\n\nLütfen konumunuzu elle girin.';

  @override
  String get locationDeniedError =>
      'Konum izni reddedildi!\n\nLütfen konumunuzu elle girin.';

  @override
  String get menuReportIssue => 'Sorun Bildir';

  @override
  String get menuWebApp => 'Web Uygulaması';

  @override
  String get menuAndroid => 'Android';

  @override
  String get menuIos => 'iOS';

  @override
  String get menuSourceCode => 'Kaynak Kodu';

  @override
  String get menuCoffee => 'Brad\'e Kahve Ismarla';

  @override
  String get menuUseMetric => '°C · m/sn kullan';

  @override
  String get menuUseImperial => '°F · mph kullan';

  @override
  String get tooltipShowMap => 'Haritayı göster';

  @override
  String get tooltipMoreOptions => 'Diğer seçenekler';

  @override
  String get tooltipReportFlight => 'Gördüğünüz çiftleşme uçuşunu bildirin';

  @override
  String todayDate(String date) {
    return 'Bugün · $date';
  }

  @override
  String get next24Hours => 'Önümüzdeki 24 saat';

  @override
  String get chartCaption => 'saatlik uçuş güveni';

  @override
  String get nowTick => 'Şimdi';

  @override
  String get upcomingWeek => 'Önümüzdeki hafta';

  @override
  String get bandNoFly => 'Uçuş yok';

  @override
  String get bandQuiet => 'Sakin';

  @override
  String get bandWatchful => 'Orta';

  @override
  String get bandPromising => 'Umut verici';

  @override
  String get bandPrime => 'Mükemmel';

  @override
  String get headlineNoFly => 'Bugün uçuş yok';

  @override
  String get headlineQuiet => 'Sakin bir gün';

  @override
  String get headlineWatchful => 'Ortalamanın biraz üzerinde';

  @override
  String get headlinePromising => 'Umut verici bir gün';

  @override
  String get headlinePrime => 'Mükemmel koşullar';

  @override
  String get actionNoFly => 'Bu havada karıncalar yuvada kalır';

  @override
  String get actionQuiet => 'Özel bir geziye değmez';

  @override
  String get actionWatchful => 'Dışarıdaysanız gözünüz açık olsun';

  @override
  String get actionPromising => 'En iyi saatlerde bakmaya değer';

  @override
  String get actionPrime => 'Dışarı çıkın - böyle koşullar nadirdir';

  @override
  String oneInN(int n) {
    return '$n günde 1';
  }

  @override
  String get daysLikeThisSeeFlights => 'böyle günlerde\nuçuş görülür';

  @override
  String bestWindow(String start, String end) {
    return 'En iyi aralık $start–$end';
  }

  @override
  String likelySizeSpecies(String size) {
    return 'Muhtemelen $size tür';
  }

  @override
  String get sizeSmall => 'küçük';

  @override
  String get sizeMedium => 'orta';

  @override
  String get sizeLarge => 'büyük';

  @override
  String get whyShort => 'Neden?';

  @override
  String get whyTitle => 'Bu tahmin neden?';

  @override
  String get whyExplainer =>
      'Her eğri, modelin bir koşul hakkında öğrendiklerini gösterir. Nokta o günün değerini işaretler — eğrinin yükseğinde olması o koşulun tahmine yardım ettiği anlamına gelir.';

  @override
  String get whyFooter =>
      'Eğriler eğitilmiş modelin marjinal tepkisidir, sabit kurallar değildir — model yeni gözlem raporlarıyla yeniden eğitildiğinde güncellenir.';

  @override
  String get tagHelps => 'Yardımcı';

  @override
  String get tagSlightlyHelps => 'Biraz yardımcı';

  @override
  String get tagNeutral => 'Belirgin etkisi yok';

  @override
  String get tagHurtsALittle => 'Biraz olumsuz';

  @override
  String get tagHurts => 'Olumsuz';

  @override
  String get featTemperature => 'Sıcaklık';

  @override
  String get featTemperatureNote => 'Sıcaklık modelin en güçlü sinyalidir';

  @override
  String get featWind => 'Rüzgar';

  @override
  String get featWindNote =>
      'Sakin hava en iyisidir; güçlü rüzgar kraliçeleri yere indirir';

  @override
  String get featHumidity => 'Nem';

  @override
  String get featHumidityNote =>
      'Yağmur sonrası nemli hava genellikle yardımcı olur';

  @override
  String get featCloud => 'Bulutluluk';

  @override
  String get featCloudNote => 'Modelin bulutluluğa öğrenilmiş tepkisi';

  @override
  String get featRain => 'Yağmur olasılığı';

  @override
  String get featRainNote => 'O günün yağış olasılığı';

  @override
  String get featPressure => 'Hava basıncı';

  @override
  String get featPressureNote => 'Basınç tahmini nadiren fazla etkiler';

  @override
  String driverTemp(String value) {
    return 'Sıcaklık $value';
  }

  @override
  String driverWind(String value) {
    return 'Rüzgar $value';
  }

  @override
  String driverHumidity(String value) {
    return 'Nem %$value';
  }

  @override
  String driverCloud(String value) {
    return 'Bulut %$value';
  }

  @override
  String driverRain(String value) {
    return 'Yağmur %$value';
  }

  @override
  String get driverPressure => 'Basınç';

  @override
  String condWind(String value) {
    return '$value rüzgar';
  }

  @override
  String condHumidity(String value) {
    return '%$value nem';
  }

  @override
  String condDewPoint(String value) {
    return 'Çiy noktası $value';
  }

  @override
  String honestyBand(String band, int percentile) {
    return 'Karınca Uçuş Endeksi: $band - bu ay enleminizdeki günlerin %$percentile\'inden daha iyi.';
  }

  @override
  String honestyOdds(int n) {
    return 'Böyle günlerin yaklaşık $n tanesinden 1\'inde kullanıcılar uçuş bildirir.';
  }

  @override
  String honestyScore(String score) {
    return 'Ham model puanı: $score (ormanın \"uçuş\" oyu veren payı - bir olasılık değildir).';
  }

  @override
  String get sizeSeasonTitle => 'Hangi boy mevsiminde?';

  @override
  String get sizeSeasonExplainer =>
      'Farklı kraliçe boyları farklı aylarda zirve yapar. O günün genel güvenine göre:';

  @override
  String get sizeRowSmall => 'Küçük (~10 mm)';

  @override
  String get sizeRowMedium => 'Orta (~20 mm)';

  @override
  String get sizeRowLarge => 'Büyük (~30 mm)';

  @override
  String get reportFlightButton => 'Uçuş bildir';

  @override
  String get reportTitle => 'Çiftleşme uçuşu bildir';

  @override
  String get reportBlurb =>
      'Yakınınızda kanatlı kraliçeler mi gördünüz? En yakın boyu seçin. Gerçek gözlemler tahmini herkes için eğitir.';

  @override
  String get reportSmall => 'Küçük';

  @override
  String get reportMedium => 'Orta';

  @override
  String get reportLarge => 'Büyük';

  @override
  String get reportAbout10mm => 'yaklaşık 10 mm';

  @override
  String get reportAbout20mm => 'yaklaşık 20 mm';

  @override
  String get reportAbout30mm => 'yaklaşık 30 mm';

  @override
  String reportingFrom(String location) {
    return 'Mevcut konumunuzdan bildiriliyor · $location';
  }

  @override
  String get submitSighting => 'Gözlemi gönder';

  @override
  String get noFlightsButton => 'Baktım — uçuş yok';

  @override
  String get cancel => 'İptal';

  @override
  String get snackFixedLocation =>
      'Bildirimler gerçek, mevcut konumunuzdan yapılmalıdır.';

  @override
  String get snackDebugMode =>
      'Hata ayıklama sürümlerinde bildirim devre dışıdır.';

  @override
  String get snackThanksNoFlight =>
      'Teşekkürler — uçuş yok bildirimleri de modeli geliştirir.';

  @override
  String get snackThanksSighting =>
      'Teşekkürler! Gözleminiz tahmini eğitmeye yardımcı oluyor.';

  @override
  String snackNearbyFlights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Son 24 saatte 500 km içinde $n uçuş bildirildi — haritaya bakın!',
      one: 'Son 24 saatte 500 km içinde 1 uçuş bildirildi — haritaya bakın!',
    );
    return '$_temp0';
  }

  @override
  String get notifReportTitle => 'Yakınınızda çiftleşme uçuşu bildirildi!';

  @override
  String notifReportBody(int n, int minutes, int distance) {
    return 'Son $minutes dakikada $n uçuş bildirildi; en yakını $distance km uzakta...';
  }

  @override
  String get notifPrimeTitle => 'Çiftleşme uçuşları için mükemmel koşullar!';

  @override
  String notifPrimeBody(int n) {
    return 'Mevsiminiz için nadir bir gün - böyle günlerin yaklaşık $n tanesinden 1\'inde uçuş bildirilir.';
  }
}
