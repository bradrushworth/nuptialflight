import 'package:flutter/material.dart';

import '../controller/flight_index.dart';

/// Shared verdict thresholds. A day at/above [greenThreshold] is "Likely",
/// at/above [amberThreshold] "Possible", otherwise "Unlikely". These are the
/// single source of truth — the widget, notifications (services.dart via
/// main.dart's re-export) and every pill/chart colour derive from them.
const int greenThreshold = 60;
const int amberThreshold = 50;

enum Verdict { likely, possible, unlikely }

Verdict verdictFor(int percentage) {
  if (percentage >= greenThreshold) return Verdict.likely;
  if (percentage >= amberThreshold) return Verdict.possible;
  return Verdict.unlikely;
}

String verdictLabel(Verdict v) {
  switch (v) {
    case Verdict.likely:
      return 'Likely';
    case Verdict.possible:
      return 'Possible';
    case Verdict.unlikely:
      return 'Unlikely';
  }
}

/// Foreground/background pair for a verdict, tuned per brightness so the
/// pills stay legible in both themes (colour is never the only encoding —
/// every pill also carries its text label).
class VerdictColors {
  const VerdictColors(this.fg, this.bg);

  final Color fg;
  final Color bg;
}

VerdictColors verdictColors(BuildContext context, Verdict v) {
  final bool dark = Theme.of(context).brightness == Brightness.dark;
  switch (v) {
    case Verdict.likely:
      return dark
          ? const VerdictColors(Color(0xFF7FCE96), Color(0xFF22352A))
          : const VerdictColors(Color(0xFF2E7D43), Color(0xFFD7E8DC));
    case Verdict.possible:
      return dark
          ? const VerdictColors(Color(0xFFDCB573), Color(0xFF3A3120))
          : const VerdictColors(Color(0xFF8A5B10), Color(0xFFF3E5C8));
    case Verdict.unlikely:
      return dark
          ? const VerdictColors(Color(0xFFE09A92), Color(0xFF3A2523))
          : const VerdictColors(Color(0xFFA04A42), Color(0xFFF6E2DF));
  }
}

/// Colours for the five Ant Flight Index bands, tuned per brightness.
/// No-fly is a neutral grey (nothing to see), quiet a muted red, watchful
/// amber, promising a yellow-green, prime the full eucalypt green.
VerdictColors bandColors(BuildContext context, FlightBand band) {
  final bool dark = Theme.of(context).brightness == Brightness.dark;
  switch (band) {
    case FlightBand.noFly:
      return dark
          ? const VerdictColors(Color(0xFF9AA69C), Color(0xFF262B27))
          : const VerdictColors(Color(0xFF55615A), Color(0xFFECEDEA));
    case FlightBand.quiet:
      return verdictColors(context, Verdict.unlikely);
    case FlightBand.watchful:
      return verdictColors(context, Verdict.possible);
    case FlightBand.promising:
      return dark
          ? const VerdictColors(Color(0xFFAFC97A), Color(0xFF2C331F))
          : const VerdictColors(Color(0xFF5E7D2E), Color(0xFFE9F0D8));
    case FlightBand.prime:
      return verdictColors(context, Verdict.likely);
  }
}

/// A labelled Flight Index band pill ("Prime", "Quiet"). Text + colour
/// together so it stays readable for colour-blind users and screen readers.
class BandPill extends StatelessWidget {
  const BandPill({Key? key, required this.band, this.compact = false})
      : super(key: key);

  final FlightBand band;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final VerdictColors c = bandColors(context, band);
    return Semantics(
      label: 'Flight index: ${bandLabel(band)}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          bandLabel(band),
          style: TextStyle(
            color: c.fg,
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// A labelled verdict pill ("Likely 64%"). Encodes the verdict with text +
/// colour together so it stays readable for colour-blind users and screen
/// readers.
class VerdictPill extends StatelessWidget {
  const VerdictPill({Key? key, required this.percentage, this.compact = false})
      : super(key: key);

  final int percentage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Verdict v = verdictFor(percentage);
    final VerdictColors c = verdictColors(context, v);
    return Semantics(
      label: 'Nuptial flight ${verdictLabel(v).toLowerCase()}, $percentage percent',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '${verdictLabel(v)} $percentage%',
          style: TextStyle(
            color: c.fg,
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
