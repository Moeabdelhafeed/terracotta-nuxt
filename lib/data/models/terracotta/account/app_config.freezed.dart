// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppConfig {

/// Identifier kinds accepted at login (`["phone"]` live). Also the
/// value the login call's mandatory `type` field must carry.
 List<String> get identifiers;/// Whether the register/profile form collects a username.
 bool get hasUsernameField;/// Whether the register/profile form collects an email.
 bool get hasEmailField;/// Whether the register/profile form collects a phone number.
 bool get hasPhoneField;/// Firebase provider ids offered for social login
/// (`["google.com", "apple.com"]`). Empty on the live tenant.
 List<String> get socialProviders;/// How many social accounts one user may link. `0` live.
 int get maxSocialAccounts;/// Master switch for the social login section.
 bool get socialAuthAvailable;/// OTPs are delivered over WhatsApp rather than SMS. Changes the
/// copy on the verification screen, not the flow.
 bool get isOtpWhatsapp;/// More than one device may hold a live session at once. When
/// false, `GET /api/devices` always returns exactly one row.
 bool get multiSession;/// Registered accounts are enabled.
 bool get appUsers;/// Guests may browse and buy without an account (`true` live).
 bool get appGuests;/// WHETHER THE STUDIO IS SELLING GIFT CREDIT AT ALL.
///
/// **Not on the live payload yet** — probed 2026-09-16, `/api/config`
/// carries neither this nor any other gift flag, and `/docs.openapi`
/// has no `allow_gift` in it. Modelled nullable so its ABSENCE is
/// not a switch-off: a build that hid the gift tile the moment the
/// key went missing would take a live feature off every screen the
/// first time the endpoint was redeployed.
///
/// Read it through [allowsGift], which answers true until the
/// server says otherwise.
 bool? get allowGift;/// `"password"` (live) or `"otp"`. Read via [mode].
 String get authMode;/// `"all"`, or a restriction expression. Not a list.
 String get allowedEmailDomains;/// `"all"` live — which is why a non-Saudi `+962…` number logs in.
/// Not a list.
 String get allowedPhoneCountries;/// THE BROADCAST TOPICS this backend publishes to.
///
/// Nine of them live: an `all` / `guests` / `users` base, each on
/// its own and once per language. A device subscribes to the ones
/// that describe it — see `NotificationTopics`.
///
/// **This is the authority, and guessing is worse than useless.**
/// The app used to invent names by convention and suffix them per
/// flavor (`all_dev`); the server publishes no suffix at all, so
/// every subscription went to a topic nobody sends to — and a
/// subscription to a topic that does not exist fails SILENTLY.
///
/// Empty on a server that predates the field, which simply means
/// no broadcasts.
 List<FcmTopic> get fcmTopics;
/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigCopyWith<AppConfig> get copyWith => _$AppConfigCopyWithImpl<AppConfig>(this as AppConfig, _$identity);

  /// Serializes this AppConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfig&&const DeepCollectionEquality().equals(other.identifiers, identifiers)&&(identical(other.hasUsernameField, hasUsernameField) || other.hasUsernameField == hasUsernameField)&&(identical(other.hasEmailField, hasEmailField) || other.hasEmailField == hasEmailField)&&(identical(other.hasPhoneField, hasPhoneField) || other.hasPhoneField == hasPhoneField)&&const DeepCollectionEquality().equals(other.socialProviders, socialProviders)&&(identical(other.maxSocialAccounts, maxSocialAccounts) || other.maxSocialAccounts == maxSocialAccounts)&&(identical(other.socialAuthAvailable, socialAuthAvailable) || other.socialAuthAvailable == socialAuthAvailable)&&(identical(other.isOtpWhatsapp, isOtpWhatsapp) || other.isOtpWhatsapp == isOtpWhatsapp)&&(identical(other.multiSession, multiSession) || other.multiSession == multiSession)&&(identical(other.appUsers, appUsers) || other.appUsers == appUsers)&&(identical(other.appGuests, appGuests) || other.appGuests == appGuests)&&(identical(other.allowGift, allowGift) || other.allowGift == allowGift)&&(identical(other.authMode, authMode) || other.authMode == authMode)&&(identical(other.allowedEmailDomains, allowedEmailDomains) || other.allowedEmailDomains == allowedEmailDomains)&&(identical(other.allowedPhoneCountries, allowedPhoneCountries) || other.allowedPhoneCountries == allowedPhoneCountries)&&const DeepCollectionEquality().equals(other.fcmTopics, fcmTopics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(identifiers),hasUsernameField,hasEmailField,hasPhoneField,const DeepCollectionEquality().hash(socialProviders),maxSocialAccounts,socialAuthAvailable,isOtpWhatsapp,multiSession,appUsers,appGuests,allowGift,authMode,allowedEmailDomains,allowedPhoneCountries,const DeepCollectionEquality().hash(fcmTopics));

