// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthSession {

/// The bearer token. Send as `Authorization: Bearer <token>`.
///
/// NULL on a registration that owes an OTP — see the class doc.
 String? get token;/// The signed-in principal.
 TerracottaUser? get user;/// Server-side id of this token, so a session can be revoked by id
/// through `DELETE /api/devices/{deviceId}`.
 int? get tokenId;/// Whether the identifier has completed OTP verification.
///
/// ABSENT on the OTP-sent shape, where the absence of [token] is
/// what says so.
 bool? get isVerified;/// How long the code just sent is good for. Present on both the
/// unverified `login` and the OTP-sent `register`; null when
/// nothing was sent.
 int? get otpExpiresInMinutes;/// THE CODE ITSELF, when the server is feeling generous.
///
/// Dev and staging hand it straight back rather than only sending
/// it — `"otp": "123456"` on a live registration, 2026-09-17 — so
/// a tester on a number that receives nothing can still get in.
/// Production does not, and nothing may depend on it: read it
/// through `DevOtp.show`, which simply says nothing when it is
/// absent.
 String? get otp;/// True for front-desk staff, not customers.
 bool? get isScanner;
/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthSessionCopyWith<AuthSession> get copyWith => _$AuthSessionCopyWithImpl<AuthSession>(this as AuthSession, _$identity);

  /// Serializes this AuthSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthSession&&(identical(other.token, token) || other.token == token)&&(identical(other.user, user) || other.user == user)&&(identical(other.tokenId, tokenId) || other.tokenId == tokenId)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.otpExpiresInMinutes, otpExpiresInMinutes) || other.otpExpiresInMinutes == otpExpiresInMinutes)&&(identical(other.otp, otp) || other.otp == otp)&&(identical(other.isScanner, isScanner) || other.isScanner == isScanner));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,user,tokenId,isVerified,otpExpiresInMinutes,otp,isScanner);

@override
String toString() {
  return 'AuthSession(token: $token, user: $user, tokenId: $tokenId, isVerified: $isVerified, otpExpiresInMinutes: $otpExpiresInMinutes, otp: $otp, isScanner: $isScanner)';
}


}

