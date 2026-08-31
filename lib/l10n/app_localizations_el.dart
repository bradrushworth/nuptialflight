// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'Πρόβλεψη Γαμήλιας Πτήσης Μυρμηγκιών';

  @override
  String get locating => 'Εντοπισμός θέσης…';

  @override
  String get unknownLocation => 'Άγνωστη τοποθεσία';

  @override
  String get fetchingWeather => 'Λήψη τοπικού καιρού…';

  @override
  String get tryAgain => 'Δοκιμή ξανά';

  @override
  String get chooseALocation => 'Επιλογή τοποθεσίας';

  @override
  String get unexpectedError =>
      'Παρουσιάστηκε απρόσμενο σφάλμα. Αναφέρετέ το στο bitbot@bitbot.com.au ';

  @override
  String get locationFailedError =>
      'Αποτυχία εντοπισμού θέσης!\n\nΕισαγάγετε την τοποθεσία χειροκίνητα.';

  @override
  String get locationDeniedError =>
      'Η άδεια τοποθεσίας απορρίφθηκε!\n\nΕισαγάγετε την τοποθεσία χειροκίνητα.';

  @override
  String get menuReportIssue => 'Αναφορά προβλήματος';

  @override
  String get menuWebApp => 'Εφαρμογή ιστού';

  @override
  String get menuAndroid => 'Android';

  @override
  String get menuIos => 'iOS';

  @override
  String get menuSourceCode => 'Πηγαίος κώδικας';

  @override
  String get menuCoffee => 'Κέρασε τον Brad καφέ';

  @override
  String get menuUseMetric => 'Χρήση °C · m/s';

  @override
  String get menuUseImperial => 'Χρήση °F · mph';

  @override
  String get tooltipShowMap => 'Εμφάνιση χάρτη';

  @override
  String get tooltipMoreOptions => 'Περισσότερες επιλογές';

  @override
  String get tooltipReportFlight => 'Αναφέρετε γαμήλια πτήση που είδατε';

  @override
  String todayDate(String date) {
    return 'Σήμερα · $date';
  }

  @override
  String get next24Hours => 'Επόμενες 24 ώρες';

  @override
  String get chartCaption => 'εμπιστοσύνη πτήσης ανά ώρα';

  @override
  String get nowTick => 'Τώρα';

  @override
  String get upcomingWeek => 'Επόμενη εβδομάδα';

  @override
  String get bandNoFly => 'Καμία πτήση';

  @override
  String get bandQuiet => 'Ήσυχα';

  @override
  String get bandWatchful => 'Μέτρια';

  @override
  String get bandPromising => 'Ελπιδοφόρα';

  @override
  String get bandPrime => 'Κορυφαία';

  @override
  String get headlineNoFly => 'Καμία πτήση σήμερα';

  @override
  String get headlineQuiet => 'Ήσυχη μέρα';

  @override
  String get headlineWatchful => 'Λίγο πάνω από τον μέσο όρο';

  @override
  String get headlinePromising => 'Ελπιδοφόρα μέρα';

  @override
  String get headlinePrime => 'Κορυφαίες συνθήκες';

  @override
  String get actionNoFly => 'Με τέτοιον καιρό τα μυρμήγκια μένουν στη φωλιά';

  @override
  String get actionQuiet => 'Δεν αξίζει ειδική έξοδο';

  @override
  String get actionWatchful => 'Έχετε τον νου σας αν είστε έξω';

  @override
  String get actionPromising => 'Αξίζει μια ματιά στο καλύτερο διάστημα';

  @override
  String get actionPrime => 'Βγείτε έξω - τέτοιες συνθήκες είναι σπάνιες';

  @override
  String oneInN(int n) {
    return '1 στις $n';
  }

  @override
  String get daysLikeThisSeeFlights => 'τέτοιες μέρες\nέχουν πτήσεις';

  @override
  String bestWindow(String start, String end) {
    return 'Καλύτερο διάστημα $start–$end';
  }

  @override
  String likelySizeSpecies(String size) {
    return 'Πιθανόν $size είδος';
  }

  @override
  String get sizeSmall => 'μικρό';

  @override
  String get sizeMedium => 'μεσαίο';

  @override
  String get sizeLarge => 'μεγάλο';

  @override
  String get whyShort => 'Γιατί;';

  @override
  String get whyTitle => 'Γιατί αυτή η πρόβλεψη;';

  @override
  String get whyExplainer =>
      'Κάθε καμπύλη δείχνει τι έμαθε το μοντέλο για μία συνθήκη. Η κουκκίδα σημειώνει το τώρα — ψηλά στην καμπύλη σημαίνει ότι η συνθήκη βοηθά τη σημερινή πρόβλεψη.';

  @override
  String get whyFooter =>
      'Οι καμπύλες είναι η οριακή απόκριση του εκπαιδευμένου μοντέλου, όχι σταθεροί κανόνες — αλλάζουν όταν το μοντέλο επανεκπαιδεύεται με νέες αναφορές.';

  @override
  String get tagHelps => 'Βοηθά σήμερα';

  @override
  String get tagSlightlyHelps => 'Βοηθά λίγο';

  @override
  String get tagNeutral => 'Χωρίς σαφή επίδραση';

  @override
  String get tagHurtsALittle => 'Βλάπτει λίγο';

  @override
  String get tagHurts => 'Βλάπτει σήμερα';

  @override
  String get featTemperature => 'Θερμοκρασία';

  @override
  String get featTemperatureNote =>
      'Η ζέστη είναι το ισχυρότερο σήμα του μοντέλου';

  @override
  String get featWind => 'Άνεμος';

  @override
  String get featWindNote =>
      'Η άπνοια είναι ιδανική· ο δυνατός άνεμος καθηλώνει τις βασίλισσες';

  @override
  String get featHumidity => 'Υγρασία';

  @override
  String get featHumidityNote => 'Ο υγρός αέρας μετά τη βροχή συνήθως βοηθά';

  @override
  String get featCloud => 'Νέφωση';

  @override
  String get featCloudNote => 'Η μαθημένη απόκριση του μοντέλου στη νέφωση';

  @override
  String get featRain => 'Πιθανότητα βροχής';

  @override
  String get featRainNote => 'Η σημερινή πιθανότητα βροχόπτωσης';

  @override
  String get featPressure => 'Ατμοσφαιρική πίεση';

  @override
  String get featPressureNote => 'Η πίεση σπάνια αλλάζει πολύ την πρόβλεψη';

  @override
  String driverTemp(String value) {
    return 'Θερμ. $value';
  }

  @override
  String driverWind(String value) {
    return 'Άνεμος $value';
  }

  @override
  String driverHumidity(String value) {
    return 'Υγρασία $value%';
  }

  @override
  String driverCloud(String value) {
    return 'Νέφη $value%';
  }

  @override
  String driverRain(String value) {
    return 'Βροχή $value%';
  }

  @override
  String get driverPressure => 'Πίεση';

  @override
  String condWind(String value) {
    return 'άνεμος $value';
  }

  @override
  String condHumidity(String value) {
    return '$value% υγρασία';
  }

  @override
  String condDewPoint(String value) {
    return 'Σημείο δρόσου $value';
  }

  @override
  String honestyBand(String band, int percentile) {
    return 'Δείκτης Πτήσεων: $band - το σήμερα είναι καλύτερο από το $percentile% των ημερών στο γεωγραφικό σας πλάτος αυτόν τον μήνα.';
  }

  @override
  String honestyOdds(int n) {
    return 'Περίπου 1 στις $n τέτοιες μέρες αναφέρεται πτήση από χρήστες.';
  }

  @override
  String honestyScore(String score) {
    return 'Ακατέργαστο σκορ μοντέλου: $score (ποσοστό του δάσους που ψηφίζει \"πτήση\" - όχι πιθανότητα).';
  }

  @override
  String get sizeSeasonTitle => 'Ποιο μέγεθος έχει εποχή;';

  @override
  String get sizeSeasonExplainer =>
      'Διαφορετικά μεγέθη βασιλισσών κορυφώνονται σε διαφορετικούς μήνες. Σε σχέση με τη σημερινή συνολική εκτίμηση:';

  @override
  String get sizeRowSmall => 'Μικρό (~10 mm)';

  @override
  String get sizeRowMedium => 'Μεσαίο (~20 mm)';

  @override
  String get sizeRowLarge => 'Μεγάλο (~30 mm)';

  @override
  String get reportFlightButton => 'Αναφορά πτήσης';

  @override
  String get reportTitle => 'Αναφορά γαμήλιας πτήσης';

  @override
  String get reportBlurb =>
      'Είδατε φτερωτές βασίλισσες κοντά σας; Διαλέξτε το πλησιέστερο μέγεθος. Οι αληθινές παρατηρήσεις εκπαιδεύουν την πρόβλεψη για όλους.';

  @override
  String get reportSmall => 'Μικρό';

  @override
  String get reportMedium => 'Μεσαίο';

  @override
  String get reportLarge => 'Μεγάλο';

  @override
  String get reportAbout10mm => 'περίπου 10 mm';

  @override
  String get reportAbout20mm => 'περίπου 20 mm';

  @override
  String get reportAbout30mm => 'περίπου 30 mm';

  @override
  String reportingFrom(String location) {
    return 'Αναφορά από την τρέχουσα θέση σας · $location';
  }

  @override
  String get submitSighting => 'Υποβολή παρατήρησης';

  @override
  String get noFlightsButton => 'Κοίταξα — καμία πτήση';

  @override
  String get cancel => 'Άκυρο';

  @override
  String get snackFixedLocation =>
      'Οι αναφορές πρέπει να γίνονται από την πραγματική, τρέχουσα θέση σας.';

  @override
  String get snackDebugMode =>
      'Η αναφορά είναι απενεργοποιημένη σε εκδόσεις debug.';

  @override
  String get snackThanksNoFlight =>
      'Ευχαριστούμε — και οι αναφορές χωρίς πτήση βελτιώνουν το μοντέλο.';

  @override
  String get snackThanksSighting =>
      'Ευχαριστούμε! Η παρατήρησή σας εκπαιδεύει την πρόβλεψη.';

  @override
  String snackNearbyFlights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n πτήσεις αναφέρθηκαν εντός 500 km το τελευταίο 24ωρο — δείτε τον χάρτη!',
      one:
          '1 πτήση αναφέρθηκε εντός 500 km το τελευταίο 24ωρο — δείτε τον χάρτη!',
    );
    return '$_temp0';
  }

  @override
  String get notifReportTitle => 'Αναφέρθηκε γαμήλια πτήση κοντά σας!';

  @override
  String notifReportBody(int n, int minutes, int distance) {
    return '$n πτήσεις αναφέρθηκαν τα τελευταία $minutes λεπτά, η πλησιέστερη $distance km μακριά...';
  }

  @override
  String get notifPrimeTitle => 'Κορυφαίες συνθήκες για γαμήλιες πτήσεις!';

  @override
  String notifPrimeBody(int n) {
    return 'Σπάνια μέρα για την εποχή σας - πτήσεις αναφέρονται περίπου 1 στις $n τέτοιες μέρες.';
  }
}
