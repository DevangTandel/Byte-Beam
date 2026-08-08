import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/fleet/domain/entities/reading.dart';
import 'package:byte_beam/features/fleet/domain/rules/staleness_evaluator.dart';
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
  final now = DateTime(2026, 8, 7, 12, 10);
  const bounds = ThresholdBounds(min: 20, max: 80);

  group('evaluateStaleness', () {
    test('null value -> null (no verdict; UI shows dash)', () {
      final clock = FakeClock(now);
      final reading = Reading<double>(
        clock: clock,
        lastPingAt: now.subtract(const Duration(minutes: 1)),
      );

      expect(evaluateStaleness(reading, bounds, clock), isNull);
    });

    test('non-null, fresh (age <= 5min), within thresholds -> normal', () {
      final clock = FakeClock(now);
      final reading = Reading<double>(
        clock: clock,
        value: 50,
        lastPingAt: now.subtract(const Duration(minutes: 5)),
      );

      expect(evaluateStaleness(reading, bounds, clock), Verdict.normal);
    });

    group('non-null, fresh, outside thresholds -> alert', () {
      test('below min', () {
        final clock = FakeClock(now);
        final reading = Reading<double>(
          clock: clock,
          value: 19.9,
          lastPingAt: now.subtract(const Duration(minutes: 1)),
        );

        expect(evaluateStaleness(reading, bounds, clock), Verdict.alert);
      });

      test('above max', () {
        final clock = FakeClock(now);
        final reading = Reading<double>(
          clock: clock,
          value: 80.1,
          lastPingAt: now.subtract(const Duration(minutes: 1)),
        );

        expect(evaluateStaleness(reading, bounds, clock), Verdict.alert);
      });
    });

    test(
      'non-null, stale (age > 5min) -> stale,even if value breaches thresholds',
      () {
        final clock = FakeClock(now);
        final reading = Reading<double>(
          clock: clock,
          value: 999,
          lastPingAt: now.subtract(const Duration(minutes: 5, seconds: 1)),
        );

        expect(evaluateStaleness(reading, bounds, clock), Verdict.stale);
      },
    );
  });
}
