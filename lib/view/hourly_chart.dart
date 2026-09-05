import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controller/flight_index.dart';
import 'l10n_ext.dart';
import 'verdict.dart';

/// One entry per hour: the model's confidence and the (unix, UTC) timestamp.
class HourlyPoint {
  const HourlyPoint(this.dt, this.percentage, this.band);

  final int dt;

  /// Raw model score as 0..100 (drives bar height / intra-day shape).
  final int percentage;

  /// Flight Index band (drives colour; percentile-based, so an unusually
  /// good hour for the season reads green even at a modest raw score).
  final FlightBand band;
}

/// The next-24-hours confidence chart: one bar per hour, ticks every six
/// hours aligned under the bars they label, and a "Now" marker. Bars show the
/// true value (no artificial floor) — quiet hours are allowed to look quiet.
///
/// Bar colour comes straight from [bandColors], the same source the pills and
/// the week list use, so the three always agree. It must NOT collapse bands
/// into a shared neutral: hours are capped at the day's band (see main.dart),
/// and since the 2026-08 recalibration ~70% of days are [FlightBand.quiet] —
/// folding quiet into the noFly grey left the whole chart one flat grey block.
class HourlyChart extends StatelessWidget {
  const HourlyChart({
    Key? key,
    required this.points,
    required this.timezoneOffsetSeconds,
  }) : super(key: key);

  final List<HourlyPoint> points;
  final int timezoneOffsetSeconds;

  // Locale-preferred hour style ("7pm" or "19"), compacted to fit a tick.
  String _localHour(BuildContext context, int dt) =>
      DateFormat.j(Localizations.localeOf(context).toString())
          .format(DateTime.fromMillisecondsSinceEpoch(
              (dt + timezoneOffsetSeconds) * 1000,
              isUtc: true))
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '');

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<HourlyPoint> shown = points.take(24).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    final int peak = shown.map((p) => p.percentage).reduce(max);
    return Semantics(
      label: '${context.l10n.chartCaption} — $peak%.',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 92,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < shown.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(
                    child: Container(
                      height: max(3.0, shown[i].percentage * 0.92),
                      decoration: BoxDecoration(
                        color: bandColors(context, shown[i].band).fg,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                          bottom: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              for (int i = 0; i < shown.length; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Expanded(
                  child: i % 6 == 0
                      ? Text(
                          i == 0
                              ? context.l10n.nowTick
                              : _localHour(context, shown[i].dt),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                i == 0 ? FontWeight.w700 : FontWeight.w600,
                            color: i == 0
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
