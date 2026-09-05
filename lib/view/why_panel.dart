import 'package:flutter/material.dart';

import 'l10n_ext.dart';
import 'verdict.dart';

/// One of the top drivers behind today's forecast, shown as a chip in the
/// "Why?" row. [direction] is +1 (helps), 0 (neutral), -1 (hurts a little) or
/// -2 (hurts strongly) — the same severity scale the detail sheet's tags use,
/// so chip and tag colours always agree.
class WhyDriver {
  const WhyDriver({required this.label, required this.direction});

  final String label;
  final int direction;
}

/// One weather attribute in the "Why this forecast?" sheet: the model's
/// partial-dependence curve for it (via [fn], the same gauge functions the
/// scoring code uses) plus today's value.
class WhyFeature {
  const WhyFeature({
    required this.name,
    required this.note,
    required this.fn,
    required this.lo,
    required this.hi,
    required this.current,
  });

  final String name;
  final String note;
  final double Function(num value) fn;
  final double lo;
  final double hi;
  final double current;
}

/// The tappable "Why?" strip on the home page: the three strongest drivers of
/// today's forecast with their direction, leading into the full sheet.
class WhyChipsRow extends StatelessWidget {
  const WhyChipsRow({Key? key, required this.drivers, required this.onTap})
      : super(key: key);

  final List<WhyDriver> drivers;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label:
          '${context.l10n.whyTitle} ${drivers.map((d) => d.label).join(', ')}.',
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Text(
                  context.l10n.whyShort,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  // Scrolls when the three chips outgrow a narrow phone width
                  // instead of overflowing.
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final WhyDriver d in drivers) ...[
                          _driverChip(context, d),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 20, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _driverChip(BuildContext context, WhyDriver d) {
    // Mirrors _FeatureCard._tagFor: green = helps, amber = hurts a little,
    // red = hurts strongly, neutral grey otherwise.
    final VerdictColors c = d.direction > 0
        ? verdictColors(context, Verdict.likely)
        : d.direction <= -2
            ? verdictColors(context, Verdict.unlikely)
            : d.direction < 0
                ? verdictColors(context, Verdict.possible)
                : VerdictColors(
                    Theme.of(context).colorScheme.onSurfaceVariant,
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                  );
    final String arrow = d.direction > 0 ? '↑' : d.direction < 0 ? '↓' : '·';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${d.label} $arrow',
        maxLines: 1,
        softWrap: false,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.fg),
      ),
    );
  }
}

