import 'package:byte_beam/features/alerts/presentation/bloc/alerts_cubit.dart';
import 'package:flutter/material.dart';

/// Helper for the post-dismiss UNDO snackbar.
abstract final class UndoSnackbar {
  /// Shows a snackbar with an UNDO action for [kAlertUndoWindow].
  static void show(
    BuildContext context, {
    required VoidCallback onUndo,
    String message = 'Alert dismissed',
    Duration duration = kAlertUndoWindow,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: onUndo,
          ),
        ),
      );
  }
}
