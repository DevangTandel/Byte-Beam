import 'package:byte_beam/core/di/injection_container.dart';
import 'package:byte_beam/features/fleet/presentation/bloc/fleet_bloc.dart';
import 'package:byte_beam/features/fleet/presentation/pages/fleet_home_page.dart';
import 'package:byte_beam/features/vehicle_detail/presentation/bloc/vehicle_detail_bloc.dart';
import 'package:byte_beam/features/vehicle_detail/presentation/pages/vehicle_detail_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// Creates the application [GoRouter].
///
/// Routes:
/// - `/` → [FleetHomePage]
/// - `/vehicle/:vin` → [VehicleDetailPage]
GoRouter createAppRouter({GetIt? getIt}) {
  final locator = getIt ?? sl;

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          return BlocProvider<FleetBloc>.value(
            value: locator<FleetBloc>(),
            child: FleetHomePage(clock: locator()),
          );
        },
      ),
      GoRoute(
        path: '/vehicle/:vin',
        builder: (context, state) {
          final vin = state.pathParameters['vin']!;
          return BlocProvider(
            create: (_) => locator<VehicleDetailBloc>(param1: vin)
              ..add(const VehicleDetailStarted()),
            child: VehicleDetailPage(clock: locator()),
          );
        },
      ),
    ],
  );
}
