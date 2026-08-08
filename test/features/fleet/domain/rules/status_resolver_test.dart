import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/fleet/domain/entities/reading.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:byte_beam/features/fleet/domain/rules/status_resolver.dart';
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

  group('resolveStatus', () {
    group('precedence (first match wins)', () {
      test('1. lastPingAt older than 10 minutes -> offline, '
          'regardless of speed/ignition', () {
        final clock = FakeClock(now);
        final vehicle = _vehicle(
          clock: clock,
          lastPingAt: now.subtract(const Duration(minutes: 10, seconds: 1)),
          speed: 42,
          ignitionOn: true,
        );

        expect(resolveStatus(vehicle, clock), VehicleStatus.offline);
      });

      test('2. speed > 0 -> moving', () {
        final clock = FakeClock(now);
        final vehicle = _vehicle(
          clock: clock,
          lastPingAt: now.subtract(const Duration(minutes: 1)),
          speed: 12.5,
          ignitionOn: true,
        );

        expect(resolveStatus(vehicle, clock), VehicleStatus.moving);
      });

      test('2b. speed > 0 -> moving even when ignitionOn is false', () {
        final clock = FakeClock(now);
        final vehicle = _vehicle(
          clock: clock,
          lastPingAt: now.subtract(const Duration(minutes: 1)),
          speed: 12.5,
          ignitionOn: false,
        );

        expect(resolveStatus(vehicle, clock), VehicleStatus.moving);
      });

      test('2c. speed > 0 -> moving even when ignitionOn is null', () {
        final clock = FakeClock(now);
        final vehicle = _vehicle(
          clock: clock,
          lastPingAt: now.subtract(const Duration(minutes: 1)),
          speed: 12.5,
          ignitionOn: null,
        );

        expect(resolveStatus(vehicle, clock), VehicleStatus.moving);
      });

      test('3. speed == 0 and ignitionOn == true -> idle', () {
        final clock = FakeClock(now);
        final vehicle = _vehicle(
          clock: clock,
          lastPingAt: now.subtract(const Duration(minutes: 1)),
          speed: 0,
          ignitionOn: true,
        );

        expect(resolveStatus(vehicle, clock), VehicleStatus.idle);
      });

      test('4. ignitionOn == false -> stopped', () {
        final clock = FakeClock(now);
        final vehicle = _vehicle(
          clock: clock,
          lastPingAt: now.subtract(const Duration(minutes: 1)),
          speed: 0,
          ignitionOn: false,
        );

        expect(resolveStatus(vehicle, clock), VehicleStatus.stopped);
      });

      test('5. ignitionOn == null falls back to stopped (safe default)', () {
        // Brief §2 does not define null ignition; STOPPED is the safe default
        // when the vehicle is online and not moving.
        final clock = FakeClock(now);
        final vehicle = _vehicle(
          clock: clock,
          lastPingAt: now.subtract(const Duration(minutes: 1)),
          speed: 0,
          ignitionOn: null,
        );

        expect(resolveStatus(vehicle, clock), VehicleStatus.stopped);
      });
    });

    group('offline boundary', () {
      test('lastPingAt exactly 10:00 old -> offline', () {
        final clock = FakeClock(now);
        final vehicle = _vehicle(
          clock: clock,
          lastPingAt: now.subtract(const Duration(minutes: 10)),
          speed: 0,
          ignitionOn: false,
        );

        expect(resolveStatus(vehicle, clock), VehicleStatus.offline);
      });

      test('lastPingAt 9:59 old -> not offline (resolves to stopped)', () {
        final clock = FakeClock(now);
        final vehicle = _vehicle(
          clock: clock,
          lastPingAt: now.subtract(const Duration(minutes: 9, seconds: 59)),
          speed: 0,
          ignitionOn: false,
        );

        expect(resolveStatus(vehicle, clock), isNot(VehicleStatus.offline));
        expect(resolveStatus(vehicle, clock), VehicleStatus.stopped);
      });
    });
  });
}

Vehicle _vehicle({
  required Clock clock,
  required DateTime lastPingAt,
  required double? speed,
  required bool? ignitionOn,
}) {
  Reading<double> reading(double? value) => Reading<double>(
        clock: clock,
        value: value,
        lastPingAt: lastPingAt,
      );

  return Vehicle(
    vin: 'VIN-TEST',
    reg: 'REG-TEST',
    model: 'Model-Test',
    soc: reading(80),
    range: reading(200),
    speed: reading(speed),
    batteryTemp: reading(30),
    odometer: reading(1000),
    lastPingAt: lastPingAt,
    ignitionOn: ignitionOn,
  );
}
