import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/core/di/injection_container.dart';
import 'package:byte_beam/core/router/app_router.dart';
import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/features/alerts/presentation/bloc/alerts_cubit.dart';
import 'package:byte_beam/features/fleet/data/datasources/mock_telemetry_data_source.dart';
import 'package:byte_beam/features/fleet/data/models/vehicle_model.dart';
import 'package:byte_beam/features/fleet/data/repositories/fleet_repository_impl.dart';
import 'package:byte_beam/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:byte_beam/features/fleet/presentation/bloc/fleet_bloc.dart';
import 'package:byte_beam/features/fleet/presentation/pages/fleet_home_page.dart';
import 'package:byte_beam/features/vehicle_detail/presentation/bloc/vehicle_detail_bloc.dart';
import 'package:byte_beam/features/vehicle_detail/presentation/pages/vehicle_detail_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Test-only clock with a fixed [now] value.
class FakeClock implements Clock {
  FakeClock(this._fixed);

  DateTime _fixed;

  @override
  DateTime now() => _fixed;

  void advance(Duration d) => _fixed = _fixed.add(d);
}

/// Counts [VehicleDetailBloc] instances and post-close [add] calls.
class SpyVehicleDetailBloc extends VehicleDetailBloc {
  SpyVehicleDetailBloc({
    required super.vin,
    required super.repository,
    required super.alertsCubit,
    required super.clock,
  });

  static int created = 0;
  static int closed = 0;
  static int addsAfterClose = 0;

  static void resetCounters() {
    created = 0;
    closed = 0;
    addsAfterClose = 0;
  }

  var _closed = false;

  @override
  void add(VehicleDetailEvent event) {
    if (_closed) {
      addsAfterClose++;
      debugPrint('VehicleDetailBloc.add after close: $event');
      return;
    }
    super.add(event);
  }

  @override
  Future<void> close() async {
    _closed = true;
    closed++;
    await super.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 8, 7, 12, 0, 0);

  const seed = [
    VehicleModel(
      vin: 'VIN0001',
      reg: 'MH 01 AB 1234',
      model: 'eCargo 55',
      speedKmh: 42,
      ignitionOn: true,
      odometerKm: 1000,
      lastPingSecondsAgo: 5,
      socPercent: 80,
      rangeKm: 200,
      batteryTempC: 30,
    ),
  ];

  late FakeClock clock;
  late MockTelemetryDataSource dataSource;
  late GoRouter router;

  Widget app() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AlertsCubit>.value(value: sl<AlertsCubit>()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    );
  }

  setUp(() async {
    SpyVehicleDetailBloc.resetCounters();
    await sl.reset();
    clock = FakeClock(now);
    dataSource = MockTelemetryDataSource(clock: clock, seed: seed);

    await configureDependencies(
      seed: seed,
      clock: clock,
      telemetryDataSource: dataSource,
    );

    sl
      ..unregister<VehicleDetailBloc>()
      ..registerFactoryParam<VehicleDetailBloc, String, void>(
        (vin, _) {
          SpyVehicleDetailBloc.created++;
          return SpyVehicleDetailBloc(
            vin: vin,
            repository: sl(),
            alertsCubit: sl(),
            clock: sl(),
          );
        },
      );

    router = createAppRouter();
  });

  tearDown(() async {
    if (sl.isRegistered<FleetRepository>()) {
      sl<FleetRepository>().dispose();
    }
    if (sl.isRegistered<FleetBloc>() && !sl<FleetBloc>().isClosed) {
      await sl<FleetBloc>().close();
    }
    if (sl.isRegistered<AlertsCubit>() && !sl<AlertsCubit>().isClosed) {
      await sl<AlertsCubit>().close();
    }
    await sl.reset();
  });

  testWidgets(
    'FleetHome → VehicleDetail → pop cancels detail subscriptions and does '
    'not leave an extra periodic timer firing',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump();

      expect(find.byType(FleetHomePage), findsOneWidget);

      final repo = sl<FleetRepositoryImpl>();
      // AlertsCubit + FleetBloc
      expect(repo.activeWatchers, 2);
      expect(dataSource.hasActiveTimer, isTrue);

      await tester.tap(find.text('MH 01 AB 1234'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(VehicleDetailPage), findsOneWidget);
      expect(SpyVehicleDetailBloc.created, 1);
      expect(repo.activeWatchers, 3);

      router.pop();
      await tester.pump();
      await tester.pump();

      expect(find.byType(FleetHomePage), findsOneWidget);
      expect(find.byType(VehicleDetailPage), findsNothing);
      expect(SpyVehicleDetailBloc.closed, 1);
      expect(repo.activeWatchers, 2);

      // App-scoped telemetry keeps a single timer — one tick per interval,
      // not two (which would mean a leaked second Timer.periodic).
      final ticksAtPop = dataSource.tickCount;
      await tester.pump(kTelemetryTick);
      expect(dataSource.tickCount, ticksAtPop + 1);
      await tester.pump(kTelemetryTick);
      expect(dataSource.tickCount, ticksAtPop + 2);

      // Closed detail must not keep handling stream events.
      expect(SpyVehicleDetailBloc.addsAfterClose, 0);

      // Second visit/pop must still not spawn an extra timer.
      await tester.tap(find.text('MH 01 AB 1234'));
      await tester.pump();
      await tester.pump();
      router.pop();
      await tester.pump();
      await tester.pump();

      expect(SpyVehicleDetailBloc.created, 2);
      expect(SpyVehicleDetailBloc.closed, 2);
      expect(repo.activeWatchers, 2);

      final ticksBefore = dataSource.tickCount;
      await tester.pump(kTelemetryTick);
      expect(
        dataSource.tickCount,
        ticksBefore + 1,
        reason: 'exactly one periodic timer must remain after pop',
      );

      // After disposing app-scoped telemetry, no further ticks.
      sl<FleetRepository>().dispose();
      expect(dataSource.hasActiveTimer, isFalse);
      final ticksAfterDispose = dataSource.tickCount;
      await tester.pump(kTelemetryTick * 3);
      expect(
        dataSource.tickCount,
        ticksAfterDispose,
        reason: 'no lingering timer fires after dispose following pop',
      );
      expect(SpyVehicleDetailBloc.addsAfterClose, 0);
    },
  );
}
