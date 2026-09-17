// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workshop_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkshopDetail {

 int get id;/// Which booking flow this workshop runs. Unknown CMS values parse
/// to [WorkshopType.unknown] rather than throwing.
@WorkshopTypeConverter() WorkshopType get type;/// Already-localized title for the requested locale.
 String get title;/// Plain-text teaser. The HTML body is [longDescription].
 String get shortDescription;/// Admin-set `#RRGGBB` for this specific workshop.
 String get color;/// Seat price, decimal string. `"0.00"` on the catalog types.
 String get price;/// Hard seat ceiling for one session across all bookings.
 int get capacityPerSession;/// Ceiling on `people_count` for a SINGLE booking.
 int get maxPeoplePerBooking;/// Session length in minutes.
 int get durationMinutes;/// Maps deep link for the studio. Open externally.
///
/// NULLABLE — verified live on 2026-08-30. The CMS leaves it empty
/// on a workshop that is not open for booking, and declared
/// required it threw inside `fromJson` and took the whole payload
/// with it. Show the map link only when there is one.
 String? get locationUrl;/// Cost of the celebration add-on, decimal string.
 String get celebrationPrice;/// Cancellation cut-off in hours before the session. Ranges 1..24
/// across the captured workshops — never hard-code it.
 int get cancellationWindowHours;/// WHO THE SESSION IS FOR — `mixed`, `women_only`, `men_only`,
/// `couples`, `kids`, `families`.
///
/// Nothing on the server checks a booking against it: the app never
/// asks for anybody's gender, so the only thing standing between a
/// customer and the wrong room is that they were able to READ this
/// before booking. Show it on the card and on the detail.
///
/// Absent or unrecognised reads as [WorkshopAudience.mixed], which
/// is the default and what every workshop had before the field
/// existed.
@WorkshopAudienceConverter() WorkshopAudience get audience;/// HOW LONG THE STUDIO HOLDS A FINISHED PIECE, in days.
///
/// Set per workshop, and 7 when the studio does not. A booking's
/// `pickup_deadline` is computed from this rather than from a fixed
/// week — so this is the number to promise BEFORE booking ("you
/// will have N days to collect it") and the deadline is the date to
/// show after the piece is ready.
///
/// Information only: nothing is cancelled or refunded when it
/// passes.
 int get pieceWarningDays;/// Whether a finished piece can be shipped instead of collected.
 bool get hasDelivery;/// Cover image. Null in the live capture — render a placeholder.
 ApiImage? get image;/// Minimum products per person. Null when the type has no catalog.
 int? get minProductsPerPerson;/// Maximum products per person. Null when the type has no catalog.
 int? get maxProductsPerPerson;// ---- detail-only keys ----
/// HTML body copy. Render through an HTML widget, not `Text`.
 String? get longDescription;/// Photo gallery for the detail hero/carousel. Empty in the live
/// capture; defaults to empty so a missing key cannot throw.
 List<ApiImage> get gallery;/// The two-level product catalog (category -> sub-category ->
/// products). Empty for workshops with no catalog; defaults to
/// empty so a missing key cannot throw.
 List<WorkshopCategory> get categories;/// The customer's own pieces, offered back to be painted.
///
/// NULL on every workshop but a `paint_your_piece` one that
/// `accepts_own_pieces` — and its `pieces` list is empty for a
/// guest, who has made nothing. See [WorkshopOwnPieces].
 WorkshopOwnPieces? get ownPieces;
