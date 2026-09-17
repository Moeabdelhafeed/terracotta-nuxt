// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'social_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SocialAccount {

 int get id;/// Firebase provider id, dotted (`"google.com"`). Read via [kind].
 String? get provider;/// Email the provider asserted. Must match the account's email for
/// the link to have been accepted.
 String? get email;/// Display name from the provider.
 String? get name;
/// Create a copy of SocialAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocialAccountCopyWith<SocialAccount> get copyWith => _$SocialAccountCopyWithImpl<SocialAccount>(this as SocialAccount, _$identity);

  /// Serializes this SocialAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocialAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.email, email) || other.email == email)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,provider,email,name);

@override
String toString() {
  return 'SocialAccount(id: $id, provider: $provider, email: $email, name: $name)';
}


}

/// @nodoc
abstract mixin class $SocialAccountCopyWith<$Res>  {
  factory $SocialAccountCopyWith(SocialAccount value, $Res Function(SocialAccount) _then) = _$SocialAccountCopyWithImpl;
@useResult
$Res call({
 int id, String? provider, String? email, String? name
});




}
/// @nodoc
class _$SocialAccountCopyWithImpl<$Res>
    implements $SocialAccountCopyWith<$Res> {
  _$SocialAccountCopyWithImpl(this._self, this._then);

  final SocialAccount _self;
  final $Res Function(SocialAccount) _then;

/// Create a copy of SocialAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? provider = freezed,Object? email = freezed,Object? name = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SocialAccount].
extension SocialAccountPatterns on SocialAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SocialAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SocialAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SocialAccount value)  $default,){
final _that = this;
switch (_that) {
case _SocialAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SocialAccount value)?  $default,){
final _that = this;
switch (_that) {
case _SocialAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? provider,  String? email,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SocialAccount() when $default != null:
return $default(_that.id,_that.provider,_that.email,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? provider,  String? email,  String? name)  $default,) {final _that = this;
switch (_that) {
case _SocialAccount():
return $default(_that.id,_that.provider,_that.email,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? provider,  String? email,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _SocialAccount() when $default != null:
return $default(_that.id,_that.provider,_that.email,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SocialAccount extends SocialAccount {
  const _SocialAccount({required this.id, this.provider, this.email, this.name}): super._();
  factory _SocialAccount.fromJson(Map<String, dynamic> json) => _$SocialAccountFromJson(json);

@override final  int id;
/// Firebase provider id, dotted (`"google.com"`). Read via [kind].
@override final  String? provider;
/// Email the provider asserted. Must match the account's email for
/// the link to have been accepted.
@override final  String? email;
/// Display name from the provider.
@override final  String? name;

/// Create a copy of SocialAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SocialAccountCopyWith<_SocialAccount> get copyWith => __$SocialAccountCopyWithImpl<_SocialAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SocialAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SocialAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.email, email) || other.email == email)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,provider,email,name);

@override
String toString() {
  return 'SocialAccount(id: $id, provider: $provider, email: $email, name: $name)';
}


}

/// @nodoc
abstract mixin class _$SocialAccountCopyWith<$Res> implements $SocialAccountCopyWith<$Res> {
  factory _$SocialAccountCopyWith(_SocialAccount value, $Res Function(_SocialAccount) _then) = __$SocialAccountCopyWithImpl;
@override @useResult
$Res call({
 int id, String? provider, String? email, String? name
});




}
/// @nodoc
class __$SocialAccountCopyWithImpl<$Res>
    implements _$SocialAccountCopyWith<$Res> {
  __$SocialAccountCopyWithImpl(this._self, this._then);

  final _SocialAccount _self;
  final $Res Function(_SocialAccount) _then;

/// Create a copy of SocialAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? provider = freezed,Object? email = freezed,Object? name = freezed,}) {
  return _then(_SocialAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
