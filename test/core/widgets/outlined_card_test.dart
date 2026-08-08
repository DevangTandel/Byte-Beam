import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/core/widgets/outlined_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }

  Material materialOf(WidgetTester tester) {
    return tester.widget<Material>(
      find.descendant(
        of: find.byType(OutlinedCard),
        matching: find.byType(Material),
      ),
    );
  }

  group('OutlinedCard', () {
    testWidgets('applies color, width, and cornerRadius to the border', (
      tester,
    ) async {
      const outline = Color(0xFF123456);
      const stroke = 3.0;
      const radius = 20.0;

      await tester.pumpWidget(
        wrap(
          const OutlinedCard(
            color: outline,
            width: stroke,
            cornerRadius: radius,
            child: Text('content'),
          ),
        ),
      );

      expect(find.text('content'), findsOneWidget);

      final shape = materialOf(tester).shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(radius));
      expect(shape.side.color, outline);
      expect(shape.side.width, stroke);
    });

    testWidgets('defaults outline color to ColorScheme.outline', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const OutlinedCard(child: Text('default'))),
      );

      final expected = AppTheme.light().colorScheme.outline;
      final shape = materialOf(tester).shape! as RoundedRectangleBorder;
      expect(shape.side.color, expected);
      expect(shape.side.width, 1);
    });

    testWidgets('applies margin around the card', (tester) async {
      await tester.pumpWidget(
        wrap(
          const OutlinedCard(
            margin: EdgeInsets.all(8),
            child: SizedBox(width: 40, height: 20),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(OutlinedCard),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(padding.padding, const EdgeInsets.all(8));
    });
  });
}
