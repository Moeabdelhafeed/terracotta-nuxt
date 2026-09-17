// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent()';
}


}

/// @nodoc
class $AuthEventCopyWith<$Res>  {
$AuthEventCopyWith(AuthEvent _, $Res Function(AuthEvent) __);
}


/// Adds pattern-matching-related methods to [AuthEvent].
extension AuthEventPatterns on AuthEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthBootstrapped value)?  bootstrapped,TResult Function( AuthSignedIn value)?  signedIn,TResult Function( AuthSignedOut value)?  signedOut,TResult Function( AuthPendingTokenSet value)?  pendingTokenSet,TResult Function( AuthPendingTokenCleared value)?  pendingTokenCleared,TResult Function( AuthFcmTokenChanged value)?  fcmTokenChanged,TResult Function( AuthUserUpdated value)?  userUpdated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthBootstrapped() when bootstrapped != null:
return bootstrapped(_that);case AuthSignedIn() when signedIn != null:
return signedIn(_that);case AuthSignedOut() when signedOut != null:
return signedOut(_that);case AuthPendingTokenSet() when pendingTokenSet != null:
return pendingTokenSet(_that);case AuthPendingTokenCleared() when pendingTokenCleared != null:
return pendingTokenCleared(_that);case AuthFcmTokenChanged() when fcmTokenChanged != null:
return fcmTokenChanged(_that);case AuthUserUpdated() when userUpdated != null:
return userUpdated(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthBootstrapped value)  bootstrapped,required TResult Function( AuthSignedIn value)  signedIn,required TResult Function( AuthSignedOut value)  signedOut,required TResult Function( AuthPendingTokenSet value)  pendingTokenSet,required TResult Function( AuthPendingTokenCleared value)  pendingTokenCleared,required TResult Function( AuthFcmTokenChanged value)  fcmTokenChanged,required TResult Function( AuthUserUpdated value)  userUpdated,}){
final _that = this;
switch (_that) {
case AuthBootstrapped():
return bootstrapped(_that);case AuthSignedIn():
return signedIn(_that);case AuthSignedOut():
return signedOut(_that);case AuthPendingTokenSet():
return pendingTokenSet(_that);case AuthPendingTokenCleared():
return pendingTokenCleared(_that);case AuthFcmTokenChanged():
return fcmTokenChanged(_that);case AuthUserUpdated():
return userUpdated(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthBootstrapped value)?  bootstrapped,TResult? Function( AuthSignedIn value)?  signedIn,TResult? Function( AuthSignedOut value)?  signedOut,TResult? Function( AuthPendingTokenSet value)?  pendingTokenSet,TResult? Function( AuthPendingTokenCleared value)?  pendingTokenCleared,TResult? Function( AuthFcmTokenChanged value)?  fcmTokenChanged,TResult? Function( AuthUserUpdated value)?  userUpdated,}){
final _that = this;
switch (_that) {
case AuthBootstrapped() when bootstrapped != null:
return bootstrapped(_that);case AuthSignedIn() when signedIn != null:
return signedIn(_that);case AuthSignedOut() when signedOut != null:
return signedOut(_that);case AuthPendingTokenSet() when pendingTokenSet != null:
return pendingTokenSet(_that);case AuthPendingTokenCleared() when pendingTokenCleared != null:
return pendingTokenCleared(_that);case AuthFcmTokenChanged() when fcmTokenChanged != null:
return fcmTokenChanged(_that);case AuthUserUpdated() when userUpdated != null:
return userUpdated(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  bootstrapped,TResult Function( User user,  String token,  bool isScanner,  bool remember)?  signedIn,TResult Function()?  signedOut,TResult Function( String token)?  pendingTokenSet,TResult Function()?  pendingTokenCleared,TResult Function( String token)?  fcmTokenChanged,TResult Function( User user)?  userUpdated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthBootstrapped() when bootstrapped != null:
return bootstrapped();case AuthSignedIn() when signedIn != null:
return signedIn(_that.user,_that.token,_that.isScanner,_that.remember);case AuthSignedOut() when signedOut != null:
return signedOut();case AuthPendingTokenSet() when pendingTokenSet != null:
return pendingTokenSet(_that.token);case AuthPendingTokenCleared() when pendingTokenCleared != null:
return pendingTokenCleared();case AuthFcmTokenChanged() when fcmTokenChanged != null:
return fcmTokenChanged(_that.token);case AuthUserUpdated() when userUpdated != null:
return userUpdated(_that.user);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  bootstrapped,required TResult Function( User user,  String token,  bool isScanner,  bool remember)  signedIn,required TResult Function()  signedOut,required TResult Function( String token)  pendingTokenSet,required TResult Function()  pendingTokenCleared,required TResult Function( String token)  fcmTokenChanged,required TResult Function( User user)  userUpdated,}) {final _that = this;
switch (_that) {
case AuthBootstrapped():
return bootstrapped();case AuthSignedIn():
return signedIn(_that.user,_that.token,_that.isScanner,_that.remember);case AuthSignedOut():
return signedOut();case AuthPendingTokenSet():
return pendingTokenSet(_that.token);case AuthPendingTokenCleared():
return pendingTokenCleared();case AuthFcmTokenChanged():
return fcmTokenChanged(_that.token);case AuthUserUpdated():
return userUpdated(_that.user);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  bootstrapped,TResult? Function( User user,  String token,  bool isScanner,  bool remember)?  signedIn,TResult? Function()?  signedOut,TResult? Function( String token)?  pendingTokenSet,TResult? Function()?  pendingTokenCleared,TResult? Function( String token)?  fcmTokenChanged,TResult? Function( User user)?  userUpdated,}) {final _that = this;
switch (_that) {
case AuthBootstrapped() when bootstrapped != null:
return bootstrapped();case AuthSignedIn() when signedIn != null:
return signedIn(_that.user,_that.token,_that.isScanner,_that.remember);case AuthSignedOut() when signedOut != null:
return signedOut();case AuthPendingTokenSet() when pendingTokenSet != null:
return pendingTokenSet(_that.token);case AuthPendingTokenCleared() when pendingTokenCleared != null:
return pendingTokenCleared();case AuthFcmTokenChanged() when fcmTokenChanged != null:
return fcmTokenChanged(_that.token);case AuthUserUpdated() when userUpdated != null:
return userUpdated(_that.user);case _:
  return null;

}
}

}

