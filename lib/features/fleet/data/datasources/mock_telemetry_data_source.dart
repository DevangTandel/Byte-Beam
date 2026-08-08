import 'dart:async';
import 'dart:math';

import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/fleet/data/datasources/telemetry_data_source.dart';
import 'package:byte_beam/features/fleet/data/models/vehicle_model.dart';

/// Offline window matching the 10-minute status rule (seconds).
const kOfflinePingSeconds = 600;

/// Tick interval for simulated telemetry updates.
const kTelemetryTick = Duration(seconds: 3);

/// In-memory telemetry source that mutates the seed fleet every 3 seconds.
class MockTelemetryDataSource implements TelemetryDataSource {
  /// Creates a mock source from [seed], advancing with [random] jitter.
  MockTelemetryDataSource({
    required this.clock,
    required List<VehicleModel> seed,
    Random? random,
  })  : _random = random ?? Random(42),
        _fleet = List<VehicleModel>.of(seed);

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

    // Idle / stopped: unchanged (no Random draws).
    if (vehicle.speedKmh <= 0) {
      return vehicle;
    }

    final socDelta = 1.0 + (_random.nextDouble() * 0.2 - 0.1);
    final odoDelta = vehicle.speedKmh * (kTelemetryTick.inSeconds / 3600);

    final soc = vehicle.socPercent;
    return vehicle.copyWith(
      socPercent: soc == null
          ? null
          : (soc - socDelta).clamp(0.0, 100.0).toDouble(),
      odometerKm: vehicle.odometerKm + odoDelta,
    );
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
