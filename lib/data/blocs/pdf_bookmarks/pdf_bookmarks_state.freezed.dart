// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pdf_bookmarks_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PdfBookmarksState {

/// `{ persistKey: [page, page, ...] }` — 1-based page numbers,
/// sorted ascending. Empty list when no bookmarks for that source.
 Map<String, List<int>> get pages;/// Last page the user was reading per source (1-based). Survives
/// app kill so the viewer can resume on next open.
 Map<String, int> get lastReadPage;
/// Create a copy of PdfBookmarksState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PdfBookmarksStateCopyWith<PdfBookmarksState> get copyWith => _$PdfBookmarksStateCopyWithImpl<PdfBookmarksState>(this as PdfBookmarksState, _$identity);

  /// Serializes this PdfBookmarksState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfBookmarksState&&const DeepCollectionEquality().equals(other.pages, pages)&&const DeepCollectionEquality().equals(other.lastReadPage, lastReadPage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(pages),const DeepCollectionEquality().hash(lastReadPage));

@override
String toString() {
  return 'PdfBookmarksState(pages: $pages, lastReadPage: $lastReadPage)';
}


}

/// @nodoc
abstract mixin class $PdfBookmarksStateCopyWith<$Res>  {
  factory $PdfBookmarksStateCopyWith(PdfBookmarksState value, $Res Function(PdfBookmarksState) _then) = _$PdfBookmarksStateCopyWithImpl;
@useResult
$Res call({
 Map<String, List<int>> pages, Map<String, int> lastReadPage
});




}
/// @nodoc
class _$PdfBookmarksStateCopyWithImpl<$Res>
    implements $PdfBookmarksStateCopyWith<$Res> {
  _$PdfBookmarksStateCopyWithImpl(this._self, this._then);

  final PdfBookmarksState _self;
  final $Res Function(PdfBookmarksState) _then;

/// Create a copy of PdfBookmarksState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pages = null,Object? lastReadPage = null,}) {
  return _then(_self.copyWith(
pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as Map<String, List<int>>,lastReadPage: null == lastReadPage ? _self.lastReadPage : lastReadPage // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [PdfBookmarksState].
extension PdfBookmarksStatePatterns on PdfBookmarksState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PdfBookmarksState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PdfBookmarksState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PdfBookmarksState value)  $default,){
final _that = this;
switch (_that) {
case _PdfBookmarksState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PdfBookmarksState value)?  $default,){
final _that = this;
switch (_that) {
case _PdfBookmarksState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, List<int>> pages,  Map<String, int> lastReadPage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PdfBookmarksState() when $default != null:
return $default(_that.pages,_that.lastReadPage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, List<int>> pages,  Map<String, int> lastReadPage)  $default,) {final _that = this;
switch (_that) {
case _PdfBookmarksState():
return $default(_that.pages,_that.lastReadPage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, List<int>> pages,  Map<String, int> lastReadPage)?  $default,) {final _that = this;
switch (_that) {
case _PdfBookmarksState() when $default != null:
return $default(_that.pages,_that.lastReadPage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PdfBookmarksState implements PdfBookmarksState {
  const _PdfBookmarksState({final  Map<String, List<int>> pages = const <String, List<int>>{}, final  Map<String, int> lastReadPage = const <String, int>{}}): _pages = pages,_lastReadPage = lastReadPage;
  factory _PdfBookmarksState.fromJson(Map<String, dynamic> json) => _$PdfBookmarksStateFromJson(json);

/// `{ persistKey: [page, page, ...] }` — 1-based page numbers,
/// sorted ascending. Empty list when no bookmarks for that source.
 final  Map<String, List<int>> _pages;
/// `{ persistKey: [page, page, ...] }` — 1-based page numbers,
/// sorted ascending. Empty list when no bookmarks for that source.
@override@JsonKey() Map<String, List<int>> get pages {
  if (_pages is EqualUnmodifiableMapView) return _pages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_pages);
}

/// Last page the user was reading per source (1-based). Survives
/// app kill so the viewer can resume on next open.
 final  Map<String, int> _lastReadPage;
/// Last page the user was reading per source (1-based). Survives
/// app kill so the viewer can resume on next open.
@override@JsonKey() Map<String, int> get lastReadPage {
  if (_lastReadPage is EqualUnmodifiableMapView) return _lastReadPage;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_lastReadPage);
}


/// Create a copy of PdfBookmarksState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PdfBookmarksStateCopyWith<_PdfBookmarksState> get copyWith => __$PdfBookmarksStateCopyWithImpl<_PdfBookmarksState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PdfBookmarksStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PdfBookmarksState&&const DeepCollectionEquality().equals(other._pages, _pages)&&const DeepCollectionEquality().equals(other._lastReadPage, _lastReadPage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_pages),const DeepCollectionEquality().hash(_lastReadPage));

@override
String toString() {
  return 'PdfBookmarksState(pages: $pages, lastReadPage: $lastReadPage)';
}


}

/// @nodoc
abstract mixin class _$PdfBookmarksStateCopyWith<$Res> implements $PdfBookmarksStateCopyWith<$Res> {
  factory _$PdfBookmarksStateCopyWith(_PdfBookmarksState value, $Res Function(_PdfBookmarksState) _then) = __$PdfBookmarksStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, List<int>> pages, Map<String, int> lastReadPage
});




}
/// @nodoc
class __$PdfBookmarksStateCopyWithImpl<$Res>
    implements _$PdfBookmarksStateCopyWith<$Res> {
  __$PdfBookmarksStateCopyWithImpl(this._self, this._then);

  final _PdfBookmarksState _self;
  final $Res Function(_PdfBookmarksState) _then;

/// Create a copy of PdfBookmarksState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pages = null,Object? lastReadPage = null,}) {
  return _then(_PdfBookmarksState(
pages: null == pages ? _self._pages : pages // ignore: cast_nullable_to_non_nullable
as Map<String, List<int>>,lastReadPage: null == lastReadPage ? _self._lastReadPage : lastReadPage // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

// dart format on