@override
String toString() {
  return 'AppConfig(identifiers: $identifiers, hasUsernameField: $hasUsernameField, hasEmailField: $hasEmailField, hasPhoneField: $hasPhoneField, socialProviders: $socialProviders, maxSocialAccounts: $maxSocialAccounts, socialAuthAvailable: $socialAuthAvailable, isOtpWhatsapp: $isOtpWhatsapp, multiSession: $multiSession, appUsers: $appUsers, appGuests: $appGuests, allowGift: $allowGift, authMode: $authMode, allowedEmailDomains: $allowedEmailDomains, allowedPhoneCountries: $allowedPhoneCountries, fcmTopics: $fcmTopics)';
}


}

/// @nodoc
abstract mixin class $AppConfigCopyWith<$Res>  {
  factory $AppConfigCopyWith(AppConfig value, $Res Function(AppConfig) _then) = _$AppConfigCopyWithImpl;
@useResult
$Res call({
 List<String> identifiers, bool hasUsernameField, bool hasEmailField, bool hasPhoneField, List<String> socialProviders, int maxSocialAccounts, bool socialAuthAvailable, bool isOtpWhatsapp, bool multiSession, bool appUsers, bool appGuests, bool? allowGift, String authMode, String allowedEmailDomains, String allowedPhoneCountries, List<FcmTopic> fcmTopics
});




}
/// @nodoc
class _$AppConfigCopyWithImpl<$Res>
    implements $AppConfigCopyWith<$Res> {
  _$AppConfigCopyWithImpl(this._self, this._then);

  final AppConfig _self;
  final $Res Function(AppConfig) _then;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? identifiers = null,Object? hasUsernameField = null,Object? hasEmailField = null,Object? hasPhoneField = null,Object? socialProviders = null,Object? maxSocialAccounts = null,Object? socialAuthAvailable = null,Object? isOtpWhatsapp = null,Object? multiSession = null,Object? appUsers = null,Object? appGuests = null,Object? allowGift = freezed,Object? authMode = null,Object? allowedEmailDomains = null,Object? allowedPhoneCountries = null,Object? fcmTopics = null,}) {
  return _then(_self.copyWith(
identifiers: null == identifiers ? _self.identifiers : identifiers // ignore: cast_nullable_to_non_nullable
as List<String>,hasUsernameField: null == hasUsernameField ? _self.hasUsernameField : hasUsernameField // ignore: cast_nullable_to_non_nullable
as bool,hasEmailField: null == hasEmailField ? _self.hasEmailField : hasEmailField // ignore: cast_nullable_to_non_nullable
as bool,hasPhoneField: null == hasPhoneField ? _self.hasPhoneField : hasPhoneField // ignore: cast_nullable_to_non_nullable
as bool,socialProviders: null == socialProviders ? _self.socialProviders : socialProviders // ignore: cast_nullable_to_non_nullable
as List<String>,maxSocialAccounts: null == maxSocialAccounts ? _self.maxSocialAccounts : maxSocialAccounts // ignore: cast_nullable_to_non_nullable
as int,socialAuthAvailable: null == socialAuthAvailable ? _self.socialAuthAvailable : socialAuthAvailable // ignore: cast_nullable_to_non_nullable
as bool,isOtpWhatsapp: null == isOtpWhatsapp ? _self.isOtpWhatsapp : isOtpWhatsapp // ignore: cast_nullable_to_non_nullable
as bool,multiSession: null == multiSession ? _self.multiSession : multiSession // ignore: cast_nullable_to_non_nullable
as bool,appUsers: null == appUsers ? _self.appUsers : appUsers // ignore: cast_nullable_to_non_nullable
as bool,appGuests: null == appGuests ? _self.appGuests : appGuests // ignore: cast_nullable_to_non_nullable
as bool,allowGift: freezed == allowGift ? _self.allowGift : allowGift // ignore: cast_nullable_to_non_nullable
as bool?,authMode: null == authMode ? _self.authMode : authMode // ignore: cast_nullable_to_non_nullable
as String,allowedEmailDomains: null == allowedEmailDomains ? _self.allowedEmailDomains : allowedEmailDomains // ignore: cast_nullable_to_non_nullable
as String,allowedPhoneCountries: null == allowedPhoneCountries ? _self.allowedPhoneCountries : allowedPhoneCountries // ignore: cast_nullable_to_non_nullable
as String,fcmTopics: null == fcmTopics ? _self.fcmTopics : fcmTopics // ignore: cast_nullable_to_non_nullable
as List<FcmTopic>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfig].
extension AppConfigPatterns on AppConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppConfig value)  $default,){
final _that = this;
switch (_that) {
case _AppConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> identifiers,  bool hasUsernameField,  bool hasEmailField,  bool hasPhoneField,  List<String> socialProviders,  int maxSocialAccounts,  bool socialAuthAvailable,  bool isOtpWhatsapp,  bool multiSession,  bool appUsers,  bool appGuests,  bool? allowGift,  String authMode,  String allowedEmailDomains,  String allowedPhoneCountries,  List<FcmTopic> fcmTopics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that.identifiers,_that.hasUsernameField,_that.hasEmailField,_that.hasPhoneField,_that.socialProviders,_that.maxSocialAccounts,_that.socialAuthAvailable,_that.isOtpWhatsapp,_that.multiSession,_that.appUsers,_that.appGuests,_that.allowGift,_that.authMode,_that.allowedEmailDomains,_that.allowedPhoneCountries,_that.fcmTopics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> identifiers,  bool hasUsernameField,  bool hasEmailField,  bool hasPhoneField,  List<String> socialProviders,  int maxSocialAccounts,  bool socialAuthAvailable,  bool isOtpWhatsapp,  bool multiSession,  bool appUsers,  bool appGuests,  bool? allowGift,  String authMode,  String allowedEmailDomains,  String allowedPhoneCountries,  List<FcmTopic> fcmTopics)  $default,) {final _that = this;
switch (_that) {
case _AppConfig():
return $default(_that.identifiers,_that.hasUsernameField,_that.hasEmailField,_that.hasPhoneField,_that.socialProviders,_that.maxSocialAccounts,_that.socialAuthAvailable,_that.isOtpWhatsapp,_that.multiSession,_that.appUsers,_that.appGuests,_that.allowGift,_that.authMode,_that.allowedEmailDomains,_that.allowedPhoneCountries,_that.fcmTopics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> identifiers,  bool hasUsernameField,  bool hasEmailField,  bool hasPhoneField,  List<String> socialProviders,  int maxSocialAccounts,  bool socialAuthAvailable,  bool isOtpWhatsapp,  bool multiSession,  bool appUsers,  bool appGuests,  bool? allowGift,  String authMode,  String allowedEmailDomains,  String allowedPhoneCountries,  List<FcmTopic> fcmTopics)?  $default,) {final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that.identifiers,_that.hasUsernameField,_that.hasEmailField,_that.hasPhoneField,_that.socialProviders,_that.maxSocialAccounts,_that.socialAuthAvailable,_that.isOtpWhatsapp,_that.multiSession,_that.appUsers,_that.appGuests,_that.allowGift,_that.authMode,_that.allowedEmailDomains,_that.allowedPhoneCountries,_that.fcmTopics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppConfig extends AppConfig {
  const _AppConfig({required final  List<String> identifiers, required this.hasUsernameField, required this.hasEmailField, required this.hasPhoneField, required final  List<String> socialProviders, required this.maxSocialAccounts, required this.socialAuthAvailable, required this.isOtpWhatsapp, required this.multiSession, required this.appUsers, required this.appGuests, this.allowGift, required this.authMode, required this.allowedEmailDomains, required this.allowedPhoneCountries, final  List<FcmTopic> fcmTopics = const <FcmTopic>[]}): _identifiers = identifiers,_socialProviders = socialProviders,_fcmTopics = fcmTopics,super._();
  factory _AppConfig.fromJson(Map<String, dynamic> json) => _$AppConfigFromJson(json);

/// Identifier kinds accepted at login (`["phone"]` live). Also the
/// value the login call's mandatory `type` field must carry.
 final  List<String> _identifiers;
/// Identifier kinds accepted at login (`["phone"]` live). Also the
/// value the login call's mandatory `type` field must carry.
@override List<String> get identifiers {
  if (_identifiers is EqualUnmodifiableListView) return _identifiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_identifiers);
}

/// Whether the register/profile form collects a username.
@override final  bool hasUsernameField;
/// Whether the register/profile form collects an email.
@override final  bool hasEmailField;
/// Whether the register/profile form collects a phone number.
@override final  bool hasPhoneField;
/// Firebase provider ids offered for social login
/// (`["google.com", "apple.com"]`). Empty on the live tenant.
 final  List<String> _socialProviders;
/// Firebase provider ids offered for social login
/// (`["google.com", "apple.com"]`). Empty on the live tenant.
@override List<String> get socialProviders {
  if (_socialProviders is EqualUnmodifiableListView) return _socialProviders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_socialProviders);
}

/// How many social accounts one user may link. `0` live.
@override final  int maxSocialAccounts;
/// Master switch for the social login section.
@override final  bool socialAuthAvailable;
/// OTPs are delivered over WhatsApp rather than SMS. Changes the
/// copy on the verification screen, not the flow.
@override final  bool isOtpWhatsapp;
/// More than one device may hold a live session at once. When
/// false, `GET /api/devices` always returns exactly one row.
@override final  bool multiSession;
/// Registered accounts are enabled.
@override final  bool appUsers;
/// Guests may browse and buy without an account (`true` live).
@override final  bool appGuests;
/// WHETHER THE STUDIO IS SELLING GIFT CREDIT AT ALL.
///
/// **Not on the live payload yet** — probed 2026-09-16, `/api/config`
/// carries neither this nor any other gift flag, and `/docs.openapi`
/// has no `allow_gift` in it. Modelled nullable so its ABSENCE is
/// not a switch-off: a build that hid the gift tile the moment the
/// key went missing would take a live feature off every screen the
/// first time the endpoint was redeployed.
///
/// Read it through [allowsGift], which answers true until the
/// server says otherwise.
@override final  bool? allowGift;
/// `"password"` (live) or `"otp"`. Read via [mode].
@override final  String authMode;
/// `"all"`, or a restriction expression. Not a list.
@override final  String allowedEmailDomains;
/// `"all"` live — which is why a non-Saudi `+962…` number logs in.
/// Not a list.
@override final  String allowedPhoneCountries;
/// THE BROADCAST TOPICS this backend publishes to.
///
/// Nine of them live: an `all` / `guests` / `users` base, each on
/// its own and once per language. A device subscribes to the ones
/// that describe it — see `NotificationTopics`.
///
/// **This is the authority, and guessing is worse than useless.**
/// The app used to invent names by convention and suffix them per
/// flavor (`all_dev`); the server publishes no suffix at all, so
/// every subscription went to a topic nobody sends to — and a
/// subscription to a topic that does not exist fails SILENTLY.
///
/// Empty on a server that predates the field, which simply means
/// no broadcasts.
 final  List<FcmTopic> _fcmTopics;
/// THE BROADCAST TOPICS this backend publishes to.
///
/// Nine of them live: an `all` / `guests` / `users` base, each on
/// its own and once per language. A device subscribes to the ones
/// that describe it — see `NotificationTopics`.
///
/// **This is the authority, and guessing is worse than useless.**
/// The app used to invent names by convention and suffix them per
/// flavor (`all_dev`); the server publishes no suffix at all, so
/// every subscription went to a topic nobody sends to — and a
/// subscription to a topic that does not exist fails SILENTLY.
///
/// Empty on a server that predates the field, which simply means
/// no broadcasts.
@override@JsonKey() List<FcmTopic> get fcmTopics {
  if (_fcmTopics is EqualUnmodifiableListView) return _fcmTopics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fcmTopics);
}


