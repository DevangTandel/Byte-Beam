import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/features/fleet/domain/rules/staleness_evaluator.dart';
import 'package:flutter/material.dart';

/// Renders a telemetry value with optional verdict pill / stale caption.
///
/// Colors and styles come from [VerdictTheme] on the ambient [ThemeData].
class VerdictPill extends StatelessWidget {
  /// Creates a [VerdictPill].
  const VerdictPill({
    required this.verdict,
    required this.value,
    required this.unit,
    required this.age,
    super.key,
  });

  /// Freshness/threshold verdict, or null when [value] is missing.
  final Verdict? verdict;

  /// Numeric reading, or null to show an em dash (no pill).
  final double? value;

  /// Unit suffix shown after [value] (e.g. `%`, `°C`).
  final String unit;

  /// Age of the reading; shown only for [Verdict.stale].
  final Duration age;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<VerdictTheme>()!;
    final reading = value;

    if (reading == null) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: theme.missingValueColor,
            ),
      );
    }

    final resolved = verdict ?? Verdict.normal;
    final valueLabel = '${_formatValue(reading)} $unit';
    final valueText = Text(
      valueLabel,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: theme.valueColorFor(resolved),
          ),
    );

    final children = <Widget>[valueText];
    if (resolved == Verdict.stale) {
      children.add(
        Text(
          'data ${age.inMinutes}m old',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme.staleCaptionColor,
              ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.pillColorFor(resolved),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  static String _formatValue(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
}
