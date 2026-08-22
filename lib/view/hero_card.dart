import 'package:flutter/material.dart';

import '../controller/flight_index.dart';
import 'l10n_ext.dart';
import 'verdict.dart';

/// The single answer to "should I go out looking?": the Ant Flight Index
/// band (a UV-index-style rating relative to days at this latitude and time
/// of year), the honest odds ("1 in N days like this see a reported
/// flight"), and the action to take. Raw model scores are demoted to the
/// "Why?" sheet — a bare percentage told users nothing.
class HeroVerdictCard extends StatelessWidget {
  const HeroVerdictCard({
    Key? key,
    required this.band,
    required this.oneInN,
    required this.dateLine,
    required this.conditionLine,
    this.bestWindow,
    this.sizeLine,
  }) : super(key: key);

  final FlightBand band;

  /// Calibrated odds denominator: 1 in [oneInN] days like this get a
  /// reported flight.
  final int oneInN;

  /// e.g. "Today · Sat 17 Jan"
  final String dateLine;

  /// e.g. "Partly cloudy · 27°C"
  final String conditionLine;

  /// e.g. "Best window 4pm–7pm" (null when no window stands out).
  final String? bestWindow;

  /// e.g. "Likely small species" (null when latitude unknown).
  final String? sizeLine;

  @override
  Widget build(BuildContext context) {
    final VerdictColors c = bandColors(context, band);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations t = context.l10n;
    final bool showOdds = band != FlightBand.noFly;

    return Semantics(
      label: '${bandHeadlineOf(t, band)}. ${bandActionOf(t, band)}.'
          '${showOdds ? ' ${t.honestyOdds(oneInN)}' : ''}'
          '${bestWindow != null ? ' $bestWindow.' : ''}'
          '${sizeLine != null ? ' $sizeLine.' : ''}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateLine.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: c.fg.withValues(alpha: 0.75),
                  ),
                ),
                Flexible(
                  child: Text(
                    conditionLine,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.fg.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bandHeadlineOf(t, band),
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                  height: 1.05,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bandActionOf(t, band),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: c.fg,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showOdds) ...[
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        t.oneInN(oneInN),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: c.fg,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                      ),
                      Text(
                        t.daysLikeThisSeeFlights,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.2,
                          color: c.fg.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (bestWindow != null || sizeLine != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (bestWindow != null)
                    _chip(context, c, Icons.schedule, bestWindow!),
                  if (sizeLine != null)
                    _chip(context, c, Icons.bug_report_outlined, sizeLine!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(
      BuildContext context, VerdictColors c, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: c.fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.fg,
            ),
          ),
        ],
      ),
    );
  }
}
