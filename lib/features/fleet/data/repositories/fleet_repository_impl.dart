import 'dart:async';

import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/fleet/data/datasources/telemetry_data_source.dart';
import 'package:byte_beam/features/fleet/data/models/vehicle_model.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:byte_beam/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:flutter/foundation.dart';

/// Maps [TelemetryDataSource] DTO streams into domain [Vehicle] streams.
///
/// Fans out a single upstream subscription so multiple listeners share one
/// telemetry watch without resetting the mock data source controller.
class FleetRepositoryImpl implements FleetRepository {
  /// Creates a [FleetRepositoryImpl].
  FleetRepositoryImpl({
    required this._dataSource,
    required this._launchClock,
  });

  final TelemetryDataSource _dataSource;
  final Clock _launchClock;

  final _fanout = StreamController<List<Vehicle>>.broadcast();
  StreamSubscription<List<VehicleModel>>? _subscription;
  List<Vehicle>? _latest;
  var _started = false;

  /// Active [watchFleet] downstream listeners (test observability).
  @visibleForTesting
  int activeWatchers = 0;

  void _ensureStarted() {
    if (_started) {
      return;
    }
    _started = true;
    _subscription = _dataSource.watchFleet().listen((models) {
      final vehicles = [
        for (final model in models) model.toDomain(_launchClock),
      ];
      _latest = vehicles;
      if (!_fanout.isClosed) {
        _fanout.add(vehicles);
      }
    });
  }

  @override
  Stream<List<Vehicle>> watchFleet() {
    _ensureStarted();
    return Stream<List<Vehicle>>.multi((controller) {
      activeWatchers++;
      final latest = _latest;
      if (latest != null) {
        scheduleMicrotask(() {
          if (!controller.isClosed) {
            controller.add(latest);
          }
        });
      }
      final sub = _fanout.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () {
        activeWatchers--;
        // Cancel synchronously — an async onCancel can deadlock Bloc.close().
        unawaited(sub.cancel());
      };
    });
  }

  @override
  void dispose() {
    final sub = _subscription;
    _subscription = null;
    unawaited(sub?.cancel());
    if (!_fanout.isClosed) {
      unawaited(_fanout.close());
    }
    _dataSource.dispose();
  }
}
