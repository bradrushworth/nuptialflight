// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Prediksi Penerbangan Kawin Semut';

  @override
  String get locating => 'Mencari lokasi…';

  @override
  String get unknownLocation => 'Lokasi tidak dikenal';

  @override
  String get fetchingWeather => 'Mengambil cuaca setempat…';

  @override
  String get tryAgain => 'Coba lagi';

  @override
  String get chooseALocation => 'Pilih lokasi';

  @override
  String get unexpectedError =>
      'Terjadi kesalahan tak terduga. Laporkan ke bitbot@bitbot.com.au ';

  @override
  String get locationFailedError =>
      'Gagal mendapatkan lokasi Anda!\n\nMasukkan lokasi secara manual.';

  @override
  String get locationDeniedError =>
      'Izin lokasi ditolak!\n\nMasukkan lokasi secara manual.';

  @override
  String get menuReportIssue => 'Laporkan Masalah';

  @override
  String get menuWebApp => 'Aplikasi Web';

  @override
  String get menuAndroid => 'Android';

  @override
  String get menuIos => 'iOS';

  @override
  String get menuSourceCode => 'Kode Sumber';

  @override
  String get menuCoffee => 'Traktir Brad Kopi';

  @override
  String get menuUseMetric => 'Gunakan °C · m/dtk';

  @override
  String get menuUseImperial => 'Gunakan °F · mph';

  @override
  String get tooltipShowMap => 'Tampilkan peta';

  @override
  String get tooltipMoreOptions => 'Opsi lainnya';

  @override
  String get tooltipReportFlight =>
      'Laporkan penerbangan kawin yang Anda lihat';

  @override
  String todayDate(String date) {
    return 'Hari ini · $date';
  }

  @override
  String get next24Hours => '24 jam ke depan';

  @override
  String get chartCaption => 'keyakinan penerbangan per jam';

  @override
  String get nowTick => 'Sekarang';

  @override
  String get upcomingWeek => 'Pekan mendatang';

  @override
  String get bandNoFly => 'Tidak terbang';

  @override
  String get bandQuiet => 'Tenang';

  @override
  String get bandWatchful => 'Cukup';

  @override
  String get bandPromising => 'Menjanjikan';

  @override
  String get bandPrime => 'Prima';

  @override
  String get headlineNoFly => 'Tidak ada penerbangan hari ini';

  @override
  String get headlineQuiet => 'Hari yang tenang';

  @override
  String get headlineWatchful => 'Sedikit di atas rata-rata';

  @override
  String get headlinePromising => 'Hari yang menjanjikan';

  @override
  String get headlinePrime => 'Kondisi prima';

  @override
  String get actionNoFly => 'Dalam cuaca ini semut tetap di sarang';

  @override
  String get actionQuiet => 'Tidak perlu perjalanan khusus';

  @override
  String get actionWatchful => 'Tetap perhatikan jika Anda di luar';

  @override
  String get actionPromising => 'Layak dilihat pada waktu terbaik';

  @override
  String get actionPrime => 'Keluarlah - kondisi seperti ini langka';

  @override
  String oneInN(int n) {
    return '1 dari $n';
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
  String get sizeMedium => 'sedang';

  @override
  String get sizeLarge => 'besar';

  @override
  String get whyShort => 'Kenapa?';

  @override
  String get whyTitle => 'Kenapa prakiraan ini?';

  @override
  String get whyExplainer =>
      'Setiap kurva menunjukkan apa yang dipelajari model tentang satu kondisi. Titik menandai nilai hari itu — posisi tinggi pada kurva berarti kondisi itu membantu prakiraan.';

  @override
  String get whyFooter =>
      'Kurva adalah respons marginal model terlatih, bukan aturan tetap — berubah saat model dilatih ulang dengan laporan baru.';

  @override
  String get tagHelps => 'Membantu';

  @override
  String get tagSlightlyHelps => 'Sedikit membantu';

  @override
  String get tagNeutral => 'Tanpa efek berarti';

  @override
  String get tagHurtsALittle => 'Sedikit menghambat';

  @override
  String get tagHurts => 'Menghambat';

  @override
  String get featTemperature => 'Suhu';

  @override
  String get featTemperatureNote => 'Kehangatan adalah sinyal terkuat model';

  @override
  String get featWind => 'Angin';

  @override
  String get featWindNote =>
      'Udara tenang paling baik; angin kencang menahan ratu di darat';

  @override
  String get featHumidity => 'Kelembapan';

  @override
  String get featHumidityNote => 'Udara lembap setelah hujan biasanya membantu';

  @override
  String get featCloud => 'Tutupan awan';

  @override
  String get featCloudNote => 'Respons model yang dipelajari terhadap awan';

  @override
  String get featRain => 'Peluang hujan';

  @override
  String get featRainNote => 'Probabilitas hujan hari itu';

  @override
  String get featPressure => 'Tekanan udara';

  @override
  String get featPressureNote => 'Tekanan jarang banyak mengubah prakiraan';

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
    return 'Titik embun $value';
  }

  @override
  String honestyBand(String band, int percentile) {
    return 'Indeks Penerbangan Semut: $band - lebih baik dari $percentile% hari di lintang Anda bulan ini.';
  }

  @override
  String honestyOdds(int n) {
    return 'Sekitar 1 dari $n hari seperti ini ada penerbangan yang dilaporkan.';
  }

  @override
  String honestyScore(String score) {
    return 'Skor mentah model: $score (porsi hutan yang memilih \"terbang\" - bukan probabilitas).';
  }

  @override
  String get sizeSeasonTitle => 'Ukuran mana yang sedang musim?';

  @override
  String get sizeSeasonExplainer =>
      'Ukuran ratu yang berbeda memuncak di bulan berbeda. Relatif terhadap keyakinan keseluruhan hari itu:';

  @override
  String get sizeRowSmall => 'Kecil (~10 mm)';

  @override
  String get sizeRowMedium => 'Sedang (~20 mm)';

  @override
  String get sizeRowLarge => 'Besar (~30 mm)';

  @override
  String get reportFlightButton => 'Laporkan';

  @override
  String get reportTitle => 'Laporkan penerbangan kawin';

  @override
  String get reportBlurb =>
      'Melihat ratu bersayap terbang di dekat Anda? Pilih ukuran terdekat. Laporan asli melatih prakiraan untuk semua.';

  @override
  String get reportSmall => 'Kecil';

  @override
  String get reportMedium => 'Sedang';

  @override
  String get reportLarge => 'Besar';

  @override
  String get reportAbout10mm => 'sekitar 10 mm';

  @override
  String get reportAbout20mm => 'sekitar 20 mm';

  @override
  String get reportAbout30mm => 'sekitar 30 mm';

  @override
  String reportingFrom(String location) {
    return 'Melapor dari lokasi Anda saat ini · $location';
  }

  @override
  String get submitSighting => 'Kirim laporan';

  @override
  String get noFlightsButton => 'Sudah melihat — tidak ada';

  @override
  String get cancel => 'Batal';

  @override
  String get snackFixedLocation =>
      'Laporan harus dari lokasi Anda yang sebenarnya saat ini.';

  @override
  String get snackDebugMode => 'Pelaporan dinonaktifkan pada build debug.';

  @override
  String get snackThanksNoFlight =>
      'Terima kasih — laporan tanpa penerbangan juga memperbaiki model.';

  @override
  String get snackThanksSighting =>
      'Terima kasih! Laporan Anda membantu melatih prakiraan.';

  @override
  String snackNearbyFlights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n penerbangan dilaporkan dalam 500 km selama 24 jam terakhir — lihat peta!',
    );
    return '$_temp0';
  }

  @override
  String get notifReportTitle => 'Penerbangan kawin dilaporkan di dekat Anda!';

  @override
  String notifReportBody(int n, int minutes, int distance) {
    return 'Ada $n penerbangan dilaporkan dalam $minutes menit terakhir, terdekat $distance km...';
  }

  @override
  String get notifPrimeTitle => 'Kondisi prima untuk penerbangan kawin!';

  @override
  String notifPrimeBody(int n) {
    return 'Hari langka untuk musim Anda - sekitar 1 dari $n hari seperti ini ada laporan penerbangan.';
  }
}
