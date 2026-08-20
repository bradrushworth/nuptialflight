import 'package:flutter/material.dart';

import 'verdict.dart';

/// The single answer to "should I go out looking?": today's verdict, the
/// percentage, and (when known) the best flight window and most likely queen
/// size. Replaces the old three-tile row + whole-app colour retint — the
/// verdict colour lives only inside this card.
class HeroVerdictCard extends StatelessWidget {
  const HeroVerdictCard({
    Key? key,
    required this.percentage,
    required this.dateLine,
    required this.conditionLine,
    this.bestWindow,
    this.sizeLine,
  }) : super(key: key);

  final int percentage;

  /// e.g. "Today · Sat 17 Jan"
  final String dateLine;

  /// e.g. "Partly cloudy · 27.2°C"
  final String conditionLine;

  /// e.g. "Best window 4pm–7pm" (null when no window clears the bar).
  final String? bestWindow;

  /// e.g. "Likely small species" (null when latitude unknown).
  final String? sizeLine;

  @override
  Widget build(BuildContext context) {
    final Verdict v = verdictFor(percentage);
    final VerdictColors c = verdictColors(context, v);
    final String headline = () {
      switch (v) {
        case Verdict.likely:
          return 'Flight likely';
        case Verdict.possible:
          return 'Flight possible';
        case Verdict.unlikely:
          return 'Flight unlikely';
      }
    }();
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Semantics(
      label:
          'Nuptial flight ${verdictLabel(v).toLowerCase()} today, $percentage percent confidence.'
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
                Flexible(
                  child: Text(
                    headline,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                          height: 1.05,
                        ),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.fg,
                      ),
                ),
              ],
            ),
            if (bestWindow != null || sizeLine != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (bestWindow != null)
                    _chip(context, Icons.schedule, bestWindow!),
                  if (sizeLine != null)
                    _chip(context, Icons.bug_report_outlined, sizeLine!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    final Verdict v = verdictFor(percentage);
    final VerdictColors c = verdictColors(context, v);
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
