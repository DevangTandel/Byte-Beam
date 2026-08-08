import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/core/widgets/verdict_pill.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:byte_beam/features/alerts/presentation/bloc/alerts_cubit.dart';
import 'package:byte_beam/features/alerts/presentation/widgets/reason_sheet.dart';
import 'package:byte_beam/features/fleet/domain/entities/reading.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:byte_beam/features/fleet/domain/rules/staleness_evaluator.dart';
import 'package:byte_beam/features/fleet/domain/rules/status_resolver.dart';
import 'package:byte_beam/features/vehicle_detail/presentation/bloc/vehicle_detail_bloc.dart';
import 'package:byte_beam/features/vehicle_detail/presentation/pages/vehicle_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockVehicleDetailBloc
    extends MockBloc<VehicleDetailEvent, VehicleDetailState>
    implements VehicleDetailBloc {}

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
  const vin = 'VIN0003';

  late FakeClock clock;
  late MockVehicleDetailBloc mockDetailBloc;
  late MockAlertsCubit mockAlertsCubit;

  Vehicle buildVehicle() {
    Reading<double> reading(double? value, {Duration age = Duration.zero}) =>
        Reading<double>(
          clock: clock,
          value: value,
          lastPingAt: now.subtract(age),
        );

    return Vehicle(
      vin: vin,
      reg: 'MH 12 EF 9012',
      model: 'eVan 30',
      soc: reading(15),
      range: reading(34),
      speed: reading(38),
      batteryTemp: reading(47),
      odometer: reading(12780),
      lastPingAt: now.subtract(const Duration(minutes: 1)),
      ignitionOn: true,
    );
  }

  Alert buildAlert() => Alert(
        id: 'alert-1',
        vin: vin,
        kind: AlertKind.lowBattery,
        severity: AlertSeverity.warning,
        raisedAt: now,
        isBasedOnStaleData: false,
      );

  VehicleDetailLoaded loadedState({List<Alert>? alerts}) {
    final vehicle = buildVehicle();
    return VehicleDetailLoaded(
      vehicle: vehicle,
      status: VehicleStatus.moving,
      verdicts: const ParameterVerdicts(
        soc: Verdict.alert,
        range: Verdict.normal,
        speed: Verdict.normal,
        batteryTemp: Verdict.alert,
        odometer: Verdict.normal,
      ),
      alerts: alerts ?? [buildAlert()],
    );
  }

  Widget pumpPage() {
    return MaterialApp(
      theme: AppTheme.light(),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<VehicleDetailBloc>.value(value: mockDetailBloc),
          BlocProvider<AlertsCubit>.value(value: mockAlertsCubit),
        ],
        child: VehicleDetailPage(clock: clock),
      ),
    );
  }

  setUpAll(() {
    registerFallbackValue(const VehicleDetailStarted());
    registerFallbackValue(DismissReason.onIt);
  });

  setUp(() {
    clock = FakeClock(now);
    mockDetailBloc = MockVehicleDetailBloc();
    mockAlertsCubit = MockAlertsCubit();
    when(() => mockAlertsCubit.state).thenReturn(const AlertsState());
    when(() => mockDetailBloc.vin).thenReturn(vin);
  });

  group('VehicleDetailPage', () {
    testWidgets(
      'readings register renders SOC/range/speed/batteryTemp/odometer/lastPing '
      'each with the correct VerdictPill state',
      (tester) async {
        whenListen(
          mockDetailBloc,
          const Stream<VehicleDetailState>.empty(),
          initialState: loadedState(),
        );

        await tester.pumpWidget(pumpPage());
        await tester.pump();

        expect(find.text('SOC'), findsOneWidget);
        expect(find.text('Range'), findsOneWidget);
        expect(find.text('Speed'), findsOneWidget);
        expect(find.text('Battery temp'), findsOneWidget);
        expect(find.text('Odometer'), findsOneWidget);
        expect(find.text('Last ping'), findsOneWidget);

        expect(find.byType(VerdictPill), findsNWidgets(6));

        final styles = AppTheme.light().extension<VerdictTheme>()!;

        // SOC alert
        final socPill = tester.widget<VerdictPill>(
          find.byKey(const Key('reading-soc')),
        );
        expect(socPill.verdict, Verdict.alert);
        expect(socPill.value, 15);
        expect(socPill.unit, '%');
        expect(
          tester.widget<Text>(find.text('15 %')).style?.color,
          styles.alertValueColor,
        );

        // Range normal
        final rangePill = tester.widget<VerdictPill>(
          find.byKey(const Key('reading-range')),
        );
        expect(rangePill.verdict, Verdict.normal);
        expect(rangePill.value, 34);
        expect(rangePill.unit, 'km');

        // Speed normal
        final speedPill = tester.widget<VerdictPill>(
          find.byKey(const Key('reading-speed')),
        );
        expect(speedPill.verdict, Verdict.normal);
        expect(speedPill.value, 38);
        expect(speedPill.unit, 'km/h');

        // Battery temp alert
        final tempPill = tester.widget<VerdictPill>(
          find.byKey(const Key('reading-batteryTemp')),
        );
        expect(tempPill.verdict, Verdict.alert);
        expect(tempPill.value, 47);
        expect(tempPill.unit, '°C');

        // Odometer normal
        final odoPill = tester.widget<VerdictPill>(
          find.byKey(const Key('reading-odometer')),
        );
        expect(odoPill.verdict, Verdict.normal);
        expect(odoPill.value, 12780);
        expect(odoPill.unit, 'km');

        // Last ping (1 minute old → normal)
        final pingPill = tester.widget<VerdictPill>(
          find.byKey(const Key('reading-lastPing')),
        );
        expect(pingPill.verdict, Verdict.normal);
        expect(pingPill.value, 1);
        expect(pingPill.unit, 'm ago');
      },
    );

    testWidgets(
      'tapping dismiss opens ReasonSheet with three options in order',
      (tester) async {
        whenListen(
          mockDetailBloc,
          const Stream<VehicleDetailState>.empty(),
          initialState: loadedState(),
        );

        await tester.pumpWidget(pumpPage());
        await tester.pump();

        await tester.ensureVisible(find.text('Dismiss'));
        await tester.tap(find.text('Dismiss'));
        await tester.pumpAndSettle();

        expect(find.byType(ReasonSheet), findsOneWidget);

        final options = find.descendant(
          of: find.byType(ReasonSheet),
          matching: find.byType(ListTile),
        );
        final labels = tester.widgetList<ListTile>(options).map((tile) {
          final title = tile.title! as Text;
          return title.data;
        }).toList();

        expect(labels, [
          'I am on it',
          'Wrong alert',
          'Something else…',
        ]);
      },
    );

    testWidgets(
      'selecting a reason closes sheet, removes alert, shows UNDO snackbar',
      (tester) async {
        final detailStates =
            StreamController<VehicleDetailState>.broadcast(sync: true);
        addTearDown(detailStates.close);

        final withAlert = loadedState();
        final withoutAlert = loadedState(alerts: const []);

        whenListen(
          mockDetailBloc,
          detailStates.stream,
          initialState: withAlert,
        );

        await tester.pumpWidget(pumpPage());
        await tester.pump();

        expect(find.text('Dismiss'), findsOneWidget);

        await tester.tap(find.text('Dismiss'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('I am on it'));
        await tester.pumpAndSettle();

        verify(
          () => mockAlertsCubit.dismiss('alert-1', DismissReason.onIt),
        ).called(1);

        expect(find.byType(ReasonSheet), findsNothing);
        expect(find.text('UNDO'), findsOneWidget);

        detailStates.add(withoutAlert);
        await tester.pump();

        expect(find.text('Dismiss'), findsNothing);
      },
    );

    testWidgets('tapping UNDO restores the alert to the list', (tester) async {
      final detailStates =
          StreamController<VehicleDetailState>.broadcast(sync: true);
      addTearDown(detailStates.close);

      final withAlert = loadedState();
      final withoutAlert = loadedState(alerts: const []);

      whenListen(
        mockDetailBloc,
        detailStates.stream,
        initialState: withAlert,
      );

      await tester.pumpWidget(pumpPage());
      await tester.pump();

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wrong alert'));
      await tester.pumpAndSettle();

      detailStates.add(withoutAlert);
      await tester.pump();
      expect(find.text('Dismiss'), findsNothing);
      expect(find.text('UNDO'), findsOneWidget);

      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();

      verify(() => mockAlertsCubit.undo()).called(1);

      detailStates.add(withAlert);
      await tester.pump();

      expect(find.text('Dismiss'), findsOneWidget);
    });
  });
}