/// @nodoc
abstract mixin class $AuthSessionCopyWith<$Res>  {
  factory $AuthSessionCopyWith(AuthSession value, $Res Function(AuthSession) _then) = _$AuthSessionCopyWithImpl;
@useResult
$Res call({
 String? token, TerracottaUser? user, int? tokenId, bool? isVerified, int? otpExpiresInMinutes, String? otp, bool? isScanner
});


$TerracottaUserCopyWith<$Res>? get user;

}
/// @nodoc
class _$AuthSessionCopyWithImpl<$Res>
    implements $AuthSessionCopyWith<$Res> {
  _$AuthSessionCopyWithImpl(this._self, this._then);

  final AuthSession _self;
  final $Res Function(AuthSession) _then;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = freezed,Object? user = freezed,Object? tokenId = freezed,Object? isVerified = freezed,Object? otpExpiresInMinutes = freezed,Object? otp = freezed,Object? isScanner = freezed,}) {
  return _then(_self.copyWith(
token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as TerracottaUser?,tokenId: freezed == tokenId ? _self.tokenId : tokenId // ignore: cast_nullable_to_non_nullable
as int?,isVerified: freezed == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool?,otpExpiresInMinutes: freezed == otpExpiresInMinutes ? _self.otpExpiresInMinutes : otpExpiresInMinutes // ignore: cast_nullable_to_non_nullable
as int?,otp: freezed == otp ? _self.otp : otp // ignore: cast_nullable_to_non_nullable
as String?,isScanner: freezed == isScanner ? _self.isScanner : isScanner // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TerracottaUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $TerracottaUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthSession].
extension AuthSessionPatterns on AuthSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthSession value)  $default,){
final _that = this;
switch (_that) {
case _AuthSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthSession value)?  $default,){
final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? token,  TerracottaUser? user,  int? tokenId,  bool? isVerified,  int? otpExpiresInMinutes,  String? otp,  bool? isScanner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
return $default(_that.token,_that.user,_that.tokenId,_that.isVerified,_that.otpExpiresInMinutes,_that.otp,_that.isScanner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? token,  TerracottaUser? user,  int? tokenId,  bool? isVerified,  int? otpExpiresInMinutes,  String? otp,  bool? isScanner)  $default,) {final _that = this;
switch (_that) {
case _AuthSession():
return $default(_that.token,_that.user,_that.tokenId,_that.isVerified,_that.otpExpiresInMinutes,_that.otp,_that.isScanner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? token,  TerracottaUser? user,  int? tokenId,  bool? isVerified,  int? otpExpiresInMinutes,  String? otp,  bool? isScanner)?  $default,) {final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
return $default(_that.token,_that.user,_that.tokenId,_that.isVerified,_that.otpExpiresInMinutes,_that.otp,_that.isScanner);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthSession extends AuthSession {
  const _AuthSession({this.token, this.user, this.tokenId, this.isVerified, this.otpExpiresInMinutes, this.otp, this.isScanner}): super._();
  factory _AuthSession.fromJson(Map<String, dynamic> json) => _$AuthSessionFromJson(json);

/// The bearer token. Send as `Authorization: Bearer <token>`.
///
/// NULL on a registration that owes an OTP — see the class doc.
@override final  String? token;
/// The signed-in principal.
@override final  TerracottaUser? user;
/// Server-side id of this token, so a session can be revoked by id
/// through `DELETE /api/devices/{deviceId}`.
@override final  int? tokenId;
/// Whether the identifier has completed OTP verification.
///
/// ABSENT on the OTP-sent shape, where the absence of [token] is
/// what says so.
@override final  bool? isVerified;
/// How long the code just sent is good for. Present on both the
/// unverified `login` and the OTP-sent `register`; null when
/// nothing was sent.
@override final  int? otpExpiresInMinutes;
/// THE CODE ITSELF, when the server is feeling generous.
///
/// Dev and staging hand it straight back rather than only sending
/// it — `"otp": "123456"` on a live registration, 2026-09-17 — so
/// a tester on a number that receives nothing can still get in.
/// Production does not, and nothing may depend on it: read it
/// through `DevOtp.show`, which simply says nothing when it is
/// absent.
@override final  String? otp;
/// True for front-desk staff, not customers.
@override final  bool? isScanner;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthSessionCopyWith<_AuthSession> get copyWith => __$AuthSessionCopyWithImpl<_AuthSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthSession&&(identical(other.token, token) || other.token == token)&&(identical(other.user, user) || other.user == user)&&(identical(other.tokenId, tokenId) || other.tokenId == tokenId)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.otpExpiresInMinutes, otpExpiresInMinutes) || other.otpExpiresInMinutes == otpExpiresInMinutes)&&(identical(other.otp, otp) || other.otp == otp)&&(identical(other.isScanner, isScanner) || other.isScanner == isScanner));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,user,tokenId,isVerified,otpExpiresInMinutes,otp,isScanner);

@override
String toString() {
  return 'AuthSession(token: $token, user: $user, tokenId: $tokenId, isVerified: $isVerified, otpExpiresInMinutes: $otpExpiresInMinutes, otp: $otp, isScanner: $isScanner)';
}


}

/// @nodoc
abstract mixin class _$AuthSessionCopyWith<$Res> implements $AuthSessionCopyWith<$Res> {
  factory _$AuthSessionCopyWith(_AuthSession value, $Res Function(_AuthSession) _then) = __$AuthSessionCopyWithImpl;
@override @useResult
$Res call({
 String? token, TerracottaUser? user, int? tokenId, bool? isVerified, int? otpExpiresInMinutes, String? otp, bool? isScanner
});


@override $TerracottaUserCopyWith<$Res>? get user;

}
/// @nodoc
class __$AuthSessionCopyWithImpl<$Res>
    implements _$AuthSessionCopyWith<$Res> {
  __$AuthSessionCopyWithImpl(this._self, this._then);

  final _AuthSession _self;
  final $Res Function(_AuthSession) _then;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = freezed,Object? user = freezed,Object? tokenId = freezed,Object? isVerified = freezed,Object? otpExpiresInMinutes = freezed,Object? otp = freezed,Object? isScanner = freezed,}) {
  return _then(_AuthSession(
token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as TerracottaUser?,tokenId: freezed == tokenId ? _self.tokenId : tokenId // ignore: cast_nullable_to_non_nullable
as int?,isVerified: freezed == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool?,otpExpiresInMinutes: freezed == otpExpiresInMinutes ? _self.otpExpiresInMinutes : otpExpiresInMinutes // ignore: cast_nullable_to_non_nullable
as int?,otp: freezed == otp ? _self.otp : otp // ignore: cast_nullable_to_non_nullable
as String?,isScanner: freezed == isScanner ? _self.isScanner : isScanner // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TerracottaUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $TerracottaUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
