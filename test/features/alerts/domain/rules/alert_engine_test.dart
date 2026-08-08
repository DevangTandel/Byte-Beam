import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:byte_beam/features/alerts/domain/rules/alert_engine.dart';
import 'package:byte_beam/features/fleet/domain/entities/reading.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:flutter_test/flutter_test.dart';

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
  const vin = 'VIN-ALERT-1';

  group('evaluateAlerts', () {
    test('1. SOC below 20% (fresh) -> one lowBattery warning', () {
      final clock = FakeClock(now);
      final vehicle = _vehicle(
        clock: clock,
        vin: vin,
        now: now,
        soc: 15,
        socAge: const Duration(minutes: 1),
        batteryTemp: 30,
      );

      final alerts = evaluateAlerts(vehicle, const [], clock);

      expect(alerts, hasLength(1));
      expect(alerts.single.kind, AlertKind.lowBattery);
      expect(alerts.single.severity, AlertSeverity.warning);
      expect(alerts.single.vin, vin);
      expect(alerts.single.isBasedOnStaleData, isFalse);
    });

    test('2. SOC below 10% (fresh) -> exactly one lowBattery critical '
        '(never stacks warning + critical)', () {
      final clock = FakeClock(now);
      final vehicle = _vehicle(
        clock: clock,
        vin: vin,
        now: now,
        soc: 5,
        socAge: const Duration(minutes: 1),
        batteryTemp: 30,
      );

      final alerts = evaluateAlerts(vehicle, const [], clock);

      expect(alerts, hasLength(1));
      expect(alerts.single.kind, AlertKind.lowBattery);
      expect(alerts.single.severity, AlertSeverity.critical);
      expect(
        alerts.where((a) => a.kind == AlertKind.lowBattery),
        hasLength(1),
      );
    });

    test('3. battery temp > 45C (fresh) -> one batteryOverheating critical', () {
      final clock = FakeClock(now);
      final vehicle = _vehicle(
        clock: clock,
        vin: vin,
        now: now,
        soc: 80,
        batteryTemp: 46,
        batteryTempAge: const Duration(minutes: 1),
      );

      final alerts = evaluateAlerts(vehicle, const [], clock);

      expect(alerts, hasLength(1));
      expect(alerts.single.kind, AlertKind.batteryOverheating);
      expect(alerts.single.severity, AlertSeverity.critical);
      expect(alerts.single.isBasedOnStaleData, isFalse);
    });

    test('4. SOC below 10% but STALE -> no NEW alert raised '
        '(staleness blocks opening alerts, §4.2)', () {
      // Contrast with case 5: previous is empty, so there is nothing to keep.
      // A stale breach must not open a brand-new alert.
      final clock = FakeClock(now);
      final vehicle = _vehicle(
        clock: clock,
        vin: vin,
        now: now,
        soc: 5,
        socAge: const Duration(minutes: 5, seconds: 1),
        batteryTemp: 30,
      );

      final alerts = evaluateAlerts(vehicle, const [], clock);

      expect(alerts, isEmpty);
    });

    test('5. existing alert + reading goes STALE -> alert PERSISTS with '
        'isBasedOnStaleData = true (existing alerts are flagged, not dropped)',
        () {
      // Contrast with case 4: same stale SOC breach, but an alert already
      // exists from a prior fresh tick. Staleness must NOT clear it — only
      // mark isBasedOnStaleData. New alerts stay blocked (case 4); survivors
      // are flagged (this case).
      final clock = FakeClock(now);
      const existingId = 'alert-low-battery-1';
      final previous = [
        Alert(
          id: existingId,
          vin: vin,
          kind: AlertKind.lowBattery,
          severity: AlertSeverity.critical,
          raisedAt: now.subtract(const Duration(minutes: 3)),
          isBasedOnStaleData: false,
        ),
      ];
      final vehicle = _vehicle(
        clock: clock,
        vin: vin,
        now: now,
        soc: 5,
        socAge: const Duration(minutes: 5, seconds: 1),
        batteryTemp: 30,
      );

      final alerts = evaluateAlerts(vehicle, previous, clock);

      expect(alerts, hasLength(1));
      expect(alerts.single.id, existingId);
      expect(alerts.single.kind, AlertKind.lowBattery);
      expect(alerts.single.isBasedOnStaleData, isTrue);
    });

    test('6. existing alert + reading recovers above threshold (fresh) '
        '-> alert removed (auto-resolve, §2.4)', () {
      final clock = FakeClock(now);
      final previous = [
        Alert(
          id: 'alert-low-battery-1',
          vin: vin,
          kind: AlertKind.lowBattery,
          severity: AlertSeverity.warning,
          raisedAt: now.subtract(const Duration(minutes: 2)),
          isBasedOnStaleData: false,
        ),
      ];
      final vehicle = _vehicle(
        clock: clock,
        vin: vin,
        now: now,
        soc: 25,
        socAge: const Duration(minutes: 1),
        batteryTemp: 30,
      );

      final alerts = evaluateAlerts(vehicle, previous, clock);

      expect(alerts, isEmpty);
    });

    test('7. existing alert still breaching and fresh -> persists unchanged, '
        'same id', () {
      final clock = FakeClock(now);
      final raisedAt = now.subtract(const Duration(minutes: 2));
      const existingId = 'alert-low-battery-stable';
      final previous = [
        Alert(
          id: existingId,
          vin: vin,
          kind: AlertKind.lowBattery,
          severity: AlertSeverity.warning,
          raisedAt: raisedAt,
          isBasedOnStaleData: false,
        ),
      ];
      final vehicle = _vehicle(
        clock: clock,
        vin: vin,
        now: now,
        soc: 15,
        socAge: const Duration(minutes: 1),
        batteryTemp: 30,
      );

      final alerts = evaluateAlerts(vehicle, previous, clock);

      expect(alerts, hasLength(1));
      expect(
        alerts.single,
        Alert(
          id: existingId,
          vin: vin,
          kind: AlertKind.lowBattery,
          severity: AlertSeverity.warning,
          raisedAt: raisedAt,
          isBasedOnStaleData: false,
        ),
      );
    });

    test('8. existing lowBattery WARNING escalates to CRITICAL on same id '
        'when fresh SOC drops below 10% (list length stays 1)', () {
      final clock = FakeClock(now);
      final raisedAt = now.subtract(const Duration(minutes: 2));
      const existingId = 'alert-low-battery-escalate';
      final previous = [
        Alert(
          id: existingId,
          vin: vin,
          kind: AlertKind.lowBattery,
          severity: AlertSeverity.warning,
          raisedAt: raisedAt,
          isBasedOnStaleData: false,
        ),
      ];
      final vehicle = _vehicle(
        clock: clock,
        vin: vin,
        now: now,
        soc: 5,
        socAge: const Duration(minutes: 1),
        batteryTemp: 30,
      );

      final alerts = evaluateAlerts(vehicle, previous, clock);

      expect(alerts, hasLength(1));
      expect(alerts.single.id, existingId);
      expect(alerts.single.kind, AlertKind.lowBattery);
      expect(alerts.single.severity, AlertSeverity.critical);
      expect(alerts.single.raisedAt, raisedAt);
      expect(
        alerts.where((a) => a.kind == AlertKind.lowBattery),
        hasLength(1),
        reason: 'escalation must not stack a second lowBattery alert',
      );
    });

    test('9. fresh SOC < 20% and temp > 45C -> two distinct alerts '
        '(lowBattery + batteryOverheating co-exist)', () {
      final clock = FakeClock(now);
      final vehicle = _vehicle(
        clock: clock,
        vin: vin,
        now: now,
        soc: 15,
        socAge: const Duration(minutes: 1),
        batteryTemp: 46,
        batteryTempAge: const Duration(minutes: 1),
      );

      final alerts = evaluateAlerts(vehicle, const [], clock);

      expect(alerts, hasLength(2));
      expect(
        alerts.map((a) => a.kind).toSet(),
        {AlertKind.lowBattery, AlertKind.batteryOverheating},
      );
      expect(
        alerts.singleWhere((a) => a.kind == AlertKind.lowBattery).severity,
        AlertSeverity.warning,
      );
      expect(
        alerts
            .singleWhere((a) => a.kind == AlertKind.batteryOverheating)
            .severity,
        AlertSeverity.critical,
      );
      expect(alerts[0].id, isNot(alerts[1].id));
    });
  });
}

Vehicle _vehicle({
  required Clock clock,
  required String vin,
  required DateTime now,
  required double soc,
  required double batteryTemp,
  Duration socAge = Duration.zero,
  Duration batteryTempAge = Duration.zero,
}) {
  Reading<double> reading(double value, Duration age) => Reading<double>(
        clock: clock,
        value: value,
        lastPingAt: now.subtract(age),
      );

  return Vehicle(
    vin: vin,
    reg: 'REG-1',
    model: 'Model-Test',
    soc: reading(soc, socAge),
    range: reading(200, Duration.zero),
    speed: reading(0, Duration.zero),
    batteryTemp: reading(batteryTemp, batteryTempAge),
    odometer: reading(1000, Duration.zero),
    lastPingAt: now,
    ignitionOn: false,
  );
}
