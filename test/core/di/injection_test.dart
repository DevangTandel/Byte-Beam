import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/core/clock/system_clock.dart';
import 'package:byte_beam/core/di/injection_container.dart';
import 'package:byte_beam/core/router/app_router.dart';
import 'package:byte_beam/features/alerts/presentation/bloc/alerts_cubit.dart';
import 'package:byte_beam/features/fleet/data/datasources/mock_telemetry_data_source.dart';
import 'package:byte_beam/features/fleet/data/models/vehicle_model.dart';
import 'package:byte_beam/features/fleet/data/repositories/fleet_repository_impl.dart';
import 'package:byte_beam/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:byte_beam/features/fleet/presentation/bloc/fleet_bloc.dart';
import 'package:byte_beam/features/vehicle_detail/presentation/bloc/vehicle_detail_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    if (sl.isRegistered<FleetRepository>()) {
      sl<FleetRepository>().dispose();
    }
    await sl.reset();
  });

  test(
    'configureDependencies registers clock, data, repo, and blocs',
    () async {
      const seed = [
        VehicleModel(
          vin: 'VIN1',
          reg: 'R1',
          model: 'M',
          speedKmh: 0,
          odometerKm: 1,
          lastPingSecondsAgo: 1,
        ),
      ];
      await configureDependencies(seed: seed);

      expect(sl<SystemClock>(), isA<SystemClock>());
      expect(sl<Clock>(), same(sl<SystemClock>()));
      expect(sl<MockTelemetryDataSource>(), isA<MockTelemetryDataSource>());
      expect(sl<FleetRepositoryImpl>(), isA<FleetRepositoryImpl>());
      expect(sl<AlertsCubit>(), isA<AlertsCubit>());
      expect(sl<FleetBloc>(), isA<FleetBloc>());
      expect(sl<VehicleDetailBloc>(param1: 'VIN1').vin, 'VIN1');
      expect(createAppRouter().configuration.routes, isNotEmpty);
    },
  );
}
