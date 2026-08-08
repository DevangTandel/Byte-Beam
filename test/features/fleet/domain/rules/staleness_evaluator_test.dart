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

    group('freshness boundary (stale means age > 5:00, not ≥)', () {
      test('age 4:59 -> normal (not stale)', () {
        final clock = FakeClock(now);
        final reading = Reading<double>(
          clock: clock,
          value: 50,
          lastPingAt: now.subtract(const Duration(minutes: 4, seconds: 59)),
        );

        expect(evaluateStaleness(reading, bounds, clock), Verdict.normal);
      });

      test('age exactly 5:00 -> normal (not stale)', () {
        final clock = FakeClock(now);
        final reading = Reading<double>(
          clock: clock,
          value: 50,
          lastPingAt: now.subtract(const Duration(minutes: 5)),
        );

        expect(evaluateStaleness(reading, bounds, clock), Verdict.normal);
      });

      test('age 5:01 -> stale', () {
        final clock = FakeClock(now);
        final reading = Reading<double>(
          clock: clock,
          value: 50,
          lastPingAt: now.subtract(const Duration(minutes: 5, seconds: 1)),
        );

        expect(evaluateStaleness(reading, bounds, clock), Verdict.stale);
      });

      test('null lastPingAt treats age as zero -> normal when in bounds', () {
        final clock = FakeClock(now);
        final reading = Reading<double>(
          clock: clock,
          value: 50,
        );

        expect(evaluateStaleness(reading, bounds, clock), Verdict.normal);
      });
    });

    group('threshold boundary (inclusive min/max)', () {
      test('value exactly at min (20) -> normal', () {
        final clock = FakeClock(now);
        final reading = Reading<double>(
          clock: clock,
          value: 20,
          lastPingAt: now.subtract(const Duration(minutes: 1)),
        );

        expect(evaluateStaleness(reading, bounds, clock), Verdict.normal);
      });

      test('value 19.9 (just below min) -> alert', () {
        final clock = FakeClock(now);
        final reading = Reading<double>(
          clock: clock,
          value: 19.9,
          lastPingAt: now.subtract(const Duration(minutes: 1)),
        );

        expect(evaluateStaleness(reading, bounds, clock), Verdict.alert);
      });

      test('value exactly at max (80) -> normal', () {
        final clock = FakeClock(now);
        final reading = Reading<double>(
          clock: clock,
          value: 80,
          lastPingAt: now.subtract(const Duration(minutes: 1)),
        );

        expect(evaluateStaleness(reading, bounds, clock), Verdict.normal);
      });

      test('value 80.1 (just above max) -> alert', () {
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
      'non-null, stale (age > 5min) -> stale, even if value breaches '
      'thresholds',
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
