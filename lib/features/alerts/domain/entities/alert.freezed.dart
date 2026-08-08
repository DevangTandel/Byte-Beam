// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alert.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Alert {

 String get id; String get vin; AlertKind get kind; AlertSeverity get severity; DateTime get raisedAt; bool get isBasedOnStaleData;
/// Create a copy of Alert
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlertCopyWith<Alert> get copyWith => _$AlertCopyWithImpl<Alert>(this as Alert, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Alert&&(identical(other.id, id) || other.id == id)&&(identical(other.vin, vin) || other.vin == vin)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.raisedAt, raisedAt) || other.raisedAt == raisedAt)&&(identical(other.isBasedOnStaleData, isBasedOnStaleData) || other.isBasedOnStaleData == isBasedOnStaleData));
}


@override
int get hashCode => Object.hash(runtimeType,id,vin,kind,severity,raisedAt,isBasedOnStaleData);

@override
String toString() {
  return 'Alert(id: $id, vin: $vin, kind: $kind, severity: $severity, raisedAt: $raisedAt, isBasedOnStaleData: $isBasedOnStaleData)';
}


}

/// @nodoc
abstract mixin class $AlertCopyWith<$Res>  {
  factory $AlertCopyWith(Alert value, $Res Function(Alert) _then) = _$AlertCopyWithImpl;
@useResult
$Res call({
 String id, String vin, AlertKind kind, AlertSeverity severity, DateTime raisedAt, bool isBasedOnStaleData
});




}
/// @nodoc
class _$AlertCopyWithImpl<$Res>
    implements $AlertCopyWith<$Res> {
  _$AlertCopyWithImpl(this._self, this._then);

  final Alert _self;
  final $Res Function(Alert) _then;

/// Create a copy of Alert
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vin = null,Object? kind = null,Object? severity = null,Object? raisedAt = null,Object? isBasedOnStaleData = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vin: null == vin ? _self.vin : vin // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AlertKind,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as AlertSeverity,raisedAt: null == raisedAt ? _self.raisedAt : raisedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isBasedOnStaleData: null == isBasedOnStaleData ? _self.isBasedOnStaleData : isBasedOnStaleData // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Alert].
extension AlertPatterns on Alert {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Alert value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Alert() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Alert value)  $default,){
final _that = this;
switch (_that) {
case _Alert():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Alert value)?  $default,){
final _that = this;
switch (_that) {
case _Alert() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String vin,  AlertKind kind,  AlertSeverity severity,  DateTime raisedAt,  bool isBasedOnStaleData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Alert() when $default != null:
return $default(_that.id,_that.vin,_that.kind,_that.severity,_that.raisedAt,_that.isBasedOnStaleData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String vin,  AlertKind kind,  AlertSeverity severity,  DateTime raisedAt,  bool isBasedOnStaleData)  $default,) {final _that = this;
switch (_that) {
case _Alert():
return $default(_that.id,_that.vin,_that.kind,_that.severity,_that.raisedAt,_that.isBasedOnStaleData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String vin,  AlertKind kind,  AlertSeverity severity,  DateTime raisedAt,  bool isBasedOnStaleData)?  $default,) {final _that = this;
switch (_that) {
case _Alert() when $default != null:
return $default(_that.id,_that.vin,_that.kind,_that.severity,_that.raisedAt,_that.isBasedOnStaleData);case _:
  return null;

}
}

}

/// @nodoc


class _Alert implements Alert {
  const _Alert({required this.id, required this.vin, required this.kind, required this.severity, required this.raisedAt, required this.isBasedOnStaleData});
  

@override final  String id;
@override final  String vin;
@override final  AlertKind kind;
@override final  AlertSeverity severity;
@override final  DateTime raisedAt;
@override final  bool isBasedOnStaleData;

/// Create a copy of Alert
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlertCopyWith<_Alert> get copyWith => __$AlertCopyWithImpl<_Alert>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Alert&&(identical(other.id, id) || other.id == id)&&(identical(other.vin, vin) || other.vin == vin)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.raisedAt, raisedAt) || other.raisedAt == raisedAt)&&(identical(other.isBasedOnStaleData, isBasedOnStaleData) || other.isBasedOnStaleData == isBasedOnStaleData));
}


@override
int get hashCode => Object.hash(runtimeType,id,vin,kind,severity,raisedAt,isBasedOnStaleData);

@override
String toString() {
  return 'Alert(id: $id, vin: $vin, kind: $kind, severity: $severity, raisedAt: $raisedAt, isBasedOnStaleData: $isBasedOnStaleData)';
}


}

/// @nodoc
abstract mixin class _$AlertCopyWith<$Res> implements $AlertCopyWith<$Res> {
  factory _$AlertCopyWith(_Alert value, $Res Function(_Alert) _then) = __$AlertCopyWithImpl;
@override @useResult
$Res call({
 String id, String vin, AlertKind kind, AlertSeverity severity, DateTime raisedAt, bool isBasedOnStaleData
});




}
/// @nodoc
class __$AlertCopyWithImpl<$Res>
    implements _$AlertCopyWith<$Res> {
  __$AlertCopyWithImpl(this._self, this._then);

  final _Alert _self;
  final $Res Function(_Alert) _then;

/// Create a copy of Alert
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vin = null,Object? kind = null,Object? severity = null,Object? raisedAt = null,Object? isBasedOnStaleData = null,}) {
  return _then(_Alert(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vin: null == vin ? _self.vin : vin // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AlertKind,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as AlertSeverity,raisedAt: null == raisedAt ? _self.raisedAt : raisedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isBasedOnStaleData: null == isBasedOnStaleData ? _self.isBasedOnStaleData : isBasedOnStaleData // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
