// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gift_preview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GiftPreview {

/// The share token from the link. The id for every call here.
 String get token;/// Who it was addressed to, as the buyer typed it.
 String get recipientName;/// The buyer's note. Empty when they left it blank.
 String get message;/// Face value as a decimal string. Never parsed.
 String get amount;/// Who it is from, as the buyer typed it.
 String get from; bool get isRedeemed;/// When it was claimed. Null while it still stands.
 DateTime? get redeemedAt;/// Whether a Claim button may be drawn at all — see the class doc.
 bool get isClaimable;/// `terracotta://gift/{token}` — the website's "Open in app"
/// target. The app is already here.
 String? get deepLink;/// Where to install the app. The website's buttons, not ours.
 List<GiftStoreLink> get storeLinks;
/// Create a copy of GiftPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GiftPreviewCopyWith<GiftPreview> get copyWith => _$GiftPreviewCopyWithImpl<GiftPreview>(this as GiftPreview, _$identity);

  /// Serializes this GiftPreview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GiftPreview&&(identical(other.token, token) || other.token == token)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.message, message) || other.message == message)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.from, from) || other.from == from)&&(identical(other.isRedeemed, isRedeemed) || other.isRedeemed == isRedeemed)&&(identical(other.redeemedAt, redeemedAt) || other.redeemedAt == redeemedAt)&&(identical(other.isClaimable, isClaimable) || other.isClaimable == isClaimable)&&(identical(other.deepLink, deepLink) || other.deepLink == deepLink)&&const DeepCollectionEquality().equals(other.storeLinks, storeLinks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,recipientName,message,amount,from,isRedeemed,redeemedAt,isClaimable,deepLink,const DeepCollectionEquality().hash(storeLinks));

@override
String toString() {
  return 'GiftPreview(token: $token, recipientName: $recipientName, message: $message, amount: $amount, from: $from, isRedeemed: $isRedeemed, redeemedAt: $redeemedAt, isClaimable: $isClaimable, deepLink: $deepLink, storeLinks: $storeLinks)';
}


}

/// @nodoc
abstract mixin class $GiftPreviewCopyWith<$Res>  {
  factory $GiftPreviewCopyWith(GiftPreview value, $Res Function(GiftPreview) _then) = _$GiftPreviewCopyWithImpl;
@useResult
$Res call({
 String token, String recipientName, String message, String amount, String from, bool isRedeemed, DateTime? redeemedAt, bool isClaimable, String? deepLink, List<GiftStoreLink> storeLinks
});




}
/// @nodoc
class _$GiftPreviewCopyWithImpl<$Res>
    implements $GiftPreviewCopyWith<$Res> {
  _$GiftPreviewCopyWithImpl(this._self, this._then);

  final GiftPreview _self;
  final $Res Function(GiftPreview) _then;

/// Create a copy of GiftPreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? recipientName = null,Object? message = null,Object? amount = null,Object? from = null,Object? isRedeemed = null,Object? redeemedAt = freezed,Object? isClaimable = null,Object? deepLink = freezed,Object? storeLinks = null,}) {
  return _then(_self.copyWith(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,recipientName: null == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,isRedeemed: null == isRedeemed ? _self.isRedeemed : isRedeemed // ignore: cast_nullable_to_non_nullable
as bool,redeemedAt: freezed == redeemedAt ? _self.redeemedAt : redeemedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isClaimable: null == isClaimable ? _self.isClaimable : isClaimable // ignore: cast_nullable_to_non_nullable
as bool,deepLink: freezed == deepLink ? _self.deepLink : deepLink // ignore: cast_nullable_to_non_nullable
as String?,storeLinks: null == storeLinks ? _self.storeLinks : storeLinks // ignore: cast_nullable_to_non_nullable
as List<GiftStoreLink>,
  ));
}

}


