import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/core/widgets/status_chip.dart';
import 'package:byte_beam/features/fleet/domain/rules/status_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }

  group('StatusChip', () {
    testWidgets('renders Moving label with moving theme colors', (tester) async {
      await tester.pumpWidget(
        wrap(const StatusChip(status: VehicleStatus.moving)),
      );

      expect(find.text('Moving'), findsOneWidget);

      final styles = AppTheme.light().extension<StatusChipTheme>()!;
      final labelStyle = tester.widget<Text>(find.text('Moving')).style;
      expect(labelStyle?.color, styles.foregroundFor(VehicleStatus.moving));

      final pill = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(StatusChip),
          matching: find.byType(DecoratedBox),
        ).first,
      );
      expect(
        (pill.decoration! as BoxDecoration).color,
        styles.backgroundFor(VehicleStatus.moving),
      );
    });

    testWidgets('renders Offline label with offline theme colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const StatusChip(status: VehicleStatus.offline)),
      );

      expect(find.text('Offline'), findsOneWidget);

      final styles = AppTheme.light().extension<StatusChipTheme>()!;
      final labelStyle = tester.widget<Text>(find.text('Offline')).style;
      expect(labelStyle?.color, styles.foregroundFor(VehicleStatus.offline));
    });
  });
}
