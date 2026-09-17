// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeviceList {

 List<DeviceSession> get devices;
/// Create a copy of DeviceList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceListCopyWith<DeviceList> get copyWith => _$DeviceListCopyWithImpl<DeviceList>(this as DeviceList, _$identity);

  /// Serializes this DeviceList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceList&&const DeepCollectionEquality().equals(other.devices, devices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(devices));

@override
String toString() {
  return 'DeviceList(devices: $devices)';
}


}

/// @nodoc
abstract mixin class $DeviceListCopyWith<$Res>  {
  factory $DeviceListCopyWith(DeviceList value, $Res Function(DeviceList) _then) = _$DeviceListCopyWithImpl;
@useResult
$Res call({
 List<DeviceSession> devices
});




}
/// @nodoc
class _$DeviceListCopyWithImpl<$Res>
    implements $DeviceListCopyWith<$Res> {
  _$DeviceListCopyWithImpl(this._self, this._then);

  final DeviceList _self;
  final $Res Function(DeviceList) _then;

/// Create a copy of DeviceList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? devices = null,}) {
  return _then(_self.copyWith(
devices: null == devices ? _self.devices : devices // ignore: cast_nullable_to_non_nullable
as List<DeviceSession>,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceList].
extension DeviceListPatterns on DeviceList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceList value)  $default,){
final _that = this;
switch (_that) {
case _DeviceList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceList value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DeviceSession> devices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceList() when $default != null:
return $default(_that.devices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DeviceSession> devices)  $default,) {final _that = this;
switch (_that) {
case _DeviceList():
return $default(_that.devices);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DeviceSession> devices)?  $default,) {final _that = this;
switch (_that) {
case _DeviceList() when $default != null:
return $default(_that.devices);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceList extends DeviceList {
  const _DeviceList({final  List<DeviceSession> devices = const <DeviceSession>[]}): _devices = devices,super._();
  factory _DeviceList.fromJson(Map<String, dynamic> json) => _$DeviceListFromJson(json);

 final  List<DeviceSession> _devices;
@override@JsonKey() List<DeviceSession> get devices {
  if (_devices is EqualUnmodifiableListView) return _devices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_devices);
}


/// Create a copy of DeviceList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceListCopyWith<_DeviceList> get copyWith => __$DeviceListCopyWithImpl<_DeviceList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceListToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceList&&const DeepCollectionEquality().equals(other._devices, _devices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_devices));

@override
String toString() {
  return 'DeviceList(devices: $devices)';
}


}

/// @nodoc
abstract mixin class _$DeviceListCopyWith<$Res> implements $DeviceListCopyWith<$Res> {
  factory _$DeviceListCopyWith(_DeviceList value, $Res Function(_DeviceList) _then) = __$DeviceListCopyWithImpl;
@override @useResult
$Res call({
 List<DeviceSession> devices
});




}
/// @nodoc
class __$DeviceListCopyWithImpl<$Res>
    implements _$DeviceListCopyWith<$Res> {
  __$DeviceListCopyWithImpl(this._self, this._then);

  final _DeviceList _self;
  final $Res Function(_DeviceList) _then;

/// Create a copy of DeviceList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? devices = null,}) {
  return _then(_DeviceList(
devices: null == devices ? _self._devices : devices // ignore: cast_nullable_to_non_nullable
as List<DeviceSession>,
  ));
}


}

// dart format on
