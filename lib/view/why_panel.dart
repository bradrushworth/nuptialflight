import 'package:flutter/material.dart';

import 'verdict.dart';

/// One of the top drivers behind today's forecast, shown as a chip in the
/// "Why?" row. [direction] is +1 (helps), 0 (neutral) or -1 (hurts).
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
          'Why this forecast? ${drivers.map((d) => '${d.label} ${d.direction > 0 ? 'helps' : d.direction < 0 ? 'hurts' : 'neutral'}').join(', ')}.',
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
                  'Why?',
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
    final VerdictColors c = d.direction > 0
        ? verdictColors(context, Verdict.likely)
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

/// Opens the full "Why this forecast?" sheet: current conditions, one
/// partial-dependence sparkline per weather attribute with today's value
/// marked, and the per-size seasonal likelihoods.
Future<void> showWhySheet(
  BuildContext context, {
  required List<String> conditions,
  required List<WhyFeature> features,
  required Map<String, int> sizePercentages,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final ColorScheme scheme = Theme.of(context).colorScheme;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Text(
                'Why this forecast?',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
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
              const SizedBox(height: 14),
              Text(
                'Each curve is what the model learned about one condition. '
                'The dot marks right now — high on the curve means that '
                'condition is helping today\'s forecast.',
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
                'Which size is in season?',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Different queen sizes peak in different months. Relative to '
                'today\'s overall confidence:',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              _SizeSeasonRow(
                  label: 'Small (~10 mm)',
                  percentage: sizePercentages['small'] ?? 0),
              _SizeSeasonRow(
                  label: 'Medium (~20 mm)',
                  percentage: sizePercentages['medium'] ?? 0),
              _SizeSeasonRow(
                  label: 'Large (~30 mm)',
                  percentage: sizePercentages['large'] ?? 0),
              const SizedBox(height: 16),
              Text(
                'Curves are the trained model\'s marginal response, not fixed '
                'rules — they update when the model is retrained on new '
                'sighting reports.',
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
    if (v >= 0.62) {
      return _Tag('Helps today', verdictColors(context, Verdict.likely));
    }
    if (v >= 0.54) {
      return _Tag('Slightly helps', verdictColors(context, Verdict.likely));
    }
    if (v > 0.46) {
      final ColorScheme scheme = Theme.of(context).colorScheme;
      return _Tag(
        'No strong effect',
        VerdictColors(scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
      );
    }
    if (v > 0.38) {
      return _Tag('Hurts a little', verdictColors(context, Verdict.possible));
    }
    return _Tag('Hurts today', verdictColors(context, Verdict.unlikely));
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
