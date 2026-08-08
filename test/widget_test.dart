import 'package:byte_beam/core/di/injection_container.dart';
import 'package:byte_beam/core/router/app_router.dart';
import 'package:byte_beam/features/fleet/data/models/vehicle_model.dart';
import 'package:byte_beam/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:byte_beam/features/fleet/presentation/pages/fleet_home_page.dart';
import 'package:byte_beam/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    if (sl.isRegistered<FleetRepository>()) {
      sl<FleetRepository>().dispose();
    }
    await sl.reset();
  });

  testWidgets('app boots to FleetHomePage', (tester) async {
    await configureDependencies(
      seed: const [
        VehicleModel(
          vin: 'VIN0001',
          reg: 'MH 01 AB 1234',
          model: 'eCargo 55',
          speedKmh: 0,
          odometerKm: 1000,
          lastPingSecondsAgo: 5,
        ),
      ],
    );

    await tester.pumpWidget(ByteBeamApp(router: createAppRouter()));
    await tester.pump();
    await tester.pump();

    expect(find.byType(FleetHomePage), findsOneWidget);
    expect(find.text('Fleet'), findsOneWidget);

    // Cancel Timer.periodic before the test ends (tearDown is too late).
    sl<FleetRepository>().dispose();
  });
}
