import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/features/fleet/domain/rules/staleness_evaluator.dart';
import 'package:flutter/material.dart';

/// Renders a telemetry value with optional stale caption.
///
/// Colors and styles come from [VerdictTheme] on the ambient [ThemeData].
class VerdictPill extends StatelessWidget {
  /// Creates a [VerdictPill].
  const VerdictPill({
    required this.verdict,
    required this.value,
    required this.unit,
    required this.age,
    this.fractionDigits,
    super.key,
  });

  /// Freshness/threshold verdict, or null when [value] is missing.
  final Verdict? verdict;

  /// Numeric reading, or null to show an em dash.
  final double? value;

  /// Unit suffix shown after [value] (e.g. `%`, `°C`).
  final String unit;

  /// Age of the reading; shown only for [Verdict.stale].
  final Duration age;

  /// When set, formats [value] with exactly this many digits after the decimal.
  final int? fractionDigits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<VerdictTheme>()!;
    final reading = value;

    if (reading == null) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: theme.missingValueColor,
              fontWeight: FontWeight.w700,
            ),
      );
    }

    final resolved = verdict ?? Verdict.normal;
    final valueLabel = '${_formatValue(reading, fractionDigits)} $unit';
    final valueText = Text(
      valueLabel,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: theme.valueColorFor(resolved),
            fontWeight: FontWeight.w700,
          ),
    );

    if (resolved != Verdict.stale) {
      return valueText;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        valueText,
        Text(
          'data ${age.inMinutes}m old',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme.staleCaptionColor,
              ),
        ),
      ],
    );
  }

  static String _formatValue(double value, int? fractionDigits) {
    if (fractionDigits != null) {
      return value.toStringAsFixed(fractionDigits);
    }
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
}
