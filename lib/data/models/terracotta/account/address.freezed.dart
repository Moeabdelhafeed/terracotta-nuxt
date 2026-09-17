// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'address.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Address {

 int get id;/// Customer-chosen name (`"Home"`), and **NULL when they did not
/// give one** — `label` is optional on `POST /api/addresses`, and
/// an address saved without it comes back with `label: null`.
/// Probed live 2026-09-06; the captured fixture happens to have one
/// on every row, which is why this was `required` and would have
/// thrown on the first unnamed address a customer saved.
 String? get label;/// Server-composed single-line address. Display as-is.
 String get addressLine;/// Latitude as a decimal STRING. Read [latitude].
 String get lat;/// Longitude as a decimal STRING. Read [longitude].
 String get lng;/// Contact number for the courier, E.164.
 String get phone;/// Free-text courier note (`"blue door"`).
 String? get notes;// ── Saudi National Address ───────────────────────────────────
 String get buildingNumber; String get street; String get district; String get postalCode;/// The 4-digit secondary number of the national address format.
 String get additionalNumber;/// Flat / unit number. Null when the building has no units.
 String? get unitNumber;/// The 8-character national short code (`"RCTB4329"`). Null until
/// the address is looked up or the customer supplies one.
 String? get shortAddress;// ── Delivery zone ────────────────────────────────────────────
/// Zone the coordinates resolved into; keys into
/// `GET /api/delivery-zones`.
 int get deliveryZoneId;/// Human-readable zone name (`"Riyadh"`). Already localized.
 String get deliveryZone;/// Zone fee as a DECIMAL STRING (`"20.00"`). Preview only — the
/// quote endpoint is authoritative.
 String get deliveryFee;/// Exactly one saved address has this set. Creating the first
/// address sets it automatically; sending `is_default` on a write
/// promotes that one and demotes the rest.
 bool get isDefault;/// Ready-made `maps.google.com/?q=lat,lng` link.
 String get mapUrl;
/// Create a copy of Address
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddressCopyWith<Address> get copyWith => _$AddressCopyWithImpl<Address>(this as Address, _$identity);

  /// Serializes this Address to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Address&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.addressLine, addressLine) || other.addressLine == addressLine)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.buildingNumber, buildingNumber) || other.buildingNumber == buildingNumber)&&(identical(other.street, street) || other.street == street)&&(identical(other.district, district) || other.district == district)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.additionalNumber, additionalNumber) || other.additionalNumber == additionalNumber)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.shortAddress, shortAddress) || other.shortAddress == shortAddress)&&(identical(other.deliveryZoneId, deliveryZoneId) || other.deliveryZoneId == deliveryZoneId)&&(identical(other.deliveryZone, deliveryZone) || other.deliveryZone == deliveryZone)&&(identical(other.deliveryFee, deliveryFee) || other.deliveryFee == deliveryFee)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.mapUrl, mapUrl) || other.mapUrl == mapUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,label,addressLine,lat,lng,phone,notes,buildingNumber,street,district,postalCode,additionalNumber,unitNumber,shortAddress,deliveryZoneId,deliveryZone,deliveryFee,isDefault,mapUrl]);

@override
String toString() {
  return 'Address(id: $id, label: $label, addressLine: $addressLine, lat: $lat, lng: $lng, phone: $phone, notes: $notes, buildingNumber: $buildingNumber, street: $street, district: $district, postalCode: $postalCode, additionalNumber: $additionalNumber, unitNumber: $unitNumber, shortAddress: $shortAddress, deliveryZoneId: $deliveryZoneId, deliveryZone: $deliveryZone, deliveryFee: $deliveryFee, isDefault: $isDefault, mapUrl: $mapUrl)';
}


}