/// Opens the full "Why this forecast?" sheet: that day's conditions, one
/// partial-dependence sparkline per weather attribute with the day's value
/// marked, and the per-size seasonal likelihoods.
///
/// [dayLabel] names the day the sheet is about (already formatted for the
/// locale, e.g. "Tue 8 Sep"). It is what tells a reader that a sheet opened
/// from an upcoming-week row is not about today; omit it for today.
Future<void> showWhySheet(
  BuildContext context, {
  required List<String> conditions,
  required List<WhyFeature> features,
  required Map<String, int> sizePercentages,
  List<String> honesty = const <String>[],
  String? dayLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final ColorScheme scheme = Theme.of(context).colorScheme;
      final AppLocalizations t = context.l10n;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            // Pad past the Android system navigation bar (edge-to-edge), or
            // the last rows hide underneath it — same treatment as the
            // report sheet.
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, 24 + MediaQuery.of(context).viewPadding.bottom),
            children: [
              Text(
                t.whyTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (dayLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  dayLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final String c in conditions)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              if (honesty.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final String line in honesty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            line,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                t.whyExplainer,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              for (final WhyFeature f in features) ...[
                _FeatureCard(feature: f),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              Text(
                t.sizeSeasonTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                t.sizeSeasonExplainer,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              _SizeSeasonRow(
                  label: t.sizeRowSmall,
                  percentage: sizePercentages['small'] ?? 0),
              _SizeSeasonRow(
                  label: t.sizeRowMedium,
                  percentage: sizePercentages['medium'] ?? 0),
              _SizeSeasonRow(
                  label: t.sizeRowLarge,
                  percentage: sizePercentages['large'] ?? 0),
              const SizedBox(height: 16),
              Text(
                t.whyFooter,
                style: TextStyle(fontSize: 11.5, color: scheme.outline),
              ),
            ],
          );
        },
      );
    },
  );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final WhyFeature feature;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double v = feature.fn(feature.current);
    final _Tag tag = _tagFor(context, v);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        feature.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: tag.colors.bg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tag.colors.fg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  feature.note,
                  style: TextStyle(
                      fontSize: 12.5, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          CustomPaint(
            size: const Size(118, 44),
            painter: _PdSparklinePainter(
              fn: feature.fn,
              lo: feature.lo,
              hi: feature.hi,
              current: feature.current,
              lineColor: scheme.outline,
              dotColor: tag.colors.fg,
              dotRing: scheme.surface,
            ),
          ),
        ],
      ),
    );
  }

  _Tag _tagFor(BuildContext context, double v) {
    final AppLocalizations t = context.l10n;
    if (v >= 0.62) {
      return _Tag(t.tagHelps, verdictColors(context, Verdict.likely));
    }
    if (v >= 0.54) {
      return _Tag(t.tagSlightlyHelps, verdictColors(context, Verdict.likely));
    }
    if (v > 0.46) {
      final ColorScheme scheme = Theme.of(context).colorScheme;
      return _Tag(
        t.tagNeutral,
        VerdictColors(scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
      );
    }
    if (v > 0.38) {
      return _Tag(t.tagHurtsALittle, verdictColors(context, Verdict.possible));
    }
    return _Tag(t.tagHurts, verdictColors(context, Verdict.unlikely));
  }
}

class _Tag {
  const _Tag(this.label, this.colors);

  final String label;
  final VerdictColors colors;
}

class _SizeSeasonRow extends StatelessWidget {
  const _SizeSeasonRow({required this.label, required this.percentage});

  final String label;
  final int percentage;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: percentage / 100.0,
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHighest,
                color: scheme.primary,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$percentage%',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws one partial-dependence curve by sampling [fn] across [lo]..[hi],
/// normalised to the curve's own min/max, with a dot at [current].
class _PdSparklinePainter extends CustomPainter {
  _PdSparklinePainter({
    required this.fn,
    required this.lo,
    required this.hi,
    required this.current,
    required this.lineColor,
    required this.dotColor,
    required this.dotRing,
  });

  final double Function(num value) fn;
  final double lo;
  final double hi;
  final double current;
  final Color lineColor;
  final Color dotColor;
  final Color dotRing;

  static const int _samples = 25;

  @override
  void paint(Canvas canvas, Size size) {
    final List<double> ys = List<double>.generate(_samples, (i) {
      final double x = lo + (hi - lo) * i / (_samples - 1);
      return fn(x);
    });

    const double padX = 4;
    const double padY = 6;
    double toX(int i) =>
        padX + (size.width - 2 * padX) * i / (_samples - 1);
    // Gauge values are already normalised 0..1 (0.5 = the model is
    // indifferent), so map that range directly; flat curves draw mid-height.
    double toY(double v) =>
        size.height - padY - (size.height - 2 * padY) * v.clamp(0.0, 1.0);

    final Path path = Path()..moveTo(toX(0), toY(ys[0]));
    for (int i = 1; i < _samples; i++) {
      path.lineTo(toX(i), toY(ys[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = lineColor,
    );

    final double t =
        ((current - lo) / (hi - lo)).clamp(0.0, 1.0).toDouble();
    final double dx = padX + (size.width - 2 * padX) * t;
    final double dy = toY(fn(current));
    canvas.drawCircle(Offset(dx, dy), 6, Paint()..color = dotRing);
    canvas.drawCircle(Offset(dx, dy), 4.5, Paint()..color = dotColor);
  }

  @override
  bool shouldRepaint(covariant _PdSparklinePainter old) =>
      old.current != current ||
      old.lo != lo ||
      old.hi != hi ||
      old.lineColor != lineColor ||
      old.dotColor != dotColor;
}
