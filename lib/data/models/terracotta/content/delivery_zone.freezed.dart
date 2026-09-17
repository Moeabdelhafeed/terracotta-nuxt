// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_zone.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeliveryZone {

/// CMS row key — what an address's `delivery_zone_id` points at.
 int get id;/// City name as the CMS spells it (`"Riyadh"`, `"Al Diriyah"`).
 String get name;/// Flat delivery charge for this zone. Decimal string.
 String get fee;/// Zone-specific free-delivery threshold. Null → use the payload's
/// `free_delivery_over` instead (unless [neverFree]).
 String? get freeOver;/// Delivery is never free here, at any basket value. Overrides both
/// [freeOver] and the payload-wide threshold.
 bool get neverFree;
/// Create a copy of DeliveryZone
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryZoneCopyWith<DeliveryZone> get copyWith => _$DeliveryZoneCopyWithImpl<DeliveryZone>(this as DeliveryZone, _$identity);

  /// Serializes this DeliveryZone to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryZone&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.freeOver, freeOver) || other.freeOver == freeOver)&&(identical(other.neverFree, neverFree) || other.neverFree == neverFree));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,fee,freeOver,neverFree);

@override
String toString() {
  return 'DeliveryZone(id: $id, name: $name, fee: $fee, freeOver: $freeOver, neverFree: $neverFree)';
}


}

/// @nodoc
abstract mixin class $DeliveryZoneCopyWith<$Res>  {
  factory $DeliveryZoneCopyWith(DeliveryZone value, $Res Function(DeliveryZone) _then) = _$DeliveryZoneCopyWithImpl;
@useResult
$Res call({
 int id, String name, String fee, String? freeOver, bool neverFree
});




}
/// @nodoc
class _$DeliveryZoneCopyWithImpl<$Res>
    implements $DeliveryZoneCopyWith<$Res> {
  _$DeliveryZoneCopyWithImpl(this._self, this._then);

  final DeliveryZone _self;
  final $Res Function(DeliveryZone) _then;

/// Create a copy of DeliveryZone
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? fee = null,Object? freeOver = freezed,Object? neverFree = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as String,freeOver: freezed == freeOver ? _self.freeOver : freeOver // ignore: cast_nullable_to_non_nullable
as String?,neverFree: null == neverFree ? _self.neverFree : neverFree // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DeliveryZone].
extension DeliveryZonePatterns on DeliveryZone {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryZone value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryZone() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryZone value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryZone():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryZone value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryZone() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String fee,  String? freeOver,  bool neverFree)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryZone() when $default != null:
return $default(_that.id,_that.name,_that.fee,_that.freeOver,_that.neverFree);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String fee,  String? freeOver,  bool neverFree)  $default,) {final _that = this;
switch (_that) {
case _DeliveryZone():
return $default(_that.id,_that.name,_that.fee,_that.freeOver,_that.neverFree);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String fee,  String? freeOver,  bool neverFree)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryZone() when $default != null:
return $default(_that.id,_that.name,_that.fee,_that.freeOver,_that.neverFree);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeliveryZone implements DeliveryZone {
  const _DeliveryZone({required this.id, required this.name, required this.fee, this.freeOver, required this.neverFree});
  factory _DeliveryZone.fromJson(Map<String, dynamic> json) => _$DeliveryZoneFromJson(json);

/// CMS row key — what an address's `delivery_zone_id` points at.
@override final  int id;
/// City name as the CMS spells it (`"Riyadh"`, `"Al Diriyah"`).
@override final  String name;
/// Flat delivery charge for this zone. Decimal string.
@override final  String fee;
/// Zone-specific free-delivery threshold. Null → use the payload's
/// `free_delivery_over` instead (unless [neverFree]).
@override final  String? freeOver;
/// Delivery is never free here, at any basket value. Overrides both
/// [freeOver] and the payload-wide threshold.
@override final  bool neverFree;

/// Create a copy of DeliveryZone
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryZoneCopyWith<_DeliveryZone> get copyWith => __$DeliveryZoneCopyWithImpl<_DeliveryZone>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeliveryZoneToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryZone&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.freeOver, freeOver) || other.freeOver == freeOver)&&(identical(other.neverFree, neverFree) || other.neverFree == neverFree));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,fee,freeOver,neverFree);

@override
String toString() {
  return 'DeliveryZone(id: $id, name: $name, fee: $fee, freeOver: $freeOver, neverFree: $neverFree)';
}


}

/// @nodoc
abstract mixin class _$DeliveryZoneCopyWith<$Res> implements $DeliveryZoneCopyWith<$Res> {
  factory _$DeliveryZoneCopyWith(_DeliveryZone value, $Res Function(_DeliveryZone) _then) = __$DeliveryZoneCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String fee, String? freeOver, bool neverFree
});




}
/// @nodoc
class __$DeliveryZoneCopyWithImpl<$Res>
    implements _$DeliveryZoneCopyWith<$Res> {
  __$DeliveryZoneCopyWithImpl(this._self, this._then);

  final _DeliveryZone _self;
  final $Res Function(_DeliveryZone) _then;

/// Create a copy of DeliveryZone
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? fee = null,Object? freeOver = freezed,Object? neverFree = null,}) {
  return _then(_DeliveryZone(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as String,freeOver: freezed == freeOver ? _self.freeOver : freeOver // ignore: cast_nullable_to_non_nullable
as String?,neverFree: null == neverFree ? _self.neverFree : neverFree // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
