import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/core/widgets/alert_badge.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }

  group('AlertBadge', () {
    testWidgets('renders count with critical theme colors', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AlertBadge(
            count: 3,
            severity: AlertSeverity.critical,
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);

      final styles = AppTheme.light().extension<AlertBadgeTheme>()!;
      final countStyle = tester.widget<Text>(find.text('3')).style;
      expect(
        countStyle?.color,
        styles.foregroundFor(AlertSeverity.critical),
      );

      final pill = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(AlertBadge),
          matching: find.byType(DecoratedBox),
        ).first,
      );
      expect(
        (pill.decoration! as BoxDecoration).color,
        styles.backgroundFor(AlertSeverity.critical),
      );
    });

    testWidgets('renders count with warning theme colors', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AlertBadge(
            count: 1,
            severity: AlertSeverity.warning,
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);

      final styles = AppTheme.light().extension<AlertBadgeTheme>()!;
      final countStyle = tester.widget<Text>(find.text('1')).style;
      expect(
        countStyle?.color,
        styles.foregroundFor(AlertSeverity.warning),
      );
    });
  });
}
