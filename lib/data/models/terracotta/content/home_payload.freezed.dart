// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HomePayload {

/// Hero carousel. 10 in the capture, each with its own link type.
 List<HomeBanner> get banners;/// Shop category tiles. 4 in the capture.
 List<HomeCategory> get categories;/// The user's in-progress booking, if any. **Shape unverified —
/// null in every capture.** See the class doc before typing it.
 Map<String, dynamic>? get currentBooking;/// Editorial "featured" rail. Overlaps [offers].
 List<HomeProductCard> get featuredProducts;/// Discounted products rail. Overlaps [featuredProducts]. Every
/// entry in the capture has a non-null `sale_price`, but the shape
/// permits null — do not assume a discount is present.
 List<HomeProductCard> get offers;
/// Create a copy of HomePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomePayloadCopyWith<HomePayload> get copyWith => _$HomePayloadCopyWithImpl<HomePayload>(this as HomePayload, _$identity);

  /// Serializes this HomePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomePayload&&const DeepCollectionEquality().equals(other.banners, banners)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.currentBooking, currentBooking)&&const DeepCollectionEquality().equals(other.featuredProducts, featuredProducts)&&const DeepCollectionEquality().equals(other.offers, offers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(banners),const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(currentBooking),const DeepCollectionEquality().hash(featuredProducts),const DeepCollectionEquality().hash(offers));

@override
String toString() {
  return 'HomePayload(banners: $banners, categories: $categories, currentBooking: $currentBooking, featuredProducts: $featuredProducts, offers: $offers)';
}


}

/// @nodoc
abstract mixin class $HomePayloadCopyWith<$Res>  {
  factory $HomePayloadCopyWith(HomePayload value, $Res Function(HomePayload) _then) = _$HomePayloadCopyWithImpl;
@useResult
$Res call({
 List<HomeBanner> banners, List<HomeCategory> categories, Map<String, dynamic>? currentBooking, List<HomeProductCard> featuredProducts, List<HomeProductCard> offers
});




}
/// @nodoc
class _$HomePayloadCopyWithImpl<$Res>
    implements $HomePayloadCopyWith<$Res> {
  _$HomePayloadCopyWithImpl(this._self, this._then);

  final HomePayload _self;
  final $Res Function(HomePayload) _then;

/// Create a copy of HomePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? banners = null,Object? categories = null,Object? currentBooking = freezed,Object? featuredProducts = null,Object? offers = null,}) {
  return _then(_self.copyWith(
banners: null == banners ? _self.banners : banners // ignore: cast_nullable_to_non_nullable
as List<HomeBanner>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<HomeCategory>,currentBooking: freezed == currentBooking ? _self.currentBooking : currentBooking // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,featuredProducts: null == featuredProducts ? _self.featuredProducts : featuredProducts // ignore: cast_nullable_to_non_nullable
as List<HomeProductCard>,offers: null == offers ? _self.offers : offers // ignore: cast_nullable_to_non_nullable
as List<HomeProductCard>,
  ));
}

}


