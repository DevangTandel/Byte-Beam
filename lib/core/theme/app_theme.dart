import 'package:byte_beam/core/widgets/alert_badge.dart';
import 'package:byte_beam/core/widgets/filter_chip_bar.dart';
import 'package:byte_beam/core/widgets/status_chip.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:byte_beam/features/fleet/domain/rules/staleness_evaluator.dart';
import 'package:byte_beam/features/fleet/domain/rules/status_resolver.dart';
import 'package:flutter/material.dart';

/// Application themes and shared style tokens.
abstract final class AppTheme {
  /// Light theme used by the app and widget tests.
  static ThemeData light() {
    const verdict = VerdictTheme(
      normalValueColor: Color(0xFF0B6E4F),
      normalPillColor: Color(0xFFD8F3E7),
      alertValueColor: Color(0xFF9B2226),
      alertPillColor: Color(0xFFFFE3E0),
      staleValueColor: Color(0xFF6C757D),
      stalePillColor: Color(0xFFE9ECEF),
      staleCaptionColor: Color(0xFFADB5BD),
      missingValueColor: Color(0xFF868E96),
    );

    const statusChip = StatusChipTheme(
      movingForeground: Color(0xFF0B6E4F),
      movingBackground: Color(0xFFD8F3E7),
      idleForeground: Color(0xFF9A7200),
      idleBackground: Color(0xFFFFF3CD),
      stoppedForeground: Color(0xFF495057),
      stoppedBackground: Color(0xFFE9ECEF),
      offlineForeground: Color(0xFF6C757D),
      offlineBackground: Color(0xFFDEE2E6),
    );

    const alertBadge = AlertBadgeTheme(
      warningForeground: Color(0xFF9A7200),
      warningBackground: Color(0xFFFFF3CD),
      criticalForeground: Color(0xFF9B2226),
      criticalBackground: Color(0xFFFFE3E0),
    );

    const filterChipBar = FilterChipBarTheme(
      selectedForeground: Color(0xFFFFFFFF),
      selectedBackground: Color(0xFF0B6E4F),
      unselectedForeground: Color(0xFF495057),
      unselectedBackground: Color(0xFFE9ECEF),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 2, 80, 111),
      outline: const Color.fromARGB(255, 30, 51, 67),
      surface: const Color.fromARGB(255, 255, 255, 255),
    );
    final textTheme = Typography.material2021().black.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      colorScheme: colorScheme,
      textTheme: textTheme,
      useMaterial3: true,
      extensions: const [verdict, statusChip, alertBadge, filterChipBar],
    );
  }
}

/// Colors/styles for [Verdict]-driven telemetry chips.
@immutable
class VerdictTheme extends ThemeExtension<VerdictTheme> {
  /// Creates a [VerdictTheme].
  const VerdictTheme({
    required this.normalValueColor,
    required this.normalPillColor,
    required this.alertValueColor,
    required this.alertPillColor,
    required this.staleValueColor,
    required this.stalePillColor,
    required this.staleCaptionColor,
    required this.missingValueColor,
  });

  /// Value text when [Verdict.normal].
  final Color normalValueColor;

  /// Pill background when [Verdict.normal].
  final Color normalPillColor;

  /// Value text when [Verdict.alert].
  final Color alertValueColor;

  /// Pill background when [Verdict.alert].
  final Color alertPillColor;

  /// Dimmed value text when [Verdict.stale].
  final Color staleValueColor;

  /// Grey pill background when [Verdict.stale].
  final Color stalePillColor;

  /// "data X min old" caption when [Verdict.stale].
  final Color staleCaptionColor;

  /// Em-dash color when value is missing.
  final Color missingValueColor;

  /// Resolves value text color for [verdict].
  Color valueColorFor(Verdict verdict) {
    return switch (verdict) {
      Verdict.normal => normalValueColor,
      Verdict.alert => alertValueColor,
      Verdict.stale => staleValueColor,
    };
  }

  /// Resolves pill background for [verdict].
  Color pillColorFor(Verdict verdict) {
    return switch (verdict) {
      Verdict.normal => normalPillColor,
      Verdict.alert => alertPillColor,
      Verdict.stale => stalePillColor,
    };
  }

