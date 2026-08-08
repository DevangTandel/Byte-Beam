import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:flutter/material.dart';

/// Count badge colored by [AlertSeverity].
///
/// Colors come from [AlertBadgeTheme].
class AlertBadge extends StatelessWidget {
  /// Creates an [AlertBadge].
  const AlertBadge({
    required this.count,
    required this.severity,
    super.key,
  });

  /// Number of alerts to show.
  final int count;

  /// Highest / representative severity for coloring.
  final AlertSeverity severity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AlertBadgeTheme>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.backgroundFor(severity),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          '$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: theme.foregroundFor(severity),
              ),
        ),
      ),
    );
  }
}