/// @nodoc
abstract mixin class $AddressCopyWith<$Res>  {
  factory $AddressCopyWith(Address value, $Res Function(Address) _then) = _$AddressCopyWithImpl;
@useResult
$Res call({
 int id, String? label, String addressLine, String lat, String lng, String phone, String? notes, String buildingNumber, String street, String district, String postalCode, String additionalNumber, String? unitNumber, String? shortAddress, int deliveryZoneId, String deliveryZone, String deliveryFee, bool isDefault, String mapUrl
});




}
/// @nodoc
class _$AddressCopyWithImpl<$Res>
    implements $AddressCopyWith<$Res> {
  _$AddressCopyWithImpl(this._self, this._then);

  final Address _self;
  final $Res Function(Address) _then;

/// Create a copy of Address
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = freezed,Object? addressLine = null,Object? lat = null,Object? lng = null,Object? phone = null,Object? notes = freezed,Object? buildingNumber = null,Object? street = null,Object? district = null,Object? postalCode = null,Object? additionalNumber = null,Object? unitNumber = freezed,Object? shortAddress = freezed,Object? deliveryZoneId = null,Object? deliveryZone = null,Object? deliveryFee = null,Object? isDefault = null,Object? mapUrl = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,addressLine: null == addressLine ? _self.addressLine : addressLine // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as String,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,buildingNumber: null == buildingNumber ? _self.buildingNumber : buildingNumber // ignore: cast_nullable_to_non_nullable
as String,street: null == street ? _self.street : street // ignore: cast_nullable_to_non_nullable
as String,district: null == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as String,postalCode: null == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String,additionalNumber: null == additionalNumber ? _self.additionalNumber : additionalNumber // ignore: cast_nullable_to_non_nullable
as String,unitNumber: freezed == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String?,shortAddress: freezed == shortAddress ? _self.shortAddress : shortAddress // ignore: cast_nullable_to_non_nullable
as String?,deliveryZoneId: null == deliveryZoneId ? _self.deliveryZoneId : deliveryZoneId // ignore: cast_nullable_to_non_nullable
as int,deliveryZone: null == deliveryZone ? _self.deliveryZone : deliveryZone // ignore: cast_nullable_to_non_nullable
as String,deliveryFee: null == deliveryFee ? _self.deliveryFee : deliveryFee // ignore: cast_nullable_to_non_nullable
as String,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,mapUrl: null == mapUrl ? _self.mapUrl : mapUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Address].
extension AddressPatterns on Address {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Address value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Address() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Address value)  $default,){
final _that = this;
switch (_that) {
case _Address():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Address value)?  $default,){
final _that = this;
switch (_that) {
case _Address() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? label,  String addressLine,  String lat,  String lng,  String phone,  String? notes,  String buildingNumber,  String street,  String district,  String postalCode,  String additionalNumber,  String? unitNumber,  String? shortAddress,  int deliveryZoneId,  String deliveryZone,  String deliveryFee,  bool isDefault,  String mapUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Address() when $default != null:
return $default(_that.id,_that.label,_that.addressLine,_that.lat,_that.lng,_that.phone,_that.notes,_that.buildingNumber,_that.street,_that.district,_that.postalCode,_that.additionalNumber,_that.unitNumber,_that.shortAddress,_that.deliveryZoneId,_that.deliveryZone,_that.deliveryFee,_that.isDefault,_that.mapUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? label,  String addressLine,  String lat,  String lng,  String phone,  String? notes,  String buildingNumber,  String street,  String district,  String postalCode,  String additionalNumber,  String? unitNumber,  String? shortAddress,  int deliveryZoneId,  String deliveryZone,  String deliveryFee,  bool isDefault,  String mapUrl)  $default,) {final _that = this;
switch (_that) {
case _Address():
return $default(_that.id,_that.label,_that.addressLine,_that.lat,_that.lng,_that.phone,_that.notes,_that.buildingNumber,_that.street,_that.district,_that.postalCode,_that.additionalNumber,_that.unitNumber,_that.shortAddress,_that.deliveryZoneId,_that.deliveryZone,_that.deliveryFee,_that.isDefault,_that.mapUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? label,  String addressLine,  String lat,  String lng,  String phone,  String? notes,  String buildingNumber,  String street,  String district,  String postalCode,  String additionalNumber,  String? unitNumber,  String? shortAddress,  int deliveryZoneId,  String deliveryZone,  String deliveryFee,  bool isDefault,  String mapUrl)?  $default,) {final _that = this;
switch (_that) {
case _Address() when $default != null:
return $default(_that.id,_that.label,_that.addressLine,_that.lat,_that.lng,_that.phone,_that.notes,_that.buildingNumber,_that.street,_that.district,_that.postalCode,_that.additionalNumber,_that.unitNumber,_that.shortAddress,_that.deliveryZoneId,_that.deliveryZone,_that.deliveryFee,_that.isDefault,_that.mapUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Address extends Address {
  const _Address({required this.id, this.label, required this.addressLine, required this.lat, required this.lng, required this.phone, this.notes, required this.buildingNumber, required this.street, required this.district, required this.postalCode, required this.additionalNumber, this.unitNumber, this.shortAddress, required this.deliveryZoneId, required this.deliveryZone, required this.deliveryFee, required this.isDefault, required this.mapUrl}): super._();
  factory _Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);

@override final  int id;
/// Customer-chosen name (`"Home"`), and **NULL when they did not
/// give one** — `label` is optional on `POST /api/addresses`, and
/// an address saved without it comes back with `label: null`.
/// Probed live 2026-09-06; the captured fixture happens to have one
/// on every row, which is why this was `required` and would have
/// thrown on the first unnamed address a customer saved.
@override final  String? label;
/// Server-composed single-line address. Display as-is.
@override final  String addressLine;
/// Latitude as a decimal STRING. Read [latitude].
@override final  String lat;
/// Longitude as a decimal STRING. Read [longitude].
@override final  String lng;
/// Contact number for the courier, E.164.
@override final  String phone;
/// Free-text courier note (`"blue door"`).
@override final  String? notes;
// ── Saudi National Address ───────────────────────────────────
@override final  String buildingNumber;
@override final  String street;
@override final  String district;
@override final  String postalCode;
/// The 4-digit secondary number of the national address format.
@override final  String additionalNumber;
/// Flat / unit number. Null when the building has no units.
@override final  String? unitNumber;
/// The 8-character national short code (`"RCTB4329"`). Null until
/// the address is looked up or the customer supplies one.
@override final  String? shortAddress;
// ── Delivery zone ────────────────────────────────────────────
/// Zone the coordinates resolved into; keys into
/// `GET /api/delivery-zones`.
@override final  int deliveryZoneId;
/// Human-readable zone name (`"Riyadh"`). Already localized.
@override final  String deliveryZone;
/// Zone fee as a DECIMAL STRING (`"20.00"`). Preview only — the
/// quote endpoint is authoritative.
@override final  String deliveryFee;
/// Exactly one saved address has this set. Creating the first
/// address sets it automatically; sending `is_default` on a write
/// promotes that one and demotes the rest.
@override final  bool isDefault;
/// Ready-made `maps.google.com/?q=lat,lng` link.
@override final  String mapUrl;

/// Create a copy of Address
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddressCopyWith<_Address> get copyWith => __$AddressCopyWithImpl<_Address>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AddressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Address&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.addressLine, addressLine) || other.addressLine == addressLine)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.buildingNumber, buildingNumber) || other.buildingNumber == buildingNumber)&&(identical(other.street, street) || other.street == street)&&(identical(other.district, district) || other.district == district)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.additionalNumber, additionalNumber) || other.additionalNumber == additionalNumber)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.shortAddress, shortAddress) || other.shortAddress == shortAddress)&&(identical(other.deliveryZoneId, deliveryZoneId) || other.deliveryZoneId == deliveryZoneId)&&(identical(other.deliveryZone, deliveryZone) || other.deliveryZone == deliveryZone)&&(identical(other.deliveryFee, deliveryFee) || other.deliveryFee == deliveryFee)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.mapUrl, mapUrl) || other.mapUrl == mapUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,label,addressLine,lat,lng,phone,notes,buildingNumber,street,district,postalCode,additionalNumber,unitNumber,shortAddress,deliveryZoneId,deliveryZone,deliveryFee,isDefault,mapUrl]);

