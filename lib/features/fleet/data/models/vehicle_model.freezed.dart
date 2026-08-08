// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VehicleModel {

 String get vin; String get reg; String get model; double? get socPercent; double? get rangeKm; double get speedKmh; bool? get ignitionOn; double? get batteryTempC; double get odometerKm; int get lastPingSecondsAgo;
/// Create a copy of VehicleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleModelCopyWith<VehicleModel> get copyWith => _$VehicleModelCopyWithImpl<VehicleModel>(this as VehicleModel, _$identity);

  /// Serializes this VehicleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VehicleModel&&(identical(other.vin, vin) || other.vin == vin)&&(identical(other.reg, reg) || other.reg == reg)&&(identical(other.model, model) || other.model == model)&&(identical(other.socPercent, socPercent) || other.socPercent == socPercent)&&(identical(other.rangeKm, rangeKm) || other.rangeKm == rangeKm)&&(identical(other.speedKmh, speedKmh) || other.speedKmh == speedKmh)&&(identical(other.ignitionOn, ignitionOn) || other.ignitionOn == ignitionOn)&&(identical(other.batteryTempC, batteryTempC) || other.batteryTempC == batteryTempC)&&(identical(other.odometerKm, odometerKm) || other.odometerKm == odometerKm)&&(identical(other.lastPingSecondsAgo, lastPingSecondsAgo) || other.lastPingSecondsAgo == lastPingSecondsAgo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,vin,reg,model,socPercent,rangeKm,speedKmh,ignitionOn,batteryTempC,odometerKm,lastPingSecondsAgo);

@override
String toString() {
  return 'VehicleModel(vin: $vin, reg: $reg, model: $model, socPercent: $socPercent, rangeKm: $rangeKm, speedKmh: $speedKmh, ignitionOn: $ignitionOn, batteryTempC: $batteryTempC, odometerKm: $odometerKm, lastPingSecondsAgo: $lastPingSecondsAgo)';
}


}

