// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'terracotta_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TerracottaUser {

 int get id;/// Display name. Null-safe on purpose: a guest record may not
/// carry one.
 String? get name;/// E.164 phone (`"+962700000000"`). The login identifier on this
/// tenant. Null for a guest.
 String? get phone;/// When the identifier was confirmed by OTP. Null while unverified.
 DateTime? get verifiedAt;/// `1` / `0` on the wire, NOT a bool. Read [isAccountActive].
///
/// DEFAULTED, like the two flags under it. The full user comes
/// back on `login` and `GET /api/user`, but the spec's
/// registration examples carry a LEANER one — id, name, phone,
/// `is_active`, `verified_at`, `created_at` and no more. Declared
/// `required`, a shape missing any of them throws inside
/// `fromJson`, and the caller sees a request that plainly
/// succeeded reported as a parse error. That is exactly what
/// `AuthSession.token` did on 2026-09-17.
///
/// An active account is the overwhelmingly common case and the
/// only one worth assuming; the two flags below default to the
/// answer that grants nothing.
 int get isActive;/// True when this record was created from a device id rather than
/// a registration.
 bool get isGuest;/// App-review account — used to hide flows from the store reviewer.
 bool get isReviewer;/// Platform the account was created on (`"web"`, `"ios"`,
/// `"android"`). Null in the live capture.
 String? get platform;/// UUID that mirrors the `X-Device-Id` header, present on guest
/// records. A STRING, not an int.
 String? get guestId;/// Last activity timestamp. Null in the live capture — prefer the
/// per-device `last_seen_at` on `GET /api/devices`, which is
/// populated.
 DateTime? get lastSeenAt;/// Locale code the account is set to (`"en"`). Drives the language
/// the server renders notification titles/bodies in.
///
/// NULL on an account that has never chosen one — which includes
/// every account the moment it is created. `POST /api/register`
/// answers with `current_lang: null`, and this field being required
/// meant a successful registration threw while parsing its own
/// response: the account existed on the server and the app reported
/// a failure. Verified live 2026-08-29.
 String? get currentLang; DateTime get createdAt;/// Absent on the LEAN user the registration shapes carry — see
/// [isActive].
 DateTime? get updatedAt;/// Store credit as a DECIMAL STRING (`"0.00"`). Never a double.
 String get walletBalance;/// False for an OTP-only or social-only account — gates whether the
/// "change password" row is drawn.
///
/// Defaults to FALSE, which draws nothing. Absent it is either a
/// lean registration user — where no profile is on screen — or an
/// account that has no password, and offering "change password"
/// to somebody who has none is the worse of the two mistakes.
 bool get hasPassword;
/// Create a copy of TerracottaUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TerracottaUserCopyWith<TerracottaUser> get copyWith => _$TerracottaUserCopyWithImpl<TerracottaUser>(this as TerracottaUser, _$identity);

  /// Serializes this TerracottaUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TerracottaUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isGuest, isGuest) || other.isGuest == isGuest)&&(identical(other.isReviewer, isReviewer) || other.isReviewer == isReviewer)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.guestId, guestId) || other.guestId == guestId)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt)&&(identical(other.currentLang, currentLang) || other.currentLang == currentLang)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.walletBalance, walletBalance) || other.walletBalance == walletBalance)&&(identical(other.hasPassword, hasPassword) || other.hasPassword == hasPassword));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,phone,verifiedAt,isActive,isGuest,isReviewer,platform,guestId,lastSeenAt,currentLang,createdAt,updatedAt,walletBalance,hasPassword);

@override
String toString() {
  return 'TerracottaUser(id: $id, name: $name, phone: $phone, verifiedAt: $verifiedAt, isActive: $isActive, isGuest: $isGuest, isReviewer: $isReviewer, platform: $platform, guestId: $guestId, lastSeenAt: $lastSeenAt, currentLang: $currentLang, createdAt: $createdAt, updatedAt: $updatedAt, walletBalance: $walletBalance, hasPassword: $hasPassword)';
}


}

