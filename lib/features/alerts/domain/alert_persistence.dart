import 'package:byte_beam/features/alerts/domain/entities/alert.dart';

/// Persistence for dismissed alerts across app restarts.
///
/// Session dismissals are intentionally in-memory only; this port exists so
/// callers can inject a no-op / mock and assert no I/O occurs.
abstract class AlertPersistence {
  /// Persists a confirmed dismissal.
  Future<void> saveDismissed(Alert alert, DismissReason reason);

  /// Loads dismissals from durable storage.
  Future<List<Alert>> loadDismissed();
}
