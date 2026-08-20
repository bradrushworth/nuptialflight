import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'verdict.dart';

final DateFormat _tickFormat = DateFormat('ha');

/// One entry per hour: the model's confidence and the (unix, UTC) timestamp.
class HourlyPoint {
  const HourlyPoint(this.dt, this.percentage);

  final int dt;
  final int percentage;
}

/// The next-24-hours confidence chart: one bar per hour, ticks every six
/// hours aligned under the bars they label, and a "Now" marker. Bars show the
/// true value (no artificial floor) — quiet hours are allowed to look quiet.
class HourlyChart extends StatelessWidget {
  const HourlyChart({
    Key? key,
    required this.points,
    required this.timezoneOffsetSeconds,
  }) : super(key: key);

  final List<HourlyPoint> points;
  final int timezoneOffsetSeconds;

  String _localHour(int dt) => _tickFormat
      .format(DateTime.fromMillisecondsSinceEpoch(
          (dt + timezoneOffsetSeconds) * 1000,
          isUtc: true))
      .toLowerCase();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<HourlyPoint> shown = points.take(24).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    final int peak = shown.map((p) => p.percentage).reduce(max);
    return Semantics(
      label:
          'Hourly flight confidence for the next ${shown.length} hours, peaking at $peak percent.',
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
                        color: _barColor(context, shown[i].percentage),
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
                          i == 0 ? 'Now' : _localHour(shown[i].dt),
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

  Color _barColor(BuildContext context, int percentage) {
    final Verdict v = verdictFor(percentage);
    if (v == Verdict.unlikely) {
      // Low hours stay quiet — a muted neutral rather than alarm red.
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
    return verdictColors(context, v).fg;
  }
}
