import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/fleet/domain/entities/reading.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test-only clock with a fixed [now] value.
class FakeClock implements Clock {
  FakeClock(this._now);

  DateTime _now;

  set now(DateTime value) => _now = value;

  @override
  DateTime now() => _now;
}

void main() {
  const lastPingAt = DateTime(2026, 8, 7, 12, 0, 0);

  group('Reading', () {
    group('fields', () {
      test('exposes nullable value', () {
        const reading = Reading<int>(
          clock: _FixedClock(lastPingAt),
          value: 78,
          lastPingAt: lastPingAt,
        );

        expect(reading.value, 78);
      });

      test('exposes nullable lastPingAt', () {
        const reading = Reading<int>(
          clock: _FixedClock(lastPingAt),
          value: 78,
          lastPingAt: lastPingAt,
        );

        expect(reading.lastPingAt, lastPingAt);
      });

      test('allows null value and null lastPingAt', () {
        const reading = Reading<int>(
          clock: _FixedClock(lastPingAt),
        );

        expect(reading.value, isNull);
        expect(reading.lastPingAt, isNull);
      });
    });

    group('age', () {
      test('is the elapsed time from lastPingAt to clock now()', () {
        final clock = FakeClock(lastPingAt.add(const Duration(minutes: 2, seconds: 30)));
        final reading = Reading<int>(
          clock: clock,
          value: 78,
          lastPingAt: lastPingAt,
        );

        expect(reading.age, const Duration(minutes: 2, seconds: 30));
      });

      test('uses floor semantics and never rounds up sub-minute remainder', () {
        final clock = FakeClock(
          lastPingAt.add(const Duration(minutes: 4, seconds: 59, milliseconds: 999)),
        );
        final reading = Reading<int>(
          clock: clock,
          value: 78,
          lastPingAt: lastPingAt,
        );

        expect(reading.age, const Duration(minutes: 4, seconds: 59));
      });
    });

    group('isMissing', () {
      test('is true when value is null', () {
        const reading = Reading<int>(
          clock: _FixedClock(lastPingAt),
          lastPingAt: lastPingAt,
        );

        expect(reading.isMissing, isTrue);
      });

      test('is false when value is non-null', () {
        const reading = Reading<int>(
          clock: _FixedClock(lastPingAt),
          value: 42,
          lastPingAt: lastPingAt,
        );

        expect(reading.isMissing, isFalse);
      });
    });

    group('isStale', () {
      test('is false when age is exactly 4 minutes 59 seconds', () {
        final clock = FakeClock(lastPingAt.add(const Duration(minutes: 4, seconds: 59)));
        final reading = Reading<int>(
          clock: clock,
          value: 78,
          lastPingAt: lastPingAt,
        );

        expect(reading.age, const Duration(minutes: 4, seconds: 59));
        expect(reading.age, isNot(greaterThan(kStaleThreshold)));
        expect(reading.isStale, isFalse);
      });

      test('is true when age is exactly 5 minutes 0 seconds', () {
        final clock = FakeClock(lastPingAt.add(kStaleThreshold));
        final reading = Reading<int>(
          clock: clock,
          value: 78,
          lastPingAt: lastPingAt,
        );

        expect(reading.age, kStaleThreshold);
        expect(reading.isStale, isTrue);
      });

      test('does not round up sub-minute remainder below threshold', () {
        final clock = FakeClock(
          lastPingAt.add(const Duration(minutes: 4, seconds: 59, milliseconds: 999)),
        );
        final reading = Reading<int>(
          clock: clock,
          value: 78,
          lastPingAt: lastPingAt,
        );

        expect(reading.isStale, isFalse);
      });
    });
  });
}

/// Const-friendly clock for tests that do not depend on elapsed time.
class _FixedClock implements Clock {
  const _FixedClock(this._now);

  final DateTime _now;

  @override
  DateTime now() => _now;
}
