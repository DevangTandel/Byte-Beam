import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:byte_beam/features/alerts/domain/rules/alert_engine.dart';
import 'package:byte_beam/features/alerts/presentation/bloc/alerts_cubit.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:byte_beam/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:byte_beam/features/fleet/domain/rules/staleness_evaluator.dart';
import 'package:byte_beam/features/fleet/domain/rules/status_resolver.dart';

/// UI-ready bounds for SOC (aligned with low-battery alert threshold).
const kSocBounds = ThresholdBounds(
  min: kLowBatteryWarningThreshold,
  max: 100,
);

/// UI-ready bounds for battery temperature (°C).
const kBatteryTempBounds = ThresholdBounds(
  min: -20,
  max: kBatteryOverheatingThreshold,
);

/// UI-ready bounds for speed (km/h).
const kSpeedBounds = ThresholdBounds(min: 0, max: 200);

/// UI-ready bounds for range (km).
const kRangeBounds = ThresholdBounds(min: 0, max: 1000);

/// UI-ready bounds for odometer (km).
const kOdometerBounds = ThresholdBounds(min: 0, max: 5000000);

/// Per-parameter [Verdict]s for the vehicle detail screen.
class ParameterVerdicts {
  /// Creates [ParameterVerdicts].
  const ParameterVerdicts({
    required this.soc,
    required this.range,
    required this.speed,
    required this.batteryTemp,
    required this.odometer,
  });

  /// Verdict for state of charge (null → show dash).
  final Verdict? soc;

  /// Verdict for range (null → show dash).
  final Verdict? range;

  /// Verdict for speed (null → show dash).
  final Verdict? speed;

  /// Verdict for battery temperature (null → show dash).
  final Verdict? batteryTemp;

  /// Verdict for odometer (null → show dash).
  final Verdict? odometer;
}

/// Vehicle detail screen events.
sealed class VehicleDetailEvent {
  const VehicleDetailEvent();
}

/// Subscribe to fleet + alerts for the detail vin.
class VehicleDetailStarted extends VehicleDetailEvent {
  /// Creates a [VehicleDetailStarted] event.
  const VehicleDetailStarted();
}

class _DetailUpdated extends VehicleDetailEvent {
  const _DetailUpdated();
}

/// Vehicle detail screen state.
sealed class VehicleDetailState {
  const VehicleDetailState();
}

/// Before the first matching vehicle emission.
class VehicleDetailInitial extends VehicleDetailState {
  /// Creates a [VehicleDetailInitial] state.
  const VehicleDetailInitial();
}

/// Loaded detail ready for direct UI binding (no widget-layer logic).
class VehicleDetailLoaded extends VehicleDetailState {
  /// Creates a [VehicleDetailLoaded] state.
  const VehicleDetailLoaded({
    required this.vehicle,
    required this.status,
    required this.verdicts,
    required this.alerts,
  });

  /// The vehicle for this detail screen.
  final Vehicle vehicle;

  /// Resolved operational status.
  final VehicleStatus status;

  /// Precomputed per-parameter verdicts.
  final ParameterVerdicts verdicts;

  /// Active alerts for this vehicle's vin only.
  final List<Alert> alerts;
}

/// Combines one vehicle's fleet stream with [AlertsCubit] for that vin.
class VehicleDetailBloc extends Bloc<VehicleDetailEvent, VehicleDetailState> {
  /// Creates a [VehicleDetailBloc] for [vin].
  VehicleDetailBloc({
    required this.vin,
    required FleetRepository repository,
    required AlertsCubit alertsCubit,
    required Clock clock,
  })  : _repository = repository,
        _alertsCubit = alertsCubit,
        _clock = clock,
        super(const VehicleDetailInitial()) {
    on<VehicleDetailStarted>(_onStarted);
    on<_DetailUpdated>(_onDetailUpdated);
  }

  /// Vehicle identification number for this detail screen.
  final String vin;

  final FleetRepository _repository;
  final AlertsCubit _alertsCubit;
  final Clock _clock;

  StreamSubscription<List<Vehicle>>? _fleetSubscription;
  StreamSubscription<AlertsState>? _alertsSubscription;
  Vehicle? _vehicle;

  Future<void> _onStarted(
    VehicleDetailStarted event,
    Emitter<VehicleDetailState> emit,
  ) async {
    await _fleetSubscription?.cancel();
    await _alertsSubscription?.cancel();

    _fleetSubscription = _repository.watchFleet().listen((fleet) {
      Vehicle? match;
      for (final vehicle in fleet) {
        if (vehicle.vin == vin) {
          match = vehicle;
          break;
        }
      }
      _vehicle = match;
      add(const _DetailUpdated());
    });

    _alertsSubscription = _alertsCubit.stream.listen((_) {
      add(const _DetailUpdated());
    });

    // Seed from current alerts state if a vehicle is already known.
    add(const _DetailUpdated());
  }

  void _onDetailUpdated(
    _DetailUpdated event,
    Emitter<VehicleDetailState> emit,
  ) {
    final vehicle = _vehicle;
    if (vehicle == null) {
      return;
    }

    emit(
      VehicleDetailLoaded(
        vehicle: vehicle,
        status: resolveStatus(vehicle, _clock),
        verdicts: _verdictsFor(vehicle),
        alerts: [
          for (final alert in _alertsCubit.state.active)
            if (alert.vin == vin) alert,
        ],
      ),
    );
  }

  ParameterVerdicts _verdictsFor(Vehicle vehicle) {
    return ParameterVerdicts(
      soc: evaluateStaleness(vehicle.soc, kSocBounds, _clock),
      range: evaluateStaleness(vehicle.range, kRangeBounds, _clock),
      speed: evaluateStaleness(vehicle.speed, kSpeedBounds, _clock),
      batteryTemp:
          evaluateStaleness(vehicle.batteryTemp, kBatteryTempBounds, _clock),
      odometer: evaluateStaleness(vehicle.odometer, kOdometerBounds, _clock),
    );
  }

  @override
  Future<void> close() async {
    await _fleetSubscription?.cancel();
    await _alertsSubscription?.cancel();
    return super.close();
  }
}
