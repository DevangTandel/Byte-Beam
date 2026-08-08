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

        // SOC alert (fractionDigits: 2 → "15.00 %")
        final socPill = tester.widget<VerdictPill>(
          find.byKey(const Key('reading-soc')),
        );
        expect(socPill.verdict, Verdict.alert);
        expect(socPill.value, 15);
        expect(socPill.unit, '%');
        expect(socPill.fractionDigits, 2);
        expect(find.text('15.00 %'), findsOneWidget);
        expect(
          tester.widget<Text>(find.text('15.00 %')).style?.color,
          styles.alertValueColor,
        );

        // Range normal (fractionDigits: 2 → "34.00 km")
        final rangePill = tester.widget<VerdictPill>(
          find.byKey(const Key('reading-range')),
        );
        expect(rangePill.verdict, Verdict.normal);
        expect(rangePill.value, 34);
        expect(rangePill.unit, 'km');
        expect(rangePill.fractionDigits, 2);
        expect(find.text('34.00 km'), findsOneWidget);
        expect(
          tester.widget<Text>(find.text('34.00 km')).style?.color,
          styles.normalValueColor,
        );

        // Speed normal (no fixed decimals)
        final speedPill = tester.widget<VerdictPill>(
          find.byKey(const Key('reading-speed')),
        );
        expect(speedPill.verdict, Verdict.normal);
        expect(speedPill.value, 38);
        expect(speedPill.unit, 'km/h');
        expect(find.text('38 km/h'), findsOneWidget);

        // Battery temp alert
        final tempPill = tester.widget<VerdictPill>(
          find.byKey(const Key('reading-batteryTemp')),
        );
        expect(tempPill.verdict, Verdict.alert);
        expect(tempPill.value, 47);
        expect(tempPill.unit, '°C');
        expect(find.text('47 °C'), findsOneWidget);
        expect(
          tester.widget<Text>(find.text('47 °C')).style?.color,
          styles.alertValueColor,
        );

        // Odometer normal (fractionDigits: 2 → "12780.00 km")
        final odoPill = tester.widget<VerdictPill>(
          find.byKey(const Key('reading-odometer')),
        );
        expect(odoPill.verdict, Verdict.normal);
        expect(odoPill.value, 12780);
        expect(odoPill.unit, 'km');
        expect(odoPill.fractionDigits, 2);
        expect(find.text('12780.00 km'), findsOneWidget);

        // Last ping (1 minute old → normal)
        final pingPill = tester.widget<VerdictPill>(
          find.byKey(const Key('reading-lastPing')),
        );
        expect(pingPill.verdict, Verdict.normal);
        expect(pingPill.value, 1);
        expect(pingPill.unit, 'm ago');
        expect(find.text('1 m ago'), findsOneWidget);
      },
    );

    testWidgets(
      'VIN0007 SOC 8% renders STALE grey, not ALERT red '
      '(staleness overrides critical SOC breach)',
      (tester) async {
        const vin0007 = 'VIN0007';
        when(() => mockDetailBloc.vin).thenReturn(vin0007);

        final pingAge = const Duration(seconds: 720);
        Reading<double> reading(double? value) => Reading<double>(
              clock: clock,
              value: value,
              lastPingAt: now.subtract(pingAge),
            );

        final vehicle = Vehicle(
          vin: vin0007,
          reg: 'AP 16 MN 1357',
          model: 'eCargo 55',
          soc: reading(8),
          range: reading(15),
          speed: reading(0),
          batteryTemp: reading(36),
          odometer: reading(91004),
          lastPingAt: now.subtract(pingAge),
          ignitionOn: true,
        );

        whenListen(
          mockDetailBloc,
          const Stream<VehicleDetailState>.empty(),
          initialState: VehicleDetailLoaded(
            vehicle: vehicle,
            status: VehicleStatus.offline,
            verdicts: const ParameterVerdicts(
              soc: Verdict.stale,
              range: Verdict.stale,
              speed: Verdict.stale,
              batteryTemp: Verdict.stale,
              odometer: Verdict.stale,
            ),
            alerts: const [],
          ),
        );

        await tester.pumpWidget(pumpPage());
        await tester.pump();

        final styles = AppTheme.light().extension<VerdictTheme>()!;
        final socPill = tester.widget<VerdictPill>(
          find.byKey(const Key('reading-soc')),
        );

        expect(vehicle.vin, vin0007);
        expect(socPill.value, 8);
        expect(socPill.verdict, Verdict.stale);
        expect(socPill.verdict, isNot(Verdict.alert));
        expect(find.text('8.00 %'), findsOneWidget);
        expect(find.textContaining('data'), findsWidgets);

        final socColor =
            tester.widget<Text>(find.text('8.00 %')).style?.color;
        expect(socColor, styles.staleValueColor);
        expect(socColor, isNot(styles.alertValueColor));
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
