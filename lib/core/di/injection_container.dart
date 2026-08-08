import 'dart:convert';

import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/core/clock/system_clock.dart';
import 'package:byte_beam/features/alerts/data/noop_alert_persistence.dart';
import 'package:byte_beam/features/alerts/presentation/bloc/alerts_cubit.dart';
import 'package:byte_beam/features/fleet/data/datasources/mock_telemetry_data_source.dart';
import 'package:byte_beam/features/fleet/data/datasources/telemetry_data_source.dart';
import 'package:byte_beam/features/fleet/data/models/vehicle_model.dart';
import 'package:byte_beam/features/fleet/data/repositories/fleet_repository_impl.dart';
import 'package:byte_beam/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:byte_beam/features/fleet/presentation/bloc/fleet_bloc.dart';
import 'package:byte_beam/features/vehicle_detail/presentation/bloc/vehicle_detail_bloc.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Loads seed fleet DTOs from the asset bundle.
Future<List<VehicleModel>> loadSeedFleet() async {
  final raw = await rootBundle.loadString('assets/seed_fleet.json');
  final decoded = jsonDecode(raw) as List<dynamic>;
  return [
    for (final json in decoded.cast<Map<String, dynamic>>())
      VehicleModel.fromJson(json),
  ];
}

/// Registers app dependencies in [sl] (or [getIt] if provided).
///
/// Registers [SystemClock], [MockTelemetryDataSource], [FleetRepositoryImpl],
/// and lazy-singleton [FleetBloc] / [AlertsCubit]. [VehicleDetailBloc] is a
/// factory parameterized by vin.
///
/// Optional [clock] / [telemetryDataSource] overrides are for tests.
Future<void> configureDependencies({
  GetIt? getIt,
  List<VehicleModel>? seed,
  Clock? clock,
  MockTelemetryDataSource? telemetryDataSource,
}) async {
  final locator = getIt ?? sl;
  final fleetSeed = seed ?? await loadSeedFleet();

  if (clock != null) {
    locator.registerLazySingleton<Clock>(() => clock);
  } else {
    locator
      ..registerLazySingleton<SystemClock>(SystemClock.new)
      ..registerLazySingleton<Clock>(() => locator<SystemClock>());
  }

  locator
    ..registerLazySingleton<MockTelemetryDataSource>(
      () =>
          telemetryDataSource ??
          MockTelemetryDataSource(
            clock: locator(),
            seed: fleetSeed,
          ),
    )
    ..registerLazySingleton<TelemetryDataSource>(
      () => locator<MockTelemetryDataSource>(),
    )
    ..registerLazySingleton<FleetRepositoryImpl>(
      () => FleetRepositoryImpl(
        dataSource: locator(),
        launchClock: locator(),
      ),
    )
    ..registerLazySingleton<FleetRepository>(
      () => locator<FleetRepositoryImpl>(),
    )
    ..registerLazySingleton<AlertPersistence>(NoopAlertPersistence.new)
    ..registerLazySingleton<AlertsCubit>(
      () => AlertsCubit(
        vehicleStream: locator<FleetRepository>().watchFleet(),
        clock: locator(),
        persistence: locator(),
      ),
    )
    ..registerLazySingleton<FleetBloc>(
      () => FleetBloc(
        repository: locator(),
        clock: locator(),
      )..add(const FleetStarted()),
    )
    ..registerFactoryParam<VehicleDetailBloc, String, void>(
      (vin, _) => VehicleDetailBloc(
        vin: vin,
        repository: locator(),
        alertsCubit: locator(),
        clock: locator(),
      ),
    );
}