/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppConfigCopyWith<_AppConfig> get copyWith => __$AppConfigCopyWithImpl<_AppConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppConfig&&const DeepCollectionEquality().equals(other._identifiers, _identifiers)&&(identical(other.hasUsernameField, hasUsernameField) || other.hasUsernameField == hasUsernameField)&&(identical(other.hasEmailField, hasEmailField) || other.hasEmailField == hasEmailField)&&(identical(other.hasPhoneField, hasPhoneField) || other.hasPhoneField == hasPhoneField)&&const DeepCollectionEquality().equals(other._socialProviders, _socialProviders)&&(identical(other.maxSocialAccounts, maxSocialAccounts) || other.maxSocialAccounts == maxSocialAccounts)&&(identical(other.socialAuthAvailable, socialAuthAvailable) || other.socialAuthAvailable == socialAuthAvailable)&&(identical(other.isOtpWhatsapp, isOtpWhatsapp) || other.isOtpWhatsapp == isOtpWhatsapp)&&(identical(other.multiSession, multiSession) || other.multiSession == multiSession)&&(identical(other.appUsers, appUsers) || other.appUsers == appUsers)&&(identical(other.appGuests, appGuests) || other.appGuests == appGuests)&&(identical(other.allowGift, allowGift) || other.allowGift == allowGift)&&(identical(other.authMode, authMode) || other.authMode == authMode)&&(identical(other.allowedEmailDomains, allowedEmailDomains) || other.allowedEmailDomains == allowedEmailDomains)&&(identical(other.allowedPhoneCountries, allowedPhoneCountries) || other.allowedPhoneCountries == allowedPhoneCountries)&&const DeepCollectionEquality().equals(other._fcmTopics, _fcmTopics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_identifiers),hasUsernameField,hasEmailField,hasPhoneField,const DeepCollectionEquality().hash(_socialProviders),maxSocialAccounts,socialAuthAvailable,isOtpWhatsapp,multiSession,appUsers,appGuests,allowGift,authMode,allowedEmailDomains,allowedPhoneCountries,const DeepCollectionEquality().hash(_fcmTopics));

