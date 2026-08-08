import 'package:flutter/material.dart';

/// Helper for the post-dismiss UNDO snackbar.
abstract final class UndoSnackbar {
  /// Shows a snackbar with an UNDO action.
  static void show(
    BuildContext context, {
    required VoidCallback onUndo,
    String message = 'Alert dismissed',
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: onUndo,
          ),
        ),
      );
  }
}
