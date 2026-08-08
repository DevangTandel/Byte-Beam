// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VehicleModel _$VehicleModelFromJson(Map<String, dynamic> json) =>
    _VehicleModel(
      vin: json['vin'] as String,
      reg: json['reg'] as String,
      model: json['model'] as String,
      socPercent: (json['socPercent'] as num?)?.toDouble(),
      rangeKm: (json['rangeKm'] as num?)?.toDouble(),
      speedKmh: (json['speedKmh'] as num).toDouble(),
      ignitionOn: json['ignitionOn'] as bool?,
      batteryTempC: (json['batteryTempC'] as num?)?.toDouble(),
      odometerKm: (json['odometerKm'] as num).toDouble(),
      lastPingSecondsAgo: (json['lastPingSecondsAgo'] as num).toInt(),
    );

Map<String, dynamic> _$VehicleModelToJson(_VehicleModel instance) =>
    <String, dynamic>{
      'vin': instance.vin,
      'reg': instance.reg,
      'model': instance.model,
      'socPercent': instance.socPercent,
      'rangeKm': instance.rangeKm,
      'speedKmh': instance.speedKmh,
      'ignitionOn': instance.ignitionOn,
      'batteryTempC': instance.batteryTempC,
      'odometerKm': instance.odometerKm,
      'lastPingSecondsAgo': instance.lastPingSecondsAgo,
    };
