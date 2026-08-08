import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/core/widgets/outlined_card.dart';
import 'package:byte_beam/core/widgets/status_chip.dart';
import 'package:byte_beam/core/widgets/verdict_pill.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:byte_beam/features/alerts/presentation/bloc/alerts_cubit.dart';
import 'package:byte_beam/features/alerts/presentation/widgets/reason_sheet.dart';
import 'package:byte_beam/features/alerts/presentation/widgets/undo_snackbar.dart';
import 'package:byte_beam/features/fleet/domain/entities/reading.dart';
import 'package:byte_beam/features/fleet/domain/rules/staleness_evaluator.dart';
import 'package:byte_beam/features/vehicle_detail/presentation/bloc/vehicle_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Vehicle detail screen: readings register, alerts, dismiss / undo.
class VehicleDetailPage extends StatelessWidget {
  /// Creates a [VehicleDetailPage].
  const VehicleDetailPage({required this.clock, super.key});

  /// Clock used for last-ping age display.
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        title: Text(
          'Vehicle detail',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: BlocBuilder<VehicleDetailBloc, VehicleDetailState>(
        builder: (context, state) {
          if (state is! VehicleDetailLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicle = state.vehicle;
          // Floor to whole seconds — ages never round up.
          final lastPingAge = Duration(
            seconds: clock.now().difference(vehicle.lastPingAt).inSeconds,
          );
          final lastPingVerdict = lastPingAge > kStaleThreshold
              ? Verdict.stale
              : Verdict.normal;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedCard(
                  color: colorScheme.outlineVariant,
                  backgroundColor: colorScheme.surface,
                  cornerRadius: 16,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              vehicle.reg,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          StatusChip(status: state.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${vehicle.model} · ${vehicle.vin}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Alerts',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (state.alerts.isEmpty)
                  OutlinedCard(
                    color: colorScheme.outlineVariant,
                    backgroundColor: colorScheme.surface,
                    cornerRadius: 16,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 22,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'No active alerts',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final alert in state.alerts) ...[
                    _AlertTile(
                      alert: alert,
                      onDismiss: () => _dismissAlert(context, alert),
                    ),
                    const SizedBox(height: 8),
                  ],
                const SizedBox(height: 20),
                Text(
                  'Readings',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ReadingMetricCard(
                        label: 'SOC',
                        pill: VerdictPill(
                          key: const Key('reading-soc'),
                          verdict: state.verdicts.soc,
                          value: vehicle.soc.value,
                          unit: '%',
                          age: vehicle.soc.age,
                          fractionDigits: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ReadingMetricCard(
                        label: 'Range',
                        pill: VerdictPill(
                          key: const Key('reading-range'),
                          verdict: state.verdicts.range,
                          value: vehicle.range.value,
                          unit: 'km',
                          age: vehicle.range.age,
                          fractionDigits: 2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ReadingMetricCard(
                        label: 'Speed',
                        pill: VerdictPill(
                          key: const Key('reading-speed'),
                          verdict: state.verdicts.speed,
                          value: vehicle.speed.value,
                          unit: 'km/h',
                          age: vehicle.speed.age,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ReadingMetricCard(
                        label: 'Battery temp',
                        pill: VerdictPill(
                          key: const Key('reading-batteryTemp'),
                          verdict: state.verdicts.batteryTemp,
                          value: vehicle.batteryTemp.value,
                          unit: '°C',
                          age: vehicle.batteryTemp.age,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ReadingMetricCard(
                  label: 'Odometer',
                  pill: VerdictPill(
                    key: const Key('reading-odometer'),
                    verdict: state.verdicts.odometer,
                    value: vehicle.odometer.value,
                    unit: 'km',
                    age: vehicle.odometer.age,
                    fractionDigits: 2,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedCard(
                  color: colorScheme.outlineVariant,
                  backgroundColor: colorScheme.surface,
                  cornerRadius: 16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Last ping',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      VerdictPill(
                        key: const Key('reading-lastPing'),
                        verdict: lastPingVerdict,
                        value: lastPingAge.inMinutes.toDouble(),
                        unit: 'm ago',
                        age: lastPingAge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _dismissAlert(BuildContext context, Alert alert) async {
    final reason = await ReasonSheet.show(context);
    if (reason == null || !context.mounted) {
      return;
    }

    context.read<AlertsCubit>().dismiss(alert.id, reason);

    UndoSnackbar.show(
      context,
      onUndo: () => context.read<AlertsCubit>().undo(),
    );
  }
}

class _ReadingMetricCard extends StatelessWidget {
  const _ReadingMetricCard({
    required this.label,
    required this.pill,
  });

  final String label;
  final VerdictPill pill;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return OutlinedCard(
      color: colorScheme.outlineVariant,
      backgroundColor: colorScheme.surface,
      cornerRadius: 16,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          pill,
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.alert,
    required this.onDismiss,
  });

  final Alert alert;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alertTheme = Theme.of(context).extension<AlertBadgeTheme>()!;
    final title = switch (alert.kind) {
      AlertKind.lowBattery => 'Low battery',
      AlertKind.batteryOverheating => 'Battery overheating',
    };

    return OutlinedCard(
      color: colorScheme.outlineVariant,
      backgroundColor: colorScheme.surface,
      cornerRadius: 16,
      child: ListTile(
        leading: Icon(
          Icons.warning_rounded,
          size: 24,
          color: alertTheme.foregroundFor(alert.severity),
        ),
        title: Text(title),
        subtitle: Text(
          alert.isBasedOnStaleData
              ? '${alert.severity.name.toUpperCase()} · based on old data'
              : alert.severity.name.toUpperCase(),
        ),
        trailing: TextButton(
          onPressed: onDismiss,
          child: const Text('Dismiss'),
        ),
      ),
    );
  }
}
