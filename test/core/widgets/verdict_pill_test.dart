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
    testWidgets('normal: colored value, no age caption', (tester) async {
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

      final pill = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(VerdictPill),
          matching: find.byType(DecoratedBox),
        ).first,
      );
      final decoration = pill.decoration! as BoxDecoration;
      expect(decoration.color, styles.normalPillColor);
    });

    testWidgets('stale: dimmed value, "data Xm old" caption, grey pill', (
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

      final captionStyle = tester.widget<Text>(find.text('data 7m old')).style;
      expect(captionStyle?.color, styles.staleCaptionColor);

      final pill = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(VerdictPill),
          matching: find.byType(DecoratedBox),
        ).first,
      );
      final decoration = pill.decoration! as BoxDecoration;
      expect(decoration.color, styles.stalePillColor);
    });

    testWidgets('null value: em dash only — no pill, no age text', (
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
