// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paintable_workshop.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaintableWorkshop {

/// The WORKSHOP's id — confirmed by the backend on 2026-09-15, and
/// what «لوّن قطعتك» opens the schedule for.
///
/// **Nullable, though the button needs it.** `/docs.openapi` only
/// ever shows `paintable_at: []`, so nothing proves the key is
/// always there; declared `required` a row without one threw
/// inside `fromJson` and took the WHOLE booking down with it — a
/// detail page that will not open because of an upsell. A row with
/// no id is dropped instead and the button goes with it, which is
/// the same outcome as the empty list the app already handles.
///
/// Read it through [isReachable] rather than force-unwrapping.
 int? get id; String? get title; ApiImage? get image;
/// Create a copy of PaintableWorkshop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaintableWorkshopCopyWith<PaintableWorkshop> get copyWith => _$PaintableWorkshopCopyWithImpl<PaintableWorkshop>(this as PaintableWorkshop, _$identity);

  /// Serializes this PaintableWorkshop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaintableWorkshop&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,image);

@override
String toString() {
  return 'PaintableWorkshop(id: $id, title: $title, image: $image)';
}


}

/// @nodoc
abstract mixin class $PaintableWorkshopCopyWith<$Res>  {
  factory $PaintableWorkshopCopyWith(PaintableWorkshop value, $Res Function(PaintableWorkshop) _then) = _$PaintableWorkshopCopyWithImpl;
@useResult
$Res call({
 int? id, String? title, ApiImage? image
});


$ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class _$PaintableWorkshopCopyWithImpl<$Res>
    implements $PaintableWorkshopCopyWith<$Res> {
  _$PaintableWorkshopCopyWithImpl(this._self, this._then);

  final PaintableWorkshop _self;
  final $Res Function(PaintableWorkshop) _then;

/// Create a copy of PaintableWorkshop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? title = freezed,Object? image = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,
  ));
}
/// Create a copy of PaintableWorkshop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiImageCopyWith<$Res>? get image {
    if (_self.image == null) {
    return null;
  }

  return $ApiImageCopyWith<$Res>(_self.image!, (value) {
    return _then(_self.copyWith(image: value));
  });
}
}


/// Adds pattern-matching-related methods to [PaintableWorkshop].
extension PaintableWorkshopPatterns on PaintableWorkshop {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaintableWorkshop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaintableWorkshop() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaintableWorkshop value)  $default,){
final _that = this;
switch (_that) {
case _PaintableWorkshop():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaintableWorkshop value)?  $default,){
final _that = this;
switch (_that) {
case _PaintableWorkshop() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? title,  ApiImage? image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaintableWorkshop() when $default != null:
return $default(_that.id,_that.title,_that.image);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? title,  ApiImage? image)  $default,) {final _that = this;
switch (_that) {
case _PaintableWorkshop():
return $default(_that.id,_that.title,_that.image);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? title,  ApiImage? image)?  $default,) {final _that = this;
switch (_that) {
case _PaintableWorkshop() when $default != null:
return $default(_that.id,_that.title,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaintableWorkshop extends PaintableWorkshop {
  const _PaintableWorkshop({this.id, this.title, this.image}): super._();
  factory _PaintableWorkshop.fromJson(Map<String, dynamic> json) => _$PaintableWorkshopFromJson(json);

/// The WORKSHOP's id — confirmed by the backend on 2026-09-15, and
/// what «لوّن قطعتك» opens the schedule for.
///
/// **Nullable, though the button needs it.** `/docs.openapi` only
/// ever shows `paintable_at: []`, so nothing proves the key is
/// always there; declared `required` a row without one threw
/// inside `fromJson` and took the WHOLE booking down with it — a
/// detail page that will not open because of an upsell. A row with
/// no id is dropped instead and the button goes with it, which is
/// the same outcome as the empty list the app already handles.
///
/// Read it through [isReachable] rather than force-unwrapping.
@override final  int? id;
@override final  String? title;
@override final  ApiImage? image;

/// Create a copy of PaintableWorkshop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaintableWorkshopCopyWith<_PaintableWorkshop> get copyWith => __$PaintableWorkshopCopyWithImpl<_PaintableWorkshop>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaintableWorkshopToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaintableWorkshop&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,image);

@override
String toString() {
  return 'PaintableWorkshop(id: $id, title: $title, image: $image)';
}


}

/// @nodoc
abstract mixin class _$PaintableWorkshopCopyWith<$Res> implements $PaintableWorkshopCopyWith<$Res> {
  factory _$PaintableWorkshopCopyWith(_PaintableWorkshop value, $Res Function(_PaintableWorkshop) _then) = __$PaintableWorkshopCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? title, ApiImage? image
});


@override $ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class __$PaintableWorkshopCopyWithImpl<$Res>
    implements _$PaintableWorkshopCopyWith<$Res> {
  __$PaintableWorkshopCopyWithImpl(this._self, this._then);

  final _PaintableWorkshop _self;
  final $Res Function(_PaintableWorkshop) _then;

/// Create a copy of PaintableWorkshop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? title = freezed,Object? image = freezed,}) {
  return _then(_PaintableWorkshop(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,
  ));
}

/// Create a copy of PaintableWorkshop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiImageCopyWith<$Res>? get image {
    if (_self.image == null) {
    return null;
  }

  return $ApiImageCopyWith<$Res>(_self.image!, (value) {
    return _then(_self.copyWith(image: value));
  });
}
}

// dart format on
