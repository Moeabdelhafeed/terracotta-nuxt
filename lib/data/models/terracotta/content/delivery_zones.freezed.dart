// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_zones.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeliveryZones {

/// Every deliverable city. 113 of them in the live capture.
 List<DeliveryZone> get zones;/// Charge for an address that matched no zone. Decimal string.
 String get defaultFee;/// Baseline free-delivery threshold. Decimal string.
 String get freeDeliveryOver;
/// Create a copy of DeliveryZones
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryZonesCopyWith<DeliveryZones> get copyWith => _$DeliveryZonesCopyWithImpl<DeliveryZones>(this as DeliveryZones, _$identity);

  /// Serializes this DeliveryZones to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryZones&&const DeepCollectionEquality().equals(other.zones, zones)&&(identical(other.defaultFee, defaultFee) || other.defaultFee == defaultFee)&&(identical(other.freeDeliveryOver, freeDeliveryOver) || other.freeDeliveryOver == freeDeliveryOver));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(zones),defaultFee,freeDeliveryOver);

@override
String toString() {
  return 'DeliveryZones(zones: $zones, defaultFee: $defaultFee, freeDeliveryOver: $freeDeliveryOver)';
}


}

/// @nodoc
abstract mixin class $DeliveryZonesCopyWith<$Res>  {
  factory $DeliveryZonesCopyWith(DeliveryZones value, $Res Function(DeliveryZones) _then) = _$DeliveryZonesCopyWithImpl;
@useResult
$Res call({
 List<DeliveryZone> zones, String defaultFee, String freeDeliveryOver
});




}
/// @nodoc
class _$DeliveryZonesCopyWithImpl<$Res>
    implements $DeliveryZonesCopyWith<$Res> {
  _$DeliveryZonesCopyWithImpl(this._self, this._then);

  final DeliveryZones _self;
  final $Res Function(DeliveryZones) _then;

/// Create a copy of DeliveryZones
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? zones = null,Object? defaultFee = null,Object? freeDeliveryOver = null,}) {
  return _then(_self.copyWith(
zones: null == zones ? _self.zones : zones // ignore: cast_nullable_to_non_nullable
as List<DeliveryZone>,defaultFee: null == defaultFee ? _self.defaultFee : defaultFee // ignore: cast_nullable_to_non_nullable
as String,freeDeliveryOver: null == freeDeliveryOver ? _self.freeDeliveryOver : freeDeliveryOver // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DeliveryZones].
extension DeliveryZonesPatterns on DeliveryZones {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryZones value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryZones() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryZones value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryZones():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryZones value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryZones() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DeliveryZone> zones,  String defaultFee,  String freeDeliveryOver)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryZones() when $default != null:
return $default(_that.zones,_that.defaultFee,_that.freeDeliveryOver);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DeliveryZone> zones,  String defaultFee,  String freeDeliveryOver)  $default,) {final _that = this;
switch (_that) {
case _DeliveryZones():
return $default(_that.zones,_that.defaultFee,_that.freeDeliveryOver);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DeliveryZone> zones,  String defaultFee,  String freeDeliveryOver)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryZones() when $default != null:
return $default(_that.zones,_that.defaultFee,_that.freeDeliveryOver);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeliveryZones extends DeliveryZones {
  const _DeliveryZones({required final  List<DeliveryZone> zones, required this.defaultFee, required this.freeDeliveryOver}): _zones = zones,super._();
  factory _DeliveryZones.fromJson(Map<String, dynamic> json) => _$DeliveryZonesFromJson(json);

/// Every deliverable city. 113 of them in the live capture.
 final  List<DeliveryZone> _zones;
/// Every deliverable city. 113 of them in the live capture.
@override List<DeliveryZone> get zones {
  if (_zones is EqualUnmodifiableListView) return _zones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_zones);
}

/// Charge for an address that matched no zone. Decimal string.
@override final  String defaultFee;
/// Baseline free-delivery threshold. Decimal string.
@override final  String freeDeliveryOver;

/// Create a copy of DeliveryZones
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryZonesCopyWith<_DeliveryZones> get copyWith => __$DeliveryZonesCopyWithImpl<_DeliveryZones>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeliveryZonesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryZones&&const DeepCollectionEquality().equals(other._zones, _zones)&&(identical(other.defaultFee, defaultFee) || other.defaultFee == defaultFee)&&(identical(other.freeDeliveryOver, freeDeliveryOver) || other.freeDeliveryOver == freeDeliveryOver));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_zones),defaultFee,freeDeliveryOver);

@override
String toString() {
  return 'DeliveryZones(zones: $zones, defaultFee: $defaultFee, freeDeliveryOver: $freeDeliveryOver)';
}


}

/// @nodoc
abstract mixin class _$DeliveryZonesCopyWith<$Res> implements $DeliveryZonesCopyWith<$Res> {
  factory _$DeliveryZonesCopyWith(_DeliveryZones value, $Res Function(_DeliveryZones) _then) = __$DeliveryZonesCopyWithImpl;
@override @useResult
$Res call({
 List<DeliveryZone> zones, String defaultFee, String freeDeliveryOver
});




}
/// @nodoc
class __$DeliveryZonesCopyWithImpl<$Res>
    implements _$DeliveryZonesCopyWith<$Res> {
  __$DeliveryZonesCopyWithImpl(this._self, this._then);

  final _DeliveryZones _self;
  final $Res Function(_DeliveryZones) _then;

/// Create a copy of DeliveryZones
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? zones = null,Object? defaultFee = null,Object? freeDeliveryOver = null,}) {
  return _then(_DeliveryZones(
zones: null == zones ? _self._zones : zones // ignore: cast_nullable_to_non_nullable
as List<DeliveryZone>,defaultFee: null == defaultFee ? _self.defaultFee : defaultFee // ignore: cast_nullable_to_non_nullable
as String,freeDeliveryOver: null == freeDeliveryOver ? _self.freeDeliveryOver : freeDeliveryOver // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
