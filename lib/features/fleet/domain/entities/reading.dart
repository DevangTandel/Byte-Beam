import 'package:byte_beam/core/clock/clock.dart';

/// Age strictly older than this duration is considered stale for a [Reading].
///
/// "Older than 5 minutes" means [age] **>** 5 minutes (not ≥).
const kStaleThreshold = Duration(minutes: 5);

/// A telemetry value with optional freshness metadata.
class Reading<T> {
  /// Creates a [Reading] backed by the given [clock].
  const Reading({
    required this.clock,
    this.value,
    this.lastPingAt,
  });

  /// Clock used to compute [age] and [isStale].
  final Clock clock;

  /// The reading value, or null when missing.
  final T? value;

  /// When this reading was last received, or null if unknown.
  final DateTime? lastPingAt;

  /// Whether [value] is absent.
  bool get isMissing => value == null;

  /// Elapsed time since [lastPingAt], floored to whole seconds.
  Duration get age {
    final ping = lastPingAt;
    if (ping == null) {
      return Duration.zero;
    }

    return Duration(seconds: clock.now().difference(ping).inSeconds);
  }

  /// Whether this reading is older than [kStaleThreshold] (strictly greater).
  bool get isStale {
    final ping = lastPingAt;
    if (ping == null) {
      return false;
    }

    return age > kStaleThreshold;
  }
}
