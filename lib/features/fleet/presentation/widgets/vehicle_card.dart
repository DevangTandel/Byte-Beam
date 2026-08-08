import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/core/widgets/outlined_card.dart';
import 'package:byte_beam/core/widgets/status_chip.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:byte_beam/features/fleet/domain/rules/status_resolver.dart';
import 'package:flutter/material.dart';

/// Fleet list row for a single [Vehicle].
class VehicleCard extends StatelessWidget {
  /// Creates a [VehicleCard].
  const VehicleCard({
    required this.vehicle,
    required this.status,
    this.onTap,
    super.key,
  });

  /// Vehicle to display.
  final Vehicle vehicle;

  /// Precomputed operational status (no logic in the widget).
  final VehicleStatus status;

  /// Optional tap handler (e.g. navigate to detail).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final verdictTheme = Theme.of(context).extension<VerdictTheme>()!;
    final soc = vehicle.soc.value;

    return OutlinedCard(
      color: colorScheme.outlineVariant,
      backgroundColor: colorScheme.surface,
      cornerRadius: 16,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.reg,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${vehicle.model} · ${vehicle.vin}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  StatusChip(status: status),
                ],
              ),
              if (soc != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.battery_charging_full,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (soc.clamp(0, 100)) / 100,
                          minHeight: 8,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          color: verdictTheme.normalValueColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${soc.round()}%',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