/// Create a copy of WorkshopDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkshopDetailCopyWith<WorkshopDetail> get copyWith => _$WorkshopDetailCopyWithImpl<WorkshopDetail>(this as WorkshopDetail, _$identity);

  /// Serializes this WorkshopDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkshopDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.shortDescription, shortDescription) || other.shortDescription == shortDescription)&&(identical(other.color, color) || other.color == color)&&(identical(other.price, price) || other.price == price)&&(identical(other.capacityPerSession, capacityPerSession) || other.capacityPerSession == capacityPerSession)&&(identical(other.maxPeoplePerBooking, maxPeoplePerBooking) || other.maxPeoplePerBooking == maxPeoplePerBooking)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.locationUrl, locationUrl) || other.locationUrl == locationUrl)&&(identical(other.celebrationPrice, celebrationPrice) || other.celebrationPrice == celebrationPrice)&&(identical(other.cancellationWindowHours, cancellationWindowHours) || other.cancellationWindowHours == cancellationWindowHours)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.pieceWarningDays, pieceWarningDays) || other.pieceWarningDays == pieceWarningDays)&&(identical(other.hasDelivery, hasDelivery) || other.hasDelivery == hasDelivery)&&(identical(other.image, image) || other.image == image)&&(identical(other.minProductsPerPerson, minProductsPerPerson) || other.minProductsPerPerson == minProductsPerPerson)&&(identical(other.maxProductsPerPerson, maxProductsPerPerson) || other.maxProductsPerPerson == maxProductsPerPerson)&&(identical(other.longDescription, longDescription) || other.longDescription == longDescription)&&const DeepCollectionEquality().equals(other.gallery, gallery)&&const DeepCollectionEquality().equals(other.categories, categories)&&(identical(other.ownPieces, ownPieces) || other.ownPieces == ownPieces));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,type,title,shortDescription,color,price,capacityPerSession,maxPeoplePerBooking,durationMinutes,locationUrl,celebrationPrice,cancellationWindowHours,audience,pieceWarningDays,hasDelivery,image,minProductsPerPerson,maxProductsPerPerson,longDescription,const DeepCollectionEquality().hash(gallery),const DeepCollectionEquality().hash(categories),ownPieces]);

@override
String toString() {
  return 'WorkshopDetail(id: $id, type: $type, title: $title, shortDescription: $shortDescription, color: $color, price: $price, capacityPerSession: $capacityPerSession, maxPeoplePerBooking: $maxPeoplePerBooking, durationMinutes: $durationMinutes, locationUrl: $locationUrl, celebrationPrice: $celebrationPrice, cancellationWindowHours: $cancellationWindowHours, audience: $audience, pieceWarningDays: $pieceWarningDays, hasDelivery: $hasDelivery, image: $image, minProductsPerPerson: $minProductsPerPerson, maxProductsPerPerson: $maxProductsPerPerson, longDescription: $longDescription, gallery: $gallery, categories: $categories, ownPieces: $ownPieces)';
}


}

