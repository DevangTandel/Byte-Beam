import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:byte_beam/features/fleet/domain/entities/reading.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';

/// SOC at or above this is healthy; below raises [AlertKind.lowBattery].
const kLowBatteryWarningThreshold = 20.0;

/// SOC below this upgrades [AlertKind.lowBattery] to [AlertSeverity.critical].
const kLowBatteryCriticalThreshold = 10.0;

/// Battery temperature above this raises [AlertKind.batteryOverheating].
const kBatteryOverheatingThreshold = 45.0;

/// Evaluates alert rules for [vehicle] against [previous] alerts.
///
/// Returns the new alert list for this tick (raise / update / flag / resolve).
List<Alert> evaluateAlerts(
  Vehicle vehicle,
  List<Alert> previous,
  Clock clock,
) {
  final previousForVin =
      previous.where((alert) => alert.vin == vehicle.vin).toList();

  final next = <Alert>[
    ?_evaluateLowBattery(vehicle, previousForVin, clock),
    ?_evaluateBatteryOverheating(vehicle, previousForVin, clock),
  ];

  return next;
}

Alert? _evaluateLowBattery(
  Vehicle vehicle,
  List<Alert> previousForVin,
  Clock clock,
) {
  return _evaluateKind(
    vehicle: vehicle,
    previousForVin: previousForVin,
    clock: clock,
    kind: AlertKind.lowBattery,
    reading: vehicle.soc,
    isBreaching: (value) => value < kLowBatteryWarningThreshold,
    severityFor: (value) => value < kLowBatteryCriticalThreshold
        ? AlertSeverity.critical
        : AlertSeverity.warning,
  );
}

Alert? _evaluateBatteryOverheating(
  Vehicle vehicle,
  List<Alert> previousForVin,
  Clock clock,
) {
  return _evaluateKind(
    vehicle: vehicle,
    previousForVin: previousForVin,
    clock: clock,
    kind: AlertKind.batteryOverheating,
    reading: vehicle.batteryTemp,
    isBreaching: (value) => value > kBatteryOverheatingThreshold,
    severityFor: (_) => AlertSeverity.critical,
  );
}

Alert? _evaluateKind({
  required Vehicle vehicle,
  required List<Alert> previousForVin,
  required Clock clock,
  required AlertKind kind,
  required Reading<double> reading,
  required bool Function(double value) isBreaching,
  required AlertSeverity Function(double value) severityFor,
}) {
  final existing = previousForVin.cast<Alert?>().firstWhere(
        (alert) => alert!.kind == kind,
        orElse: () => null,
      );

  final value = reading.value;
  if (value == null) {
    return null;
  }

  // Existing alerts survive staleness (flagged); new alerts are blocked.
  if (reading.isStale) {
    if (existing == null) {
      return null;
    }
    return existing.copyWith(isBasedOnStaleData: true);
  }

  if (!isBreaching(value)) {
    return null;
  }

  final severity = severityFor(value);
  if (existing != null) {
    return existing.copyWith(
      severity: severity,
      isBasedOnStaleData: false,
    );
  }

  return Alert(
    id: '${vehicle.vin}-${kind.name}',
    vin: vehicle.vin,
    kind: kind,
    severity: severity,
    raisedAt: clock.now(),
    isBasedOnStaleData: false,
  );
}
