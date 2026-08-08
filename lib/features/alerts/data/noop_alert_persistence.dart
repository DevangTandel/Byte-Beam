import 'package:byte_beam/features/alerts/domain/alert_persistence.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';

/// No-op [AlertPersistence] — session dismissals stay in memory only.
class NoopAlertPersistence implements AlertPersistence {
  /// Creates a [NoopAlertPersistence].
  const NoopAlertPersistence();

  @override
  Future<void> saveDismissed(Alert alert, DismissReason reason) async {}

  @override
  Future<List<Alert>> loadDismissed() async => const [];
}
