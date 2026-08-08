import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/fleet/domain/entities/reading.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_model.freezed.dart';
part 'vehicle_model.g.dart';

@freezed
abstract class VehicleModel with _$VehicleModel {
  const factory VehicleModel({
    required String vin,
    required String reg,
    required String model,
    required double speedKmh,
    required double odometerKm,
    required int lastPingSecondsAgo,
    double? socPercent,
    double? rangeKm,
    bool? ignitionOn,
    double? batteryTempC,
  }) = _VehicleModel;
  const VehicleModel._();

  factory VehicleModel.fromJson(Map<String, dynamic> json) =>
      _$VehicleModelFromJson(json);

  /// Maps this DTO to a domain [Vehicle], resolving lastPingAt from
  /// [lastPingSecondsAgo] against the fixed app-launch [launchClock].
  Vehicle toDomain(Clock launchClock) {
    final lastPingAt = launchClock.now().subtract(
      Duration(seconds: lastPingSecondsAgo),
    );

    Reading<double> reading(double? value) => Reading<double>(
      clock: launchClock,
      value: value,
      lastPingAt: lastPingAt,
    );

    return Vehicle(
      vin: vin,
      reg: reg,
      model: model,
      soc: reading(socPercent),
      range: reading(rangeKm),
      speed: reading(speedKmh),
      batteryTemp: reading(batteryTempC),
      odometer: reading(odometerKm),
      lastPingAt: lastPingAt,
      ignitionOn: ignitionOn,
    );
  }
}
