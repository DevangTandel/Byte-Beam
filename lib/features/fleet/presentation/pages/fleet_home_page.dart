import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/core/widgets/empty_state.dart';
import 'package:byte_beam/core/widgets/filter_chip_bar.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:byte_beam/features/alerts/presentation/bloc/alerts_cubit.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:byte_beam/features/fleet/domain/rules/status_resolver.dart';
import 'package:byte_beam/features/fleet/presentation/bloc/fleet_bloc.dart';
import 'package:byte_beam/features/fleet/presentation/widgets/vehicle_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Fleet home: filter chips + vehicle list (or empty state).
class FleetHomePage extends StatelessWidget {
  /// Creates a [FleetHomePage].
  const FleetHomePage({required this.clock, super.key});

  /// Clock used to resolve [VehicleStatus] for list cards.
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet')),
      body: SafeArea(
        child: BlocBuilder<FleetBloc, FleetState>(
          builder: (context, fleetState) {
            if (fleetState is! FleetLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            return BlocBuilder<AlertsCubit, AlertsState>(
              builder: (context, alertsState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: FilterChipBar<FleetFilter>(
                        options: FleetFilter.values,
                        counts: {
                          FleetFilter.all: fleetState.counts.all,
                          FleetFilter.moving: fleetState.counts.moving,
                          FleetFilter.idle: fleetState.counts.idle,
                          FleetFilter.stopped: fleetState.counts.stopped,
                          FleetFilter.offline: fleetState.counts.offline,
                        },
                        selected: fleetState.filter,
                        labelBuilder: _labelFor,
                        onChanged: (filter) {
                          context.read<FleetBloc>().add(FilterChanged(filter));
                        },
                      ),
                    ),
                    Expanded(
                      child: fleetState.vehicles.isEmpty
                          ? const EmptyState(
                              title: 'No vehicles',
                              message:
                                  'Nothing matches this filter. Try another status.',
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  for (final vehicle in fleetState.vehicles)
                                    _vehicleCard(
                                      context,
                                      vehicle,
                                      alertsState.active,
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _vehicleCard(
    BuildContext context,
    Vehicle vehicle,
    List<Alert> activeAlerts,
  ) {
    final summary = _alertSummaryForVin(activeAlerts, vehicle.vin);
    return VehicleCard(
      vehicle: vehicle,
      status: resolveStatus(vehicle, clock),
      alertCount: summary.count,
      alertSeverity: summary.severity,
      onTap: () => context.push('/vehicle/${vehicle.vin}'),
    );
  }

  static String _labelFor(FleetFilter filter) {
    return switch (filter) {
      FleetFilter.all => 'All',
      FleetFilter.moving => 'Moving',
      FleetFilter.idle => 'Idle',
      FleetFilter.stopped => 'Stopped',
      FleetFilter.offline => 'Offline',
    };
  }
}

/// Per-vin alert count and worst severity for [VehicleCard].
({int count, AlertSeverity? severity}) _alertSummaryForVin(
  List<Alert> active,
  String vin,
) {
  var count = 0;
  var hasCritical = false;

  for (final alert in active) {
    if (alert.vin != vin) {
      continue;
    }
    count++;
    if (alert.severity == AlertSeverity.critical) {
      hasCritical = true;
    }
  }

  if (count == 0) {
    return (count: 0, severity: null);
  }

  return (
    count: count,
    severity: hasCritical ? AlertSeverity.critical : AlertSeverity.warning,
  );
}
