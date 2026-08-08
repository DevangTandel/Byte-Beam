import 'package:byte_beam/core/di/injection_container.dart';
import 'package:byte_beam/core/router/app_router.dart';
import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/features/alerts/presentation/bloc/alerts_cubit.dart';
import 'package:byte_beam/features/fleet/data/models/vehicle_model.dart';
import 'package:byte_beam/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:byte_beam/features/fleet/presentation/pages/fleet_home_page.dart';
import 'package:byte_beam/features/vehicle_detail/presentation/pages/vehicle_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  setUp(() async {
    await sl.reset();
    await configureDependencies(seed: seed);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget app(GoRouter router) {
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

  Future<void> disposeTelemetry() async {
    sl<FleetRepository>().dispose();
  }

  testWidgets('/ shows FleetHomePage', (tester) async {
    final router = createAppRouter();
    await tester.pumpWidget(app(router));
    await tester.pump();
    await tester.pump();

    expect(find.byType(FleetHomePage), findsOneWidget);
    expect(router.state.uri.path, '/');

    await disposeTelemetry();
  });

  testWidgets('/vehicle/:vin shows VehicleDetailPage', (tester) async {
    final router = createAppRouter();
    await tester.pumpWidget(app(router));
    await tester.pump();

    router.go('/vehicle/VIN0001');
    await tester.pump();
    await tester.pump();

    expect(find.byType(VehicleDetailPage), findsOneWidget);
    expect(router.state.uri.path, '/vehicle/VIN0001');

    await disposeTelemetry();
  });
}
