import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/core/widgets/alert_badge.dart';
import 'package:byte_beam/core/widgets/empty_state.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:byte_beam/features/alerts/presentation/bloc/alerts_cubit.dart';
import 'package:byte_beam/features/fleet/domain/entities/reading.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:byte_beam/features/fleet/presentation/bloc/fleet_bloc.dart';
import 'package:byte_beam/features/fleet/presentation/pages/fleet_home_page.dart';
import 'package:byte_beam/features/fleet/presentation/widgets/vehicle_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFleetBloc extends MockBloc<FleetEvent, FleetState>
    implements FleetBloc {}

class MockAlertsCubit extends MockCubit<AlertsState> implements AlertsCubit {}

/// Test-only clock with a fixed [now] value.
class FakeClock implements Clock {
  FakeClock(this._fixed);

  DateTime _fixed;

  @override
  DateTime now() => _fixed;

  void advance(Duration d) => _fixed = _fixed.add(d);
}

void main() {
  final now = DateTime(2026, 8, 7, 12, 10, 0);
  late FakeClock clock;
  late MockFleetBloc mockBloc;
  late MockAlertsCubit mockAlertsCubit;

  Vehicle vehicle(String vin, {double speed = 0, bool? ignitionOn = false}) {
    Reading<double> reading(double? value) => Reading<double>(
          clock: clock,
          value: value,
          lastPingAt: now.subtract(const Duration(minutes: 1)),
        );

    return Vehicle(
      vin: vin,
      reg: 'REG-$vin',
      model: 'eCargo 55',
      soc: reading(50),
      range: reading(100),
      speed: reading(speed),
      batteryTemp: reading(30),
      odometer: reading(1000),
      lastPingAt: now.subtract(const Duration(minutes: 1)),
      ignitionOn: ignitionOn,
    );
  }

  List<Vehicle> eightVehicles() => [
        for (var i = 1; i <= 8; i++)
          vehicle('VIN000$i', speed: i <= 3 ? 20 : 0, ignitionOn: i == 2),
      ];

  Widget pumpPage() {
    return MaterialApp(
      theme: AppTheme.light(),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<FleetBloc>.value(value: mockBloc),
          BlocProvider<AlertsCubit>.value(value: mockAlertsCubit),
        ],
        child: FleetHomePage(clock: clock),
      ),
    );
  }

  setUpAll(() {
    registerFallbackValue(const FleetStarted());
    registerFallbackValue(const FilterChanged(FleetFilter.all));
  });

  setUp(() {
    clock = FakeClock(now);
    mockBloc = MockFleetBloc();
    mockAlertsCubit = MockAlertsCubit();
    whenListen(
      mockAlertsCubit,
      const Stream<AlertsState>.empty(),
      initialState: const AlertsState(),
    );
  });

  group('FleetHomePage', () {
    testWidgets('renders 8 vehicle cards from a loaded state', (tester) async {
      final vehicles = eightVehicles();
      const counts = FleetStatusCounts(
        all: 8,
        moving: 3,
        idle: 1,
        stopped: 4,
        offline: 0,
      );
      final loaded = FleetLoaded(
        vehicles: vehicles,
        filter: FleetFilter.all,
        counts: counts,
      );

      whenListen(
        mockBloc,
        const Stream<FleetState>.empty(),
        initialState: loaded,
      );

      await tester.pumpWidget(pumpPage());
      await tester.pump();

      expect(find.byType(VehicleCard), findsNWidgets(8));
      expect(find.byType(EmptyState), findsNothing);
      expect(find.text('REG-VIN0001'), findsOneWidget);
      expect(find.text('REG-VIN0008'), findsOneWidget);
      expect(find.byType(AlertBadge), findsNothing);
    });

    testWidgets(
      'shows AlertBadge on vehicle cards that have active alerts',
      (tester) async {
        final vehicles = eightVehicles();
        final loaded = FleetLoaded(
          vehicles: vehicles,
          filter: FleetFilter.all,
          counts: const FleetStatusCounts(
            all: 8,
            moving: 3,
            idle: 1,
            stopped: 4,
            offline: 0,
          ),
        );

        whenListen(
          mockBloc,
          const Stream<FleetState>.empty(),
          initialState: loaded,
        );
        whenListen(
          mockAlertsCubit,
          const Stream<AlertsState>.empty(),
          initialState: AlertsState(
            active: [
              Alert(
                id: 'a1',
                vin: 'VIN0001',
                kind: AlertKind.lowBattery,
                severity: AlertSeverity.warning,
                raisedAt: now,
                isBasedOnStaleData: false,
              ),
              Alert(
                id: 'a2',
                vin: 'VIN0001',
                kind: AlertKind.batteryOverheating,
                severity: AlertSeverity.critical,
                raisedAt: now,
                isBasedOnStaleData: false,
              ),
              Alert(
                id: 'a3',
                vin: 'VIN0003',
                kind: AlertKind.lowBattery,
                severity: AlertSeverity.warning,
                raisedAt: now,
                isBasedOnStaleData: false,
              ),
            ],
          ),
        );

        await tester.pumpWidget(pumpPage());
        await tester.pump();

        expect(find.byType(AlertBadge), findsNWidgets(2));

        final card1 = tester.widget<VehicleCard>(
          find.ancestor(
            of: find.text('REG-VIN0001'),
            matching: find.byType(VehicleCard),
          ),
        );
        expect(card1.alertCount, 2);
        expect(card1.alertSeverity, AlertSeverity.critical);

        final card3 = tester.widget<VehicleCard>(
          find.ancestor(
            of: find.text('REG-VIN0003'),
            matching: find.byType(VehicleCard),
          ),
        );
        expect(card3.alertCount, 1);
        expect(card3.alertSeverity, AlertSeverity.warning);

        final card2 = tester.widget<VehicleCard>(
          find.ancestor(
            of: find.text('REG-VIN0002'),
            matching: find.byType(VehicleCard),
          ),
        );
        expect(card2.alertCount, 0);
      },
    );

    testWidgets(
      'selecting a filter with zero results shows EmptyState, not a blank list',
      (tester) async {
        const counts = FleetStatusCounts(
          all: 8,
          moving: 3,
          idle: 0,
          stopped: 4,
          offline: 1,
        );
        final withVehicles = FleetLoaded(
          vehicles: eightVehicles(),
          filter: FleetFilter.all,
          counts: counts,
        );
        const emptyIdle = FleetLoaded(
          vehicles: [],
          filter: FleetFilter.idle,
          counts: counts,
        );

        final states = StreamController<FleetState>();
        addTearDown(states.close);

        whenListen(
          mockBloc,
          states.stream,
          initialState: withVehicles,
        );

        await tester.pumpWidget(pumpPage());
        await tester.pump();
        expect(find.byType(VehicleCard), findsNWidgets(8));
        expect(find.byType(EmptyState), findsNothing);

        await tester.tap(find.text('Idle (0)'));
        await tester.pump();

        final added = verify(() => mockBloc.add(captureAny())).captured;
        expect(added, hasLength(1));
        expect(added.single, isA<FilterChanged>());
        expect((added.single as FilterChanged).filter, FleetFilter.idle);

        states.add(emptyIdle);
        await tester.pump();

        expect(find.byType(EmptyState), findsOneWidget);
        expect(find.byType(VehicleCard), findsNothing);
        expect(find.textContaining('No vehicles'), findsOneWidget);
      },
    );
  });
}
