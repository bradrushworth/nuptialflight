// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Predictor de Vuelo Nupcial de Hormigas';

  @override
  String get locating => 'Localizando…';

  @override
  String get unknownLocation => 'Ubicación desconocida';

  @override
  String get fetchingWeather => 'Obteniendo el tiempo de tu zona…';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get chooseALocation => 'Elegir ubicación';

  @override
  String get unexpectedError =>
      'Ocurrió un error inesperado. Infórmalo a bitbot@bitbot.com.au ';

  @override
  String get locationFailedError =>
      '¡No se pudo obtener tu ubicación!\n\nIntrodúcela manualmente.';

  @override
  String get locationDeniedError =>
      '¡Permiso de ubicación denegado!\n\nIntroduce tu ubicación manualmente.';

  @override
  String get menuReportIssue => 'Informar de un problema';

  @override
  String get menuWebApp => 'Aplicación web';

  @override
  String get menuAndroid => 'Android';

  @override
  String get menuIos => 'iOS';

  @override
  String get menuSourceCode => 'Código fuente';

  @override
  String get menuCoffee => 'Invítale un café a Brad';

  @override
  String get menuUseMetric => 'Usar °C · m/s';

  @override
  String get menuUseImperial => 'Usar °F · mph';

  @override
  String get tooltipShowMap => 'Mostrar mapa';

  @override
  String get tooltipMoreOptions => 'Más opciones';

  @override
  String get tooltipReportFlight => 'Informa de un vuelo nupcial que viste';

  @override
  String todayDate(String date) {
    return 'Hoy · $date';
  }

  @override
  String get next24Hours => 'Próximas 24 horas';

  @override
  String get chartCaption => 'confianza de vuelo por hora';

  @override
  String get nowTick => 'Ahora';

  @override
  String get upcomingWeek => 'Próxima semana';

  @override
  String get bandNoFly => 'Sin vuelo';

  @override
  String get bandQuiet => 'Tranquilo';

  @override
  String get bandWatchful => 'Regular';

  @override
  String get bandPromising => 'Prometedor';

  @override
  String get bandPrime => 'Óptimo';

  @override
  String get headlineNoFly => 'Hoy no hay vuelos';

  @override
  String get headlineQuiet => 'Día tranquilo';

  @override
  String get headlineWatchful => 'Algo mejor que la media';

  @override
  String get headlinePromising => 'Día prometedor';

  @override
  String get headlinePrime => 'Condiciones óptimas';

  @override
  String get actionNoFly => 'Con este tiempo las hormigas no salen';

  @override
  String get actionQuiet => 'No merece un viaje especial';

  @override
  String get actionWatchful => 'Mantente atento si estás fuera';

  @override
  String get actionPromising => 'Merece un vistazo en la mejor franja';

  @override
  String get actionPrime => 'Sal ya - condiciones así son raras';

  @override
  String oneInN(int n) {
    return '1 de $n';
  }

  @override
  String get daysLikeThisSeeFlights => 'días como este\nven vuelos';

  @override
  String bestWindow(String start, String end) {
    return 'Mejor franja $start–$end';
  }

  @override
  String likelySizeSpecies(String size) {
    return 'Probablemente especie $size';
  }

  @override
  String get sizeSmall => 'pequeña';

  @override
  String get sizeMedium => 'mediana';

  @override
  String get sizeLarge => 'grande';

  @override
  String get whyShort => '¿Por qué?';

  @override
  String get whyTitle => '¿Por qué este pronóstico?';

  @override
  String get whyExplainer =>
      'Cada curva es lo que el modelo aprendió sobre una condición. El punto marca el ahora: estar alto en la curva significa que esa condición ayuda al pronóstico de hoy.';

  @override
  String get whyFooter =>
      'Las curvas son la respuesta marginal del modelo entrenado, no reglas fijas: se actualizan cuando el modelo se reentrena con nuevos avistamientos.';

  @override
  String get tagHelps => 'Ayuda hoy';

  @override
  String get tagSlightlyHelps => 'Ayuda un poco';

  @override
  String get tagNeutral => 'Sin efecto claro';

  @override
  String get tagHurtsALittle => 'Perjudica un poco';

  @override
  String get tagHurts => 'Perjudica hoy';

  @override
  String get featTemperature => 'Temperatura';

  @override
  String get featTemperatureNote =>
      'El calor es la señal más fuerte del modelo';

  @override
  String get featWind => 'Viento';

  @override
  String get featWindNote =>
      'El aire en calma puntúa mejor; el viento fuerte impide volar';

  @override
  String get featHumidity => 'Humedad';

  @override
  String get featHumidityNote => 'El aire húmedo tras la lluvia suele ayudar';

  @override
  String get featCloud => 'Nubosidad';

  @override
  String get featCloudNote => 'La respuesta aprendida del modelo a las nubes';

  @override
  String get featRain => 'Prob. de lluvia';

  @override
  String get featRainNote => 'Probabilidad de precipitación hoy';

  @override
  String get featPressure => 'Presión atmosférica';

  @override
  String get featPressureNote =>
      'La presión rara vez cambia mucho el pronóstico';

  @override
  String driverTemp(String value) {
    return 'Temp $value';
  }

  @override
  String driverWind(String value) {
    return 'Viento $value';
  }

  @override
  String driverHumidity(String value) {
    return 'Humedad $value%';
  }

  @override
  String driverCloud(String value) {
    return 'Nubes $value%';
  }

  @override
  String driverRain(String value) {
    return 'Lluvia $value%';
  }

  @override
  String get driverPressure => 'Presión';

  @override
  String condWind(String value) {
    return 'viento $value';
  }

  @override
  String condHumidity(String value) {
    return '$value% humedad';
  }

  @override
  String condDewPoint(String value) {
    return 'Punto de rocío $value';
  }

  @override
  String honestyBand(String band, int percentile) {
    return 'Índice de Vuelo: $band - hoy es mejor que el $percentile% de los días en tu latitud este mes.';
  }

  @override
  String honestyOdds(int n) {
    return 'Aproximadamente 1 de cada $n días como este recibe un vuelo reportado.';
  }

  @override
  String honestyScore(String score) {
    return 'Puntuación bruta del modelo: $score (fracción del bosque que vota \"vuelo\" - no es una probabilidad).';
  }

  @override
  String get sizeSeasonTitle => '¿Qué tamaño está en temporada?';

  @override
  String get sizeSeasonExplainer =>
      'Cada tamaño de reina alcanza su pico en meses distintos. Respecto a la confianza de hoy:';

  @override
  String get sizeRowSmall => 'Pequeña (~10 mm)';

  @override
  String get sizeRowMedium => 'Mediana (~20 mm)';

  @override
  String get sizeRowLarge => 'Grande (~30 mm)';

  @override
  String get reportFlightButton => 'Reportar vuelo';

  @override
  String get reportTitle => 'Informar de un vuelo nupcial';

  @override
  String get reportBlurb =>
      '¿Viste reinas aladas volando cerca? Elige el tamaño más parecido. Los avistamientos reales entrenan el pronóstico para todos.';

  @override
  String get reportSmall => 'Pequeña';

  @override
  String get reportMedium => 'Mediana';

  @override
  String get reportLarge => 'Grande';

  @override
  String get reportAbout10mm => 'unos 10 mm';

  @override
  String get reportAbout20mm => 'unos 20 mm';

  @override
  String get reportAbout30mm => 'unos 30 mm';

  @override
  String reportingFrom(String location) {
    return 'Informando desde tu ubicación actual · $location';
  }

  @override
  String get submitSighting => 'Enviar avistamiento';

  @override
  String get noFlightsButton => 'Miré — sin vuelos';

  @override
  String get cancel => 'Cancelar';

  @override
  String get snackFixedLocation =>
      'Los informes deben hacerse desde tu ubicación real y actual.';

  @override
  String get snackDebugMode =>
      'Informar está desactivado en compilaciones de depuración.';

  @override
  String get snackThanksNoFlight =>
      'Gracias — los informes sin vuelo también mejoran el modelo.';

  @override
  String get snackThanksSighting =>
      '¡Gracias! Tu avistamiento ayuda a entrenar el pronóstico.';

  @override
  String snackNearbyFlights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n vuelos reportados a menos de 500 km en las últimas 24 h — ¡mira el mapa!',
      one:
          '1 vuelo reportado a menos de 500 km en las últimas 24 h — ¡mira el mapa!',
    );
    return '$_temp0';
  }

  @override
  String get notifReportTitle => '¡Vuelo nupcial reportado cerca!';

  @override
  String notifReportBody(int n, int minutes, int distance) {
    return 'Hay $n vuelos reportados en los últimos $minutes minutos; el más cercano a $distance km...';
  }

  @override
  String get notifPrimeTitle => '¡Condiciones óptimas para vuelos nupciales!';

  @override
  String notifPrimeBody(int n) {
    return 'Un día raro para tu temporada - aproximadamente 1 de cada $n días como este registra vuelos.';
  }
}
