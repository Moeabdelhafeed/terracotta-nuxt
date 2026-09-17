// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_inbox.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationInbox {

 int get unreadCount;/// The rows, from a bare list OR from the paginator `per_page`
/// turns them into — see [readPaginatedRows]. Declared as a list
/// alone this threw inside `fromJson` and took `unread_count`, the
/// field the badge is driven from, down with it.
@JsonKey(fromJson: _readNotifications) List<AppNotification> get notifications;
/// Create a copy of NotificationInbox
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationInboxCopyWith<NotificationInbox> get copyWith => _$NotificationInboxCopyWithImpl<NotificationInbox>(this as NotificationInbox, _$identity);

  /// Serializes this NotificationInbox to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationInbox&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&const DeepCollectionEquality().equals(other.notifications, notifications));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,unreadCount,const DeepCollectionEquality().hash(notifications));

@override
String toString() {
  return 'NotificationInbox(unreadCount: $unreadCount, notifications: $notifications)';
}


}

/// @nodoc
abstract mixin class $NotificationInboxCopyWith<$Res>  {
  factory $NotificationInboxCopyWith(NotificationInbox value, $Res Function(NotificationInbox) _then) = _$NotificationInboxCopyWithImpl;
@useResult
$Res call({
 int unreadCount,@JsonKey(fromJson: _readNotifications) List<AppNotification> notifications
});




}
/// @nodoc
class _$NotificationInboxCopyWithImpl<$Res>
    implements $NotificationInboxCopyWith<$Res> {
  _$NotificationInboxCopyWithImpl(this._self, this._then);

  final NotificationInbox _self;
  final $Res Function(NotificationInbox) _then;

/// Create a copy of NotificationInbox
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? unreadCount = null,Object? notifications = null,}) {
  return _then(_self.copyWith(
unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,notifications: null == notifications ? _self.notifications : notifications // ignore: cast_nullable_to_non_nullable
as List<AppNotification>,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationInbox].
extension NotificationInboxPatterns on NotificationInbox {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationInbox value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationInbox() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationInbox value)  $default,){
final _that = this;
switch (_that) {
case _NotificationInbox():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationInbox value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationInbox() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int unreadCount, @JsonKey(fromJson: _readNotifications)  List<AppNotification> notifications)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationInbox() when $default != null:
return $default(_that.unreadCount,_that.notifications);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int unreadCount, @JsonKey(fromJson: _readNotifications)  List<AppNotification> notifications)  $default,) {final _that = this;
switch (_that) {
case _NotificationInbox():
return $default(_that.unreadCount,_that.notifications);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int unreadCount, @JsonKey(fromJson: _readNotifications)  List<AppNotification> notifications)?  $default,) {final _that = this;
switch (_that) {
case _NotificationInbox() when $default != null:
return $default(_that.unreadCount,_that.notifications);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationInbox extends NotificationInbox {
  const _NotificationInbox({this.unreadCount = 0, @JsonKey(fromJson: _readNotifications) final  List<AppNotification> notifications = const <AppNotification>[]}): _notifications = notifications,super._();
  factory _NotificationInbox.fromJson(Map<String, dynamic> json) => _$NotificationInboxFromJson(json);

@override@JsonKey() final  int unreadCount;
/// The rows, from a bare list OR from the paginator `per_page`
/// turns them into — see [readPaginatedRows]. Declared as a list
/// alone this threw inside `fromJson` and took `unread_count`, the
/// field the badge is driven from, down with it.
 final  List<AppNotification> _notifications;
/// The rows, from a bare list OR from the paginator `per_page`
/// turns them into — see [readPaginatedRows]. Declared as a list
/// alone this threw inside `fromJson` and took `unread_count`, the
/// field the badge is driven from, down with it.
@override@JsonKey(fromJson: _readNotifications) List<AppNotification> get notifications {
  if (_notifications is EqualUnmodifiableListView) return _notifications;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notifications);
}


/// Create a copy of NotificationInbox
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationInboxCopyWith<_NotificationInbox> get copyWith => __$NotificationInboxCopyWithImpl<_NotificationInbox>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationInboxToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationInbox&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&const DeepCollectionEquality().equals(other._notifications, _notifications));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,unreadCount,const DeepCollectionEquality().hash(_notifications));

@override
String toString() {
  return 'NotificationInbox(unreadCount: $unreadCount, notifications: $notifications)';
}


}

/// @nodoc
abstract mixin class _$NotificationInboxCopyWith<$Res> implements $NotificationInboxCopyWith<$Res> {
  factory _$NotificationInboxCopyWith(_NotificationInbox value, $Res Function(_NotificationInbox) _then) = __$NotificationInboxCopyWithImpl;
@override @useResult
$Res call({
 int unreadCount,@JsonKey(fromJson: _readNotifications) List<AppNotification> notifications
});




}
/// @nodoc
class __$NotificationInboxCopyWithImpl<$Res>
    implements _$NotificationInboxCopyWith<$Res> {
  __$NotificationInboxCopyWithImpl(this._self, this._then);

  final _NotificationInbox _self;
  final $Res Function(_NotificationInbox) _then;

/// Create a copy of NotificationInbox
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? unreadCount = null,Object? notifications = null,}) {
  return _then(_NotificationInbox(
unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,notifications: null == notifications ? _self._notifications : notifications // ignore: cast_nullable_to_non_nullable
as List<AppNotification>,
  ));
}


}

// dart format on
