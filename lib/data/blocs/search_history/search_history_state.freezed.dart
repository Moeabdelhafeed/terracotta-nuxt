// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_history_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SearchHistoryState {

/// `{ searchId: [query, query, ...] }` — most-recent first.
 Map<String, List<String>> get entries;
/// Create a copy of SearchHistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchHistoryStateCopyWith<SearchHistoryState> get copyWith => _$SearchHistoryStateCopyWithImpl<SearchHistoryState>(this as SearchHistoryState, _$identity);

  /// Serializes this SearchHistoryState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchHistoryState&&const DeepCollectionEquality().equals(other.entries, entries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(entries));

@override
String toString() {
  return 'SearchHistoryState(entries: $entries)';
}


}

/// @nodoc
abstract mixin class $SearchHistoryStateCopyWith<$Res>  {
  factory $SearchHistoryStateCopyWith(SearchHistoryState value, $Res Function(SearchHistoryState) _then) = _$SearchHistoryStateCopyWithImpl;
@useResult
$Res call({
 Map<String, List<String>> entries
});




}
/// @nodoc
class _$SearchHistoryStateCopyWithImpl<$Res>
    implements $SearchHistoryStateCopyWith<$Res> {
  _$SearchHistoryStateCopyWithImpl(this._self, this._then);

  final SearchHistoryState _self;
  final $Res Function(SearchHistoryState) _then;

/// Create a copy of SearchHistoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entries = null,}) {
  return _then(_self.copyWith(
entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchHistoryState].
extension SearchHistoryStatePatterns on SearchHistoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchHistoryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchHistoryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchHistoryState value)  $default,){
final _that = this;
switch (_that) {
case _SearchHistoryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchHistoryState value)?  $default,){
final _that = this;
switch (_that) {
case _SearchHistoryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, List<String>> entries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchHistoryState() when $default != null:
return $default(_that.entries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, List<String>> entries)  $default,) {final _that = this;
switch (_that) {
case _SearchHistoryState():
return $default(_that.entries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, List<String>> entries)?  $default,) {final _that = this;
switch (_that) {
case _SearchHistoryState() when $default != null:
return $default(_that.entries);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchHistoryState implements SearchHistoryState {
  const _SearchHistoryState({final  Map<String, List<String>> entries = const <String, List<String>>{}}): _entries = entries;
  factory _SearchHistoryState.fromJson(Map<String, dynamic> json) => _$SearchHistoryStateFromJson(json);

/// `{ searchId: [query, query, ...] }` — most-recent first.
 final  Map<String, List<String>> _entries;
/// `{ searchId: [query, query, ...] }` — most-recent first.
@override@JsonKey() Map<String, List<String>> get entries {
  if (_entries is EqualUnmodifiableMapView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_entries);
}


/// Create a copy of SearchHistoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchHistoryStateCopyWith<_SearchHistoryState> get copyWith => __$SearchHistoryStateCopyWithImpl<_SearchHistoryState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchHistoryStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchHistoryState&&const DeepCollectionEquality().equals(other._entries, _entries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_entries));

@override
String toString() {
  return 'SearchHistoryState(entries: $entries)';
}


}

/// @nodoc
abstract mixin class _$SearchHistoryStateCopyWith<$Res> implements $SearchHistoryStateCopyWith<$Res> {
  factory _$SearchHistoryStateCopyWith(_SearchHistoryState value, $Res Function(_SearchHistoryState) _then) = __$SearchHistoryStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, List<String>> entries
});




}
/// @nodoc
class __$SearchHistoryStateCopyWithImpl<$Res>
    implements _$SearchHistoryStateCopyWith<$Res> {
  __$SearchHistoryStateCopyWithImpl(this._self, this._then);

  final _SearchHistoryState _self;
  final $Res Function(_SearchHistoryState) _then;

/// Create a copy of SearchHistoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entries = null,}) {
  return _then(_SearchHistoryState(
entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,
  ));
}


}

// dart format on
