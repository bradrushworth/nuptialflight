import 'package:flutter/material.dart';

import '../controller/flight_index.dart';
import 'l10n_ext.dart';
import 'verdict.dart';

/// One row of the upcoming-week list.
class WeekDay {
  const WeekDay({
    required this.day,
    required this.temp,
    required this.wind,
    required this.band,
    required this.percentile,
  });

  final String day;
  final String temp;
  final String wind;
  final FlightBand band;

  /// Percentile (0..100) vs days at this hemisphere + month; drives the bar.
  final double percentile;
}

/// The upcoming week as accessible list rows: day, temp, wind, a bar showing
/// the day's percentile against the season, and a named Flight Index band
/// (text + colour together, so colour is never the only encoding).
class WeekList extends StatelessWidget {
  const WeekList({Key? key, required this.days}) : super(key: key);

  final List<WeekDay> days;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle valueStyle = TextStyle(
      fontSize: 13,
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Column(
      children: [
        for (final WeekDay d in days)
          Semantics(
            label:
                '${d.day}: ${bandLabelOf(context.l10n, d.band)}, ${d.percentile.round()}%. ${d.temp}, ${d.wind}.',
            excludeSemantics: true,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant, width: 1),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      d.day,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(width: 52, child: Text(d.temp, style: valueStyle)),
                  SizedBox(width: 72, child: Text(d.wind, style: valueStyle)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: d.percentile / 100.0,
                          minHeight: 6,
                          backgroundColor: scheme.surfaceContainerHighest,
                          color: bandColors(context, d.band).fg,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 88,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: BandPill(band: d.band, compact: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
