import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/core/widgets/alert_badge.dart';
import 'package:byte_beam/core/widgets/outlined_card.dart';
import 'package:byte_beam/core/widgets/status_chip.dart';
import 'package:byte_beam/core/widgets/verdict_pill.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:byte_beam/features/fleet/domain/rules/reading_bounds.dart';
import 'package:byte_beam/features/fleet/domain/rules/staleness_evaluator.dart';
import 'package:byte_beam/features/fleet/domain/rules/status_resolver.dart';
import 'package:flutter/material.dart';

/// Fleet list row for a single [Vehicle].
class VehicleCard extends StatelessWidget {
  /// Creates a [VehicleCard].
  const VehicleCard({
    required this.vehicle,
    required this.status,
    required this.clock,
    this.alertCount = 0,
    this.alertSeverity,
    this.onTap,
    super.key,
  });

  /// Vehicle to display.
  final Vehicle vehicle;

  /// Precomputed operational status (no logic in the widget).
  final VehicleStatus status;

  /// Clock used for SOC/range honesty (§4) via [evaluateStaleness].
  final Clock clock;

  /// Active alert count for this vehicle (badge hidden when 0).
  final int alertCount;

  /// Severity used to color [AlertBadge] when [alertCount] > 0.
  final AlertSeverity? alertSeverity;

  /// Optional tap handler (e.g. navigate to detail).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final showBadge = alertCount > 0 && alertSeverity != null;

    final socVerdict = evaluateStaleness(vehicle.soc, kSocBounds, clock);
    final rangeVerdict = evaluateStaleness(vehicle.range, kRangeBounds, clock);

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
                  if (showBadge) ...[
                    AlertBadge(
                      count: alertCount,
                      severity: alertSeverity,
                    ),
                    const SizedBox(width: 8),
                  ],
                  StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ReadingColumn(
                      label: 'SOC',
                      pill: VerdictPill(
                        key: const Key('home-reading-soc'),
                        verdict: socVerdict,
                        value: vehicle.soc.value,
                        unit: '%',
                        age: vehicle.soc.age,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ReadingColumn(
                      label: 'Range',
                      pill: VerdictPill(
                        key: const Key('home-reading-range'),
                        verdict: rangeVerdict,
                        value: vehicle.range.value,
                        unit: 'km',
                        age: vehicle.range.age,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingColumn extends StatelessWidget {
  const _ReadingColumn({
    required this.label,
    required this.pill,
  });

  final String label;
  final VerdictPill pill;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        pill,
      ],
    );
  }
}