@override
String toString() {
  return 'Address(id: $id, label: $label, addressLine: $addressLine, lat: $lat, lng: $lng, phone: $phone, notes: $notes, buildingNumber: $buildingNumber, street: $street, district: $district, postalCode: $postalCode, additionalNumber: $additionalNumber, unitNumber: $unitNumber, shortAddress: $shortAddress, deliveryZoneId: $deliveryZoneId, deliveryZone: $deliveryZone, deliveryFee: $deliveryFee, isDefault: $isDefault, mapUrl: $mapUrl)';
}


}

/// @nodoc
abstract mixin class _$AddressCopyWith<$Res> implements $AddressCopyWith<$Res> {
  factory _$AddressCopyWith(_Address value, $Res Function(_Address) _then) = __$AddressCopyWithImpl;
@override @useResult
$Res call({
 int id, String? label, String addressLine, String lat, String lng, String phone, String? notes, String buildingNumber, String street, String district, String postalCode, String additionalNumber, String? unitNumber, String? shortAddress, int deliveryZoneId, String deliveryZone, String deliveryFee, bool isDefault, String mapUrl
});




}
/// @nodoc
class __$AddressCopyWithImpl<$Res>
    implements _$AddressCopyWith<$Res> {
  __$AddressCopyWithImpl(this._self, this._then);

  final _Address _self;
  final $Res Function(_Address) _then;

/// Create a copy of Address
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = freezed,Object? addressLine = null,Object? lat = null,Object? lng = null,Object? phone = null,Object? notes = freezed,Object? buildingNumber = null,Object? street = null,Object? district = null,Object? postalCode = null,Object? additionalNumber = null,Object? unitNumber = freezed,Object? shortAddress = freezed,Object? deliveryZoneId = null,Object? deliveryZone = null,Object? deliveryFee = null,Object? isDefault = null,Object? mapUrl = null,}) {
  return _then(_Address(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,addressLine: null == addressLine ? _self.addressLine : addressLine // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as String,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,buildingNumber: null == buildingNumber ? _self.buildingNumber : buildingNumber // ignore: cast_nullable_to_non_nullable
as String,street: null == street ? _self.street : street // ignore: cast_nullable_to_non_nullable
as String,district: null == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as String,postalCode: null == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String,additionalNumber: null == additionalNumber ? _self.additionalNumber : additionalNumber // ignore: cast_nullable_to_non_nullable
as String,unitNumber: freezed == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String?,shortAddress: freezed == shortAddress ? _self.shortAddress : shortAddress // ignore: cast_nullable_to_non_nullable
as String?,deliveryZoneId: null == deliveryZoneId ? _self.deliveryZoneId : deliveryZoneId // ignore: cast_nullable_to_non_nullable
as int,deliveryZone: null == deliveryZone ? _self.deliveryZone : deliveryZone // ignore: cast_nullable_to_non_nullable
as String,deliveryFee: null == deliveryFee ? _self.deliveryFee : deliveryFee // ignore: cast_nullable_to_non_nullable
as String,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,mapUrl: null == mapUrl ? _self.mapUrl : mapUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
