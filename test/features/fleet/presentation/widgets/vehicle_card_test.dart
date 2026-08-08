import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/core/widgets/alert_badge.dart';
import 'package:byte_beam/core/widgets/verdict_pill.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:byte_beam/features/fleet/domain/entities/reading.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:byte_beam/features/fleet/domain/rules/staleness_evaluator.dart';
import 'package:byte_beam/features/fleet/domain/rules/status_resolver.dart';
import 'package:byte_beam/features/fleet/presentation/widgets/vehicle_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeClock implements Clock {
  FakeClock(this._fixed);

  DateTime _fixed;

  @override
  DateTime now() => _fixed;

  void advance(Duration d) => _fixed = _fixed.add(d);
}

void main() {
  final now = DateTime(2026, 8, 7, 12, 10);
  late FakeClock clock;

  Vehicle buildVehicle({
    double? soc = 80,
    double? range = 172,
    Duration age = const Duration(minutes: 1),
  }) {
    Reading<double> reading(double? value) => Reading<double>(
          clock: clock,
          value: value,
          lastPingAt: now.subtract(age),
        );

    return Vehicle(
      vin: 'VIN0001',
      reg: 'KA 01 AB 1234',
      model: 'eCargo 55',
      soc: reading(soc),
      range: reading(range),
      speed: reading(42),
      batteryTemp: reading(31),
      odometer: reading(45210),
      lastPingAt: now.subtract(age),
      ignitionOn: true,
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }

  setUp(() {
    clock = FakeClock(now);
  });

  group('VehicleCard', () {
    testWidgets('hides AlertBadge when alertCount is 0', (tester) async {
      await tester.pumpWidget(
        wrap(
          VehicleCard(
            vehicle: buildVehicle(),
            status: VehicleStatus.moving,
            clock: clock,
          ),
        ),
      );

      expect(find.byType(AlertBadge), findsNothing);
      expect(find.text('KA 01 AB 1234'), findsOneWidget);
    });

    testWidgets('shows AlertBadge with count and critical severity', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          VehicleCard(
            vehicle: buildVehicle(),
            status: VehicleStatus.moving,
            clock: clock,
            alertCount: 2,
            alertSeverity: AlertSeverity.critical,
          ),
        ),
      );

      expect(find.byType(AlertBadge), findsOneWidget);
      expect(find.text('2 Alerts'), findsOneWidget);

      final badge = tester.widget<AlertBadge>(find.byType(AlertBadge));
      expect(badge.count, 2);
      expect(badge.severity, AlertSeverity.critical);
    });

    testWidgets('shows AlertBadge with warning severity', (tester) async {
      await tester.pumpWidget(
        wrap(
          VehicleCard(
            vehicle: buildVehicle(),
            status: VehicleStatus.idle,
            clock: clock,
            alertCount: 1,
            alertSeverity: AlertSeverity.warning,
          ),
        ),
      );

      final badge = tester.widget<AlertBadge>(find.byType(AlertBadge));
      expect(badge.count, 1);
      expect(badge.severity, AlertSeverity.warning);
      expect(find.text('1 Alert'), findsOneWidget);
    });

    testWidgets(
      'SOC and range use VerdictPill honesty: fresh values colored normal',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            VehicleCard(
              vehicle: buildVehicle(),
              status: VehicleStatus.moving,
              clock: clock,
            ),
          ),
        );

        final styles = AppTheme.light().extension<VerdictTheme>()!;

        final socPill = tester.widget<VerdictPill>(
          find.byKey(const Key('home-reading-soc')),
        );
        expect(socPill.verdict, Verdict.normal);
        expect(socPill.value, 80);
        expect(find.text('80 %'), findsOneWidget);
        expect(
          tester.widget<Text>(find.text('80 %')).style?.color,
          styles.normalValueColor,
        );

        final rangePill = tester.widget<VerdictPill>(
          find.byKey(const Key('home-reading-range')),
        );
        expect(rangePill.verdict, Verdict.normal);
        expect(rangePill.value, 172);
        expect(find.text('172 km'), findsOneWidget);
      },
    );

    testWidgets(
      'null SOC/range render dash "—" with no verdict (same as detail)',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            VehicleCard(
              vehicle: buildVehicle(soc: null, range: null),
              status: VehicleStatus.stopped,
              clock: clock,
            ),
          ),
        );

        final socPill = tester.widget<VerdictPill>(
          find.byKey(const Key('home-reading-soc')),
        );
        final rangePill = tester.widget<VerdictPill>(
          find.byKey(const Key('home-reading-range')),
        );

        expect(socPill.value, isNull);
        expect(socPill.verdict, isNull);
        expect(rangePill.value, isNull);
        expect(rangePill.verdict, isNull);
        expect(find.text('—'), findsNWidgets(2));
        expect(find.textContaining('%'), findsNothing);
        expect(find.textContaining('km'), findsNothing);
        expect(find.textContaining('old'), findsNothing);
      },
    );

    testWidgets(
      'stale SOC/range render dimmed value + age caption, not alert red '
      '(VIN0007-style honesty on home)',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            VehicleCard(
              vehicle: buildVehicle(
                soc: 8,
                range: 15,
                age: const Duration(seconds: 720),
              ),
              status: VehicleStatus.offline,
              clock: clock,
            ),
          ),
        );

        final styles = AppTheme.light().extension<VerdictTheme>()!;

        final socPill = tester.widget<VerdictPill>(
          find.byKey(const Key('home-reading-soc')),
        );
        expect(socPill.verdict, Verdict.stale);
        expect(socPill.verdict, isNot(Verdict.alert));
        expect(socPill.value, 8);

        expect(find.text('8 %'), findsOneWidget);
        expect(
          tester.widget<Text>(find.text('8 %')).style?.color,
          styles.staleValueColor,
        );
        expect(
          tester.widget<Text>(find.text('8 %')).style?.color,
          isNot(styles.alertValueColor),
        );
        expect(find.text('data 12 min old'), findsWidgets);

        final rangePill = tester.widget<VerdictPill>(
          find.byKey(const Key('home-reading-range')),
        );
        expect(rangePill.verdict, Verdict.stale);
        expect(find.text('15 km'), findsOneWidget);
      },
    );

    testWidgets(
      'fresh SOC below threshold shows ALERT color on home (not raw green)',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            VehicleCard(
              vehicle: buildVehicle(soc: 15, range: 34),
              status: VehicleStatus.moving,
              clock: clock,
            ),
          ),
        );

        final styles = AppTheme.light().extension<VerdictTheme>()!;
        final socPill = tester.widget<VerdictPill>(
          find.byKey(const Key('home-reading-soc')),
        );

        expect(socPill.verdict, Verdict.alert);
        expect(
          tester.widget<Text>(find.text('15 %')).style?.color,
          styles.alertValueColor,
        );
      },
    );
  });
}
