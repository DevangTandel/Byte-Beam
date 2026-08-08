import 'package:byte_beam/features/alerts/domain/rules/alert_engine.dart';
import 'package:byte_beam/features/fleet/domain/rules/staleness_evaluator.dart';

/// UI-ready bounds for SOC (aligned with low-battery alert threshold).
const kSocBounds = ThresholdBounds(
  min: kLowBatteryWarningThreshold,
  max: 100,
);

/// UI-ready bounds for battery temperature (°C).
const kBatteryTempBounds = ThresholdBounds(
  min: 0,
  max: kBatteryOverheatingThreshold,
);

/// UI-ready bounds for speed (km/h).
const kSpeedBounds = ThresholdBounds(min: 0, max: 200);

/// UI-ready bounds for range (km).
const kRangeBounds = ThresholdBounds(min: 0, max: 1000);

/// UI-ready bounds for odometer (km).
const kOdometerBounds = ThresholdBounds(min: 0, max: 5000000);
