import 'package:flutter/material.dart';

import 'verdict.dart';

/// One row of the upcoming-week list.
class WeekDay {
  const WeekDay({
    required this.day,
    required this.temp,
    required this.wind,
    required this.percentage,
  });

  final String day;
  final String temp;
  final String wind;
  final int percentage;
}

/// The upcoming week as accessible list rows: day, temp, wind, a small
/// confidence bar, and a labelled verdict pill (text + colour together, so
/// colour is never the only encoding). Replaces the old 22px DataTable rows.
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
                '${d.day}: flight ${verdictLabel(verdictFor(d.percentage)).toLowerCase()}, ${d.percentage} percent. ${d.temp}, wind ${d.wind}.',
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
                          value: d.percentage / 100.0,
                          minHeight: 6,
                          backgroundColor: scheme.surfaceContainerHighest,
                          color: verdictColors(
                                  context, verdictFor(d.percentage))
                              .fg,
                        ),
                      ),
                    ),
                  ),
                  VerdictPill(percentage: d.percentage, compact: true),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