/// Adds pattern-matching-related methods to [GiftPreview].
extension GiftPreviewPatterns on GiftPreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GiftPreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GiftPreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GiftPreview value)  $default,){
final _that = this;
switch (_that) {
case _GiftPreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GiftPreview value)?  $default,){
final _that = this;
switch (_that) {
case _GiftPreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  String recipientName,  String message,  String amount,  String from,  bool isRedeemed,  DateTime? redeemedAt,  bool isClaimable,  String? deepLink,  List<GiftStoreLink> storeLinks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GiftPreview() when $default != null:
return $default(_that.token,_that.recipientName,_that.message,_that.amount,_that.from,_that.isRedeemed,_that.redeemedAt,_that.isClaimable,_that.deepLink,_that.storeLinks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  String recipientName,  String message,  String amount,  String from,  bool isRedeemed,  DateTime? redeemedAt,  bool isClaimable,  String? deepLink,  List<GiftStoreLink> storeLinks)  $default,) {final _that = this;
switch (_that) {
case _GiftPreview():
return $default(_that.token,_that.recipientName,_that.message,_that.amount,_that.from,_that.isRedeemed,_that.redeemedAt,_that.isClaimable,_that.deepLink,_that.storeLinks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  String recipientName,  String message,  String amount,  String from,  bool isRedeemed,  DateTime? redeemedAt,  bool isClaimable,  String? deepLink,  List<GiftStoreLink> storeLinks)?  $default,) {final _that = this;
switch (_that) {
case _GiftPreview() when $default != null:
return $default(_that.token,_that.recipientName,_that.message,_that.amount,_that.from,_that.isRedeemed,_that.redeemedAt,_that.isClaimable,_that.deepLink,_that.storeLinks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GiftPreview implements GiftPreview {
  const _GiftPreview({required this.token, required this.recipientName, this.message = '', required this.amount, this.from = '', required this.isRedeemed, this.redeemedAt, required this.isClaimable, this.deepLink, final  List<GiftStoreLink> storeLinks = const <GiftStoreLink>[]}): _storeLinks = storeLinks;
  factory _GiftPreview.fromJson(Map<String, dynamic> json) => _$GiftPreviewFromJson(json);

/// The share token from the link. The id for every call here.
@override final  String token;
/// Who it was addressed to, as the buyer typed it.
@override final  String recipientName;
/// The buyer's note. Empty when they left it blank.
@override@JsonKey() final  String message;
/// Face value as a decimal string. Never parsed.
@override final  String amount;
/// Who it is from, as the buyer typed it.
@override@JsonKey() final  String from;
@override final  bool isRedeemed;
/// When it was claimed. Null while it still stands.
@override final  DateTime? redeemedAt;
/// Whether a Claim button may be drawn at all — see the class doc.
@override final  bool isClaimable;
/// `terracotta://gift/{token}` — the website's "Open in app"
/// target. The app is already here.
@override final  String? deepLink;
/// Where to install the app. The website's buttons, not ours.
 final  List<GiftStoreLink> _storeLinks;
/// Where to install the app. The website's buttons, not ours.
@override@JsonKey() List<GiftStoreLink> get storeLinks {
  if (_storeLinks is EqualUnmodifiableListView) return _storeLinks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_storeLinks);
}


/// Create a copy of GiftPreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GiftPreviewCopyWith<_GiftPreview> get copyWith => __$GiftPreviewCopyWithImpl<_GiftPreview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GiftPreviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GiftPreview&&(identical(other.token, token) || other.token == token)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.message, message) || other.message == message)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.from, from) || other.from == from)&&(identical(other.isRedeemed, isRedeemed) || other.isRedeemed == isRedeemed)&&(identical(other.redeemedAt, redeemedAt) || other.redeemedAt == redeemedAt)&&(identical(other.isClaimable, isClaimable) || other.isClaimable == isClaimable)&&(identical(other.deepLink, deepLink) || other.deepLink == deepLink)&&const DeepCollectionEquality().equals(other._storeLinks, _storeLinks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,recipientName,message,amount,from,isRedeemed,redeemedAt,isClaimable,deepLink,const DeepCollectionEquality().hash(_storeLinks));

@override
String toString() {
  return 'GiftPreview(token: $token, recipientName: $recipientName, message: $message, amount: $amount, from: $from, isRedeemed: $isRedeemed, redeemedAt: $redeemedAt, isClaimable: $isClaimable, deepLink: $deepLink, storeLinks: $storeLinks)';
}


}

/// @nodoc
abstract mixin class _$GiftPreviewCopyWith<$Res> implements $GiftPreviewCopyWith<$Res> {
  factory _$GiftPreviewCopyWith(_GiftPreview value, $Res Function(_GiftPreview) _then) = __$GiftPreviewCopyWithImpl;
@override @useResult
$Res call({
 String token, String recipientName, String message, String amount, String from, bool isRedeemed, DateTime? redeemedAt, bool isClaimable, String? deepLink, List<GiftStoreLink> storeLinks
});




}
/// @nodoc
class __$GiftPreviewCopyWithImpl<$Res>
    implements _$GiftPreviewCopyWith<$Res> {
  __$GiftPreviewCopyWithImpl(this._self, this._then);

  final _GiftPreview _self;
  final $Res Function(_GiftPreview) _then;

/// Create a copy of GiftPreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? recipientName = null,Object? message = null,Object? amount = null,Object? from = null,Object? isRedeemed = null,Object? redeemedAt = freezed,Object? isClaimable = null,Object? deepLink = freezed,Object? storeLinks = null,}) {
  return _then(_GiftPreview(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,recipientName: null == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,isRedeemed: null == isRedeemed ? _self.isRedeemed : isRedeemed // ignore: cast_nullable_to_non_nullable
as bool,redeemedAt: freezed == redeemedAt ? _self.redeemedAt : redeemedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isClaimable: null == isClaimable ? _self.isClaimable : isClaimable // ignore: cast_nullable_to_non_nullable
as bool,deepLink: freezed == deepLink ? _self.deepLink : deepLink // ignore: cast_nullable_to_non_nullable
as String?,storeLinks: null == storeLinks ? _self._storeLinks : storeLinks // ignore: cast_nullable_to_non_nullable
as List<GiftStoreLink>,
  ));
}


}


/// @nodoc
mixin _$GiftStoreLink {

/// `app_store` or `google_play`. An OPEN set — the CMS holds
/// these, so match the ones you handle and ignore the rest.
 String get type; String get url;
/// Create a copy of GiftStoreLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GiftStoreLinkCopyWith<GiftStoreLink> get copyWith => _$GiftStoreLinkCopyWithImpl<GiftStoreLink>(this as GiftStoreLink, _$identity);

  /// Serializes this GiftStoreLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GiftStoreLink&&(identical(other.type, type) || other.type == type)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,url);

@override
String toString() {
  return 'GiftStoreLink(type: $type, url: $url)';
}


}

/// @nodoc
abstract mixin class $GiftStoreLinkCopyWith<$Res>  {
  factory $GiftStoreLinkCopyWith(GiftStoreLink value, $Res Function(GiftStoreLink) _then) = _$GiftStoreLinkCopyWithImpl;
@useResult
$Res call({
 String type, String url
});




}
/// @nodoc
class _$GiftStoreLinkCopyWithImpl<$Res>
    implements $GiftStoreLinkCopyWith<$Res> {
  _$GiftStoreLinkCopyWithImpl(this._self, this._then);

  final GiftStoreLink _self;
  final $Res Function(GiftStoreLink) _then;

/// Create a copy of GiftStoreLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? url = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GiftStoreLink].
extension GiftStoreLinkPatterns on GiftStoreLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GiftStoreLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GiftStoreLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GiftStoreLink value)  $default,){
final _that = this;
switch (_that) {
case _GiftStoreLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GiftStoreLink value)?  $default,){
final _that = this;
switch (_that) {
case _GiftStoreLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GiftStoreLink() when $default != null:
return $default(_that.type,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String url)  $default,) {final _that = this;
switch (_that) {
case _GiftStoreLink():
return $default(_that.type,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String url)?  $default,) {final _that = this;
switch (_that) {
case _GiftStoreLink() when $default != null:
return $default(_that.type,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GiftStoreLink implements GiftStoreLink {
  const _GiftStoreLink({required this.type, required this.url});
  factory _GiftStoreLink.fromJson(Map<String, dynamic> json) => _$GiftStoreLinkFromJson(json);

/// `app_store` or `google_play`. An OPEN set — the CMS holds
/// these, so match the ones you handle and ignore the rest.
@override final  String type;
@override final  String url;

/// Create a copy of GiftStoreLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GiftStoreLinkCopyWith<_GiftStoreLink> get copyWith => __$GiftStoreLinkCopyWithImpl<_GiftStoreLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GiftStoreLinkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GiftStoreLink&&(identical(other.type, type) || other.type == type)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,url);

@override
String toString() {
  return 'GiftStoreLink(type: $type, url: $url)';
}


}

/// @nodoc
abstract mixin class _$GiftStoreLinkCopyWith<$Res> implements $GiftStoreLinkCopyWith<$Res> {
  factory _$GiftStoreLinkCopyWith(_GiftStoreLink value, $Res Function(_GiftStoreLink) _then) = __$GiftStoreLinkCopyWithImpl;
@override @useResult
$Res call({
 String type, String url
});




}
/// @nodoc
class __$GiftStoreLinkCopyWithImpl<$Res>
    implements _$GiftStoreLinkCopyWith<$Res> {
  __$GiftStoreLinkCopyWithImpl(this._self, this._then);

  final _GiftStoreLink _self;
  final $Res Function(_GiftStoreLink) _then;

/// Create a copy of GiftStoreLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? url = null,}) {
  return _then(_GiftStoreLink(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
