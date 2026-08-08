import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/fleet/domain/entities/reading.dart';

/// Inclusive lower/upper bounds for a telemetry reading.
class ThresholdBounds {
  /// Creates bounds where [min] <= value <= [max] is normal.
  const ThresholdBounds({required this.min, required this.max});

  /// Inclusive minimum acceptable value.
  final double min;

  /// Inclusive maximum acceptable value.
  final double max;
}

/// Verdict for a non-null reading after freshness and threshold checks.
enum Verdict {
  /// Fresh and within [ThresholdBounds].
  normal,

  /// Fresh but outside [ThresholdBounds].
  alert,

  /// Older than [kStaleThreshold], regardless of value.
  stale,
}

/// Evaluates [reading] against [bounds] using [clock] for age.
///
/// Returns null when [Reading.value] is null (UI shows a dash, no verdict).
Verdict? evaluateStaleness(
  Reading<double> reading,
  ThresholdBounds bounds,
  Clock clock,
) {
  final value = reading.value;
  if (value == null) {
    return null;
  }

  // Floor age to whole seconds (honesty: never round up), same as [Reading.age]
  final ping = reading.lastPingAt;
  final age = ping == null
      ? Duration.zero
      : Duration(seconds: clock.now().difference(ping).inSeconds);
  if (age > kStaleThreshold) {
    return Verdict.stale;
  }

  if (value < bounds.min || value > bounds.max) {
    return Verdict.alert;
  }

  return Verdict.normal;
}
