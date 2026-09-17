// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'social_account_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SocialAccountList {

 List<SocialAccount> get socialAccounts; List<String> get allowedProviders; int? get maxAccounts; bool? get canLinkMore;
/// Create a copy of SocialAccountList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocialAccountListCopyWith<SocialAccountList> get copyWith => _$SocialAccountListCopyWithImpl<SocialAccountList>(this as SocialAccountList, _$identity);

  /// Serializes this SocialAccountList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocialAccountList&&const DeepCollectionEquality().equals(other.socialAccounts, socialAccounts)&&const DeepCollectionEquality().equals(other.allowedProviders, allowedProviders)&&(identical(other.maxAccounts, maxAccounts) || other.maxAccounts == maxAccounts)&&(identical(other.canLinkMore, canLinkMore) || other.canLinkMore == canLinkMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(socialAccounts),const DeepCollectionEquality().hash(allowedProviders),maxAccounts,canLinkMore);

@override
String toString() {
  return 'SocialAccountList(socialAccounts: $socialAccounts, allowedProviders: $allowedProviders, maxAccounts: $maxAccounts, canLinkMore: $canLinkMore)';
}


}

/// @nodoc
abstract mixin class $SocialAccountListCopyWith<$Res>  {
  factory $SocialAccountListCopyWith(SocialAccountList value, $Res Function(SocialAccountList) _then) = _$SocialAccountListCopyWithImpl;
@useResult
$Res call({
 List<SocialAccount> socialAccounts, List<String> allowedProviders, int? maxAccounts, bool? canLinkMore
});




}
/// @nodoc
class _$SocialAccountListCopyWithImpl<$Res>
    implements $SocialAccountListCopyWith<$Res> {
  _$SocialAccountListCopyWithImpl(this._self, this._then);

  final SocialAccountList _self;
  final $Res Function(SocialAccountList) _then;

/// Create a copy of SocialAccountList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? socialAccounts = null,Object? allowedProviders = null,Object? maxAccounts = freezed,Object? canLinkMore = freezed,}) {
  return _then(_self.copyWith(
socialAccounts: null == socialAccounts ? _self.socialAccounts : socialAccounts // ignore: cast_nullable_to_non_nullable
as List<SocialAccount>,allowedProviders: null == allowedProviders ? _self.allowedProviders : allowedProviders // ignore: cast_nullable_to_non_nullable
as List<String>,maxAccounts: freezed == maxAccounts ? _self.maxAccounts : maxAccounts // ignore: cast_nullable_to_non_nullable
as int?,canLinkMore: freezed == canLinkMore ? _self.canLinkMore : canLinkMore // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [SocialAccountList].
extension SocialAccountListPatterns on SocialAccountList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SocialAccountList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SocialAccountList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SocialAccountList value)  $default,){
final _that = this;
switch (_that) {
case _SocialAccountList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SocialAccountList value)?  $default,){
final _that = this;
switch (_that) {
case _SocialAccountList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SocialAccount> socialAccounts,  List<String> allowedProviders,  int? maxAccounts,  bool? canLinkMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SocialAccountList() when $default != null:
return $default(_that.socialAccounts,_that.allowedProviders,_that.maxAccounts,_that.canLinkMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SocialAccount> socialAccounts,  List<String> allowedProviders,  int? maxAccounts,  bool? canLinkMore)  $default,) {final _that = this;
switch (_that) {
case _SocialAccountList():
return $default(_that.socialAccounts,_that.allowedProviders,_that.maxAccounts,_that.canLinkMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SocialAccount> socialAccounts,  List<String> allowedProviders,  int? maxAccounts,  bool? canLinkMore)?  $default,) {final _that = this;
switch (_that) {
case _SocialAccountList() when $default != null:
return $default(_that.socialAccounts,_that.allowedProviders,_that.maxAccounts,_that.canLinkMore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SocialAccountList extends SocialAccountList {
  const _SocialAccountList({final  List<SocialAccount> socialAccounts = const <SocialAccount>[], final  List<String> allowedProviders = const <String>[], this.maxAccounts, this.canLinkMore}): _socialAccounts = socialAccounts,_allowedProviders = allowedProviders,super._();
  factory _SocialAccountList.fromJson(Map<String, dynamic> json) => _$SocialAccountListFromJson(json);

 final  List<SocialAccount> _socialAccounts;
@override@JsonKey() List<SocialAccount> get socialAccounts {
  if (_socialAccounts is EqualUnmodifiableListView) return _socialAccounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_socialAccounts);
}

 final  List<String> _allowedProviders;
@override@JsonKey() List<String> get allowedProviders {
  if (_allowedProviders is EqualUnmodifiableListView) return _allowedProviders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allowedProviders);
}

@override final  int? maxAccounts;
@override final  bool? canLinkMore;

/// Create a copy of SocialAccountList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SocialAccountListCopyWith<_SocialAccountList> get copyWith => __$SocialAccountListCopyWithImpl<_SocialAccountList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SocialAccountListToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SocialAccountList&&const DeepCollectionEquality().equals(other._socialAccounts, _socialAccounts)&&const DeepCollectionEquality().equals(other._allowedProviders, _allowedProviders)&&(identical(other.maxAccounts, maxAccounts) || other.maxAccounts == maxAccounts)&&(identical(other.canLinkMore, canLinkMore) || other.canLinkMore == canLinkMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_socialAccounts),const DeepCollectionEquality().hash(_allowedProviders),maxAccounts,canLinkMore);

@override
String toString() {
  return 'SocialAccountList(socialAccounts: $socialAccounts, allowedProviders: $allowedProviders, maxAccounts: $maxAccounts, canLinkMore: $canLinkMore)';
}


}

/// @nodoc
abstract mixin class _$SocialAccountListCopyWith<$Res> implements $SocialAccountListCopyWith<$Res> {
  factory _$SocialAccountListCopyWith(_SocialAccountList value, $Res Function(_SocialAccountList) _then) = __$SocialAccountListCopyWithImpl;
@override @useResult
$Res call({
 List<SocialAccount> socialAccounts, List<String> allowedProviders, int? maxAccounts, bool? canLinkMore
});




}
/// @nodoc
class __$SocialAccountListCopyWithImpl<$Res>
    implements _$SocialAccountListCopyWith<$Res> {
  __$SocialAccountListCopyWithImpl(this._self, this._then);

  final _SocialAccountList _self;
  final $Res Function(_SocialAccountList) _then;

/// Create a copy of SocialAccountList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? socialAccounts = null,Object? allowedProviders = null,Object? maxAccounts = freezed,Object? canLinkMore = freezed,}) {
  return _then(_SocialAccountList(
socialAccounts: null == socialAccounts ? _self._socialAccounts : socialAccounts // ignore: cast_nullable_to_non_nullable
as List<SocialAccount>,allowedProviders: null == allowedProviders ? _self._allowedProviders : allowedProviders // ignore: cast_nullable_to_non_nullable
as List<String>,maxAccounts: freezed == maxAccounts ? _self.maxAccounts : maxAccounts // ignore: cast_nullable_to_non_nullable
as int?,canLinkMore: freezed == canLinkMore ? _self.canLinkMore : canLinkMore // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
