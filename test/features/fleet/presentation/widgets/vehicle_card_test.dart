import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/core/widgets/alert_badge.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:byte_beam/features/fleet/domain/entities/reading.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
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

  Vehicle buildVehicle() {
    Reading<double> reading(double? value) => Reading<double>(
          clock: clock,
          value: value,
          lastPingAt: now.subtract(const Duration(minutes: 1)),
        );

    return Vehicle(
      vin: 'VIN0001',
      reg: 'KA 01 AB 1234',
      model: 'eCargo 55',
      soc: reading(80),
      range: reading(172),
      speed: reading(42),
      batteryTemp: reading(31),
      odometer: reading(45210),
      lastPingAt: now.subtract(const Duration(minutes: 1)),
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
            alertCount: 2,
            alertSeverity: AlertSeverity.critical,
          ),
        ),
      );

      expect(find.byType(AlertBadge), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

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
            alertCount: 1,
            alertSeverity: AlertSeverity.warning,
          ),
        ),
      );

      final badge = tester.widget<AlertBadge>(find.byType(AlertBadge));
      expect(badge.count, 1);
      expect(badge.severity, AlertSeverity.warning);
    });
  });
}
