// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'faq_history_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FaqHistoryState {

/// Recently-viewed entry ids, most-recent first.
 List<String> get recent;/// `entryId → 'helpful' | 'notHelpful'`. Lets the UI show a
/// "you thought this was helpful" indicator on return visits.
 Map<String, String> get feedback;
/// Create a copy of FaqHistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FaqHistoryStateCopyWith<FaqHistoryState> get copyWith => _$FaqHistoryStateCopyWithImpl<FaqHistoryState>(this as FaqHistoryState, _$identity);

  /// Serializes this FaqHistoryState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FaqHistoryState&&const DeepCollectionEquality().equals(other.recent, recent)&&const DeepCollectionEquality().equals(other.feedback, feedback));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(recent),const DeepCollectionEquality().hash(feedback));

@override
String toString() {
  return 'FaqHistoryState(recent: $recent, feedback: $feedback)';
}


}

/// @nodoc
abstract mixin class $FaqHistoryStateCopyWith<$Res>  {
  factory $FaqHistoryStateCopyWith(FaqHistoryState value, $Res Function(FaqHistoryState) _then) = _$FaqHistoryStateCopyWithImpl;
@useResult
$Res call({
 List<String> recent, Map<String, String> feedback
});




}
/// @nodoc
class _$FaqHistoryStateCopyWithImpl<$Res>
    implements $FaqHistoryStateCopyWith<$Res> {
  _$FaqHistoryStateCopyWithImpl(this._self, this._then);

  final FaqHistoryState _self;
  final $Res Function(FaqHistoryState) _then;

/// Create a copy of FaqHistoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? recent = null,Object? feedback = null,}) {
  return _then(_self.copyWith(
recent: null == recent ? _self.recent : recent // ignore: cast_nullable_to_non_nullable
as List<String>,feedback: null == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [FaqHistoryState].
extension FaqHistoryStatePatterns on FaqHistoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FaqHistoryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FaqHistoryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FaqHistoryState value)  $default,){
final _that = this;
switch (_that) {
case _FaqHistoryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FaqHistoryState value)?  $default,){
final _that = this;
switch (_that) {
case _FaqHistoryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> recent,  Map<String, String> feedback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FaqHistoryState() when $default != null:
return $default(_that.recent,_that.feedback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> recent,  Map<String, String> feedback)  $default,) {final _that = this;
switch (_that) {
case _FaqHistoryState():
return $default(_that.recent,_that.feedback);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> recent,  Map<String, String> feedback)?  $default,) {final _that = this;
switch (_that) {
case _FaqHistoryState() when $default != null:
return $default(_that.recent,_that.feedback);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FaqHistoryState implements FaqHistoryState {
  const _FaqHistoryState({final  List<String> recent = const <String>[], final  Map<String, String> feedback = const <String, String>{}}): _recent = recent,_feedback = feedback;
  factory _FaqHistoryState.fromJson(Map<String, dynamic> json) => _$FaqHistoryStateFromJson(json);

/// Recently-viewed entry ids, most-recent first.
 final  List<String> _recent;
/// Recently-viewed entry ids, most-recent first.
@override@JsonKey() List<String> get recent {
  if (_recent is EqualUnmodifiableListView) return _recent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recent);
}

/// `entryId → 'helpful' | 'notHelpful'`. Lets the UI show a
/// "you thought this was helpful" indicator on return visits.
 final  Map<String, String> _feedback;
/// `entryId → 'helpful' | 'notHelpful'`. Lets the UI show a
/// "you thought this was helpful" indicator on return visits.
@override@JsonKey() Map<String, String> get feedback {
  if (_feedback is EqualUnmodifiableMapView) return _feedback;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_feedback);
}


/// Create a copy of FaqHistoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FaqHistoryStateCopyWith<_FaqHistoryState> get copyWith => __$FaqHistoryStateCopyWithImpl<_FaqHistoryState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FaqHistoryStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FaqHistoryState&&const DeepCollectionEquality().equals(other._recent, _recent)&&const DeepCollectionEquality().equals(other._feedback, _feedback));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_recent),const DeepCollectionEquality().hash(_feedback));

@override
String toString() {
  return 'FaqHistoryState(recent: $recent, feedback: $feedback)';
}


}

/// @nodoc
abstract mixin class _$FaqHistoryStateCopyWith<$Res> implements $FaqHistoryStateCopyWith<$Res> {
  factory _$FaqHistoryStateCopyWith(_FaqHistoryState value, $Res Function(_FaqHistoryState) _then) = __$FaqHistoryStateCopyWithImpl;
@override @useResult
$Res call({
 List<String> recent, Map<String, String> feedback
});




}
/// @nodoc
class __$FaqHistoryStateCopyWithImpl<$Res>
    implements _$FaqHistoryStateCopyWith<$Res> {
  __$FaqHistoryStateCopyWithImpl(this._self, this._then);

  final _FaqHistoryState _self;
  final $Res Function(_FaqHistoryState) _then;

/// Create a copy of FaqHistoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? recent = null,Object? feedback = null,}) {
  return _then(_FaqHistoryState(
recent: null == recent ? _self._recent : recent // ignore: cast_nullable_to_non_nullable
as List<String>,feedback: null == feedback ? _self._feedback : feedback // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
