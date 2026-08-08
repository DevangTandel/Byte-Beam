import 'package:byte_beam/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Horizontal bar of selectable filter chips with live counts.
///
/// Colors come from [FilterChipBarTheme]. A count of `0` still renders the
/// chip (e.g. `Idle (0)`) so users can select empty filters.
class FilterChipBar<T> extends StatelessWidget {
  /// Creates a [FilterChipBar].
  const FilterChipBar({
    required this.options,
    required this.counts,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
    super.key,
  });

  /// Filter values to render, in display order.
  final List<T> options;

  /// Live counts keyed by option (missing keys treated as 0).
  final Map<T, int> counts;

  /// Currently selected option.
  final T selected;

  /// Human-readable label for an option (count is appended by the bar).
  final String Function(T value) labelBuilder;

  /// Called when the user taps a chip.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<FilterChipBarTheme>()!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options) ...[
            _FilterChip(
              label: '${labelBuilder(option)} (${counts[option] ?? 0})',
              selected: option == selected,
              theme: theme,
              onTap: () => onChanged(option),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final FilterChipBarTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? theme.selectedBackground : theme.unselectedBackground,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? theme.selectedForeground
                      : theme.unselectedForeground,
                ),
          ),
        ),
      ),
    );
  }
}
