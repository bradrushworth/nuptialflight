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
///
/// When [onDayTap] is supplied every row becomes a button that opens the "Why
/// this forecast?" sheet for THAT day — the callback gets the index into
/// [days]. Without it the rows stay inert (and grow no chevron), so the widget
/// still works as a read-only summary.
class WeekList extends StatelessWidget {
  const WeekList({Key? key, required this.days, this.onDayTap})
      : super(key: key);

  final List<WeekDay> days;
  final ValueChanged<int>? onDayTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations t = context.l10n;
    final TextStyle valueStyle = TextStyle(
      fontSize: 13,
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final bool tappable = onDayTap != null;
    return Column(
      children: [
        for (int i = 0; i < days.length; i++)
          Semantics(
            button: tappable,
            label: '${days[i].day}: ${bandLabelOf(t, days[i].band)}, '
                '${days[i].percentile.round()}%. '
                '${days[i].temp}, ${days[i].wind}.'
                '${tappable ? ' ${t.whyTitle}' : ''}',
            excludeSemantics: true,
            child: Container(
              // The rule sits outside the ink so a tap splash covers the whole
              // row rather than stopping short of the divider.
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant, width: 1),
                ),
              ),
              child: tappable
                  ? Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onDayTap!(i),
                        child: _row(context, days[i], scheme, valueStyle),
                      ),
                    )
                  : _row(context, days[i], scheme, valueStyle),
            ),
          ),
      ],
    );
  }

  Widget _row(BuildContext context, WeekDay d, ColorScheme scheme,
      TextStyle valueStyle) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              d.day,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
            width: 84,
            child: Align(
              alignment: Alignment.centerRight,
              // scaleDown keeps long localized band names (e.g. German
              // "Vielversprechend") on one line instead of wrapping.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: BandPill(band: d.band, compact: true),
              ),
            ),
          ),
          if (onDayTap != null)
            Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
