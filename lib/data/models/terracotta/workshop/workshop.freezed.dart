// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workshop.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Workshop {

 int get id;/// Which booking flow this workshop runs. Unknown CMS values parse
/// to [WorkshopType.unknown] rather than throwing.
@WorkshopTypeConverter() WorkshopType get type;/// Already-localized title for the requested locale. Display as-is.
 String get title;/// Plain-text teaser for the card. The HTML body lives on
/// [WorkshopDetail.longDescription].
 String get shortDescription;/// Admin-set `#RRGGBB` for this specific workshop. See the class doc
/// — this is not a per-type colour.
 String get color;/// Seat price, decimal string (`"25.00"`). `"0.00"` on the
/// catalog-driven types; see the class doc.
 String get price;/// Hard seat ceiling for one session across all bookings.
 int get capacityPerSession;/// Ceiling on `people_count` for a SINGLE booking. Always <=
/// [capacityPerSession]. Cap the seat stepper with this one.
 int get maxPeoplePerBooking;/// Session length in minutes — pair with a slot's `start_time` to
/// show the end of the session.
 int get durationMinutes;/// Maps deep link for the studio. Open externally, not in a webview.
///
/// NULLABLE — verified live on 2026-08-30. The CMS leaves it empty
/// on a workshop that is not open for booking (`Make Your Own
/// Vase`, id 3, on both the list and the detail), and declared
/// required it threw a cast error inside `fromJson` that took the
/// WHOLE list down: five workshops arrived and the page showed the
/// failure state. Show the map link only when there is one.
 String? get locationUrl;/// Cost of the celebration add-on, decimal string. Quoted even when
/// the customer has not asked for it — check the booking's
/// `has_celebration` before charging or displaying it. `"0.00"` here
/// means the add-on is free, not that it is unavailable.
 String get celebrationPrice;/// Cancellation cut-off, in hours before the session. The live
/// capture ranges 1..24 across workshops, so never hard-code 24.
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
 int get pieceWarningDays;/// Whether a finished piece from this workshop can be shipped
/// instead of collected. False means pickup only — hide the whole
/// delivery step.
 bool get hasDelivery;/// Cover image. Null on every workshop in the live capture; render a
/// placeholder rather than assuming it exists.
 ApiImage? get image;/// Minimum products the customer must pick per person. Null on
/// types with no catalog ([WorkshopType.makeYourPiece]).
 int? get minProductsPerPerson;/// Maximum products the customer may pick per person. Null on types
/// with no catalog.
 int? get maxProductsPerPerson;/// The full description, as HTML.
///
/// NOT on the wire yet — the list endpoint returns everything the
/// expanded card shows EXCEPT this, so the backend is adding it.
/// Declared now and read when it appears: with it, opening a card
/// needs no second request at all; without it, the panel falls back
/// to `GET /api/workshops/{id}`.
///
/// Nullable rather than defaulted, because "absent" and "empty" are
/// different answers — absent means ask the detail endpoint.
 String? get longDescription;
/// Create a copy of Workshop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkshopCopyWith<Workshop> get copyWith => _$WorkshopCopyWithImpl<Workshop>(this as Workshop, _$identity);

  /// Serializes this Workshop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Workshop&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.shortDescription, shortDescription) || other.shortDescription == shortDescription)&&(identical(other.color, color) || other.color == color)&&(identical(other.price, price) || other.price == price)&&(identical(other.capacityPerSession, capacityPerSession) || other.capacityPerSession == capacityPerSession)&&(identical(other.maxPeoplePerBooking, maxPeoplePerBooking) || other.maxPeoplePerBooking == maxPeoplePerBooking)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.locationUrl, locationUrl) || other.locationUrl == locationUrl)&&(identical(other.celebrationPrice, celebrationPrice) || other.celebrationPrice == celebrationPrice)&&(identical(other.cancellationWindowHours, cancellationWindowHours) || other.cancellationWindowHours == cancellationWindowHours)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.pieceWarningDays, pieceWarningDays) || other.pieceWarningDays == pieceWarningDays)&&(identical(other.hasDelivery, hasDelivery) || other.hasDelivery == hasDelivery)&&(identical(other.image, image) || other.image == image)&&(identical(other.minProductsPerPerson, minProductsPerPerson) || other.minProductsPerPerson == minProductsPerPerson)&&(identical(other.maxProductsPerPerson, maxProductsPerPerson) || other.maxProductsPerPerson == maxProductsPerPerson)&&(identical(other.longDescription, longDescription) || other.longDescription == longDescription));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,type,title,shortDescription,color,price,capacityPerSession,maxPeoplePerBooking,durationMinutes,locationUrl,celebrationPrice,cancellationWindowHours,audience,pieceWarningDays,hasDelivery,image,minProductsPerPerson,maxProductsPerPerson,longDescription]);

