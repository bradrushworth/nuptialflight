// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appTitle => 'Peramal Penerbangan Kahwin Semut';

  @override
  String get locating => 'Mencari lokasi…';

  @override
  String get unknownLocation => 'Lokasi tidak diketahui';

  @override
  String get fetchingWeather => 'Mendapatkan cuaca setempat…';

  @override
  String get tryAgain => 'Cuba lagi';

  @override
  String get chooseALocation => 'Pilih lokasi';

  @override
  String get unexpectedError =>
      'Ralat tidak dijangka berlaku. Laporkan kepada bitbot@bitbot.com.au ';

  @override
  String get locationFailedError =>
      'Gagal mendapatkan lokasi anda!\n\nSila masukkan lokasi secara manual.';

  @override
  String get locationDeniedError =>
      'Kebenaran lokasi ditolak!\n\nSila masukkan lokasi secara manual.';

  @override
  String get menuReportIssue => 'Laporkan Masalah';

  @override
  String get menuWebApp => 'Aplikasi Web';

  @override
  String get menuAndroid => 'Android';

  @override
  String get menuIos => 'iOS';

  @override
  String get menuSourceCode => 'Kod Sumber';

  @override
  String get menuCoffee => 'Belanja Brad Kopi';

  @override
  String get menuUseMetric => 'Guna °C · m/s';

  @override
  String get menuUseImperial => 'Guna °F · mph';

  @override
  String get tooltipShowMap => 'Tunjukkan peta';

  @override
  String get tooltipMoreOptions => 'Pilihan lain';

  @override
  String get tooltipReportFlight =>
      'Laporkan penerbangan kahwin yang anda lihat';

  @override
  String todayDate(String date) {
    return 'Hari ini · $date';
  }

  @override
  String get next24Hours => '24 jam akan datang';

  @override
  String get chartCaption => 'keyakinan penerbangan mengikut jam';

  @override
  String get nowTick => 'Sekarang';

  @override
  String get upcomingWeek => 'Minggu akan datang';

  @override
  String get bandNoFly => 'Tiada penerbangan';

  @override
  String get bandQuiet => 'Tenang';

  @override
  String get bandWatchful => 'Berjaga-jaga';

  @override
  String get bandPromising => 'Menjanjikan';

  @override
  String get bandPrime => 'Terbaik';

  @override
  String get headlineNoFly => 'Tiada penerbangan hari ini';

  @override
  String get headlineQuiet => 'Hari yang tenang';

  @override
  String get headlineWatchful => 'Patut diperhatikan';

  @override
  String get headlinePromising => 'Hari yang menjanjikan';

  @override
  String get headlinePrime => 'Keadaan terbaik';

  @override
  String get actionNoFly => 'Dalam cuaca ini semut kekal di sarang';

  @override
  String get actionQuiet => 'Tidak berbaloi keluar khas';

  @override
  String get actionWatchful => 'Perhatikan jika anda di luar';

  @override
  String get actionPromising => 'Berbaloi melihat pada waktu terbaik';

  @override
  String get actionPrime => 'Keluarlah - keadaan begini jarang berlaku';

  @override
  String oneInN(int n) {
    return '1 daripada $n';
  }

  @override
  String get daysLikeThisSeeFlights => 'hari seperti ini\nada penerbangan';

  @override
  String bestWindow(String start, String end) {
    return 'Waktu terbaik $start–$end';
  }

  @override
  String likelySizeSpecies(String size) {
    return 'Kemungkinan spesies $size';
  }

  @override
  String get sizeSmall => 'kecil';

  @override
  String get sizeMedium => 'sederhana';

  @override
  String get sizeLarge => 'besar';

  @override
  String get whyShort => 'Kenapa?';

  @override
  String get whyTitle => 'Kenapa ramalan ini?';

  @override
  String get whyExplainer =>
      'Setiap lengkung menunjukkan apa yang model pelajari tentang satu keadaan. Titik menandakan sekarang — kedudukan tinggi pada lengkung bermakna keadaan itu membantu ramalan hari ini.';

  @override
  String get whyFooter =>
      'Lengkung ialah tindak balas marginal model terlatih, bukan peraturan tetap — berubah apabila model dilatih semula dengan laporan baharu.';

  @override
  String get tagHelps => 'Membantu hari ini';

  @override
  String get tagSlightlyHelps => 'Sedikit membantu';

  @override
  String get tagNeutral => 'Tiada kesan ketara';

  @override
  String get tagHurtsALittle => 'Sedikit menjejaskan';

  @override
  String get tagHurts => 'Menjejaskan hari ini';

  @override
  String get featTemperature => 'Suhu';

  @override
  String get featTemperatureNote => 'Kehangatan ialah isyarat terkuat model';

  @override
  String get featWind => 'Angin';

  @override
  String get featWindNote =>
      'Udara tenang paling baik; angin kencang menahan permaisuri';

  @override
  String get featHumidity => 'Kelembapan';

  @override
  String get featHumidityNote => 'Udara lembap selepas hujan biasanya membantu';

  @override
  String get featCloud => 'Litupan awan';

  @override
  String get featCloudNote =>
      'Tindak balas model yang dipelajari terhadap awan';

  @override
  String get featRain => 'Kemungkinan hujan';

  @override
  String get featRainNote => 'Kebarangkalian hujan hari ini';

  @override
  String get featPressure => 'Tekanan udara';

  @override
  String get featPressureNote => 'Tekanan jarang banyak mengubah ramalan';

  @override
  String driverTemp(String value) {
    return 'Suhu $value';
  }

  @override
  String driverWind(String value) {
    return 'Angin $value';
  }

  @override
  String driverHumidity(String value) {
    return 'Lembap $value%';
  }

  @override
  String driverCloud(String value) {
    return 'Awan $value%';
  }

  @override
  String driverRain(String value) {
    return 'Hujan $value%';
  }

  @override
  String get driverPressure => 'Tekanan';

  @override
  String condWind(String value) {
    return 'angin $value';
  }

  @override
  String condHumidity(String value) {
    return 'kelembapan $value%';
  }

  @override
  String condDewPoint(String value) {
    return 'Takat embun $value';
  }

  @override
  String honestyBand(String band, int percentile) {
    return 'Indeks Penerbangan Semut: $band - hari ini lebih baik daripada $percentile% hari di latitud anda bulan ini.';
  }

  @override
  String honestyOdds(int n) {
    return 'Kira-kira 1 daripada $n hari seperti ini ada penerbangan dilaporkan.';
  }

  @override
  String honestyScore(String score) {
    return 'Skor mentah model: $score (bahagian hutan yang mengundi \"terbang\" - bukan kebarangkalian).';
  }

  @override
  String get sizeSeasonTitle => 'Saiz mana yang bermusim?';

  @override
  String get sizeSeasonExplainer =>
      'Saiz permaisuri berbeza memuncak pada bulan berbeza. Relatif kepada keyakinan keseluruhan hari ini:';

  @override
  String get sizeRowSmall => 'Kecil (~10 mm)';

  @override
  String get sizeRowMedium => 'Sederhana (~20 mm)';

  @override
  String get sizeRowLarge => 'Besar (~30 mm)';

  @override
  String get reportFlightButton => 'Laporkan';

  @override
  String get reportTitle => 'Laporkan penerbangan kahwin';

  @override
  String get reportBlurb =>
      'Nampak permaisuri bersayap terbang berdekatan? Pilih saiz terdekat. Laporan sebenar melatih ramalan untuk semua.';

  @override
  String get reportSmall => 'Kecil';

  @override
  String get reportMedium => 'Sederhana';

  @override
  String get reportLarge => 'Besar';

  @override
  String get reportAbout10mm => 'kira-kira 10 mm';

  @override
  String get reportAbout20mm => 'kira-kira 20 mm';

  @override
  String get reportAbout30mm => 'kira-kira 30 mm';

  @override
  String reportingFrom(String location) {
    return 'Melapor dari lokasi semasa anda · $location';
  }

  @override
  String get submitSighting => 'Hantar laporan';

  @override
  String get noFlightsButton => 'Sudah lihat — tiada penerbangan';

  @override
  String get cancel => 'Batal';

  @override
  String get snackFixedLocation =>
      'Laporan mesti dari lokasi sebenar semasa anda.';

  @override
  String get snackDebugMode => 'Pelaporan dimatikan dalam binaan nyahpepijat.';

  @override
  String get snackThanksNoFlight =>
      'Terima kasih — laporan tiada penerbangan juga menambah baik model.';

  @override
  String get snackThanksSighting =>
      'Terima kasih! Laporan anda membantu melatih ramalan.';

  @override
  String snackNearbyFlights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n penerbangan dilaporkan dalam lingkungan 500 km sejak 24 jam lalu — lihat peta!',
    );
    return '$_temp0';
  }

  @override
  String get notifReportTitle => 'Penerbangan kahwin dilaporkan berdekatan!';

  @override
  String notifReportBody(int n, int minutes, int distance) {
    return 'Terdapat $n penerbangan dilaporkan dalam $minutes minit lalu, yang terdekat $distance km...';
  }

  @override
  String get notifPrimeTitle => 'Keadaan terbaik untuk penerbangan kahwin!';

  @override
  String notifPrimeBody(int n) {
    return 'Hari yang jarang untuk musim anda - kira-kira 1 daripada $n hari seperti ini ada laporan penerbangan.';
  }
}