  @override
  VerdictTheme copyWith({
    Color? normalValueColor,
    Color? normalPillColor,
    Color? alertValueColor,
    Color? alertPillColor,
    Color? staleValueColor,
    Color? stalePillColor,
    Color? staleCaptionColor,
    Color? missingValueColor,
  }) {
    return VerdictTheme(
      normalValueColor: normalValueColor ?? this.normalValueColor,
      normalPillColor: normalPillColor ?? this.normalPillColor,
      alertValueColor: alertValueColor ?? this.alertValueColor,
      alertPillColor: alertPillColor ?? this.alertPillColor,
      staleValueColor: staleValueColor ?? this.staleValueColor,
      stalePillColor: stalePillColor ?? this.stalePillColor,
      staleCaptionColor: staleCaptionColor ?? this.staleCaptionColor,
      missingValueColor: missingValueColor ?? this.missingValueColor,
    );
  }

  @override
  VerdictTheme lerp(ThemeExtension<VerdictTheme>? other, double t) {
    if (other is! VerdictTheme) {
      return this;
    }
    return VerdictTheme(
      normalValueColor: Color.lerp(
        normalValueColor,
        other.normalValueColor,
        t,
      )!,
      normalPillColor: Color.lerp(normalPillColor, other.normalPillColor, t)!,
      alertValueColor: Color.lerp(alertValueColor, other.alertValueColor, t)!,
      alertPillColor: Color.lerp(alertPillColor, other.alertPillColor, t)!,
      staleValueColor: Color.lerp(staleValueColor, other.staleValueColor, t)!,
      stalePillColor: Color.lerp(stalePillColor, other.stalePillColor, t)!,
      staleCaptionColor: Color.lerp(
        staleCaptionColor,
        other.staleCaptionColor,
        t,
      )!,
      missingValueColor: Color.lerp(
        missingValueColor,
        other.missingValueColor,
        t,
      )!,
    );
  }
}

/// Colors for [StatusChip] by [VehicleStatus].
@immutable
class StatusChipTheme extends ThemeExtension<StatusChipTheme> {
  /// Creates a [StatusChipTheme].
  const StatusChipTheme({
    required this.movingForeground,
    required this.movingBackground,
    required this.idleForeground,
    required this.idleBackground,
    required this.stoppedForeground,
    required this.stoppedBackground,
    required this.offlineForeground,
    required this.offlineBackground,
  });

  /// Foreground for moving status.
  final Color movingForeground;

  /// Background for moving status.
  final Color movingBackground;

  /// Foreground for idle status.
  final Color idleForeground;

  /// Background for idle status.
  final Color idleBackground;

  /// Foreground for stopped status.
  final Color stoppedForeground;

  /// Background for stopped status.
  final Color stoppedBackground;

  /// Foreground for offline status.
  final Color offlineForeground;

  /// Background for offline status.
  final Color offlineBackground;

  /// Label color for [status].
  Color foregroundFor(VehicleStatus status) {
    return switch (status) {
      VehicleStatus.moving => movingForeground,
      VehicleStatus.idle => idleForeground,
      VehicleStatus.stopped => stoppedForeground,
      VehicleStatus.offline => offlineForeground,
    };
  }

  /// Pill background for [status].
  Color backgroundFor(VehicleStatus status) {
    return switch (status) {
      VehicleStatus.moving => movingBackground,
      VehicleStatus.idle => idleBackground,
      VehicleStatus.stopped => stoppedBackground,
      VehicleStatus.offline => offlineBackground,
    };
  }

  /// Display label for [status].
  String labelFor(VehicleStatus status) {
    return switch (status) {
      VehicleStatus.moving => 'Moving',
      VehicleStatus.idle => 'Idle',
      VehicleStatus.stopped => 'Stopped',
      VehicleStatus.offline => 'Offline',
    };
  }

  @override
  StatusChipTheme copyWith({
    Color? movingForeground,
    Color? movingBackground,
    Color? idleForeground,
    Color? idleBackground,
    Color? stoppedForeground,
    Color? stoppedBackground,
    Color? offlineForeground,
    Color? offlineBackground,
  }) {
    return StatusChipTheme(
      movingForeground: movingForeground ?? this.movingForeground,
      movingBackground: movingBackground ?? this.movingBackground,
      idleForeground: idleForeground ?? this.idleForeground,
      idleBackground: idleBackground ?? this.idleBackground,
      stoppedForeground: stoppedForeground ?? this.stoppedForeground,
      stoppedBackground: stoppedBackground ?? this.stoppedBackground,
      offlineForeground: offlineForeground ?? this.offlineForeground,
      offlineBackground: offlineBackground ?? this.offlineBackground,
    );
  }

