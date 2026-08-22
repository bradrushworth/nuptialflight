// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Previsor de Voo Nupcial de Formigas';

  @override
  String get locating => 'Localizando…';

  @override
  String get unknownLocation => 'Local desconhecido';

  @override
  String get fetchingWeather => 'Obtendo o clima da sua região…';

  @override
  String get tryAgain => 'Tentar novamente';

  @override
  String get chooseALocation => 'Escolher local';

  @override
  String get unexpectedError =>
      'Ocorreu um erro inesperado. Informe em bitbot@bitbot.com.au ';

  @override
  String get locationFailedError =>
      'Não foi possível obter sua localização!\n\nInsira-a manualmente.';

  @override
  String get locationDeniedError =>
      'Permissão de localização negada!\n\nInsira sua localização manualmente.';

  @override
  String get menuReportIssue => 'Relatar problema';

  @override
  String get menuWebApp => 'Aplicativo web';

  @override
  String get menuAndroid => 'Android';

  @override
  String get menuIos => 'iOS';

  @override
  String get menuSourceCode => 'Código-fonte';

  @override
  String get menuCoffee => 'Pague um café ao Brad';

  @override
  String get menuUseMetric => 'Usar °C · m/s';

  @override
  String get menuUseImperial => 'Usar °F · mph';

  @override
  String get tooltipShowMap => 'Mostrar mapa';

  @override
  String get tooltipMoreOptions => 'Mais opções';

  @override
  String get tooltipReportFlight => 'Relatar um voo nupcial que você viu';

  @override
  String todayDate(String date) {
    return 'Hoje · $date';
  }

  @override
  String get next24Hours => 'Próximas 24 horas';

  @override
  String get chartCaption => 'confiança de voo por hora';

  @override
  String get nowTick => 'Agora';

  @override
  String get upcomingWeek => 'Próxima semana';

  @override
  String get bandNoFly => 'Sem voo';

  @override
  String get bandQuiet => 'Calmo';

  @override
  String get bandWatchful => 'Atento';

  @override
  String get bandPromising => 'Promissor';

  @override
  String get bandPrime => 'Excelente';

  @override
  String get headlineNoFly => 'Sem voos hoje';

  @override
  String get headlineQuiet => 'Dia calmo';

  @override
  String get headlineWatchful => 'Vale ficar de olho';

  @override
  String get headlinePromising => 'Dia promissor';

  @override
  String get headlinePrime => 'Condições excelentes';

  @override
  String get actionNoFly => 'Com esse tempo as formigas ficam no ninho';

  @override
  String get actionQuiet => 'Não vale uma saída especial';

  @override
  String get actionWatchful => 'Fique de olho se estiver na rua';

  @override
  String get actionPromising => 'Vale uma olhada no melhor horário';

  @override
  String get actionPrime => 'Saia agora - condições assim são raras';

  @override
  String oneInN(int n) {
    return '1 em $n';
  }

  @override
  String get daysLikeThisSeeFlights => 'dias como este\ntêm voos';

  @override
  String bestWindow(String start, String end) {
    return 'Melhor janela $start–$end';
  }

  @override
  String likelySizeSpecies(String size) {
    return 'Provavelmente espécie $size';
  }

  @override
  String get sizeSmall => 'pequena';

  @override
  String get sizeMedium => 'média';

  @override
  String get sizeLarge => 'grande';

  @override
  String get whyShort => 'Por quê?';

  @override
  String get whyTitle => 'Por que esta previsão?';

  @override
  String get whyExplainer =>
      'Cada curva mostra o que o modelo aprendeu sobre uma condição. O ponto marca o agora — alto na curva significa que a condição ajuda a previsão de hoje.';

  @override
  String get whyFooter =>
      'As curvas são a resposta marginal do modelo treinado, não regras fixas — mudam quando o modelo é retreinado com novos relatos.';

  @override
  String get tagHelps => 'Ajuda hoje';

  @override
  String get tagSlightlyHelps => 'Ajuda um pouco';

  @override
  String get tagNeutral => 'Sem efeito claro';

  @override
  String get tagHurtsALittle => 'Atrapalha um pouco';

  @override
  String get tagHurts => 'Atrapalha hoje';

  @override
  String get featTemperature => 'Temperatura';

  @override
  String get featTemperatureNote => 'O calor é o sinal mais forte do modelo';

  @override
  String get featWind => 'Vento';

  @override
  String get featWindNote =>
      'Ar calmo é o ideal; vento forte impede o voo das rainhas';

  @override
  String get featHumidity => 'Umidade';

  @override
  String get featHumidityNote => 'Ar úmido após a chuva geralmente ajuda';

  @override
  String get featCloud => 'Nebulosidade';

  @override
  String get featCloudNote => 'A resposta aprendida do modelo às nuvens';

  @override
  String get featRain => 'Chance de chuva';

  @override
  String get featRainNote => 'Probabilidade de precipitação hoje';

  @override
  String get featPressure => 'Pressão atmosférica';

  @override
  String get featPressureNote => 'A pressão raramente muda muito a previsão';

  @override
  String driverTemp(String value) {
    return 'Temp $value';
  }

  @override
  String driverWind(String value) {
    return 'Vento $value';
  }

  @override
  String driverHumidity(String value) {
    return 'Umidade $value%';
  }

  @override
  String driverCloud(String value) {
    return 'Nuvens $value%';
  }

  @override
  String driverRain(String value) {
    return 'Chuva $value%';
  }

  @override
  String get driverPressure => 'Pressão';

  @override
  String condWind(String value) {
    return 'vento $value';
  }

  @override
  String condHumidity(String value) {
    return '$value% de umidade';
  }

  @override
  String condDewPoint(String value) {
    return 'Ponto de orvalho $value';
  }

  @override
  String honestyBand(String band, int percentile) {
    return 'Índice de Voo: $band - hoje é melhor que $percentile% dos dias na sua latitude neste mês.';
  }

  @override
  String honestyOdds(int n) {
    return 'Cerca de 1 em cada $n dias como este tem um voo relatado.';
  }

  @override
  String honestyScore(String score) {
    return 'Pontuação bruta do modelo: $score (fração da floresta votando \"voo\" - não é uma probabilidade).';
  }

  @override
  String get sizeSeasonTitle => 'Qual tamanho está na estação?';

  @override
  String get sizeSeasonExplainer =>
      'Tamanhos diferentes de rainha atingem o pico em meses diferentes. Em relação à confiança geral de hoje:';

  @override
  String get sizeRowSmall => 'Pequena (~10 mm)';

  @override
  String get sizeRowMedium => 'Média (~20 mm)';

  @override
  String get sizeRowLarge => 'Grande (~30 mm)';

  @override
  String get reportFlightButton => 'Relatar voo';

  @override
  String get reportTitle => 'Relatar voo nupcial';

  @override
  String get reportBlurb =>
      'Viu rainhas aladas voando por perto? Escolha o tamanho mais próximo. Relatos reais treinam a previsão para todos.';

  @override
  String get reportSmall => 'Pequena';

  @override
  String get reportMedium => 'Média';

  @override
  String get reportLarge => 'Grande';

  @override
  String get reportAbout10mm => 'cerca de 10 mm';

  @override
  String get reportAbout20mm => 'cerca de 20 mm';

  @override
  String get reportAbout30mm => 'cerca de 30 mm';

  @override
  String reportingFrom(String location) {
    return 'Relatando da sua localização atual · $location';
  }

  @override
  String get submitSighting => 'Enviar avistamento';

  @override
  String get noFlightsButton => 'Olhei — sem voos';

  @override
  String get cancel => 'Cancelar';

  @override
  String get snackFixedLocation =>
      'Relatos devem vir da sua localização real e atual.';

  @override
  String get snackDebugMode =>
      'Relatar está desativado em builds de depuração.';

  @override
  String get snackThanksNoFlight =>
      'Obrigado — relatos sem voo também melhoram o modelo.';

  @override
  String get snackThanksSighting =>
      'Obrigado! Seu avistamento ajuda a treinar a previsão.';

  @override
  String snackNearbyFlights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n voos relatados num raio de 500 km nas últimas 24 h — veja o mapa!',
      one: '1 voo relatado num raio de 500 km nas últimas 24 h — veja o mapa!',
    );
    return '$_temp0';
  }

  @override
  String get notifReportTitle => 'Voo nupcial relatado por perto!';

  @override
  String notifReportBody(int n, int minutes, int distance) {
    return 'Há $n voos relatados nos últimos $minutes minutos, o mais próximo a $distance km...';
  }

  @override
  String get notifPrimeTitle => 'Condições excelentes para voos nupciais!';

  @override
  String notifPrimeBody(int n) {
    return 'Um dia raro para a sua estação - cerca de 1 em cada $n dias como este registra voos.';
  }
}