/// @nodoc
abstract mixin class $WorkshopDetailCopyWith<$Res>  {
  factory $WorkshopDetailCopyWith(WorkshopDetail value, $Res Function(WorkshopDetail) _then) = _$WorkshopDetailCopyWithImpl;
@useResult
$Res call({
 int id,@WorkshopTypeConverter() WorkshopType type, String title, String shortDescription, String color, String price, int capacityPerSession, int maxPeoplePerBooking, int durationMinutes, String? locationUrl, String celebrationPrice, int cancellationWindowHours,@WorkshopAudienceConverter() WorkshopAudience audience, int pieceWarningDays, bool hasDelivery, ApiImage? image, int? minProductsPerPerson, int? maxProductsPerPerson, String? longDescription, List<ApiImage> gallery, List<WorkshopCategory> categories, WorkshopOwnPieces? ownPieces
});


$ApiImageCopyWith<$Res>? get image;$WorkshopOwnPiecesCopyWith<$Res>? get ownPieces;

}
/// @nodoc
class _$WorkshopDetailCopyWithImpl<$Res>
    implements $WorkshopDetailCopyWith<$Res> {
  _$WorkshopDetailCopyWithImpl(this._self, this._then);

  final WorkshopDetail _self;
  final $Res Function(WorkshopDetail) _then;

/// Create a copy of WorkshopDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? title = null,Object? shortDescription = null,Object? color = null,Object? price = null,Object? capacityPerSession = null,Object? maxPeoplePerBooking = null,Object? durationMinutes = null,Object? locationUrl = freezed,Object? celebrationPrice = null,Object? cancellationWindowHours = null,Object? audience = null,Object? pieceWarningDays = null,Object? hasDelivery = null,Object? image = freezed,Object? minProductsPerPerson = freezed,Object? maxProductsPerPerson = freezed,Object? longDescription = freezed,Object? gallery = null,Object? categories = null,Object? ownPieces = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WorkshopType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,shortDescription: null == shortDescription ? _self.shortDescription : shortDescription // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,capacityPerSession: null == capacityPerSession ? _self.capacityPerSession : capacityPerSession // ignore: cast_nullable_to_non_nullable
as int,maxPeoplePerBooking: null == maxPeoplePerBooking ? _self.maxPeoplePerBooking : maxPeoplePerBooking // ignore: cast_nullable_to_non_nullable
as int,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,locationUrl: freezed == locationUrl ? _self.locationUrl : locationUrl // ignore: cast_nullable_to_non_nullable
as String?,celebrationPrice: null == celebrationPrice ? _self.celebrationPrice : celebrationPrice // ignore: cast_nullable_to_non_nullable
as String,cancellationWindowHours: null == cancellationWindowHours ? _self.cancellationWindowHours : cancellationWindowHours // ignore: cast_nullable_to_non_nullable
as int,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as WorkshopAudience,pieceWarningDays: null == pieceWarningDays ? _self.pieceWarningDays : pieceWarningDays // ignore: cast_nullable_to_non_nullable
as int,hasDelivery: null == hasDelivery ? _self.hasDelivery : hasDelivery // ignore: cast_nullable_to_non_nullable
as bool,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,minProductsPerPerson: freezed == minProductsPerPerson ? _self.minProductsPerPerson : minProductsPerPerson // ignore: cast_nullable_to_non_nullable
as int?,maxProductsPerPerson: freezed == maxProductsPerPerson ? _self.maxProductsPerPerson : maxProductsPerPerson // ignore: cast_nullable_to_non_nullable
as int?,longDescription: freezed == longDescription ? _self.longDescription : longDescription // ignore: cast_nullable_to_non_nullable
as String?,gallery: null == gallery ? _self.gallery : gallery // ignore: cast_nullable_to_non_nullable
as List<ApiImage>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<WorkshopCategory>,ownPieces: freezed == ownPieces ? _self.ownPieces : ownPieces // ignore: cast_nullable_to_non_nullable
as WorkshopOwnPieces?,
  ));
}
/// Create a copy of WorkshopDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiImageCopyWith<$Res>? get image {
    if (_self.image == null) {
    return null;
  }

  return $ApiImageCopyWith<$Res>(_self.image!, (value) {
    return _then(_self.copyWith(image: value));
  });
}/// Create a copy of WorkshopDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkshopOwnPiecesCopyWith<$Res>? get ownPieces {
    if (_self.ownPieces == null) {
    return null;
  }

  return $WorkshopOwnPiecesCopyWith<$Res>(_self.ownPieces!, (value) {
    return _then(_self.copyWith(ownPieces: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkshopDetail].
extension WorkshopDetailPatterns on WorkshopDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkshopDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkshopDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkshopDetail value)  $default,){
final _that = this;
switch (_that) {
case _WorkshopDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkshopDetail value)?  $default,){
final _that = this;
switch (_that) {
case _WorkshopDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @WorkshopTypeConverter()  WorkshopType type,  String title,  String shortDescription,  String color,  String price,  int capacityPerSession,  int maxPeoplePerBooking,  int durationMinutes,  String? locationUrl,  String celebrationPrice,  int cancellationWindowHours, @WorkshopAudienceConverter()  WorkshopAudience audience,  int pieceWarningDays,  bool hasDelivery,  ApiImage? image,  int? minProductsPerPerson,  int? maxProductsPerPerson,  String? longDescription,  List<ApiImage> gallery,  List<WorkshopCategory> categories,  WorkshopOwnPieces? ownPieces)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkshopDetail() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.shortDescription,_that.color,_that.price,_that.capacityPerSession,_that.maxPeoplePerBooking,_that.durationMinutes,_that.locationUrl,_that.celebrationPrice,_that.cancellationWindowHours,_that.audience,_that.pieceWarningDays,_that.hasDelivery,_that.image,_that.minProductsPerPerson,_that.maxProductsPerPerson,_that.longDescription,_that.gallery,_that.categories,_that.ownPieces);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @WorkshopTypeConverter()  WorkshopType type,  String title,  String shortDescription,  String color,  String price,  int capacityPerSession,  int maxPeoplePerBooking,  int durationMinutes,  String? locationUrl,  String celebrationPrice,  int cancellationWindowHours, @WorkshopAudienceConverter()  WorkshopAudience audience,  int pieceWarningDays,  bool hasDelivery,  ApiImage? image,  int? minProductsPerPerson,  int? maxProductsPerPerson,  String? longDescription,  List<ApiImage> gallery,  List<WorkshopCategory> categories,  WorkshopOwnPieces? ownPieces)  $default,) {final _that = this;
switch (_that) {
case _WorkshopDetail():
return $default(_that.id,_that.type,_that.title,_that.shortDescription,_that.color,_that.price,_that.capacityPerSession,_that.maxPeoplePerBooking,_that.durationMinutes,_that.locationUrl,_that.celebrationPrice,_that.cancellationWindowHours,_that.audience,_that.pieceWarningDays,_that.hasDelivery,_that.image,_that.minProductsPerPerson,_that.maxProductsPerPerson,_that.longDescription,_that.gallery,_that.categories,_that.ownPieces);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @WorkshopTypeConverter()  WorkshopType type,  String title,  String shortDescription,  String color,  String price,  int capacityPerSession,  int maxPeoplePerBooking,  int durationMinutes,  String? locationUrl,  String celebrationPrice,  int cancellationWindowHours, @WorkshopAudienceConverter()  WorkshopAudience audience,  int pieceWarningDays,  bool hasDelivery,  ApiImage? image,  int? minProductsPerPerson,  int? maxProductsPerPerson,  String? longDescription,  List<ApiImage> gallery,  List<WorkshopCategory> categories,  WorkshopOwnPieces? ownPieces)?  $default,) {final _that = this;
switch (_that) {
case _WorkshopDetail() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.shortDescription,_that.color,_that.price,_that.capacityPerSession,_that.maxPeoplePerBooking,_that.durationMinutes,_that.locationUrl,_that.celebrationPrice,_that.cancellationWindowHours,_that.audience,_that.pieceWarningDays,_that.hasDelivery,_that.image,_that.minProductsPerPerson,_that.maxProductsPerPerson,_that.longDescription,_that.gallery,_that.categories,_that.ownPieces);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkshopDetail extends WorkshopDetail {
  const _WorkshopDetail({required this.id, @WorkshopTypeConverter() required this.type, required this.title, required this.shortDescription, required this.color, required this.price, required this.capacityPerSession, required this.maxPeoplePerBooking, required this.durationMinutes, this.locationUrl, required this.celebrationPrice, required this.cancellationWindowHours, @WorkshopAudienceConverter() this.audience = WorkshopAudience.mixed, this.pieceWarningDays = 7, required this.hasDelivery, this.image, this.minProductsPerPerson, this.maxProductsPerPerson, this.longDescription, final  List<ApiImage> gallery = const <ApiImage>[], final  List<WorkshopCategory> categories = const <WorkshopCategory>[], this.ownPieces}): _gallery = gallery,_categories = categories,super._();
  factory _WorkshopDetail.fromJson(Map<String, dynamic> json) => _$WorkshopDetailFromJson(json);

@override final  int id;
/// Which booking flow this workshop runs. Unknown CMS values parse
/// to [WorkshopType.unknown] rather than throwing.
@override@WorkshopTypeConverter() final  WorkshopType type;
/// Already-localized title for the requested locale.
@override final  String title;
/// Plain-text teaser. The HTML body is [longDescription].
@override final  String shortDescription;
/// Admin-set `#RRGGBB` for this specific workshop.
@override final  String color;
/// Seat price, decimal string. `"0.00"` on the catalog types.
@override final  String price;
/// Hard seat ceiling for one session across all bookings.
@override final  int capacityPerSession;
/// Ceiling on `people_count` for a SINGLE booking.
@override final  int maxPeoplePerBooking;
/// Session length in minutes.
@override final  int durationMinutes;
/// Maps deep link for the studio. Open externally.
///
/// NULLABLE — verified live on 2026-08-30. The CMS leaves it empty
/// on a workshop that is not open for booking, and declared
/// required it threw inside `fromJson` and took the whole payload
/// with it. Show the map link only when there is one.
@override final  String? locationUrl;
/// Cost of the celebration add-on, decimal string.
@override final  String celebrationPrice;
/// Cancellation cut-off in hours before the session. Ranges 1..24
/// across the captured workshops — never hard-code it.
@override final  int cancellationWindowHours;
/// WHO THE SESSION IS FOR — `mixed`, `women_only`, `men_only`,
/// `couples`, `kids`, `families`.
///
/// Nothing on the server checks a booking against it: the app never
/// asks for anybody's gender, so the only thing standing between a
/// customer and the wrong room is that they were able to READ this
/// before booking. Show it on the card and on the detail.
///
/// Absent or unrecognised reads as [WorkshopAudience.mixed], which
/// is the default and what every workshop had before the field
/// existed.
@override@JsonKey()@WorkshopAudienceConverter() final  WorkshopAudience audience;
/// HOW LONG THE STUDIO HOLDS A FINISHED PIECE, in days.
///
/// Set per workshop, and 7 when the studio does not. A booking's
/// `pickup_deadline` is computed from this rather than from a fixed
/// week — so this is the number to promise BEFORE booking ("you
/// will have N days to collect it") and the deadline is the date to
/// show after the piece is ready.
///
/// Information only: nothing is cancelled or refunded when it
/// passes.
@override@JsonKey() final  int pieceWarningDays;
/// Whether a finished piece can be shipped instead of collected.
@override final  bool hasDelivery;
/// Cover image. Null in the live capture — render a placeholder.
@override final  ApiImage? image;
/// Minimum products per person. Null when the type has no catalog.
@override final  int? minProductsPerPerson;
/// Maximum products per person. Null when the type has no catalog.
@override final  int? maxProductsPerPerson;
// ---- detail-only keys ----
/// HTML body copy. Render through an HTML widget, not `Text`.
@override final  String? longDescription;
/// Photo gallery for the detail hero/carousel. Empty in the live
/// capture; defaults to empty so a missing key cannot throw.
 final  List<ApiImage> _gallery;
/// Photo gallery for the detail hero/carousel. Empty in the live
/// capture; defaults to empty so a missing key cannot throw.
@override@JsonKey() List<ApiImage> get gallery {
  if (_gallery is EqualUnmodifiableListView) return _gallery;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_gallery);
}

/// The two-level product catalog (category -> sub-category ->
/// products). Empty for workshops with no catalog; defaults to
/// empty so a missing key cannot throw.
 final  List<WorkshopCategory> _categories;
/// The two-level product catalog (category -> sub-category ->
/// products). Empty for workshops with no catalog; defaults to
/// empty so a missing key cannot throw.
@override@JsonKey() List<WorkshopCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

/// The customer's own pieces, offered back to be painted.
///
/// NULL on every workshop but a `paint_your_piece` one that
/// `accepts_own_pieces` — and its `pieces` list is empty for a
/// guest, who has made nothing. See [WorkshopOwnPieces].
@override final  WorkshopOwnPieces? ownPieces;

/// Create a copy of WorkshopDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkshopDetailCopyWith<_WorkshopDetail> get copyWith => __$WorkshopDetailCopyWithImpl<_WorkshopDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkshopDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkshopDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.shortDescription, shortDescription) || other.shortDescription == shortDescription)&&(identical(other.color, color) || other.color == color)&&(identical(other.price, price) || other.price == price)&&(identical(other.capacityPerSession, capacityPerSession) || other.capacityPerSession == capacityPerSession)&&(identical(other.maxPeoplePerBooking, maxPeoplePerBooking) || other.maxPeoplePerBooking == maxPeoplePerBooking)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.locationUrl, locationUrl) || other.locationUrl == locationUrl)&&(identical(other.celebrationPrice, celebrationPrice) || other.celebrationPrice == celebrationPrice)&&(identical(other.cancellationWindowHours, cancellationWindowHours) || other.cancellationWindowHours == cancellationWindowHours)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.pieceWarningDays, pieceWarningDays) || other.pieceWarningDays == pieceWarningDays)&&(identical(other.hasDelivery, hasDelivery) || other.hasDelivery == hasDelivery)&&(identical(other.image, image) || other.image == image)&&(identical(other.minProductsPerPerson, minProductsPerPerson) || other.minProductsPerPerson == minProductsPerPerson)&&(identical(other.maxProductsPerPerson, maxProductsPerPerson) || other.maxProductsPerPerson == maxProductsPerPerson)&&(identical(other.longDescription, longDescription) || other.longDescription == longDescription)&&const DeepCollectionEquality().equals(other._gallery, _gallery)&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.ownPieces, ownPieces) || other.ownPieces == ownPieces));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,type,title,shortDescription,color,price,capacityPerSession,maxPeoplePerBooking,durationMinutes,locationUrl,celebrationPrice,cancellationWindowHours,audience,pieceWarningDays,hasDelivery,image,minProductsPerPerson,maxProductsPerPerson,longDescription,const DeepCollectionEquality().hash(_gallery),const DeepCollectionEquality().hash(_categories),ownPieces]);

@override
String toString() {
  return 'WorkshopDetail(id: $id, type: $type, title: $title, shortDescription: $shortDescription, color: $color, price: $price, capacityPerSession: $capacityPerSession, maxPeoplePerBooking: $maxPeoplePerBooking, durationMinutes: $durationMinutes, locationUrl: $locationUrl, celebrationPrice: $celebrationPrice, cancellationWindowHours: $cancellationWindowHours, audience: $audience, pieceWarningDays: $pieceWarningDays, hasDelivery: $hasDelivery, image: $image, minProductsPerPerson: $minProductsPerPerson, maxProductsPerPerson: $maxProductsPerPerson, longDescription: $longDescription, gallery: $gallery, categories: $categories, ownPieces: $ownPieces)';
}


}

