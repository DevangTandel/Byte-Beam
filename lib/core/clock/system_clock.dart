import 'package:byte_beam/core/clock/clock.dart';

/// A [Clock] backed by the system clock via [DateTime.now].
class SystemClock implements Clock {
  /// Creates a [SystemClock].
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
