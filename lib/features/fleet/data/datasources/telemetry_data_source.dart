import 'package:byte_beam/features/fleet/data/models/vehicle_model.dart';

/// Streams live fleet telemetry snapshots.
abstract class TelemetryDataSource {
  /// Emits the current fleet whenever telemetry updates.
  Stream<List<VehicleModel>> watchFleet();

  /// Releases timers / subscriptions owned by this source.
  void dispose();
}