@override
String toString() {
  return 'AppConfig(identifiers: $identifiers, hasUsernameField: $hasUsernameField, hasEmailField: $hasEmailField, hasPhoneField: $hasPhoneField, socialProviders: $socialProviders, maxSocialAccounts: $maxSocialAccounts, socialAuthAvailable: $socialAuthAvailable, isOtpWhatsapp: $isOtpWhatsapp, multiSession: $multiSession, appUsers: $appUsers, appGuests: $appGuests, allowGift: $allowGift, authMode: $authMode, allowedEmailDomains: $allowedEmailDomains, allowedPhoneCountries: $allowedPhoneCountries, fcmTopics: $fcmTopics)';
}


}

/// @nodoc
abstract mixin class _$AppConfigCopyWith<$Res> implements $AppConfigCopyWith<$Res> {
  factory _$AppConfigCopyWith(_AppConfig value, $Res Function(_AppConfig) _then) = __$AppConfigCopyWithImpl;
@override @useResult
$Res call({
 List<String> identifiers, bool hasUsernameField, bool hasEmailField, bool hasPhoneField, List<String> socialProviders, int maxSocialAccounts, bool socialAuthAvailable, bool isOtpWhatsapp, bool multiSession, bool appUsers, bool appGuests, bool? allowGift, String authMode, String allowedEmailDomains, String allowedPhoneCountries, List<FcmTopic> fcmTopics
});




}
/// @nodoc
class __$AppConfigCopyWithImpl<$Res>
    implements _$AppConfigCopyWith<$Res> {
  __$AppConfigCopyWithImpl(this._self, this._then);

  final _AppConfig _self;
  final $Res Function(_AppConfig) _then;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? identifiers = null,Object? hasUsernameField = null,Object? hasEmailField = null,Object? hasPhoneField = null,Object? socialProviders = null,Object? maxSocialAccounts = null,Object? socialAuthAvailable = null,Object? isOtpWhatsapp = null,Object? multiSession = null,Object? appUsers = null,Object? appGuests = null,Object? allowGift = freezed,Object? authMode = null,Object? allowedEmailDomains = null,Object? allowedPhoneCountries = null,Object? fcmTopics = null,}) {
  return _then(_AppConfig(
identifiers: null == identifiers ? _self._identifiers : identifiers // ignore: cast_nullable_to_non_nullable
as List<String>,hasUsernameField: null == hasUsernameField ? _self.hasUsernameField : hasUsernameField // ignore: cast_nullable_to_non_nullable
as bool,hasEmailField: null == hasEmailField ? _self.hasEmailField : hasEmailField // ignore: cast_nullable_to_non_nullable
as bool,hasPhoneField: null == hasPhoneField ? _self.hasPhoneField : hasPhoneField // ignore: cast_nullable_to_non_nullable
as bool,socialProviders: null == socialProviders ? _self._socialProviders : socialProviders // ignore: cast_nullable_to_non_nullable
as List<String>,maxSocialAccounts: null == maxSocialAccounts ? _self.maxSocialAccounts : maxSocialAccounts // ignore: cast_nullable_to_non_nullable
as int,socialAuthAvailable: null == socialAuthAvailable ? _self.socialAuthAvailable : socialAuthAvailable // ignore: cast_nullable_to_non_nullable
as bool,isOtpWhatsapp: null == isOtpWhatsapp ? _self.isOtpWhatsapp : isOtpWhatsapp // ignore: cast_nullable_to_non_nullable
as bool,multiSession: null == multiSession ? _self.multiSession : multiSession // ignore: cast_nullable_to_non_nullable
as bool,appUsers: null == appUsers ? _self.appUsers : appUsers // ignore: cast_nullable_to_non_nullable
as bool,appGuests: null == appGuests ? _self.appGuests : appGuests // ignore: cast_nullable_to_non_nullable
as bool,allowGift: freezed == allowGift ? _self.allowGift : allowGift // ignore: cast_nullable_to_non_nullable
as bool?,authMode: null == authMode ? _self.authMode : authMode // ignore: cast_nullable_to_non_nullable
as String,allowedEmailDomains: null == allowedEmailDomains ? _self.allowedEmailDomains : allowedEmailDomains // ignore: cast_nullable_to_non_nullable
as String,allowedPhoneCountries: null == allowedPhoneCountries ? _self.allowedPhoneCountries : allowedPhoneCountries // ignore: cast_nullable_to_non_nullable
as String,fcmTopics: null == fcmTopics ? _self._fcmTopics : fcmTopics // ignore: cast_nullable_to_non_nullable
as List<FcmTopic>,
  ));
}


}


