import 'package:byte_beam/features/alerts/domain/entities/alert.dart';

/// Per-VIN badge inputs for fleet list cards.
typedef AlertBadgeSummary = ({int count, AlertSeverity? severity});

/// Aggregates active alerts for [vin] into a badge count + worst severity.
///
/// Severity is critical if any matching alert is critical; otherwise warning
/// when count > 0. Empty match → count 0 and null severity.
AlertBadgeSummary summarizeAlertsForVin(List<Alert> active, String vin) {
  var count = 0;
  var hasCritical = false;

  for (final alert in active) {
    if (alert.vin != vin) {
      continue;
    }
    count++;
    if (alert.severity == AlertSeverity.critical) {
      hasCritical = true;
    }
  }

  if (count == 0) {
    return (count: 0, severity: null);
  }

  return (
    count: count,
    severity: hasCritical ? AlertSeverity.critical : AlertSeverity.warning,
  );
}
