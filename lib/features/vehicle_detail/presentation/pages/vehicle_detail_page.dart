import 'package:byte_beam/core/clock/clock.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle detail')),
      body: BlocBuilder<VehicleDetailBloc, VehicleDetailState>(
        builder: (context, state) {
          if (state is! VehicleDetailLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicle = state.vehicle;
          final lastPingAge = clock.now().difference(vehicle.lastPingAt);
          final lastPingVerdict = lastPingAge > kStaleThreshold
              ? Verdict.stale
              : Verdict.normal;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  vehicle.reg,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text('${vehicle.model} · ${vehicle.vin}'),
                const SizedBox(height: 8),
                StatusChip(status: state.status),
                const SizedBox(height: 24),
                Text(
                  'Alerts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (state.alerts.isEmpty)
                  Text(
                    'No active alerts',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  for (final alert in state.alerts)
                    _AlertTile(
                      alert: alert,
                      onDismiss: () => _dismissAlert(context, alert),
                    ),
                const SizedBox(height: 24),
                Text(
                  'Readings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _ReadingRow(
                  keyLabel: 'SOC',
                  pill: VerdictPill(
                    key: const Key('reading-soc'),
                    verdict: state.verdicts.soc,
                    value: vehicle.soc.value,
                    unit: '%',
                    age: vehicle.soc.age,
                  ),
                ),
                _ReadingRow(
                  keyLabel: 'Range',
                  pill: VerdictPill(
                    key: const Key('reading-range'),
                    verdict: state.verdicts.range,
                    value: vehicle.range.value,
                    unit: 'km',
                    age: vehicle.range.age,
                  ),
                ),
                _ReadingRow(
                  keyLabel: 'Speed',
                  pill: VerdictPill(
                    key: const Key('reading-speed'),
                    verdict: state.verdicts.speed,
                    value: vehicle.speed.value,
                    unit: 'km/h',
                    age: vehicle.speed.age,
                  ),
                ),
                _ReadingRow(
                  keyLabel: 'Battery temp',
                  pill: VerdictPill(
                    key: const Key('reading-batteryTemp'),
                    verdict: state.verdicts.batteryTemp,
                    value: vehicle.batteryTemp.value,
                    unit: '°C',
                    age: vehicle.batteryTemp.age,
                  ),
                ),
                _ReadingRow(
                  keyLabel: 'Odometer',
                  pill: VerdictPill(
                    key: const Key('reading-odometer'),
                    verdict: state.verdicts.odometer,
                    value: vehicle.odometer.value,
                    unit: 'km',
                    age: vehicle.odometer.age,
                  ),
                ),
                _ReadingRow(
                  keyLabel: 'Last ping',
                  pill: VerdictPill(
                    key: const Key('reading-lastPing'),
                    verdict: lastPingVerdict,
                    value: lastPingAge.inMinutes.toDouble(),
                    unit: 'm ago',
                    age: lastPingAge,
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

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({
    required this.keyLabel,
    required this.pill,
  });

  final String keyLabel;
  final VerdictPill pill;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(keyLabel),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: pill,
            ),
          ),
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
    final title = switch (alert.kind) {
      AlertKind.lowBattery => 'Low battery',
      AlertKind.batteryOverheating => 'Battery overheating',
    };

    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(alert.severity.name),
        trailing: TextButton(
          onPressed: onDismiss,
          child: const Text('Dismiss'),
        ),
      ),
    );
  }
}
