import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/features/fleet/domain/rules/status_resolver.dart';
import 'package:flutter/material.dart';

/// Compact status pill for a [VehicleStatus].
///
/// Colors/labels come from [StatusChipTheme].
class StatusChip extends StatelessWidget {
  /// Creates a [StatusChip].
  const StatusChip({required this.status, super.key});

  /// Status to display.
  final VehicleStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<StatusChipTheme>()!;
    final foreground = theme.foregroundFor(status);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.backgroundFor(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              theme.labelFor(status),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
