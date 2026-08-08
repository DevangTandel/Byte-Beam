import 'dart:async';
import 'dart:math';

import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/fleet/data/datasources/telemetry_data_source.dart';
import 'package:byte_beam/features/fleet/data/models/vehicle_model.dart';

/// Offline window matching the 10-minute status rule (seconds).
const kOfflinePingSeconds = 600;

/// Tick interval for simulated telemetry updates.
const kTelemetryTick = Duration(seconds: 3);

/// Full-pack range in kilometres at 100% SOC.
const kFullBatteryRangeKm = 532.0;

/// Peak half-range of per-tick speed jitter for moving vehicles (km/h).
const kSpeedJitterKmh = 2.0;

/// Estimated remaining range from battery state of charge.
double? rangeKmFromSoc(double? socPercent) {
  if (socPercent == null) {
    return null;
  }
  return socPercent / 100.0 * kFullBatteryRangeKm;
}

/// In-memory telemetry source that mutates the seed fleet every 3 seconds.
///
/// Moving vehicles: SOC drains, range tracks SOC, odometer rises, speed
/// jitters by a few km/h, and [VehicleModel.lastPingSecondsAgo] resets to 0.
/// Idle/stopped (online) vehicles only refresh lastPing. Offline vehicles
/// ([kOfflinePingSeconds]+) are frozen.
class MockTelemetryDataSource implements TelemetryDataSource {
  /// Creates a mock source from [seed], advancing with [random] jitter.
  MockTelemetryDataSource({
    required this.clock,
    required List<VehicleModel> seed,
    Random? random,
  }) : _random = random ?? Random(42),
       _fleet = [
         for (final vehicle in seed) _withRangeFromSoc(vehicle),
       ];

  /// App-launch / wall clock used by callers mapping to domain.
  final Clock clock;

  final Random _random;
  List<VehicleModel> _fleet;
  Timer? _timer;
  StreamController<List<VehicleModel>>? _controller;
  bool _disposed = false;

  /// How many periodic ticks have been applied (test observability).
  int tickCount = 0;

  /// Whether [Timer.periodic] is currently scheduled.
  bool get hasActiveTimer => _timer?.isActive ?? false;

  @override
  Stream<List<VehicleModel>> watchFleet() {
    if (_disposed) {
      return const Stream.empty();
    }

    final controller = StreamController<List<VehicleModel>>(
      sync: true,
      onListen: _onListen,
      onCancel: _onCancel,
    );
    _controller = controller;
    return controller.stream;
  }

  void _onListen() {
    _controller?.add(List<VehicleModel>.unmodifiable(_fleet));
    _timer ??= Timer.periodic(kTelemetryTick, (_) => _onTick());
  }

  void _onCancel() {
    // Timer lifecycle is owned by [dispose], not by stream cancel.
  }

  void _onTick() {
    if (_disposed) {
      return;
    }

    tickCount++;
    _fleet = [
      for (final vehicle in _fleet) _mutate(vehicle),
    ];
    _controller?.add(List<VehicleModel>.unmodifiable(_fleet));
  }

  VehicleModel _mutate(VehicleModel vehicle) {
    // Offline vehicles are frozen: no field changes, no Random draws.
    if (vehicle.lastPingSecondsAgo >= kOfflinePingSeconds) {
      return vehicle;
    }

    // Idle / stopped: refresh lastPing only (no Random draws).
    if (vehicle.speedKmh <= 0) {
      return vehicle.copyWith(lastPingSecondsAgo: 0);
    }

    final socDelta = 1.0 + (_random.nextDouble() * 0.2 - 0.1);
    final speedJitter =
        _random.nextDouble() * (kSpeedJitterKmh * 2) - kSpeedJitterKmh;
    final odoDelta = vehicle.speedKmh * (kTelemetryTick.inSeconds / 3600);
    // Stay moving: clamp away from zero so status does not flip to stopped.
    final nextSpeed = (vehicle.speedKmh + speedJitter).clamp(1.0, 120.0);

    final soc = vehicle.socPercent;
    if (soc == null) {
      return vehicle.copyWith(
        speedKmh: nextSpeed,
        odometerKm: vehicle.odometerKm + odoDelta,
        lastPingSecondsAgo: 0,
      );
    }

    // Battery % only decreases tick-over-tick for moving vehicles.
    final nextSoc = (soc - socDelta).clamp(0.0, 100.0);
    // Keep an explicit null range (seed honesty); otherwise track SOC.
    final nextRange = vehicle.rangeKm == null ? null : rangeKmFromSoc(nextSoc);
    return vehicle.copyWith(
      socPercent: nextSoc,
      rangeKm: nextRange,
      speedKmh: nextSpeed,
      odometerKm: vehicle.odometerKm + odoDelta,
      lastPingSecondsAgo: 0,
    );
  }

  /// Aligns non-null seed ranges to the 532 km pack formula.
  ///
  /// Leaves `rangeKm: null` untouched so missing-range honesty cases
  /// (e.g. VIN0006) survive into the domain/UI as a dash.
  static VehicleModel _withRangeFromSoc(VehicleModel vehicle) {
    if (vehicle.rangeKm == null || vehicle.socPercent == null) {
      return vehicle;
    }
    return vehicle.copyWith(rangeKm: rangeKmFromSoc(vehicle.socPercent));
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    final controller = _controller;
    _controller = null;
    if (controller != null && !controller.isClosed) {
      unawaited(controller.close());
    }
  }
}
