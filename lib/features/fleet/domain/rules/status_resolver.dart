import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';

/// Age at or beyond this duration marks a vehicle offline.
const kOfflineThreshold = Duration(minutes: 10);

/// Operational status of a fleet vehicle.
enum VehicleStatus {
  /// No recent ping within [kOfflineThreshold].
  offline,

  /// Online with speed greater than zero.
  moving,

  /// Online, stationary, ignition on.
  idle,

  /// Online and not moving; ignition off or unknown.
  stopped,
}

/// Resolves [v]'s status using brief §2 precedence (first match wins).
VehicleStatus resolveStatus(Vehicle v, Clock clock) {
  final age = clock.now().difference(v.lastPingAt);
  if (age >= kOfflineThreshold) {
    return VehicleStatus.offline;
  }

  final speed = v.speed.value;
  if (speed != null && speed > 0) {
    return VehicleStatus.moving;
  }

  if (speed == 0 && (v.ignitionOn ?? false)) {
    return VehicleStatus.idle;
  }

  // ignitionOn == false, or null (safe default).
  return VehicleStatus.stopped;
}
