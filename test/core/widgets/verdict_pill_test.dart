import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/core/widgets/verdict_pill.dart';
import 'package:byte_beam/features/fleet/domain/rules/staleness_evaluator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }

  group('VerdictPill', () {
    testWidgets('normal: bold colored value, no age caption, no fill', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const VerdictPill(
            verdict: Verdict.normal,
            value: 78,
            unit: '%',
            age: Duration(minutes: 2),
          ),
        ),
      );

      expect(find.text('78 %'), findsOneWidget);
      expect(find.textContaining('old'), findsNothing);
      expect(find.text('—'), findsNothing);

      final valueStyle = tester.widget<Text>(find.text('78 %')).style;
      final styles = AppTheme.light().extension<VerdictTheme>()!;
      expect(valueStyle?.color, styles.normalValueColor);
      expect(valueStyle?.fontWeight, FontWeight.w700);
      expect(
        find.descendant(
          of: find.byType(VerdictPill),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    });

    testWidgets('stale: bold dimmed value, "data Xm old" caption, no fill', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const VerdictPill(
            verdict: Verdict.stale,
            value: 36,
            unit: '°C',
            age: Duration(minutes: 7),
          ),
        ),
      );

      expect(find.text('36 °C'), findsOneWidget);
      expect(find.text('data 7m old'), findsOneWidget);

      final styles = AppTheme.light().extension<VerdictTheme>()!;
      final valueStyle = tester.widget<Text>(find.text('36 °C')).style;
      expect(valueStyle?.color, styles.staleValueColor);
      expect(valueStyle?.fontWeight, FontWeight.w700);

      final captionStyle = tester.widget<Text>(find.text('data 7m old')).style;
      expect(captionStyle?.color, styles.staleCaptionColor);
      expect(
        find.descendant(
          of: find.byType(VerdictPill),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    });

    testWidgets('fractionDigits: formats with fixed decimals', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VerdictPill(
            verdict: Verdict.normal,
            value: 45211.8,
            unit: 'km',
            age: Duration.zero,
            fractionDigits: 2,
          ),
        ),
      );

      expect(find.text('45211.80 km'), findsOneWidget);
    });

    testWidgets('null value: em dash only — no fill, no age text', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const VerdictPill(
            verdict: null,
            value: null,
            unit: '%',
            age: Duration(minutes: 3),
          ),
        ),
      );

      expect(find.text('—'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('old'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(VerdictPill),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    });
  });
}
