import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/features/alerts/presentation/bloc/alerts_cubit.dart';
import 'package:byte_beam/features/alerts/presentation/widgets/undo_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UndoSnackbar', () {
    testWidgets(
      'shows UNDO action with duration matching kAlertUndoWindow (5s)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () {
                      UndoSnackbar.show(context, onUndo: () {});
                    },
                    child: const Text('Dismiss'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Dismiss'));
        await tester.pump();

        expect(find.text('UNDO'), findsOneWidget);
        expect(find.text('Alert dismissed'), findsOneWidget);

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.duration, kAlertUndoWindow);
        expect(snackBar.duration, const Duration(seconds: 5));
        expect(
          snackBar.duration,
          isNot(const Duration(milliseconds: 4000)),
          reason: 'must not use Material SnackBar default (~4s)',
        );
      },
    );
  });
}
