import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:byte_beam/features/alerts/presentation/bloc/alerts_cubit.dart';
import 'package:byte_beam/features/fleet/domain/entities/reading.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([AlertPersistence])
import 'alerts_cubit_test.mocks.dart';

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
  late StreamController<List<Vehicle>> vehiclesController;
  late MockAlertPersistence mockPersistence;
  late AlertsCubit cubit;

  Vehicle vehicle({
    required double soc,
    double batteryTemp = 30,
  }) {
    Reading<double> reading(double? value) => Reading<double>(
          clock: clock,
          value: value,
          lastPingAt: now.subtract(const Duration(minutes: 1)),
        );

    return Vehicle(
      vin: vin,
      reg: 'MH 12 EF 9012',
      model: 'eVan 30',
      soc: reading(soc),
      range: reading(34),
      speed: reading(38),
      batteryTemp: reading(batteryTemp),
      odometer: reading(12780),
      lastPingAt: now.subtract(const Duration(minutes: 1)),
      ignitionOn: true,
    );
  }

  AlertsCubit buildCubit() => AlertsCubit(
        vehicleStream: vehiclesController.stream,
        clock: clock,
        persistence: mockPersistence,
      );

  setUp(() {
    clock = FakeClock(now);
    vehiclesController = StreamController<List<Vehicle>>.broadcast();
    mockPersistence = MockAlertPersistence();
  });

  tearDown(() async {
    if (!cubit.isClosed) {
      await cubit.close();
    }
    await vehiclesController.close();
  });

  group('AlertsCubit', () {
    test('vehicle stream SOC breach emits state containing the new alert', () {
      fakeAsync((async) {
        cubit = buildCubit();

        expect(cubit.state.active, isEmpty);

        vehiclesController.add([vehicle(soc: 15)]);
        async.flushMicrotasks();

        expect(cubit.state.active, hasLength(1));
        expect(cubit.state.active.single.kind, AlertKind.lowBattery);
        expect(cubit.state.active.single.severity, AlertSeverity.warning);
        expect(cubit.state.active.single.vin, vin);
        expect(cubit.state.undoable, isNull);
      });
    });

    test('dismiss moves alert to undoable slot with a 5-second window', () {
      fakeAsync((async) {
        cubit = buildCubit();

        vehiclesController.add([vehicle(soc: 15)]);
        async.flushMicrotasks();

        final alertId = cubit.state.active.single.id;

        cubit.dismiss(alertId, DismissReason.onIt);

        expect(cubit.state.active, isEmpty);
        expect(cubit.state.undoable, isNotNull);
        expect(cubit.state.undoable!.alert.id, alertId);
        expect(cubit.state.undoable!.reason, DismissReason.onIt);
        expect(
          cubit.state.undoable!.expiresAt,
          clock.now().add(const Duration(seconds: 5)),
        );
      });
    });

    test('undo() within the 5s window restores the alert to active', () {
      fakeAsync((async) {
        cubit = buildCubit();

        vehiclesController.add([vehicle(soc: 15)]);
        async.flushMicrotasks();

        final alert = cubit.state.active.single;
        cubit.dismiss(alert.id, DismissReason.wrongAlert);

        async.elapse(const Duration(seconds: 4));
        cubit.undo();

        expect(cubit.state.undoable, isNull);
        expect(cubit.state.active, hasLength(1));
        expect(cubit.state.active.single.id, alert.id);
        expect(cubit.state.active.single.kind, AlertKind.lowBattery);
      });
    });

    test('after undo window elapses, alert stays dismissed and continuous '
        'breach updates do NOT resurrect it', () {
      fakeAsync((async) {
        cubit = buildCubit();

        vehiclesController.add([vehicle(soc: 15)]);
        async.flushMicrotasks();

        final alertId = cubit.state.active.single.id;
        cubit.dismiss(alertId, DismissReason.somethingElse);

        // Undo window expires — dismissal becomes permanent for this instance.
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(cubit.state.active, isEmpty);
        expect(cubit.state.undoable, isNull);

        // Still breaching (never resolved) — must not resurrect the same alert.
        vehiclesController.add([vehicle(soc: 12)]);
        async.flushMicrotasks();

        expect(
          cubit.state.active,
          isEmpty,
          reason: 'continuous breach after dismiss must not resurrect',
        );
      });
    });

    /// SIGN-OFF NEEDED (brief §2.4 is silent on rebreach after resolve).
    ///
    /// Chosen behavior: YES — a fresh breach after the condition has resolved
    /// counts as a new alert occurrence. Dismissal is tied to the alert
    /// instance/session; once the underlying condition clears, a later breach
    /// is a new instance (new id / new raise), bypassing the old dismissal.
    test('SIGN-OFF: resolve then rebreach raises a NEW alert '
        '(dismissal does not permanently suppress the kind)', () {
      fakeAsync((async) {
        cubit = buildCubit();

        // 1) Breach → alert.
        vehiclesController.add([vehicle(soc: 15)]);
        async.flushMicrotasks();
        final firstId = cubit.state.active.single.id;

        // 2) Dismiss and let undo window expire.
        cubit.dismiss(firstId, DismissReason.onIt);
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(cubit.state.active, isEmpty);

        // 3) Resolve (SOC recovers above threshold).
        vehiclesController.add([vehicle(soc: 25)]);
        async.flushMicrotasks();
        expect(cubit.state.active, isEmpty);

        // 4) Rebreach — new occurrence, must surface again.
        vehiclesController.add([vehicle(soc: 15)]);
        async.flushMicrotasks();

        expect(cubit.state.active, hasLength(1));
        expect(cubit.state.active.single.kind, AlertKind.lowBattery);
        expect(
          cubit.state.active.single.id,
          isNot(firstId),
          reason: 'rebreach after resolve is a new alert instance',
        );
      });
    });

    test('dismissed state is in-memory only — no persistence calls', () {
      fakeAsync((async) {
        cubit = buildCubit();

        vehiclesController.add([vehicle(soc: 15)]);
        async.flushMicrotasks();

        final alertId = cubit.state.active.single.id;
        cubit.dismiss(alertId, DismissReason.onIt);
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        cubit.undo(); // no-op after window; still must not touch persistence
        vehiclesController.add([vehicle(soc: 15)]);
        async.flushMicrotasks();

        // App-restart semantics: dismissal is not written/read from storage.
        verifyZeroInteractions(mockPersistence);
      });
    });

    test(
      'dismissing a second alert cancels the prior undo timer '
      '(only the latest dismissal finalizes after 5s)',
      () {
        fakeAsync((async) {
          cubit = buildCubit();

          vehiclesController.add([
            vehicle(soc: 15),
            Vehicle(
              vin: 'VIN0005',
              reg: 'TN 09 IJ 7890',
              model: 'eCargo 55',
              soc: Reading<double>(
                clock: clock,
                value: 12,
                lastPingAt: now.subtract(const Duration(minutes: 1)),
              ),
              range: Reading<double>(
                clock: clock,
                value: 50,
                lastPingAt: now.subtract(const Duration(minutes: 1)),
              ),
              speed: Reading<double>(
                clock: clock,
                value: 12,
                lastPingAt: now.subtract(const Duration(minutes: 1)),
              ),
              batteryTemp: Reading<double>(
                clock: clock,
                value: 30,
                lastPingAt: now.subtract(const Duration(minutes: 1)),
              ),
              odometer: Reading<double>(
                clock: clock,
                value: 1000,
                lastPingAt: now.subtract(const Duration(minutes: 1)),
              ),
              lastPingAt: now.subtract(const Duration(minutes: 1)),
              ignitionOn: true,
            ),
          ]);
          async.flushMicrotasks();
          expect(cubit.state.active, hasLength(2));

          final first = cubit.state.active.first;
          final second = cubit.state.active.last;
          expect(first.id, isNot(second.id));

          cubit.dismiss(first.id, DismissReason.onIt);
          expect(cubit.state.undoable!.alert.id, first.id);

          // Re-dismiss within the window replaces undoable and cancels timer.
          async.elapse(const Duration(seconds: 2));
          cubit.dismiss(second.id, DismissReason.wrongAlert);
          expect(cubit.state.undoable!.alert.id, second.id);
          expect(cubit.state.active, isEmpty);

          // Only the second dismissal's 5s window should finalize.
          async.elapse(const Duration(seconds: 5));
          async.flushMicrotasks();
          expect(cubit.state.undoable, isNull);
          expect(cubit.state.active, isEmpty);

          // Continuous breach: first kind can resurface (never suppressed);
          // second stays suppressed for this session.
          vehiclesController.add([
            vehicle(soc: 15),
            Vehicle(
              vin: 'VIN0005',
              reg: 'TN 09 IJ 7890',
              model: 'eCargo 55',
              soc: Reading<double>(
                clock: clock,
                value: 12,
                lastPingAt: now.subtract(const Duration(minutes: 1)),
              ),
              range: Reading<double>(
                clock: clock,
                value: 50,
                lastPingAt: now.subtract(const Duration(minutes: 1)),
              ),
              speed: Reading<double>(
                clock: clock,
                value: 12,
                lastPingAt: now.subtract(const Duration(minutes: 1)),
              ),
              batteryTemp: Reading<double>(
                clock: clock,
                value: 30,
                lastPingAt: now.subtract(const Duration(minutes: 1)),
              ),
              odometer: Reading<double>(
                clock: clock,
                value: 1000,
                lastPingAt: now.subtract(const Duration(minutes: 1)),
              ),
              lastPingAt: now.subtract(const Duration(minutes: 1)),
              ignitionOn: true,
            ),
          ]);
          async.flushMicrotasks();

          expect(
            cubit.state.active.any((a) => a.vin == vin),
            isTrue,
            reason: 'first dismissal was replaced, not finalized/suppressed',
          );
          expect(
            cubit.state.active.any((a) => a.vin == 'VIN0005'),
            isFalse,
            reason: 'second dismissal finalized after its own 5s window',
          );
        });
      },
    );

    test(
      'close() cancels undo timer so it cannot fire on a disposed cubit',
      () {
        fakeAsync((async) {
          cubit = buildCubit();

          vehiclesController.add([vehicle(soc: 15)]);
          async.flushMicrotasks();
          final alertId = cubit.state.active.single.id;
          cubit.dismiss(alertId, DismissReason.onIt);
          expect(cubit.state.undoable, isNotNull);
          expect(async.pendingTimers, isNotEmpty);

          // Navigate-away / dispose mid-window cancels the undo Timer.
          // ignore: unawaited_futures
          cubit.close();
          async.flushMicrotasks();

          async.elapse(const Duration(seconds: 5));
          async.flushMicrotasks();

          // Timer did not fire: undoable was never cleared by _onUndoWindowElapsed.
          expect(cubit.state.undoable, isNotNull);
          expect(cubit.state.undoable!.alert.id, alertId);
        });
      },
    );

    blocTest<AlertsCubit, AlertsState>(
      'emits active alert on SOC breach (bloc_test stream assertion)',
      build: () {
        cubit = buildCubit();
        return cubit;
      },
      act: (c) {
        vehiclesController.add([vehicle(soc: 8)]);
      },
      wait: const Duration(milliseconds: 10),
      expect: () => [
        isA<AlertsState>()
            .having((s) => s.active, 'active', hasLength(1))
            .having(
              (s) => s.active.single.severity,
              'severity',
              AlertSeverity.critical,
            )
            .having((s) => s.undoable, 'undoable', isNull),
      ],
    );
  });
}
