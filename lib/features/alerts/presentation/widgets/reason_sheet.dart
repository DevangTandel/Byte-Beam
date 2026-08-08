import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:flutter/material.dart';

/// Bottom sheet listing dismissal reasons in brief order.
class ReasonSheet extends StatelessWidget {
  /// Creates a [ReasonSheet].
  const ReasonSheet({super.key});

  /// Ordered labels matching [DismissReason] declaration order.
  static const labels = <(DismissReason, String)>[
    (DismissReason.onIt, 'I am on it'),
    (DismissReason.wrongAlert, 'Wrong alert'),
    (DismissReason.somethingElse, 'Something else…'),
  ];

  /// Shows the sheet and returns the selected [DismissReason], if any.
  static Future<DismissReason?> show(BuildContext context) {
    return showModalBottomSheet<DismissReason>(
      context: context,
      builder: (context) => const ReasonSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Why dismiss this alert?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final entry in labels)
            ListTile(
              title: Text(entry.$2),
              onTap: () => Navigator.of(context).pop(entry.$1),
            ),
        ],
      ),
    );
  }
}
