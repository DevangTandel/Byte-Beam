import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:byte_beam/core/clock/clock.dart';
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
/// For each vehicle with `speedKmh > 0` (moving), excluding frozen offline
/// vehicles (`lastPingSecondsAgo >= 600`, i.e. VIN0007):
///   - `socDelta = 1.0 + (random.nextDouble() * 0.2 - 0.1)`  // ≈ 1 ± 0.1
///   - `socPercent -= socDelta` (battery % only decreases)
///   - `rangeKm = socPercent / 100 * 532` (full pack = 532 km)
///   - `odometerKm += speedKmh * (3 / 3600)`                 // exact km in 3s
///
/// Offline vehicles are emitted unchanged: no soc/odo/lastPing mutation and
/// no Random draws consumed for them.
///
/// Expected Random(42) first-tick moving deltas (VIN0001, VIN0003, VIN0005):
///   VIN0001 socDelta = 0.9301850911955949
///   VIN0003 socDelta = 1.0208295945072243
///   VIN0005 socDelta = 1.032336203157413
void main() {
  final launchAt = DateTime(2026, 8, 7, 12, 0, 0);

  // Exact first-tick values produced by Random(42) under the contract above.
  const expectedVin0003SocAfterTick1 = 15.979170405492775;
  const expectedVin0003RangeAfterTick1 =
      expectedVin0003SocAfterTick1 / 100 * kFullBatteryRangeKm;
  const expectedVin0001OdoAfterTick1 = 45210.035;
  const expectedVin0003OdoAfterTick1 = 12780.031666666666;
  const expectedVin0005OdoAfterTick1 = 67002.01;

  group('MockTelemetryDataSource.watchFleet', () {
    test('emits seed, ticks every 3s with deterministic Random(42) mutations, '
        'and freezes VIN0007 (offline) across ticks', () {
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

        // Snapshot VIN0007 (offline) from the seed emission — must never drift.
        final vin0007Seed = initial.singleWhere((v) => v.vin == 'VIN0007');
        expect(vin0007Seed.lastPingSecondsAgo, 720);
        expect(vin0007Seed.socPercent, 8);
        expect(vin0007Seed.rangeKm, rangeKmFromSoc(8));
        expect(vin0007Seed.odometerKm, 91004);
        expect(vin0007Seed.speedKmh, 0);
        expect(vin0007Seed.batteryTempC, 36);
        expect(vin0007Seed.ignitionOn, isTrue);

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
          closeTo(1.0208295945072243, 1e-12),
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

        // Moving fleet exact odometer sequence after tick 1.
        expect(
          tick1.singleWhere((v) => v.vin == 'VIN0001').odometerKm,
          expectedVin0001OdoAfterTick1,
        );
        expect(
          tick1.singleWhere((v) => v.vin == 'VIN0005').odometerKm,
          expectedVin0005OdoAfterTick1,
        );

        // VIN0007: values AND lastPing must be identical to seed (not advanced).
        final vin0007Tick1 = tick1.singleWhere((v) => v.vin == 'VIN0007');
        expect(
          vin0007Tick1,
          vin0007Seed,
          reason: 'VIN0007 must be referentially/value-equal to seed after tick 1',
        );
        expect(vin0007Tick1.lastPingSecondsAgo, 720);
        expect(vin0007Tick1.socPercent, vin0007Seed.socPercent);
        expect(vin0007Tick1.odometerKm, vin0007Seed.odometerKm);

        // --- tick 2 @ +6s ---
        async.elapse(const Duration(seconds: 3));
        expect(emissions, hasLength(3));

        // --- tick 3 @ +9s ---
        async.elapse(const Duration(seconds: 3));
        expect(emissions, hasLength(4));

        // Moving odometers strictly increase tick-over-tick.
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

        // Idle / non-moving (except asserting VIN0002 odo frozen as control).
        final vin0002Seed = initial.singleWhere((v) => v.vin == 'VIN0002');
        for (final emission in emissions) {
          expect(
            emission.singleWhere((v) => v.vin == 'VIN0002').odometerKm,
            vin0002Seed.odometerKm,
          );
        }

        sub.cancel();
        source.dispose();
      });
    });

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
