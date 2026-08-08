import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';

/// Domain contract for observing the live fleet.
abstract class FleetRepository {
  /// Emits domain [Vehicle] snapshots as telemetry updates.
  Stream<List<Vehicle>> watchFleet();

  /// Releases resources owned by this repository.
  void dispose();
}