@override
String toString() {
  return 'Workshop(id: $id, type: $type, title: $title, shortDescription: $shortDescription, color: $color, price: $price, capacityPerSession: $capacityPerSession, maxPeoplePerBooking: $maxPeoplePerBooking, durationMinutes: $durationMinutes, locationUrl: $locationUrl, celebrationPrice: $celebrationPrice, cancellationWindowHours: $cancellationWindowHours, audience: $audience, pieceWarningDays: $pieceWarningDays, hasDelivery: $hasDelivery, image: $image, minProductsPerPerson: $minProductsPerPerson, maxProductsPerPerson: $maxProductsPerPerson, longDescription: $longDescription)';
}


}

/// @nodoc
abstract mixin class $WorkshopCopyWith<$Res>  {
  factory $WorkshopCopyWith(Workshop value, $Res Function(Workshop) _then) = _$WorkshopCopyWithImpl;
@useResult
$Res call({
 int id,@WorkshopTypeConverter() WorkshopType type, String title, String shortDescription, String color, String price, int capacityPerSession, int maxPeoplePerBooking, int durationMinutes, String? locationUrl, String celebrationPrice, int cancellationWindowHours,@WorkshopAudienceConverter() WorkshopAudience audience, int pieceWarningDays, bool hasDelivery, ApiImage? image, int? minProductsPerPerson, int? maxProductsPerPerson, String? longDescription
});


$ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class _$WorkshopCopyWithImpl<$Res>
    implements $WorkshopCopyWith<$Res> {
  _$WorkshopCopyWithImpl(this._self, this._then);

  final Workshop _self;
  final $Res Function(Workshop) _then;

/// Create a copy of Workshop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? title = null,Object? shortDescription = null,Object? color = null,Object? price = null,Object? capacityPerSession = null,Object? maxPeoplePerBooking = null,Object? durationMinutes = null,Object? locationUrl = freezed,Object? celebrationPrice = null,Object? cancellationWindowHours = null,Object? audience = null,Object? pieceWarningDays = null,Object? hasDelivery = null,Object? image = freezed,Object? minProductsPerPerson = freezed,Object? maxProductsPerPerson = freezed,Object? longDescription = freezed,}) {
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
as String?,
  ));
}
/// Create a copy of Workshop
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
}
}


