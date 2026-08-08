import 'package:freezed_annotation/freezed_annotation.dart';

part 'alert.freezed.dart';

/// Kind of fleet alert raised from telemetry rules.
enum AlertKind {
  /// State of charge below the low-battery threshold.
  lowBattery,

  /// Battery temperature above the overheating threshold.
  batteryOverheating,
}

/// Severity of an [Alert].
enum AlertSeverity {
  /// Non-critical issue that still requires attention.
  warning,

  /// Severe issue requiring immediate attention.
  critical,
}

/// Why an operator dismissed an alert.
enum DismissReason {
  /// Operator is handling the issue.
  onIt,

  /// Alert was incorrect / false positive.
  wrongAlert,

  /// Other dismissal reason.
  somethingElse,
}

/// A raised fleet alert (pure data; no domain logic).
@freezed
abstract class Alert with _$Alert {
  /// Creates an [Alert].
  const factory Alert({
    required String id,
    required String vin,
    required AlertKind kind,
    required AlertSeverity severity,
    required DateTime raisedAt,
    required bool isBasedOnStaleData,
  }) = _Alert;
}