/// @nodoc
abstract mixin class $TerracottaUserCopyWith<$Res>  {
  factory $TerracottaUserCopyWith(TerracottaUser value, $Res Function(TerracottaUser) _then) = _$TerracottaUserCopyWithImpl;
@useResult
$Res call({
 int id, String? name, String? phone, DateTime? verifiedAt, int isActive, bool isGuest, bool isReviewer, String? platform, String? guestId, DateTime? lastSeenAt, String? currentLang, DateTime createdAt, DateTime? updatedAt, String walletBalance, bool hasPassword
});




}
/// @nodoc
class _$TerracottaUserCopyWithImpl<$Res>
    implements $TerracottaUserCopyWith<$Res> {
  _$TerracottaUserCopyWithImpl(this._self, this._then);

  final TerracottaUser _self;
  final $Res Function(TerracottaUser) _then;

/// Create a copy of TerracottaUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? phone = freezed,Object? verifiedAt = freezed,Object? isActive = null,Object? isGuest = null,Object? isReviewer = null,Object? platform = freezed,Object? guestId = freezed,Object? lastSeenAt = freezed,Object? currentLang = freezed,Object? createdAt = null,Object? updatedAt = freezed,Object? walletBalance = null,Object? hasPassword = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as int,isGuest: null == isGuest ? _self.isGuest : isGuest // ignore: cast_nullable_to_non_nullable
as bool,isReviewer: null == isReviewer ? _self.isReviewer : isReviewer // ignore: cast_nullable_to_non_nullable
as bool,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,guestId: freezed == guestId ? _self.guestId : guestId // ignore: cast_nullable_to_non_nullable
as String?,lastSeenAt: freezed == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,currentLang: freezed == currentLang ? _self.currentLang : currentLang // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,walletBalance: null == walletBalance ? _self.walletBalance : walletBalance // ignore: cast_nullable_to_non_nullable
as String,hasPassword: null == hasPassword ? _self.hasPassword : hasPassword // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TerracottaUser].
extension TerracottaUserPatterns on TerracottaUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TerracottaUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TerracottaUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TerracottaUser value)  $default,){
final _that = this;
switch (_that) {
case _TerracottaUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TerracottaUser value)?  $default,){
final _that = this;
switch (_that) {
case _TerracottaUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? name,  String? phone,  DateTime? verifiedAt,  int isActive,  bool isGuest,  bool isReviewer,  String? platform,  String? guestId,  DateTime? lastSeenAt,  String? currentLang,  DateTime createdAt,  DateTime? updatedAt,  String walletBalance,  bool hasPassword)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TerracottaUser() when $default != null:
return $default(_that.id,_that.name,_that.phone,_that.verifiedAt,_that.isActive,_that.isGuest,_that.isReviewer,_that.platform,_that.guestId,_that.lastSeenAt,_that.currentLang,_that.createdAt,_that.updatedAt,_that.walletBalance,_that.hasPassword);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? name,  String? phone,  DateTime? verifiedAt,  int isActive,  bool isGuest,  bool isReviewer,  String? platform,  String? guestId,  DateTime? lastSeenAt,  String? currentLang,  DateTime createdAt,  DateTime? updatedAt,  String walletBalance,  bool hasPassword)  $default,) {final _that = this;
switch (_that) {
case _TerracottaUser():
return $default(_that.id,_that.name,_that.phone,_that.verifiedAt,_that.isActive,_that.isGuest,_that.isReviewer,_that.platform,_that.guestId,_that.lastSeenAt,_that.currentLang,_that.createdAt,_that.updatedAt,_that.walletBalance,_that.hasPassword);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? name,  String? phone,  DateTime? verifiedAt,  int isActive,  bool isGuest,  bool isReviewer,  String? platform,  String? guestId,  DateTime? lastSeenAt,  String? currentLang,  DateTime createdAt,  DateTime? updatedAt,  String walletBalance,  bool hasPassword)?  $default,) {final _that = this;
switch (_that) {
case _TerracottaUser() when $default != null:
return $default(_that.id,_that.name,_that.phone,_that.verifiedAt,_that.isActive,_that.isGuest,_that.isReviewer,_that.platform,_that.guestId,_that.lastSeenAt,_that.currentLang,_that.createdAt,_that.updatedAt,_that.walletBalance,_that.hasPassword);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TerracottaUser extends TerracottaUser {
  const _TerracottaUser({required this.id, this.name, this.phone, this.verifiedAt, this.isActive = 1, this.isGuest = false, this.isReviewer = false, this.platform, this.guestId, this.lastSeenAt, this.currentLang, required this.createdAt, this.updatedAt, this.walletBalance = '0.00', this.hasPassword = false}): super._();
  factory _TerracottaUser.fromJson(Map<String, dynamic> json) => _$TerracottaUserFromJson(json);

@override final  int id;
/// Display name. Null-safe on purpose: a guest record may not
/// carry one.
@override final  String? name;
/// E.164 phone (`"+962700000000"`). The login identifier on this
/// tenant. Null for a guest.
@override final  String? phone;
/// When the identifier was confirmed by OTP. Null while unverified.
@override final  DateTime? verifiedAt;
/// `1` / `0` on the wire, NOT a bool. Read [isAccountActive].
///
/// DEFAULTED, like the two flags under it. The full user comes
/// back on `login` and `GET /api/user`, but the spec's
/// registration examples carry a LEANER one — id, name, phone,
/// `is_active`, `verified_at`, `created_at` and no more. Declared
/// `required`, a shape missing any of them throws inside
/// `fromJson`, and the caller sees a request that plainly
/// succeeded reported as a parse error. That is exactly what
/// `AuthSession.token` did on 2026-09-17.
///
/// An active account is the overwhelmingly common case and the
/// only one worth assuming; the two flags below default to the
/// answer that grants nothing.
@override@JsonKey() final  int isActive;
/// True when this record was created from a device id rather than
/// a registration.
@override@JsonKey() final  bool isGuest;
/// App-review account — used to hide flows from the store reviewer.
@override@JsonKey() final  bool isReviewer;
/// Platform the account was created on (`"web"`, `"ios"`,
/// `"android"`). Null in the live capture.
@override final  String? platform;
/// UUID that mirrors the `X-Device-Id` header, present on guest
/// records. A STRING, not an int.
@override final  String? guestId;
/// Last activity timestamp. Null in the live capture — prefer the
/// per-device `last_seen_at` on `GET /api/devices`, which is
/// populated.
@override final  DateTime? lastSeenAt;
/// Locale code the account is set to (`"en"`). Drives the language
/// the server renders notification titles/bodies in.
///
/// NULL on an account that has never chosen one — which includes
/// every account the moment it is created. `POST /api/register`
/// answers with `current_lang: null`, and this field being required
/// meant a successful registration threw while parsing its own
/// response: the account existed on the server and the app reported
/// a failure. Verified live 2026-08-29.
@override final  String? currentLang;
@override final  DateTime createdAt;
/// Absent on the LEAN user the registration shapes carry — see
/// [isActive].
@override final  DateTime? updatedAt;
/// Store credit as a DECIMAL STRING (`"0.00"`). Never a double.
@override@JsonKey() final  String walletBalance;
/// False for an OTP-only or social-only account — gates whether the
/// "change password" row is drawn.
///
/// Defaults to FALSE, which draws nothing. Absent it is either a
/// lean registration user — where no profile is on screen — or an
/// account that has no password, and offering "change password"
/// to somebody who has none is the worse of the two mistakes.
@override@JsonKey() final  bool hasPassword;

/// Create a copy of TerracottaUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TerracottaUserCopyWith<_TerracottaUser> get copyWith => __$TerracottaUserCopyWithImpl<_TerracottaUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TerracottaUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TerracottaUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isGuest, isGuest) || other.isGuest == isGuest)&&(identical(other.isReviewer, isReviewer) || other.isReviewer == isReviewer)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.guestId, guestId) || other.guestId == guestId)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt)&&(identical(other.currentLang, currentLang) || other.currentLang == currentLang)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.walletBalance, walletBalance) || other.walletBalance == walletBalance)&&(identical(other.hasPassword, hasPassword) || other.hasPassword == hasPassword));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,phone,verifiedAt,isActive,isGuest,isReviewer,platform,guestId,lastSeenAt,currentLang,createdAt,updatedAt,walletBalance,hasPassword);

@override
String toString() {
  return 'TerracottaUser(id: $id, name: $name, phone: $phone, verifiedAt: $verifiedAt, isActive: $isActive, isGuest: $isGuest, isReviewer: $isReviewer, platform: $platform, guestId: $guestId, lastSeenAt: $lastSeenAt, currentLang: $currentLang, createdAt: $createdAt, updatedAt: $updatedAt, walletBalance: $walletBalance, hasPassword: $hasPassword)';
}


}

/// @nodoc
abstract mixin class _$TerracottaUserCopyWith<$Res> implements $TerracottaUserCopyWith<$Res> {
  factory _$TerracottaUserCopyWith(_TerracottaUser value, $Res Function(_TerracottaUser) _then) = __$TerracottaUserCopyWithImpl;
@override @useResult
$Res call({
 int id, String? name, String? phone, DateTime? verifiedAt, int isActive, bool isGuest, bool isReviewer, String? platform, String? guestId, DateTime? lastSeenAt, String? currentLang, DateTime createdAt, DateTime? updatedAt, String walletBalance, bool hasPassword
});




}
/// @nodoc
class __$TerracottaUserCopyWithImpl<$Res>
    implements _$TerracottaUserCopyWith<$Res> {
  __$TerracottaUserCopyWithImpl(this._self, this._then);

  final _TerracottaUser _self;
  final $Res Function(_TerracottaUser) _then;

/// Create a copy of TerracottaUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? phone = freezed,Object? verifiedAt = freezed,Object? isActive = null,Object? isGuest = null,Object? isReviewer = null,Object? platform = freezed,Object? guestId = freezed,Object? lastSeenAt = freezed,Object? currentLang = freezed,Object? createdAt = null,Object? updatedAt = freezed,Object? walletBalance = null,Object? hasPassword = null,}) {
  return _then(_TerracottaUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as int,isGuest: null == isGuest ? _self.isGuest : isGuest // ignore: cast_nullable_to_non_nullable
as bool,isReviewer: null == isReviewer ? _self.isReviewer : isReviewer // ignore: cast_nullable_to_non_nullable
as bool,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,guestId: freezed == guestId ? _self.guestId : guestId // ignore: cast_nullable_to_non_nullable
as String?,lastSeenAt: freezed == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,currentLang: freezed == currentLang ? _self.currentLang : currentLang // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,walletBalance: null == walletBalance ? _self.walletBalance : walletBalance // ignore: cast_nullable_to_non_nullable
as String,hasPassword: null == hasPassword ? _self.hasPassword : hasPassword // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