/// @nodoc
abstract mixin class $VehicleModelCopyWith<$Res>  {
  factory $VehicleModelCopyWith(VehicleModel value, $Res Function(VehicleModel) _then) = _$VehicleModelCopyWithImpl;
@useResult
$Res call({
 String vin, String reg, String model, double? socPercent, double? rangeKm, double speedKmh, bool? ignitionOn, double? batteryTempC, double odometerKm, int lastPingSecondsAgo
});




}
/// @nodoc
class _$VehicleModelCopyWithImpl<$Res>
    implements $VehicleModelCopyWith<$Res> {
  _$VehicleModelCopyWithImpl(this._self, this._then);

  final VehicleModel _self;
  final $Res Function(VehicleModel) _then;

/// Create a copy of VehicleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vin = null,Object? reg = null,Object? model = null,Object? socPercent = freezed,Object? rangeKm = freezed,Object? speedKmh = null,Object? ignitionOn = freezed,Object? batteryTempC = freezed,Object? odometerKm = null,Object? lastPingSecondsAgo = null,}) {
  return _then(_self.copyWith(
vin: null == vin ? _self.vin : vin // ignore: cast_nullable_to_non_nullable
as String,reg: null == reg ? _self.reg : reg // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,socPercent: freezed == socPercent ? _self.socPercent : socPercent // ignore: cast_nullable_to_non_nullable
as double?,rangeKm: freezed == rangeKm ? _self.rangeKm : rangeKm // ignore: cast_nullable_to_non_nullable
as double?,speedKmh: null == speedKmh ? _self.speedKmh : speedKmh // ignore: cast_nullable_to_non_nullable
as double,ignitionOn: freezed == ignitionOn ? _self.ignitionOn : ignitionOn // ignore: cast_nullable_to_non_nullable
as bool?,batteryTempC: freezed == batteryTempC ? _self.batteryTempC : batteryTempC // ignore: cast_nullable_to_non_nullable
as double?,odometerKm: null == odometerKm ? _self.odometerKm : odometerKm // ignore: cast_nullable_to_non_nullable
as double,lastPingSecondsAgo: null == lastPingSecondsAgo ? _self.lastPingSecondsAgo : lastPingSecondsAgo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VehicleModel].
extension VehicleModelPatterns on VehicleModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VehicleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VehicleModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VehicleModel value)  $default,){
final _that = this;
switch (_that) {
case _VehicleModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VehicleModel value)?  $default,){
final _that = this;
switch (_that) {
case _VehicleModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String vin,  String reg,  String model,  double? socPercent,  double? rangeKm,  double speedKmh,  bool? ignitionOn,  double? batteryTempC,  double odometerKm,  int lastPingSecondsAgo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VehicleModel() when $default != null:
return $default(_that.vin,_that.reg,_that.model,_that.socPercent,_that.rangeKm,_that.speedKmh,_that.ignitionOn,_that.batteryTempC,_that.odometerKm,_that.lastPingSecondsAgo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String vin,  String reg,  String model,  double? socPercent,  double? rangeKm,  double speedKmh,  bool? ignitionOn,  double? batteryTempC,  double odometerKm,  int lastPingSecondsAgo)  $default,) {final _that = this;
switch (_that) {
case _VehicleModel():
return $default(_that.vin,_that.reg,_that.model,_that.socPercent,_that.rangeKm,_that.speedKmh,_that.ignitionOn,_that.batteryTempC,_that.odometerKm,_that.lastPingSecondsAgo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String vin,  String reg,  String model,  double? socPercent,  double? rangeKm,  double speedKmh,  bool? ignitionOn,  double? batteryTempC,  double odometerKm,  int lastPingSecondsAgo)?  $default,) {final _that = this;
switch (_that) {
case _VehicleModel() when $default != null:
return $default(_that.vin,_that.reg,_that.model,_that.socPercent,_that.rangeKm,_that.speedKmh,_that.ignitionOn,_that.batteryTempC,_that.odometerKm,_that.lastPingSecondsAgo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VehicleModel extends VehicleModel {
  const _VehicleModel({required this.vin, required this.reg, required this.model, this.socPercent, this.rangeKm, required this.speedKmh, this.ignitionOn, this.batteryTempC, required this.odometerKm, required this.lastPingSecondsAgo}): super._();
  factory _VehicleModel.fromJson(Map<String, dynamic> json) => _$VehicleModelFromJson(json);

@override final  String vin;
@override final  String reg;
@override final  String model;
@override final  double? socPercent;
@override final  double? rangeKm;
@override final  double speedKmh;
@override final  bool? ignitionOn;
@override final  double? batteryTempC;
@override final  double odometerKm;
@override final  int lastPingSecondsAgo;

/// Create a copy of VehicleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleModelCopyWith<_VehicleModel> get copyWith => __$VehicleModelCopyWithImpl<_VehicleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VehicleModel&&(identical(other.vin, vin) || other.vin == vin)&&(identical(other.reg, reg) || other.reg == reg)&&(identical(other.model, model) || other.model == model)&&(identical(other.socPercent, socPercent) || other.socPercent == socPercent)&&(identical(other.rangeKm, rangeKm) || other.rangeKm == rangeKm)&&(identical(other.speedKmh, speedKmh) || other.speedKmh == speedKmh)&&(identical(other.ignitionOn, ignitionOn) || other.ignitionOn == ignitionOn)&&(identical(other.batteryTempC, batteryTempC) || other.batteryTempC == batteryTempC)&&(identical(other.odometerKm, odometerKm) || other.odometerKm == odometerKm)&&(identical(other.lastPingSecondsAgo, lastPingSecondsAgo) || other.lastPingSecondsAgo == lastPingSecondsAgo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,vin,reg,model,socPercent,rangeKm,speedKmh,ignitionOn,batteryTempC,odometerKm,lastPingSecondsAgo);

@override
String toString() {
  return 'VehicleModel(vin: $vin, reg: $reg, model: $model, socPercent: $socPercent, rangeKm: $rangeKm, speedKmh: $speedKmh, ignitionOn: $ignitionOn, batteryTempC: $batteryTempC, odometerKm: $odometerKm, lastPingSecondsAgo: $lastPingSecondsAgo)';
}


}

/// @nodoc
abstract mixin class _$VehicleModelCopyWith<$Res> implements $VehicleModelCopyWith<$Res> {
  factory _$VehicleModelCopyWith(_VehicleModel value, $Res Function(_VehicleModel) _then) = __$VehicleModelCopyWithImpl;
@override @useResult
$Res call({
 String vin, String reg, String model, double? socPercent, double? rangeKm, double speedKmh, bool? ignitionOn, double? batteryTempC, double odometerKm, int lastPingSecondsAgo
});




}
/// @nodoc
class __$VehicleModelCopyWithImpl<$Res>
    implements _$VehicleModelCopyWith<$Res> {
  __$VehicleModelCopyWithImpl(this._self, this._then);

  final _VehicleModel _self;
  final $Res Function(_VehicleModel) _then;

/// Create a copy of VehicleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vin = null,Object? reg = null,Object? model = null,Object? socPercent = freezed,Object? rangeKm = freezed,Object? speedKmh = null,Object? ignitionOn = freezed,Object? batteryTempC = freezed,Object? odometerKm = null,Object? lastPingSecondsAgo = null,}) {
  return _then(_VehicleModel(
vin: null == vin ? _self.vin : vin // ignore: cast_nullable_to_non_nullable
as String,reg: null == reg ? _self.reg : reg // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,socPercent: freezed == socPercent ? _self.socPercent : socPercent // ignore: cast_nullable_to_non_nullable
as double?,rangeKm: freezed == rangeKm ? _self.rangeKm : rangeKm // ignore: cast_nullable_to_non_nullable
as double?,speedKmh: null == speedKmh ? _self.speedKmh : speedKmh // ignore: cast_nullable_to_non_nullable
as double,ignitionOn: freezed == ignitionOn ? _self.ignitionOn : ignitionOn // ignore: cast_nullable_to_non_nullable
as bool?,batteryTempC: freezed == batteryTempC ? _self.batteryTempC : batteryTempC // ignore: cast_nullable_to_non_nullable
as double?,odometerKm: null == odometerKm ? _self.odometerKm : odometerKm // ignore: cast_nullable_to_non_nullable
as double,lastPingSecondsAgo: null == lastPingSecondsAgo ? _self.lastPingSecondsAgo : lastPingSecondsAgo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