/// Adds pattern-matching-related methods to [Workshop].
extension WorkshopPatterns on Workshop {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Workshop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Workshop() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Workshop value)  $default,){
final _that = this;
switch (_that) {
case _Workshop():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Workshop value)?  $default,){
final _that = this;
switch (_that) {
case _Workshop() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @WorkshopTypeConverter()  WorkshopType type,  String title,  String shortDescription,  String color,  String price,  int capacityPerSession,  int maxPeoplePerBooking,  int durationMinutes,  String? locationUrl,  String celebrationPrice,  int cancellationWindowHours, @WorkshopAudienceConverter()  WorkshopAudience audience,  int pieceWarningDays,  bool hasDelivery,  ApiImage? image,  int? minProductsPerPerson,  int? maxProductsPerPerson,  String? longDescription)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Workshop() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.shortDescription,_that.color,_that.price,_that.capacityPerSession,_that.maxPeoplePerBooking,_that.durationMinutes,_that.locationUrl,_that.celebrationPrice,_that.cancellationWindowHours,_that.audience,_that.pieceWarningDays,_that.hasDelivery,_that.image,_that.minProductsPerPerson,_that.maxProductsPerPerson,_that.longDescription);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @WorkshopTypeConverter()  WorkshopType type,  String title,  String shortDescription,  String color,  String price,  int capacityPerSession,  int maxPeoplePerBooking,  int durationMinutes,  String? locationUrl,  String celebrationPrice,  int cancellationWindowHours, @WorkshopAudienceConverter()  WorkshopAudience audience,  int pieceWarningDays,  bool hasDelivery,  ApiImage? image,  int? minProductsPerPerson,  int? maxProductsPerPerson,  String? longDescription)  $default,) {final _that = this;
switch (_that) {
case _Workshop():
return $default(_that.id,_that.type,_that.title,_that.shortDescription,_that.color,_that.price,_that.capacityPerSession,_that.maxPeoplePerBooking,_that.durationMinutes,_that.locationUrl,_that.celebrationPrice,_that.cancellationWindowHours,_that.audience,_that.pieceWarningDays,_that.hasDelivery,_that.image,_that.minProductsPerPerson,_that.maxProductsPerPerson,_that.longDescription);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @WorkshopTypeConverter()  WorkshopType type,  String title,  String shortDescription,  String color,  String price,  int capacityPerSession,  int maxPeoplePerBooking,  int durationMinutes,  String? locationUrl,  String celebrationPrice,  int cancellationWindowHours, @WorkshopAudienceConverter()  WorkshopAudience audience,  int pieceWarningDays,  bool hasDelivery,  ApiImage? image,  int? minProductsPerPerson,  int? maxProductsPerPerson,  String? longDescription)?  $default,) {final _that = this;
switch (_that) {
case _Workshop() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.shortDescription,_that.color,_that.price,_that.capacityPerSession,_that.maxPeoplePerBooking,_that.durationMinutes,_that.locationUrl,_that.celebrationPrice,_that.cancellationWindowHours,_that.audience,_that.pieceWarningDays,_that.hasDelivery,_that.image,_that.minProductsPerPerson,_that.maxProductsPerPerson,_that.longDescription);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Workshop extends Workshop {
  const _Workshop({required this.id, @WorkshopTypeConverter() required this.type, required this.title, required this.shortDescription, required this.color, required this.price, required this.capacityPerSession, required this.maxPeoplePerBooking, required this.durationMinutes, this.locationUrl, required this.celebrationPrice, required this.cancellationWindowHours, @WorkshopAudienceConverter() this.audience = WorkshopAudience.mixed, this.pieceWarningDays = 7, required this.hasDelivery, this.image, this.minProductsPerPerson, this.maxProductsPerPerson, this.longDescription}): super._();
  factory _Workshop.fromJson(Map<String, dynamic> json) => _$WorkshopFromJson(json);

@override final  int id;
/// Which booking flow this workshop runs. Unknown CMS values parse
/// to [WorkshopType.unknown] rather than throwing.
@override@WorkshopTypeConverter() final  WorkshopType type;
/// Already-localized title for the requested locale. Display as-is.
@override final  String title;
/// Plain-text teaser for the card. The HTML body lives on
/// [WorkshopDetail.longDescription].
@override final  String shortDescription;
/// Admin-set `#RRGGBB` for this specific workshop. See the class doc
/// — this is not a per-type colour.
@override final  String color;
/// Seat price, decimal string (`"25.00"`). `"0.00"` on the
/// catalog-driven types; see the class doc.
@override final  String price;
/// Hard seat ceiling for one session across all bookings.
@override final  int capacityPerSession;
/// Ceiling on `people_count` for a SINGLE booking. Always <=
/// [capacityPerSession]. Cap the seat stepper with this one.
@override final  int maxPeoplePerBooking;
/// Session length in minutes — pair with a slot's `start_time` to
/// show the end of the session.
@override final  int durationMinutes;
/// Maps deep link for the studio. Open externally, not in a webview.
///
/// NULLABLE — verified live on 2026-08-30. The CMS leaves it empty
/// on a workshop that is not open for booking (`Make Your Own
/// Vase`, id 3, on both the list and the detail), and declared
/// required it threw a cast error inside `fromJson` that took the
/// WHOLE list down: five workshops arrived and the page showed the
/// failure state. Show the map link only when there is one.
@override final  String? locationUrl;
/// Cost of the celebration add-on, decimal string. Quoted even when
/// the customer has not asked for it — check the booking's
/// `has_celebration` before charging or displaying it. `"0.00"` here
/// means the add-on is free, not that it is unavailable.
@override final  String celebrationPrice;
/// Cancellation cut-off, in hours before the session. The live
/// capture ranges 1..24 across workshops, so never hard-code 24.
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
/// Whether a finished piece from this workshop can be shipped
/// instead of collected. False means pickup only — hide the whole
/// delivery step.
@override final  bool hasDelivery;
/// Cover image. Null on every workshop in the live capture; render a
/// placeholder rather than assuming it exists.
@override final  ApiImage? image;
/// Minimum products the customer must pick per person. Null on
/// types with no catalog ([WorkshopType.makeYourPiece]).
@override final  int? minProductsPerPerson;
/// Maximum products the customer may pick per person. Null on types
/// with no catalog.
@override final  int? maxProductsPerPerson;
/// The full description, as HTML.
///
/// NOT on the wire yet — the list endpoint returns everything the
/// expanded card shows EXCEPT this, so the backend is adding it.
/// Declared now and read when it appears: with it, opening a card
/// needs no second request at all; without it, the panel falls back
/// to `GET /api/workshops/{id}`.
///
/// Nullable rather than defaulted, because "absent" and "empty" are
/// different answers — absent means ask the detail endpoint.
@override final  String? longDescription;

/// Create a copy of Workshop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkshopCopyWith<_Workshop> get copyWith => __$WorkshopCopyWithImpl<_Workshop>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkshopToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Workshop&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.shortDescription, shortDescription) || other.shortDescription == shortDescription)&&(identical(other.color, color) || other.color == color)&&(identical(other.price, price) || other.price == price)&&(identical(other.capacityPerSession, capacityPerSession) || other.capacityPerSession == capacityPerSession)&&(identical(other.maxPeoplePerBooking, maxPeoplePerBooking) || other.maxPeoplePerBooking == maxPeoplePerBooking)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.locationUrl, locationUrl) || other.locationUrl == locationUrl)&&(identical(other.celebrationPrice, celebrationPrice) || other.celebrationPrice == celebrationPrice)&&(identical(other.cancellationWindowHours, cancellationWindowHours) || other.cancellationWindowHours == cancellationWindowHours)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.pieceWarningDays, pieceWarningDays) || other.pieceWarningDays == pieceWarningDays)&&(identical(other.hasDelivery, hasDelivery) || other.hasDelivery == hasDelivery)&&(identical(other.image, image) || other.image == image)&&(identical(other.minProductsPerPerson, minProductsPerPerson) || other.minProductsPerPerson == minProductsPerPerson)&&(identical(other.maxProductsPerPerson, maxProductsPerPerson) || other.maxProductsPerPerson == maxProductsPerPerson)&&(identical(other.longDescription, longDescription) || other.longDescription == longDescription));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,type,title,shortDescription,color,price,capacityPerSession,maxPeoplePerBooking,durationMinutes,locationUrl,celebrationPrice,cancellationWindowHours,audience,pieceWarningDays,hasDelivery,image,minProductsPerPerson,maxProductsPerPerson,longDescription]);

@override
String toString() {
  return 'Workshop(id: $id, type: $type, title: $title, shortDescription: $shortDescription, color: $color, price: $price, capacityPerSession: $capacityPerSession, maxPeoplePerBooking: $maxPeoplePerBooking, durationMinutes: $durationMinutes, locationUrl: $locationUrl, celebrationPrice: $celebrationPrice, cancellationWindowHours: $cancellationWindowHours, audience: $audience, pieceWarningDays: $pieceWarningDays, hasDelivery: $hasDelivery, image: $image, minProductsPerPerson: $minProductsPerPerson, maxProductsPerPerson: $maxProductsPerPerson, longDescription: $longDescription)';
}


}

/// @nodoc
abstract mixin class _$WorkshopCopyWith<$Res> implements $WorkshopCopyWith<$Res> {
  factory _$WorkshopCopyWith(_Workshop value, $Res Function(_Workshop) _then) = __$WorkshopCopyWithImpl;
@override @useResult
$Res call({
 int id,@WorkshopTypeConverter() WorkshopType type, String title, String shortDescription, String color, String price, int capacityPerSession, int maxPeoplePerBooking, int durationMinutes, String? locationUrl, String celebrationPrice, int cancellationWindowHours,@WorkshopAudienceConverter() WorkshopAudience audience, int pieceWarningDays, bool hasDelivery, ApiImage? image, int? minProductsPerPerson, int? maxProductsPerPerson, String? longDescription
});


@override $ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class __$WorkshopCopyWithImpl<$Res>
    implements _$WorkshopCopyWith<$Res> {
  __$WorkshopCopyWithImpl(this._self, this._then);

  final _Workshop _self;
  final $Res Function(_Workshop) _then;

/// Create a copy of Workshop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? title = null,Object? shortDescription = null,Object? color = null,Object? price = null,Object? capacityPerSession = null,Object? maxPeoplePerBooking = null,Object? durationMinutes = null,Object? locationUrl = freezed,Object? celebrationPrice = null,Object? cancellationWindowHours = null,Object? audience = null,Object? pieceWarningDays = null,Object? hasDelivery = null,Object? image = freezed,Object? minProductsPerPerson = freezed,Object? maxProductsPerPerson = freezed,Object? longDescription = freezed,}) {
  return _then(_Workshop(
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
as String?,
  ));
}

/// Create a copy of Workshop
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
}
}

// dart format on
