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
    final soc = vehicle.soc.value;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(vehicle.reg, style: textTheme.titleMedium),
        subtitle: Text(
          '${vehicle.model} · ${vehicle.vin}',
          style: textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (soc != null) ...[
              Text(
                '${soc.round()}%',
                style: textTheme.labelLarge,
              ),
              const SizedBox(width: 8),
            ],
            StatusChip(status: status),
          ],
        ),
      ),
    );
  }
}
