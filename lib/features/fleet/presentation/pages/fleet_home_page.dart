import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/core/widgets/empty_state.dart';
import 'package:byte_beam/core/widgets/filter_chip_bar.dart';
import 'package:byte_beam/features/fleet/domain/rules/status_resolver.dart';
import 'package:byte_beam/features/fleet/presentation/bloc/fleet_bloc.dart';
import 'package:byte_beam/features/fleet/presentation/widgets/vehicle_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      body: BlocBuilder<FleetBloc, FleetState>(
        builder: (context, state) {
          if (state is! FleetLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: FilterChipBar<FleetFilter>(
                  options: FleetFilter.values,
                  counts: {
                    FleetFilter.all: state.counts.all,
                    FleetFilter.moving: state.counts.moving,
                    FleetFilter.idle: state.counts.idle,
                    FleetFilter.stopped: state.counts.stopped,
                    FleetFilter.offline: state.counts.offline,
                  },
                  selected: state.filter,
                  labelBuilder: _labelFor,
                  onChanged: (filter) {
                    context.read<FleetBloc>().add(FilterChanged(filter));
                  },
                ),
              ),
              Expanded(
                child: state.vehicles.isEmpty
                    ? const EmptyState(
                        title: 'No vehicles',
                        message:
                            'Nothing matches this filter. Try another status.',
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final vehicle in state.vehicles)
                              VehicleCard(
                                vehicle: vehicle,
                                status: resolveStatus(vehicle, clock),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
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
