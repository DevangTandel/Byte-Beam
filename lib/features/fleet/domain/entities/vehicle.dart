import 'package:byte_beam/features/fleet/domain/entities/reading.dart';

/// Fleet vehicle with typed telemetry readings.
class Vehicle {
  /// Creates a [Vehicle].
  const Vehicle({
    required this.vin,
    required this.reg,
    required this.model,
    required this.soc,
    required this.range,
    required this.speed,
    required this.batteryTemp,
    required this.odometer,
    required this.lastPingAt,
    this.ignitionOn,
  });

  /// Vehicle identification number.
  final String vin;

  /// Registration plate.
  final String reg;

  /// Vehicle model name.
  final String model;

  /// State of charge percentage.
  final Reading<double> soc;

  /// Estimated range in kilometres.
  final Reading<double> range;

  /// Current speed in km/h.
  final Reading<double> speed;

  /// Battery temperature in degrees Celsius.
  final Reading<double> batteryTemp;

  /// Odometer reading in kilometres.
  final Reading<double> odometer;

  /// Last vehicle ping time for the 10-minute offline window.
  final DateTime lastPingAt;

  /// Ignition state, or null when unknown.
  final bool? ignitionOn;
}
