import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:byte_beam/features/alerts/domain/rules/alert_engine.dart';
import 'package:byte_beam/features/fleet/data/datasources/mock_telemetry_data_source.dart';
import 'package:byte_beam/features/fleet/data/models/vehicle_model.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test-only clock with a fixed [now] value.
class FakeClock implements Clock {
  FakeClock(this._fixed);

  DateTime _fixed;

  @override
  DateTime now() => _fixed;

  void advance(Duration d) => _fixed = _fixed.add(d);
}

/// Reads [assets/seed_fleet.json] from disk (not the Flutter asset bundle).
List<VehicleModel> loadSeedFleet() {
  final file = File('assets/seed_fleet.json');
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return [
    for (final json in decoded.cast<Map<String, dynamic>>())
      VehicleModel.fromJson(json),
  ];
}

/// Tick mutation contract the mock must follow (Random draws in seed order):
///
/// Offline (`lastPingSecondsAgo >= 600`, VIN0007): frozen — no field changes,
/// no Random draws.
///
/// Idle / stopped (`speedKmh <= 0`, online): `lastPingSecondsAgo = 0` only;
/// no Random draws; other fields unchanged.
///
/// Moving (`speedKmh > 0`):
///   - `socDelta = 1.0 + (random.nextDouble() * 0.2 - 0.1)`  // ≈ 1 ± 0.1
///   - `speedJitter = random.nextDouble() * 4 - 2`           // ±2 km/h
///   - `socPercent -= socDelta` (battery % only decreases)
///   - `rangeKm = socPercent / 100 * 532`
///   - `odometerKm += speedKmh * (3 / 3600)`  // uses pre-jitter speed
///   - `speedKmh = (speedKmh + speedJitter).clamp(1, 120)`
///   - `lastPingSecondsAgo = 0`
///
/// Expected Random(42) first-tick moving draws (VIN0001, VIN0003, VIN0005):
///   VIN0001 socDelta=0.9301850911955949 speedJitter=0.41659189014448694
///   VIN0003 socDelta=1.032336203157413  speedJitter=-1.116034560444946
///   VIN0005 socDelta=1.058088066430467  speedJitter=-1.35771182085149
void main() {
  final launchAt = DateTime(2026, 8, 7, 12);

  // Exact first-tick values produced by Random(42) under the contract above.
  const expectedVin0003SocAfterTick1 = 15.967663796842587;
  const expectedVin0003RangeAfterTick1 =
      expectedVin0003SocAfterTick1 / 100 * kFullBatteryRangeKm;
  const expectedVin0003SpeedAfterTick1 = 36.883965439555055;
  const expectedVin0001SpeedAfterTick1 = 42.41659189014449;
  const expectedVin0005SpeedAfterTick1 = 10.64228817914851;
  const expectedVin0001OdoAfterTick1 = 45210.035;
  const expectedVin0003OdoAfterTick1 = 12780.031666666666;
  const expectedVin0005OdoAfterTick1 = 67002.01;

  group('MockTelemetryDataSource.watchFleet', () {
    test('emits seed, ticks every 3s with deterministic Random(42) mutations, '
        'refreshes online lastPing, and freezes VIN0007 (offline)', () {
      fakeAsync((async) {
        final clock = FakeClock(launchAt);
        final seed = loadSeedFleet();
        final source = MockTelemetryDataSource(
          clock: clock,
          seed: seed,
          random: Random(42),
        );

        final emissions = <List<VehicleModel>>[];
        final sub = source.watchFleet().listen(emissions.add);

        // Initial emission on listen (construction + subscribe).
        async.flushMicrotasks();
        expect(emissions, hasLength(1));
        expect(emissions[0], hasLength(8));
        expect(
          emissions[0].map((v) => v.vin).toList(),
          [
            'VIN0001',
            'VIN0002',
            'VIN0003',
            'VIN0004',
            'VIN0005',
            'VIN0006',
            'VIN0007',
            'VIN0008',
          ],
        );

        final initial = emissions[0];
        final vin0003Seed = initial[2];
        expect(vin0003Seed.vin, 'VIN0003');
        expect(vin0003Seed.socPercent, 17);
        expect(vin0003Seed.rangeKm, rangeKmFromSoc(17));
        expect(vin0003Seed.speedKmh, 38);
        expect(vin0003Seed.lastPingSecondsAgo, 5);

        // Snapshot VIN0007 (offline) from the seed emission — must never drift.
        final vin0007Seed = initial.singleWhere((v) => v.vin == 'VIN0007');
        expect(vin0007Seed.lastPingSecondsAgo, 720);
        expect(vin0007Seed.socPercent, 8);
        expect(vin0007Seed.rangeKm, rangeKmFromSoc(8));
        expect(vin0007Seed.odometerKm, 91004);
        expect(vin0007Seed.speedKmh, 0);
        expect(vin0007Seed.batteryTempC, 36);
        expect(vin0007Seed.ignitionOn, isTrue);

        // Snapshot idle VIN0002 — other values frozen; lastPing refreshes.
        final vin0002Seed = initial.singleWhere((v) => v.vin == 'VIN0002');
        expect(vin0002Seed.speedKmh, 0);
        expect(vin0002Seed.lastPingSecondsAgo, 8);

        // --- tick 1 @ +3s ---
        async.elapse(const Duration(seconds: 3));
        expect(emissions, hasLength(2), reason: 'new emission after 3 seconds');

        final tick1 = emissions[1];
        expect(tick1, hasLength(8));

        final vin0003Tick1 = tick1[2];
        expect(vin0003Tick1.vin, 'VIN0003');
        expect(
          vin0003Tick1.socPercent,
          expectedVin0003SocAfterTick1,
          reason: 'VIN0003 soc reduced by ~1 via Random(42) first-tick delta',
        );
        expect(
          vin0003Seed.socPercent! - vin0003Tick1.socPercent!,
          closeTo(1.032336203157413, 1e-12),
        );
        expect(
          vin0003Tick1.rangeKm,
          expectedVin0003RangeAfterTick1,
          reason: 'range tracks SOC at 532 km / 100%',
        );
        expect(
          vin0003Tick1.socPercent!,
          lessThan(vin0003Seed.socPercent!),
          reason: 'battery % must decrease on each moving tick',
        );
        expect(vin0003Tick1.odometerKm, expectedVin0003OdoAfterTick1);
        expect(
          vin0003Tick1.speedKmh,
          expectedVin0003SpeedAfterTick1,
          reason: 'moving speed jitters by a few km/h each tick',
        );
        expect(vin0003Tick1.speedKmh, isNot(vin0003Seed.speedKmh));
        expect(vin0003Tick1.lastPingSecondsAgo, 0);

        // Moving fleet exact odometer + speed sequence after tick 1.
        final vin0001Tick1 = tick1.singleWhere((v) => v.vin == 'VIN0001');
        expect(vin0001Tick1.odometerKm, expectedVin0001OdoAfterTick1);
        expect(vin0001Tick1.speedKmh, expectedVin0001SpeedAfterTick1);
        expect(vin0001Tick1.lastPingSecondsAgo, 0);

        final vin0005Tick1 = tick1.singleWhere((v) => v.vin == 'VIN0005');
        expect(vin0005Tick1.odometerKm, expectedVin0005OdoAfterTick1);
        expect(vin0005Tick1.speedKmh, expectedVin0005SpeedAfterTick1);
        expect(vin0005Tick1.lastPingSecondsAgo, 0);

        // VIN0007: values AND lastPing must be identical to seed (not advanced).
        final vin0007Tick1 = tick1.singleWhere((v) => v.vin == 'VIN0007');
        expect(
          vin0007Tick1,
          vin0007Seed,
          reason: 'VIN0007 must be value-equal to seed after tick 1',
        );
        expect(vin0007Tick1.lastPingSecondsAgo, 720);

        // Idle/stopped: lastPing refreshed; other fields unchanged.
        final vin0002Tick1 = tick1.singleWhere((v) => v.vin == 'VIN0002');
        expect(vin0002Tick1.lastPingSecondsAgo, 0);
        expect(vin0002Tick1.socPercent, vin0002Seed.socPercent);
        expect(vin0002Tick1.rangeKm, vin0002Seed.rangeKm);
        expect(vin0002Tick1.speedKmh, vin0002Seed.speedKmh);
        expect(vin0002Tick1.odometerKm, vin0002Seed.odometerKm);
        expect(vin0002Tick1.batteryTempC, vin0002Seed.batteryTempC);
        expect(vin0002Tick1.ignitionOn, vin0002Seed.ignitionOn);

        final vin0004Seed = initial.singleWhere((v) => v.vin == 'VIN0004');
        final vin0004Tick1 = tick1.singleWhere((v) => v.vin == 'VIN0004');
        expect(vin0004Tick1.lastPingSecondsAgo, 0);
        expect(vin0004Tick1.socPercent, vin0004Seed.socPercent);
        expect(vin0004Tick1.speedKmh, 0);
        expect(vin0004Tick1.odometerKm, vin0004Seed.odometerKm);

        // VIN0006: seed rangeKm null must survive mock normalize + idle ticks.
        final vin0006Seed = initial.singleWhere((v) => v.vin == 'VIN0006');
        expect(vin0006Seed.socPercent, 44);
        expect(vin0006Seed.rangeKm, isNull);
        expect(vin0006Seed.batteryTempC, isNull);
        final vin0006Tick1 = tick1.singleWhere((v) => v.vin == 'VIN0006');
        expect(vin0006Tick1.rangeKm, isNull);
        expect(vin0006Tick1.batteryTempC, isNull);
        expect(vin0006Tick1.lastPingSecondsAgo, 0);

        final vin0008Seed = initial.singleWhere((v) => v.vin == 'VIN0008');
        final vin0008Tick1 = tick1.singleWhere((v) => v.vin == 'VIN0008');
        expect(vin0008Tick1.lastPingSecondsAgo, 0);
        expect(vin0008Tick1.socPercent, isNull);
        expect(vin0008Tick1.rangeKm, isNull);
        expect(vin0008Tick1.odometerKm, vin0008Seed.odometerKm);

        // --- tick 2 @ +6s ---
        async.elapse(const Duration(seconds: 3));
        expect(emissions, hasLength(3));

        // --- tick 3 @ +9s ---
        async.elapse(const Duration(seconds: 3));
        expect(emissions, hasLength(4));

        // Moving odometers strictly increase; speeds vary across ticks.
        for (final vin in ['VIN0001', 'VIN0003', 'VIN0005']) {
          final odos = [
            for (final emission in emissions)
              emission.singleWhere((v) => v.vin == vin).odometerKm,
          ];
          for (var i = 1; i < odos.length; i++) {
            expect(
              odos[i],
              greaterThan(odos[i - 1]),
              reason: '$vin odometer must strictly increase at emission $i',
            );
          }

          final speeds = [
            for (final emission in emissions.skip(1))
              emission.singleWhere((v) => v.vin == vin).speedKmh,
          ];
          expect(
            speeds.toSet().length,
            greaterThan(1),
            reason: '$vin speed must jitter across ticks',
          );
          for (final speed in speeds) {
            expect(speed, greaterThan(0));
          }
          for (final emission in emissions.skip(1)) {
            expect(
              emission.singleWhere((v) => v.vin == vin).lastPingSecondsAgo,
              0,
            );
          }
        }

        // VIN0007 never changes across the full sequence (the critical case).
        for (var i = 0; i < emissions.length; i++) {
          final v7 = emissions[i].singleWhere((v) => v.vin == 'VIN0007');
          expect(
            v7,
            vin0007Seed,
            reason: 'VIN0007 must be unchanged at emission $i '
                '(offline: no value mutation, lastPing must not advance)',
          );
          expect(
            v7.lastPingSecondsAgo,
            720,
            reason: 'VIN0007 lastPingSecondsAgo must stay 720 at emission $i',
          );
        }

        // Idle VIN0002: odo/soc/speed frozen; lastPing stays refreshed at 0.
        for (final emission in emissions.skip(1)) {
          final v2 = emission.singleWhere((v) => v.vin == 'VIN0002');
          expect(v2.odometerKm, vin0002Seed.odometerKm);
          expect(v2.socPercent, vin0002Seed.socPercent);
          expect(v2.speedKmh, 0);
          expect(v2.lastPingSecondsAgo, 0);
        }

        sub.cancel();
        source.dispose();
      });
    });

    test(
      'VIN0003 drains ~1%/tick live: already <20% warning, then escalates '
      'to CRITICAL below 10% on the same alert id',
      () {
        fakeAsync((async) {
          final clock = FakeClock(launchAt);
          final source = MockTelemetryDataSource(
            clock: clock,
            seed: loadSeedFleet(),
            random: Random(42),
          );

          final emissions = <List<VehicleModel>>[];
          final sub = source.watchFleet().listen(emissions.add);
          async.flushMicrotasks();

          var previous = <Alert>[];
          var sawWarning = false;
          String? alertId;
          var sawCritical = false;

          for (var tick = 0; tick < 25; tick++) {
            final model =
                emissions.last.singleWhere((v) => v.vin == 'VIN0003');
            final vehicle = model.toDomain(clock);
            final alerts = evaluateAlerts(vehicle, previous, clock);
            previous = alerts;

            final lowBattery = alerts.where(
              (a) => a.kind == AlertKind.lowBattery,
            );
            if (lowBattery.isEmpty) {
              async.elapse(kTelemetryTick);
              continue;
            }

            final alert = lowBattery.single;
            alertId ??= alert.id;
            expect(alert.id, alertId, reason: 'same alert escalates in place');

            if (alert.severity == AlertSeverity.warning) {
              sawWarning = true;
              expect(model.socPercent, lessThan(20));
              expect(model.socPercent, greaterThanOrEqualTo(10));
            }
            if (alert.severity == AlertSeverity.critical) {
              sawCritical = true;
              expect(model.socPercent, lessThan(10));
              break;
            }

            async.elapse(kTelemetryTick);
          }

          expect(sawWarning, isTrue, reason: 'VIN0003 seed 17% is <20%');
          expect(
            sawCritical,
            isTrue,
            reason: 'live ticks must drain VIN0003 SOC below 10%',
          );

          sub.cancel();
          source.dispose();
        });
      },
    );

    test('after dispose(), no further emissions even when fake time advances',
        () {
      fakeAsync((async) {
        final clock = FakeClock(launchAt);
        final source = MockTelemetryDataSource(
          clock: clock,
          seed: loadSeedFleet(),
          random: Random(42),
        );

        final emissions = <List<VehicleModel>>[];
        final sub = source.watchFleet().listen(emissions.add);

        async.flushMicrotasks();
        expect(emissions, hasLength(1));

        async.elapse(const Duration(seconds: 3));
        expect(emissions, hasLength(2));

        source.dispose();
        final countAtDispose = emissions.length;

        async.elapse(const Duration(seconds: 3));
        async.elapse(const Duration(seconds: 9));
        async.flushMicrotasks();

        expect(
          emissions,
          hasLength(countAtDispose),
          reason: 'dispose() must cancel Timer.periodic; no ticks after dispose',
        );

        sub.cancel();
      });
    });
  });
}