/// @nodoc


class AuthBootstrapped implements AuthEvent {
  const AuthBootstrapped();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthBootstrapped);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.bootstrapped()';
}


}




/// @nodoc


class AuthSignedIn implements AuthEvent {
  const AuthSignedIn({required this.user, required this.token, this.isScanner = false, this.remember = true});
  

 final  User user;
 final  String token;
/// Whether this is a FRONT-DESK account — `is_scanner` on the
/// sign-in response. Persisted with the token; see
/// [AuthAuthenticated.isScanner].
@JsonKey() final  bool isScanner;
/// Whether the session should survive the app being killed.
///
/// True is the ordinary case and what every caller but the
/// sign-in screen sends. FALSE means the reader unticked «أبقني
/// مسجّل الدخول», and the token is then held in MEMORY only —
/// `AuthBloc` does not write it to secure storage at all, rather
/// than writing it and deleting it on the next launch. Somebody
/// who asked the app not to keep their session should not have it
/// written to disk even briefly.
@JsonKey() final  bool remember;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthSignedInCopyWith<AuthSignedIn> get copyWith => _$AuthSignedInCopyWithImpl<AuthSignedIn>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthSignedIn&&(identical(other.user, user) || other.user == user)&&(identical(other.token, token) || other.token == token)&&(identical(other.isScanner, isScanner) || other.isScanner == isScanner)&&(identical(other.remember, remember) || other.remember == remember));
}


@override
int get hashCode => Object.hash(runtimeType,user,token,isScanner,remember);

@override
String toString() {
  return 'AuthEvent.signedIn(user: $user, token: $token, isScanner: $isScanner, remember: $remember)';
}


}

/// @nodoc
abstract mixin class $AuthSignedInCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthSignedInCopyWith(AuthSignedIn value, $Res Function(AuthSignedIn) _then) = _$AuthSignedInCopyWithImpl;
@useResult
$Res call({
 User user, String token, bool isScanner, bool remember
});


