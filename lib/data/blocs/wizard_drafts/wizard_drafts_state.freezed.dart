// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wizard_drafts_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WizardDraftsState {

/// `{ draftKey: { fieldId: value } }`. Values must be JSON-encodable
/// (Hydrated serializes via `jsonEncode`).
 Map<String, Map<String, dynamic>> get drafts;/// `{ draftKey: currentStepIndex }` — restored on next mount.
 Map<String, int> get steps;
/// Create a copy of WizardDraftsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WizardDraftsStateCopyWith<WizardDraftsState> get copyWith => _$WizardDraftsStateCopyWithImpl<WizardDraftsState>(this as WizardDraftsState, _$identity);

  /// Serializes this WizardDraftsState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WizardDraftsState&&const DeepCollectionEquality().equals(other.drafts, drafts)&&const DeepCollectionEquality().equals(other.steps, steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(drafts),const DeepCollectionEquality().hash(steps));

@override
String toString() {
  return 'WizardDraftsState(drafts: $drafts, steps: $steps)';
}


}

/// @nodoc
abstract mixin class $WizardDraftsStateCopyWith<$Res>  {
  factory $WizardDraftsStateCopyWith(WizardDraftsState value, $Res Function(WizardDraftsState) _then) = _$WizardDraftsStateCopyWithImpl;
@useResult
$Res call({
 Map<String, Map<String, dynamic>> drafts, Map<String, int> steps
});




}
/// @nodoc
class _$WizardDraftsStateCopyWithImpl<$Res>
    implements $WizardDraftsStateCopyWith<$Res> {
  _$WizardDraftsStateCopyWithImpl(this._self, this._then);

  final WizardDraftsState _self;
  final $Res Function(WizardDraftsState) _then;

/// Create a copy of WizardDraftsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? drafts = null,Object? steps = null,}) {
  return _then(_self.copyWith(
drafts: null == drafts ? _self.drafts : drafts // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, dynamic>>,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [WizardDraftsState].
extension WizardDraftsStatePatterns on WizardDraftsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WizardDraftsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WizardDraftsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WizardDraftsState value)  $default,){
final _that = this;
switch (_that) {
case _WizardDraftsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WizardDraftsState value)?  $default,){
final _that = this;
switch (_that) {
case _WizardDraftsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, Map<String, dynamic>> drafts,  Map<String, int> steps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WizardDraftsState() when $default != null:
return $default(_that.drafts,_that.steps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, Map<String, dynamic>> drafts,  Map<String, int> steps)  $default,) {final _that = this;
switch (_that) {
case _WizardDraftsState():
return $default(_that.drafts,_that.steps);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, Map<String, dynamic>> drafts,  Map<String, int> steps)?  $default,) {final _that = this;
switch (_that) {
case _WizardDraftsState() when $default != null:
return $default(_that.drafts,_that.steps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WizardDraftsState implements WizardDraftsState {
  const _WizardDraftsState({final  Map<String, Map<String, dynamic>> drafts = const <String, Map<String, dynamic>>{}, final  Map<String, int> steps = const <String, int>{}}): _drafts = drafts,_steps = steps;
  factory _WizardDraftsState.fromJson(Map<String, dynamic> json) => _$WizardDraftsStateFromJson(json);

/// `{ draftKey: { fieldId: value } }`. Values must be JSON-encodable
/// (Hydrated serializes via `jsonEncode`).
 final  Map<String, Map<String, dynamic>> _drafts;
/// `{ draftKey: { fieldId: value } }`. Values must be JSON-encodable
/// (Hydrated serializes via `jsonEncode`).
@override@JsonKey() Map<String, Map<String, dynamic>> get drafts {
  if (_drafts is EqualUnmodifiableMapView) return _drafts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_drafts);
}

/// `{ draftKey: currentStepIndex }` — restored on next mount.
 final  Map<String, int> _steps;
/// `{ draftKey: currentStepIndex }` — restored on next mount.
@override@JsonKey() Map<String, int> get steps {
  if (_steps is EqualUnmodifiableMapView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_steps);
}


/// Create a copy of WizardDraftsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WizardDraftsStateCopyWith<_WizardDraftsState> get copyWith => __$WizardDraftsStateCopyWithImpl<_WizardDraftsState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WizardDraftsStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WizardDraftsState&&const DeepCollectionEquality().equals(other._drafts, _drafts)&&const DeepCollectionEquality().equals(other._steps, _steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_drafts),const DeepCollectionEquality().hash(_steps));

@override
String toString() {
  return 'WizardDraftsState(drafts: $drafts, steps: $steps)';
}


}

/// @nodoc
abstract mixin class _$WizardDraftsStateCopyWith<$Res> implements $WizardDraftsStateCopyWith<$Res> {
  factory _$WizardDraftsStateCopyWith(_WizardDraftsState value, $Res Function(_WizardDraftsState) _then) = __$WizardDraftsStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, Map<String, dynamic>> drafts, Map<String, int> steps
});




}
/// @nodoc
class __$WizardDraftsStateCopyWithImpl<$Res>
    implements _$WizardDraftsStateCopyWith<$Res> {
  __$WizardDraftsStateCopyWithImpl(this._self, this._then);

  final _WizardDraftsState _self;
  final $Res Function(_WizardDraftsState) _then;

/// Create a copy of WizardDraftsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? drafts = null,Object? steps = null,}) {
  return _then(_WizardDraftsState(
drafts: null == drafts ? _self._drafts : drafts // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, dynamic>>,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

// dart format on