/// @nodoc
mixin _$FcmTopic {

 String get name; String get base; String? get lang;
/// Create a copy of FcmTopic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FcmTopicCopyWith<FcmTopic> get copyWith => _$FcmTopicCopyWithImpl<FcmTopic>(this as FcmTopic, _$identity);

  /// Serializes this FcmTopic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FcmTopic&&(identical(other.name, name) || other.name == name)&&(identical(other.base, base) || other.base == base)&&(identical(other.lang, lang) || other.lang == lang));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,base,lang);

@override
String toString() {
  return 'FcmTopic(name: $name, base: $base, lang: $lang)';
}


}

/// @nodoc
abstract mixin class $FcmTopicCopyWith<$Res>  {
  factory $FcmTopicCopyWith(FcmTopic value, $Res Function(FcmTopic) _then) = _$FcmTopicCopyWithImpl;
@useResult
$Res call({
 String name, String base, String? lang
});




}
/// @nodoc
class _$FcmTopicCopyWithImpl<$Res>
    implements $FcmTopicCopyWith<$Res> {
  _$FcmTopicCopyWithImpl(this._self, this._then);

  final FcmTopic _self;
  final $Res Function(FcmTopic) _then;

/// Create a copy of FcmTopic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? base = null,Object? lang = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,base: null == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as String,lang: freezed == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FcmTopic].
extension FcmTopicPatterns on FcmTopic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FcmTopic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FcmTopic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FcmTopic value)  $default,){
final _that = this;
switch (_that) {
case _FcmTopic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FcmTopic value)?  $default,){
final _that = this;
switch (_that) {
case _FcmTopic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String base,  String? lang)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FcmTopic() when $default != null:
return $default(_that.name,_that.base,_that.lang);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String base,  String? lang)  $default,) {final _that = this;
switch (_that) {
case _FcmTopic():
return $default(_that.name,_that.base,_that.lang);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String base,  String? lang)?  $default,) {final _that = this;
switch (_that) {
case _FcmTopic() when $default != null:
return $default(_that.name,_that.base,_that.lang);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FcmTopic extends FcmTopic {
  const _FcmTopic({required this.name, required this.base, this.lang}): super._();
  factory _FcmTopic.fromJson(Map<String, dynamic> json) => _$FcmTopicFromJson(json);

@override final  String name;
@override final  String base;
@override final  String? lang;

/// Create a copy of FcmTopic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FcmTopicCopyWith<_FcmTopic> get copyWith => __$FcmTopicCopyWithImpl<_FcmTopic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FcmTopicToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FcmTopic&&(identical(other.name, name) || other.name == name)&&(identical(other.base, base) || other.base == base)&&(identical(other.lang, lang) || other.lang == lang));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,base,lang);

@override
String toString() {
  return 'FcmTopic(name: $name, base: $base, lang: $lang)';
}


}

/// @nodoc
abstract mixin class _$FcmTopicCopyWith<$Res> implements $FcmTopicCopyWith<$Res> {
  factory _$FcmTopicCopyWith(_FcmTopic value, $Res Function(_FcmTopic) _then) = __$FcmTopicCopyWithImpl;
@override @useResult
$Res call({
 String name, String base, String? lang
});




}
/// @nodoc
class __$FcmTopicCopyWithImpl<$Res>
    implements _$FcmTopicCopyWith<$Res> {
  __$FcmTopicCopyWithImpl(this._self, this._then);

  final _FcmTopic _self;
  final $Res Function(_FcmTopic) _then;

/// Create a copy of FcmTopic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? base = null,Object? lang = freezed,}) {
  return _then(_FcmTopic(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,base: null == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as String,lang: freezed == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
