import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:byte_beam/features/alerts/domain/rules/alert_badge_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 7, 12);

  Alert alert({
    required String id,
    required String vin,
    required AlertSeverity severity,
  }) {
    return Alert(
      id: id,
      vin: vin,
      kind: AlertKind.lowBattery,
      severity: severity,
      raisedAt: now,
      isBasedOnStaleData: false,
    );
  }

  group('summarizeAlertsForVin', () {
    test('returns zero count and null severity when vin has no alerts', () {
      final summary = summarizeAlertsForVin(
        [
          alert(id: 'a1', vin: 'VIN0001', severity: AlertSeverity.warning),
        ],
        'VIN0002',
      );

      expect(summary.count, 0);
      expect(summary.severity, isNull);
    });

    test('counts only matching vin and uses warning when none critical', () {
      final summary = summarizeAlertsForVin(
        [
          alert(id: 'a1', vin: 'VIN0001', severity: AlertSeverity.warning),
          alert(id: 'a2', vin: 'VIN0001', severity: AlertSeverity.warning),
          alert(id: 'a3', vin: 'VIN0002', severity: AlertSeverity.critical),
        ],
        'VIN0001',
      );

      expect(summary.count, 2);
      expect(summary.severity, AlertSeverity.warning);
    });

    test('worst severity is critical when any matching alert is critical', () {
      final summary = summarizeAlertsForVin(
        [
          alert(id: 'a1', vin: 'VIN0001', severity: AlertSeverity.warning),
          alert(id: 'a2', vin: 'VIN0001', severity: AlertSeverity.critical),
        ],
        'VIN0001',
      );

      expect(summary.count, 2);
      expect(summary.severity, AlertSeverity.critical);
    });
  });
}