  @override
  StatusChipTheme lerp(ThemeExtension<StatusChipTheme>? other, double t) {
    if (other is! StatusChipTheme) {
      return this;
    }
    return StatusChipTheme(
      movingForeground: Color.lerp(
        movingForeground,
        other.movingForeground,
        t,
      )!,
      movingBackground: Color.lerp(
        movingBackground,
        other.movingBackground,
        t,
      )!,
      idleForeground: Color.lerp(idleForeground, other.idleForeground, t)!,
      idleBackground: Color.lerp(idleBackground, other.idleBackground, t)!,
      stoppedForeground: Color.lerp(
        stoppedForeground,
        other.stoppedForeground,
        t,
      )!,
      stoppedBackground: Color.lerp(
        stoppedBackground,
        other.stoppedBackground,
        t,
      )!,
      offlineForeground: Color.lerp(
        offlineForeground,
        other.offlineForeground,
        t,
      )!,
      offlineBackground: Color.lerp(
        offlineBackground,
        other.offlineBackground,
        t,
      )!,
    );
  }
}

/// Colors for [AlertBadge] by [AlertSeverity].
@immutable
class AlertBadgeTheme extends ThemeExtension<AlertBadgeTheme> {
  /// Creates an [AlertBadgeTheme].
  const AlertBadgeTheme({
    required this.warningForeground,
    required this.warningBackground,
    required this.criticalForeground,
    required this.criticalBackground,
  });

  /// Foreground for warning severity.
  final Color warningForeground;

  /// Background for warning severity.
  final Color warningBackground;

  /// Foreground for critical severity.
  final Color criticalForeground;

  /// Background for critical severity.
  final Color criticalBackground;

  /// Count text color for [severity].
  Color foregroundFor(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.warning => warningForeground,
      AlertSeverity.critical => criticalForeground,
    };
  }

  /// Badge background for [severity].
  Color backgroundFor(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.warning => warningBackground,
      AlertSeverity.critical => criticalBackground,
    };
  }

  @override
  AlertBadgeTheme copyWith({
    Color? warningForeground,
    Color? warningBackground,
    Color? criticalForeground,
    Color? criticalBackground,
  }) {
    return AlertBadgeTheme(
      warningForeground: warningForeground ?? this.warningForeground,
      warningBackground: warningBackground ?? this.warningBackground,
      criticalForeground: criticalForeground ?? this.criticalForeground,
      criticalBackground: criticalBackground ?? this.criticalBackground,
    );
  }

  @override
  AlertBadgeTheme lerp(ThemeExtension<AlertBadgeTheme>? other, double t) {
    if (other is! AlertBadgeTheme) {
      return this;
    }
    return AlertBadgeTheme(
      warningForeground: Color.lerp(
        warningForeground,
        other.warningForeground,
        t,
      )!,
      warningBackground: Color.lerp(
        warningBackground,
        other.warningBackground,
        t,
      )!,
      criticalForeground: Color.lerp(
        criticalForeground,
        other.criticalForeground,
        t,
      )!,
      criticalBackground: Color.lerp(
        criticalBackground,
        other.criticalBackground,
        t,
      )!,
    );
  }
}

/// Colors for [FilterChipBar] selected / unselected chips.
@immutable
class FilterChipBarTheme extends ThemeExtension<FilterChipBarTheme> {
  /// Creates a [FilterChipBarTheme].
  const FilterChipBarTheme({
    required this.selectedForeground,
    required this.selectedBackground,
    required this.unselectedForeground,
    required this.unselectedBackground,
  });

  /// Selected chip label color.
  final Color selectedForeground;

  /// Selected chip background.
  final Color selectedBackground;

  /// Unselected chip label color.
  final Color unselectedForeground;

  /// Unselected chip background.
  final Color unselectedBackground;

  @override
  FilterChipBarTheme copyWith({
    Color? selectedForeground,
    Color? selectedBackground,
    Color? unselectedForeground,
    Color? unselectedBackground,
  }) {
    return FilterChipBarTheme(
      selectedForeground: selectedForeground ?? this.selectedForeground,
      selectedBackground: selectedBackground ?? this.selectedBackground,
      unselectedForeground: unselectedForeground ?? this.unselectedForeground,
      unselectedBackground: unselectedBackground ?? this.unselectedBackground,
    );
  }

  @override
  FilterChipBarTheme lerp(ThemeExtension<FilterChipBarTheme>? other, double t) {
    if (other is! FilterChipBarTheme) {
      return this;
    }
    return FilterChipBarTheme(
      selectedForeground: Color.lerp(
        selectedForeground,
        other.selectedForeground,
        t,
      )!,
      selectedBackground: Color.lerp(
        selectedBackground,
        other.selectedBackground,
        t,
      )!,
      unselectedForeground: Color.lerp(
        unselectedForeground,
        other.unselectedForeground,
        t,
      )!,
      unselectedBackground: Color.lerp(
        unselectedBackground,
        other.unselectedBackground,
        t,
      )!,
    );
  }
}