$UserCopyWith<$Res> get user;

}
/// @nodoc
class _$AuthSignedInCopyWithImpl<$Res>
    implements $AuthSignedInCopyWith<$Res> {
  _$AuthSignedInCopyWithImpl(this._self, this._then);

  final AuthSignedIn _self;
  final $Res Function(AuthSignedIn) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,Object? token = null,Object? isScanner = null,Object? remember = null,}) {
  return _then(AuthSignedIn(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,isScanner: null == isScanner ? _self.isScanner : isScanner // ignore: cast_nullable_to_non_nullable
as bool,remember: null == remember ? _self.remember : remember // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

/// @nodoc


class AuthSignedOut implements AuthEvent {
  const AuthSignedOut();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthSignedOut);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.signedOut()';
}


}




/// @nodoc


class AuthPendingTokenSet implements AuthEvent {
  const AuthPendingTokenSet(this.token);
  

 final  String token;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthPendingTokenSetCopyWith<AuthPendingTokenSet> get copyWith => _$AuthPendingTokenSetCopyWithImpl<AuthPendingTokenSet>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthPendingTokenSet&&(identical(other.token, token) || other.token == token));
}


@override
int get hashCode => Object.hash(runtimeType,token);

@override
String toString() {
  return 'AuthEvent.pendingTokenSet(token: $token)';
}


}

/// @nodoc
abstract mixin class $AuthPendingTokenSetCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthPendingTokenSetCopyWith(AuthPendingTokenSet value, $Res Function(AuthPendingTokenSet) _then) = _$AuthPendingTokenSetCopyWithImpl;
@useResult
$Res call({
 String token
});




}
/// @nodoc
class _$AuthPendingTokenSetCopyWithImpl<$Res>
    implements $AuthPendingTokenSetCopyWith<$Res> {
  _$AuthPendingTokenSetCopyWithImpl(this._self, this._then);

  final AuthPendingTokenSet _self;
  final $Res Function(AuthPendingTokenSet) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? token = null,}) {
  return _then(AuthPendingTokenSet(
null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AuthPendingTokenCleared implements AuthEvent {
  const AuthPendingTokenCleared();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthPendingTokenCleared);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.pendingTokenCleared()';
}


}




/// @nodoc


class AuthFcmTokenChanged implements AuthEvent {
  const AuthFcmTokenChanged(this.token);
  

 final  String token;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthFcmTokenChangedCopyWith<AuthFcmTokenChanged> get copyWith => _$AuthFcmTokenChangedCopyWithImpl<AuthFcmTokenChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthFcmTokenChanged&&(identical(other.token, token) || other.token == token));
}


@override
int get hashCode => Object.hash(runtimeType,token);

@override
String toString() {
  return 'AuthEvent.fcmTokenChanged(token: $token)';
}


}

/// @nodoc
abstract mixin class $AuthFcmTokenChangedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthFcmTokenChangedCopyWith(AuthFcmTokenChanged value, $Res Function(AuthFcmTokenChanged) _then) = _$AuthFcmTokenChangedCopyWithImpl;
@useResult
$Res call({
 String token
});




}
/// @nodoc
class _$AuthFcmTokenChangedCopyWithImpl<$Res>
    implements $AuthFcmTokenChangedCopyWith<$Res> {
  _$AuthFcmTokenChangedCopyWithImpl(this._self, this._then);

  final AuthFcmTokenChanged _self;
  final $Res Function(AuthFcmTokenChanged) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? token = null,}) {
  return _then(AuthFcmTokenChanged(
null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AuthUserUpdated implements AuthEvent {
  const AuthUserUpdated(this.user);
  

 final  User user;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthUserUpdatedCopyWith<AuthUserUpdated> get copyWith => _$AuthUserUpdatedCopyWithImpl<AuthUserUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUserUpdated&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'AuthEvent.userUpdated(user: $user)';
}


}

/// @nodoc
abstract mixin class $AuthUserUpdatedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthUserUpdatedCopyWith(AuthUserUpdated value, $Res Function(AuthUserUpdated) _then) = _$AuthUserUpdatedCopyWithImpl;
@useResult
$Res call({
 User user
});


$UserCopyWith<$Res> get user;

}
/// @nodoc
class _$AuthUserUpdatedCopyWithImpl<$Res>
    implements $AuthUserUpdatedCopyWith<$Res> {
  _$AuthUserUpdatedCopyWithImpl(this._self, this._then);

  final AuthUserUpdated _self;
  final $Res Function(AuthUserUpdated) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(AuthUserUpdated(
null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,
  ));
}

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
