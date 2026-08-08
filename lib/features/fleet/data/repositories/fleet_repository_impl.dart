import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/fleet/data/datasources/telemetry_data_source.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:byte_beam/features/fleet/domain/repositories/fleet_repository.dart';

/// Maps [TelemetryDataSource] DTO streams into domain [Vehicle] streams.
class FleetRepositoryImpl implements FleetRepository {
  /// Creates a [FleetRepositoryImpl].
  FleetRepositoryImpl({
    required TelemetryDataSource dataSource,
    required Clock launchClock,
  })  : _dataSource = dataSource,
        _launchClock = launchClock;

  final TelemetryDataSource _dataSource;
  final Clock _launchClock;

  @override
  Stream<List<Vehicle>> watchFleet() {
    return _dataSource.watchFleet().map(
          (models) => [
            for (final model in models) model.toDomain(_launchClock),
          ],
        );
  }

  @override
  void dispose() => _dataSource.dispose();
}
