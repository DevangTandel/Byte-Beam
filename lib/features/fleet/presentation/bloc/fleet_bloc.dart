import 'dart:async';

import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:byte_beam/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:byte_beam/features/fleet/domain/rules/reading_bounds.dart';
import 'package:byte_beam/features/fleet/domain/rules/staleness_evaluator.dart';
import 'package:byte_beam/features/fleet/domain/rules/status_resolver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Chip / list filter for the fleet screen.
enum FleetFilter {
  /// No status filter.
  all,

  /// [VehicleStatus.moving] only.
  moving,

  /// [VehicleStatus.idle] only.
  idle,

  /// [VehicleStatus.stopped] only.
  stopped,

  /// [VehicleStatus.offline] only.
  offline,
}

/// Live status tallies over the full (unfiltered) fleet.
class FleetStatusCounts {
  /// Creates [FleetStatusCounts].
  const FleetStatusCounts({
    required this.all,
    required this.moving,
    required this.idle,
    required this.stopped,
    required this.offline,
  });

  /// Total vehicles in the fleet snapshot.
  final int all;

  /// Count of [VehicleStatus.moving].
  final int moving;

  /// Count of [VehicleStatus.idle].
  final int idle;

  /// Count of [VehicleStatus.stopped].
  final int stopped;

  /// Count of [VehicleStatus.offline].
  final int offline;

  @override
  bool operator ==(Object other) {
    return other is FleetStatusCounts &&
        other.all == all &&
        other.moving == moving &&
        other.idle == idle &&
        other.stopped == stopped &&
        other.offline == offline;
  }

  @override
  int get hashCode => Object.hash(all, moving, idle, stopped, offline);
}

/// One fleet-list row with domain decisions already applied.
///
/// The home page binds these fields directly — it must not re-run
/// [resolveStatus] / [evaluateStaleness].
class FleetListItem {
  /// Creates a [FleetListItem].
  const FleetListItem({
    required this.vehicle,
    required this.status,
    required this.socVerdict,
    required this.rangeVerdict,
  });

  /// Underlying vehicle telemetry.
  final Vehicle vehicle;

  /// Precomputed operational status.
  final VehicleStatus status;

  /// Precomputed SOC honesty verdict (null → dash).
  final Verdict? socVerdict;

  /// Precomputed range honesty verdict (null → dash).
  final Verdict? rangeVerdict;
}

/// Fleet screen events.
sealed class FleetEvent {
  const FleetEvent();
}

/// Subscribe to repository telemetry and emit the first loaded state.
class FleetStarted extends FleetEvent {
  /// Creates a [FleetStarted] event.
  const FleetStarted();
}

/// User selected a status filter chip.
class FilterChanged extends FleetEvent {
  /// Creates a [FilterChanged] event.
  const FilterChanged(this.filter);

  /// Newly selected filter.
  final FleetFilter filter;
}

class _FleetUpdated extends FleetEvent {
  const _FleetUpdated(this.vehicles);

  final List<Vehicle> vehicles;
}

/// Fleet screen state.
sealed class FleetState {
  const FleetState();
}

/// Before the first telemetry emission.
class FleetInitial extends FleetState {
  /// Creates a [FleetInitial] state.
  const FleetInitial();
}

/// Telemetry-backed fleet UI state.
class FleetLoaded extends FleetState {
  /// Creates a [FleetLoaded] state.
  const FleetLoaded({
    required this.items,
    required this.filter,
    required this.counts,
  });

  /// Visible list rows under [filter] (status + verdicts precomputed).
  final List<FleetListItem> items;

  /// Active status filter.
  final FleetFilter filter;

  /// Live counts over the full unfiltered fleet.
  final FleetStatusCounts counts;
}

/// Manages fleet list projection, filtering, and live status counts.
class FleetBloc extends Bloc<FleetEvent, FleetState> {
  /// Creates a [FleetBloc].
  FleetBloc({
    required this._repository,
    required this._clock,
  }) : super(const FleetInitial()) {
    on<FleetStarted>(_onStarted);
    on<_FleetUpdated>(_onFleetUpdated);
    on<FilterChanged>(_onFilterChanged);
  }

  final FleetRepository _repository;
  final Clock _clock;

  StreamSubscription<List<Vehicle>>? _subscription;
  List<Vehicle> _allVehicles = const [];
  FleetFilter _filter = FleetFilter.all;

  Future<void> _onStarted(
    FleetStarted event,
    Emitter<FleetState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _repository.watchFleet().listen((vehicles) {
      if (isClosed) {
        return;
      }
      add(_FleetUpdated(vehicles));
    });
  }

  void _onFleetUpdated(
    _FleetUpdated event,
    Emitter<FleetState> emit,
  ) {
    _allVehicles = event.vehicles;
    emit(_toLoaded());
  }

  void _onFilterChanged(
    FilterChanged event,
    Emitter<FleetState> emit,
  ) {
    _filter = event.filter;
    emit(_toLoaded());
  }

  FleetLoaded _toLoaded() {
    final allItems = _project(_allVehicles);
    return FleetLoaded(
      items: _applyFilter(allItems, _filter),
      filter: _filter,
      counts: _countsFor(allItems),
    );
  }

  List<FleetListItem> _project(List<Vehicle> vehicles) {
    return [
      for (final vehicle in vehicles)
        FleetListItem(
          vehicle: vehicle,
          status: resolveStatus(vehicle, _clock),
          socVerdict: evaluateStaleness(vehicle.soc, kSocBounds, _clock),
          rangeVerdict: evaluateStaleness(vehicle.range, kRangeBounds, _clock),
        ),
    ];
  }

  FleetStatusCounts _countsFor(List<FleetListItem> items) {
    var moving = 0;
    var idle = 0;
    var stopped = 0;
    var offline = 0;

    for (final item in items) {
      switch (item.status) {
        case VehicleStatus.moving:
          moving++;
        case VehicleStatus.idle:
          idle++;
        case VehicleStatus.stopped:
          stopped++;
        case VehicleStatus.offline:
          offline++;
      }
    }

    return FleetStatusCounts(
      all: items.length,
      moving: moving,
      idle: idle,
      stopped: stopped,
      offline: offline,
    );
  }

  List<FleetListItem> _applyFilter(
    List<FleetListItem> items,
    FleetFilter filter,
  ) {
    if (filter == FleetFilter.all) {
      return List<FleetListItem>.unmodifiable(items);
    }

    final status = switch (filter) {
      FleetFilter.all => throw StateError('all is handled above'),
      FleetFilter.moving => VehicleStatus.moving,
      FleetFilter.idle => VehicleStatus.idle,
      FleetFilter.stopped => VehicleStatus.stopped,
      FleetFilter.offline => VehicleStatus.offline,
    };

    return [
      for (final item in items)
        if (item.status == status) item,
    ];
  }

  @override
  Future<void> close() async {
    final sub = _subscription;
    _subscription = null;
    await sub?.cancel();
    return super.close();
  }
}
