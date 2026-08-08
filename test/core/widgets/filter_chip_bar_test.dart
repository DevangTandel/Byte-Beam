import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:byte_beam/core/widgets/filter_chip_bar.dart';
import 'package:byte_beam/features/fleet/presentation/bloc/fleet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }

  String labelOf(FleetFilter filter) {
    return switch (filter) {
      FleetFilter.all => 'All',
      FleetFilter.moving => 'Moving',
      FleetFilter.idle => 'Idle',
      FleetFilter.stopped => 'Stopped',
      FleetFilter.offline => 'Offline',
    };
  }

  group('FilterChipBar', () {
    testWidgets('renders option labels with counts and highlights selected', (
      tester,
    ) async {
      FleetFilter? changedTo;

      await tester.pumpWidget(
        wrap(
          FilterChipBar<FleetFilter>(
            options: const [
              FleetFilter.all,
              FleetFilter.moving,
              FleetFilter.idle,
            ],
            counts: const {
              FleetFilter.all: 8,
              FleetFilter.moving: 3,
              FleetFilter.idle: 1,
            },
            selected: FleetFilter.moving,
            labelBuilder: labelOf,
            onChanged: (value) => changedTo = value,
          ),
        ),
      );

      expect(find.text('All (8)'), findsOneWidget);
      expect(find.text('Moving (3)'), findsOneWidget);
      expect(find.text('Idle (1)'), findsOneWidget);

      final styles = AppTheme.light().extension<FilterChipBarTheme>()!;
      final selectedText = tester.widget<Text>(find.text('Moving (3)'));
      expect(selectedText.style?.color, styles.selectedForeground);

      await tester.tap(find.text('All (8)'));
      await tester.pump();
      expect(changedTo, FleetFilter.all);
    });

    testWidgets('renders correctly when a filter count is 0', (tester) async {
      await tester.pumpWidget(
        wrap(
          FilterChipBar<FleetFilter>(
            options: const [
              FleetFilter.all,
              FleetFilter.idle,
              FleetFilter.offline,
            ],
            counts: const {
              FleetFilter.all: 7,
              FleetFilter.idle: 0,
              FleetFilter.offline: 1,
            },
            selected: FleetFilter.all,
            labelBuilder: labelOf,
            onChanged: (_) {},
          ),
        ),
      );

      // Zero-count filters remain visible (empty-state is the list,
      // not the chip).
      expect(find.text('Idle (0)'), findsOneWidget);
      expect(find.text('All (7)'), findsOneWidget);
      expect(find.text('Offline (1)'), findsOneWidget);

      final styles = AppTheme.light().extension<FilterChipBarTheme>()!;
      final zeroChipText = tester.widget<Text>(find.text('Idle (0)'));
      expect(zeroChipText.style?.color, styles.unselectedForeground);

      // Zero-count chip is still tappable.
      await tester.tap(find.text('Idle (0)'));
      await tester.pump();
    });
  });
}