/// @nodoc
abstract mixin class _$WorkshopDetailCopyWith<$Res> implements $WorkshopDetailCopyWith<$Res> {
  factory _$WorkshopDetailCopyWith(_WorkshopDetail value, $Res Function(_WorkshopDetail) _then) = __$WorkshopDetailCopyWithImpl;
@override @useResult
$Res call({
 int id,@WorkshopTypeConverter() WorkshopType type, String title, String shortDescription, String color, String price, int capacityPerSession, int maxPeoplePerBooking, int durationMinutes, String? locationUrl, String celebrationPrice, int cancellationWindowHours,@WorkshopAudienceConverter() WorkshopAudience audience, int pieceWarningDays, bool hasDelivery, ApiImage? image, int? minProductsPerPerson, int? maxProductsPerPerson, String? longDescription, List<ApiImage> gallery, List<WorkshopCategory> categories, WorkshopOwnPieces? ownPieces
});


@override $ApiImageCopyWith<$Res>? get image;@override $WorkshopOwnPiecesCopyWith<$Res>? get ownPieces;

}
/// @nodoc
class __$WorkshopDetailCopyWithImpl<$Res>
    implements _$WorkshopDetailCopyWith<$Res> {
  __$WorkshopDetailCopyWithImpl(this._self, this._then);

  final _WorkshopDetail _self;
  final $Res Function(_WorkshopDetail) _then;

/// Create a copy of WorkshopDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? title = null,Object? shortDescription = null,Object? color = null,Object? price = null,Object? capacityPerSession = null,Object? maxPeoplePerBooking = null,Object? durationMinutes = null,Object? locationUrl = freezed,Object? celebrationPrice = null,Object? cancellationWindowHours = null,Object? audience = null,Object? pieceWarningDays = null,Object? hasDelivery = null,Object? image = freezed,Object? minProductsPerPerson = freezed,Object? maxProductsPerPerson = freezed,Object? longDescription = freezed,Object? gallery = null,Object? categories = null,Object? ownPieces = freezed,}) {
  return _then(_WorkshopDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WorkshopType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,shortDescription: null == shortDescription ? _self.shortDescription : shortDescription // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,capacityPerSession: null == capacityPerSession ? _self.capacityPerSession : capacityPerSession // ignore: cast_nullable_to_non_nullable
as int,maxPeoplePerBooking: null == maxPeoplePerBooking ? _self.maxPeoplePerBooking : maxPeoplePerBooking // ignore: cast_nullable_to_non_nullable
as int,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,locationUrl: freezed == locationUrl ? _self.locationUrl : locationUrl // ignore: cast_nullable_to_non_nullable
as String?,celebrationPrice: null == celebrationPrice ? _self.celebrationPrice : celebrationPrice // ignore: cast_nullable_to_non_nullable
as String,cancellationWindowHours: null == cancellationWindowHours ? _self.cancellationWindowHours : cancellationWindowHours // ignore: cast_nullable_to_non_nullable
as int,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as WorkshopAudience,pieceWarningDays: null == pieceWarningDays ? _self.pieceWarningDays : pieceWarningDays // ignore: cast_nullable_to_non_nullable
as int,hasDelivery: null == hasDelivery ? _self.hasDelivery : hasDelivery // ignore: cast_nullable_to_non_nullable
as bool,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,minProductsPerPerson: freezed == minProductsPerPerson ? _self.minProductsPerPerson : minProductsPerPerson // ignore: cast_nullable_to_non_nullable
as int?,maxProductsPerPerson: freezed == maxProductsPerPerson ? _self.maxProductsPerPerson : maxProductsPerPerson // ignore: cast_nullable_to_non_nullable
as int?,longDescription: freezed == longDescription ? _self.longDescription : longDescription // ignore: cast_nullable_to_non_nullable
as String?,gallery: null == gallery ? _self._gallery : gallery // ignore: cast_nullable_to_non_nullable
as List<ApiImage>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<WorkshopCategory>,ownPieces: freezed == ownPieces ? _self.ownPieces : ownPieces // ignore: cast_nullable_to_non_nullable
as WorkshopOwnPieces?,
  ));
}

/// Create a copy of WorkshopDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiImageCopyWith<$Res>? get image {
    if (_self.image == null) {
    return null;
  }

  return $ApiImageCopyWith<$Res>(_self.image!, (value) {
    return _then(_self.copyWith(image: value));
  });
}/// Create a copy of WorkshopDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkshopOwnPiecesCopyWith<$Res>? get ownPieces {
    if (_self.ownPieces == null) {
    return null;
  }

  return $WorkshopOwnPiecesCopyWith<$Res>(_self.ownPieces!, (value) {
    return _then(_self.copyWith(ownPieces: value));
  });
}
}

// dart format on
