import 'package:flutter/widgets.dart';

import '../controller/flight_index.dart';
import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

/// Shorthand for the generated localizations lookup. The delegates are always
/// installed on the MaterialApp, so the bang is safe below it.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// Localized Flight Index band strings. The English copy in
/// controller/flight_index.dart stays as the context-free fallback (tests,
/// background isolates); widgets should always use these.
String bandLabelOf(AppLocalizations t, FlightBand band) {
  switch (band) {
    case FlightBand.noFly:
      return t.bandNoFly;
    case FlightBand.quiet:
      return t.bandQuiet;
    case FlightBand.watchful:
      return t.bandWatchful;
    case FlightBand.promising:
      return t.bandPromising;
    case FlightBand.prime:
      return t.bandPrime;
  }
}

String bandHeadlineOf(AppLocalizations t, FlightBand band) {
  switch (band) {
    case FlightBand.noFly:
      return t.headlineNoFly;
    case FlightBand.quiet:
      return t.headlineQuiet;
    case FlightBand.watchful:
      return t.headlineWatchful;
    case FlightBand.promising:
      return t.headlinePromising;
    case FlightBand.prime:
      return t.headlinePrime;
  }
}

String bandActionOf(AppLocalizations t, FlightBand band) {
  switch (band) {
    case FlightBand.noFly:
      return t.actionNoFly;
    case FlightBand.quiet:
      return t.actionQuiet;
    case FlightBand.watchful:
      return t.actionWatchful;
    case FlightBand.promising:
      return t.actionPromising;
    case FlightBand.prime:
      return t.actionPrime;
  }
}
