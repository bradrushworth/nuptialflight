import 'package:flutter/material.dart';

import 'app_icons.dart';
import 'l10n_ext.dart';

/// The outcome of the report sheet: a sighting of a given size, an explicit
/// "I looked and saw nothing", or null when the user simply cancelled.
class ReportResult {
  const ReportResult.sighting(this.size) : sawNothing = false;
  const ReportResult.noFlight()
      : size = null,
        sawNothing = true;

  /// 'small' | 'medium' | 'large' for a sighting; null for a no-flight report.
  final String? size;
  final bool sawNothing;
}

/// Opens the report bottom sheet. Cancel is a plain dismissal (returns null),
/// clearly separated from the explicit "I looked — no flights" observation —
/// the old dialog conflated the two.
Future<ReportResult?> showReportSheet(BuildContext context,
    {required String locationLabel}) {
  return showModalBottomSheet<ReportResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      String? selected;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final ColorScheme scheme = Theme.of(context).colorScheme;
          final AppLocalizations t = context.l10n;
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, 22 + MediaQuery.of(context).viewPadding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.reportTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  t.reportBlurb,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _SizeOption(
                      label: t.reportSmall,
                      sublabel: t.reportAbout10mm,
                      iconSize: 18,
                      selected: selected == 'small',
                      onTap: () => setSheetState(() => selected = 'small'),
                    ),
                    const SizedBox(width: 10),
                    _SizeOption(
                      label: t.reportMedium,
                      sublabel: t.reportAbout20mm,
                      iconSize: 26,
                      selected: selected == 'medium',
                      onTap: () => setSheetState(() => selected = 'medium'),
                    ),
                    const SizedBox(width: 10),
                    _SizeOption(
                      label: t.reportLarge,
                      sublabel: t.reportAbout30mm,
                      iconSize: 34,
                      selected: selected == 'large',
                      onTap: () => setSheetState(() => selected = 'large'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.place_outlined,
                        size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.reportingFrom(locationLabel),
                        style: TextStyle(
                            fontSize: 12.5, color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.of(context)
                          .pop(ReportResult.sighting(selected)),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  child: Text(t.submitSighting),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context)
                            .pop(const ReportResult.noFlight()),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: Text(t.noFlightsButton),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: Text(t.cancel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _SizeOption extends StatelessWidget {
  const _SizeOption({
    required this.label,
    required this.sublabel,
    required this.iconSize,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final double iconSize;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label queen, $sublabel',
        excludeSemantics: true,
        child: Material(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 36,
                    child: Center(
                      child: Icon(
                        AppIcons.wingedAnt,
                        size: iconSize,
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