/// Adds pattern-matching-related methods to [HomePayload].
extension HomePayloadPatterns on HomePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomePayload value)  $default,){
final _that = this;
switch (_that) {
case _HomePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomePayload value)?  $default,){
final _that = this;
switch (_that) {
case _HomePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<HomeBanner> banners,  List<HomeCategory> categories,  Map<String, dynamic>? currentBooking,  List<HomeProductCard> featuredProducts,  List<HomeProductCard> offers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomePayload() when $default != null:
return $default(_that.banners,_that.categories,_that.currentBooking,_that.featuredProducts,_that.offers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<HomeBanner> banners,  List<HomeCategory> categories,  Map<String, dynamic>? currentBooking,  List<HomeProductCard> featuredProducts,  List<HomeProductCard> offers)  $default,) {final _that = this;
switch (_that) {
case _HomePayload():
return $default(_that.banners,_that.categories,_that.currentBooking,_that.featuredProducts,_that.offers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<HomeBanner> banners,  List<HomeCategory> categories,  Map<String, dynamic>? currentBooking,  List<HomeProductCard> featuredProducts,  List<HomeProductCard> offers)?  $default,) {final _that = this;
switch (_that) {
case _HomePayload() when $default != null:
return $default(_that.banners,_that.categories,_that.currentBooking,_that.featuredProducts,_that.offers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomePayload extends HomePayload {
  const _HomePayload({required final  List<HomeBanner> banners, required final  List<HomeCategory> categories, final  Map<String, dynamic>? currentBooking, required final  List<HomeProductCard> featuredProducts, required final  List<HomeProductCard> offers}): _banners = banners,_categories = categories,_currentBooking = currentBooking,_featuredProducts = featuredProducts,_offers = offers,super._();
  factory _HomePayload.fromJson(Map<String, dynamic> json) => _$HomePayloadFromJson(json);

/// Hero carousel. 10 in the capture, each with its own link type.
 final  List<HomeBanner> _banners;
/// Hero carousel. 10 in the capture, each with its own link type.
@override List<HomeBanner> get banners {
  if (_banners is EqualUnmodifiableListView) return _banners;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_banners);
}

/// Shop category tiles. 4 in the capture.
 final  List<HomeCategory> _categories;
/// Shop category tiles. 4 in the capture.
@override List<HomeCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

/// The user's in-progress booking, if any. **Shape unverified —
/// null in every capture.** See the class doc before typing it.
 final  Map<String, dynamic>? _currentBooking;
/// The user's in-progress booking, if any. **Shape unverified —
/// null in every capture.** See the class doc before typing it.
@override Map<String, dynamic>? get currentBooking {
  final value = _currentBooking;
  if (value == null) return null;
  if (_currentBooking is EqualUnmodifiableMapView) return _currentBooking;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Editorial "featured" rail. Overlaps [offers].
 final  List<HomeProductCard> _featuredProducts;
/// Editorial "featured" rail. Overlaps [offers].
@override List<HomeProductCard> get featuredProducts {
  if (_featuredProducts is EqualUnmodifiableListView) return _featuredProducts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_featuredProducts);
}

/// Discounted products rail. Overlaps [featuredProducts]. Every
/// entry in the capture has a non-null `sale_price`, but the shape
/// permits null — do not assume a discount is present.
 final  List<HomeProductCard> _offers;
/// Discounted products rail. Overlaps [featuredProducts]. Every
/// entry in the capture has a non-null `sale_price`, but the shape
/// permits null — do not assume a discount is present.
@override List<HomeProductCard> get offers {
  if (_offers is EqualUnmodifiableListView) return _offers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_offers);
}


/// Create a copy of HomePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomePayloadCopyWith<_HomePayload> get copyWith => __$HomePayloadCopyWithImpl<_HomePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HomePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomePayload&&const DeepCollectionEquality().equals(other._banners, _banners)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._currentBooking, _currentBooking)&&const DeepCollectionEquality().equals(other._featuredProducts, _featuredProducts)&&const DeepCollectionEquality().equals(other._offers, _offers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_banners),const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_currentBooking),const DeepCollectionEquality().hash(_featuredProducts),const DeepCollectionEquality().hash(_offers));

@override
String toString() {
  return 'HomePayload(banners: $banners, categories: $categories, currentBooking: $currentBooking, featuredProducts: $featuredProducts, offers: $offers)';
}


}

/// @nodoc
abstract mixin class _$HomePayloadCopyWith<$Res> implements $HomePayloadCopyWith<$Res> {
  factory _$HomePayloadCopyWith(_HomePayload value, $Res Function(_HomePayload) _then) = __$HomePayloadCopyWithImpl;
@override @useResult
$Res call({
 List<HomeBanner> banners, List<HomeCategory> categories, Map<String, dynamic>? currentBooking, List<HomeProductCard> featuredProducts, List<HomeProductCard> offers
});




}
/// @nodoc
class __$HomePayloadCopyWithImpl<$Res>
    implements _$HomePayloadCopyWith<$Res> {
  __$HomePayloadCopyWithImpl(this._self, this._then);

  final _HomePayload _self;
  final $Res Function(_HomePayload) _then;

/// Create a copy of HomePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? banners = null,Object? categories = null,Object? currentBooking = freezed,Object? featuredProducts = null,Object? offers = null,}) {
  return _then(_HomePayload(
banners: null == banners ? _self._banners : banners // ignore: cast_nullable_to_non_nullable
as List<HomeBanner>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<HomeCategory>,currentBooking: freezed == currentBooking ? _self._currentBooking : currentBooking // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,featuredProducts: null == featuredProducts ? _self._featuredProducts : featuredProducts // ignore: cast_nullable_to_non_nullable
as List<HomeProductCard>,offers: null == offers ? _self._offers : offers // ignore: cast_nullable_to_non_nullable
as List<HomeProductCard>,
  ));
}


}

// dart format on
