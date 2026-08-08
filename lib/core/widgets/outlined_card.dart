import 'package:flutter/material.dart';

/// A bordered container with configurable outline [color], stroke [width],
/// and [cornerRadius].
class OutlinedCard extends StatelessWidget {
  /// Creates an [OutlinedCard].
  const OutlinedCard({
    required this.child,
    this.color,
    this.width = 1,
    this.cornerRadius = 12,
    this.margin,
    this.padding,
    this.backgroundColor,
    super.key,
  });

  /// Content inside the card.
  final Widget child;

  /// Outline stroke color. Defaults to [ColorScheme.outline].
  final Color? color;

  /// Outline stroke width.
  final double width;

  /// Corner radius of the card shape.
  final double cornerRadius;

  /// Outer margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Inner padding around [child].
  final EdgeInsetsGeometry? padding;

  /// Fill behind [child]. Defaults to [ColorScheme.surface].
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = color ?? colorScheme.outline;
    final fill = backgroundColor ?? colorScheme.surface;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cornerRadius),
      side: BorderSide(color: borderColor, width: width),
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: fill,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );
  }
}
