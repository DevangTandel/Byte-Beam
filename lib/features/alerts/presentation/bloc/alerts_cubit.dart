import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/alerts/domain/alert_persistence.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:byte_beam/features/alerts/domain/rules/alert_engine.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';

export 'package:byte_beam/features/alerts/domain/alert_persistence.dart';

/// Duration the user can undo a dismissal.
const kAlertUndoWindow = Duration(seconds: 5);

/// A dismissal waiting in the undo window.
class UndoableDismissal {
  /// Creates an [UndoableDismissal].
  const UndoableDismissal({
    required this.alert,
    required this.reason,
    required this.expiresAt,
  });

  /// Alert removed from [AlertsState.active].
  final Alert alert;

  /// Why the operator dismissed.
  final DismissReason reason;

  /// When the undo window ends ([Clock]-based).
  final DateTime expiresAt;
}

/// Active alerts plus an optional undoable dismissal.
class AlertsState {
  /// Creates an [AlertsState].
  const AlertsState({
    this.active = const [],
    this.undoable,
  });

  /// Alerts currently shown to the operator.
  final List<Alert> active;

  /// Most recent dismissal still within the undo window, if any.
  final UndoableDismissal? undoable;

  /// Copies this state with selective overrides.
  AlertsState copyWith({
    List<Alert>? active,
    UndoableDismissal? undoable,
    bool clearUndoable = false,
  }) {
    return AlertsState(
      active: active ?? this.active,
      undoable: clearUndoable ? null : (undoable ?? this.undoable),
    );
  }
}

/// Derives alerts from a vehicle stream and handles dismiss / undo.
class AlertsCubit extends Cubit<AlertsState> {
  /// Creates an [AlertsCubit].
  ///
  /// [_persistence] is accepted for DI / testing but session dismissals are
  /// in-memory only — this cubit never reads or writes it.
  AlertsCubit({
    required Stream<List<Vehicle>> vehicleStream,
    required this._clock,
    required this._persistence,
  }) : super(const AlertsState()) {
    _subscription = vehicleStream.listen(_onVehicles);
  }

  // ignore: unused_field - injected to prove dismissals are not persisted
  final AlertPersistence _persistence;
  final Clock _clock;

  StreamSubscription<List<Vehicle>>? _subscription;
  Timer? _undoTimer;
  int _idSeq = 0;

  /// (vin, kind) pairs suppressed after the undo window until the condition
  /// resolves (so continuous breach does not resurrect; rebreach after
  /// resolve can raise a new instance).
  final Set<(String, AlertKind)> _suppressed = {};

  /// Dismisses [alertId] into the undoable slot for [kAlertUndoWindow].
  void dismiss(String alertId, DismissReason reason) {
    Alert? target;
    for (final alert in state.active) {
      if (alert.id == alertId) {
        target = alert;
        break;
      }
    }
    if (target == null) {
      return;
    }

    final expiresAt = _clock.now().add(kAlertUndoWindow);
    _undoTimer?.cancel();
    _undoTimer = Timer(kAlertUndoWindow, _onUndoWindowElapsed);

    emit(
      AlertsState(
        active: [
          for (final alert in state.active)
            if (alert.id != alertId) alert,
        ],
        undoable: UndoableDismissal(
          alert: target,
          reason: reason,
          expiresAt: expiresAt,
        ),
      ),
    );
  }

  /// Restores the undoable alert if the window is still open.
  void undo() {
    final pending = state.undoable;
    if (pending == null) {
      return;
    }

    _undoTimer?.cancel();
    _undoTimer = null;

    emit(
      AlertsState(
        active: [...state.active, pending.alert],
        undoable: null,
      ),
    );
  }

  void _onUndoWindowElapsed() {
    final pending = state.undoable;
    if (pending == null) {
      return;
    }

    _suppressed.add((pending.alert.vin, pending.alert.kind));
    _undoTimer = null;
    emit(state.copyWith(clearUndoable: true));
  }

  void _onVehicles(List<Vehicle> vehicles) {
    final nextActive = <Alert>[];
    final seenKeys = <(String, AlertKind)>{};

    for (final vehicle in vehicles) {
      final previousForEngine = [
        for (final alert in state.active)
          if (alert.vin == vehicle.vin) alert,
      ];

      final evaluated = evaluateAlerts(vehicle, previousForEngine, _clock);

      for (final kind in AlertKind.values) {
        final key = (vehicle.vin, kind);
        final stillBreaching = evaluated.any((alert) => alert.kind == kind);
        if (!stillBreaching) {
          _suppressed.remove(key);
        }
      }

      for (final proposed in evaluated) {
        final key = (proposed.vin, proposed.kind);
        if (seenKeys.contains(key)) {
          continue;
        }
        seenKeys.add(key);

        if (_suppressed.contains(key)) {
          continue;
        }

        final undoable = state.undoable;
        if (undoable != null &&
            undoable.alert.vin == proposed.vin &&
            undoable.alert.kind == proposed.kind) {
          continue;
        }

        Alert? existing;
        for (final alert in state.active) {
          if (alert.vin == proposed.vin && alert.kind == proposed.kind) {
            existing = alert;
            break;
          }
        }

        if (existing != null) {
          nextActive.add(
            proposed.copyWith(
              id: existing.id,
              raisedAt: existing.raisedAt,
            ),
          );
        } else {
          nextActive.add(
            proposed.copyWith(id: _mintId(proposed)),
          );
        }
      }
    }

    emit(
      AlertsState(
        active: nextActive,
        undoable: state.undoable,
      ),
    );
  }

  String _mintId(Alert alert) => '${alert.vin}-${alert.kind.name}-${_idSeq++}';

  @override
  Future<void> close() async {
    // Cancel the undo timer before awaiting stream cancel so it cannot fire
    // after close() yields (BlocProvider does not await close()).
    _undoTimer?.cancel();
    _undoTimer = null;
    final sub = _subscription;
    _subscription = null;
    await sub?.cancel();
    return super.close();
  }
}
