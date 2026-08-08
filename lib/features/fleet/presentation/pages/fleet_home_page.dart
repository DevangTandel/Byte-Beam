import 'package:byte_beam/core/widgets/empty_state.dart';
import 'package:byte_beam/core/widgets/filter_chip_bar.dart';
import 'package:byte_beam/features/alerts/presentation/bloc/alerts_cubit.dart';
import 'package:byte_beam/features/fleet/presentation/bloc/fleet_bloc.dart';
import 'package:byte_beam/features/fleet/presentation/widgets/vehicle_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Fleet home: filter chips + vehicle list (or empty state).
///
/// Domain decisions (status, SOC/range verdicts, alert badges) come from
/// [FleetBloc] / [AlertsCubit] — this page only composes UI.
class FleetHomePage extends StatelessWidget {
  /// Creates a [FleetHomePage].
  const FleetHomePage({super.key});

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
                      child: fleetState.items.isEmpty
                          ? const EmptyState(
                              title: 'No vehicles',
                              message:
                                  '''Nothing matches this filter. Try another status.''',
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  for (final item in fleetState.items)
                                    _vehicleCard(context, item, alertsState),
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
    FleetListItem item,
    AlertsState alertsState,
  ) {
    final badge = alertsState.badgeSummaryFor(item.vehicle.vin);
    return VehicleCard(
      vehicle: item.vehicle,
      status: item.status,
      socVerdict: item.socVerdict,
      rangeVerdict: item.rangeVerdict,
      alertCount: badge.count,
      alertSeverity: badge.severity,
      onTap: () => context.push('/vehicle/${item.vehicle.vin}'),
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
