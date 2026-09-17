// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'price_quote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PriceQuote {

// ---- common core: present in every quote ----
/// Line-items total before delivery, discount, VAT and wallet.
 String get subtotal;/// Amount taken off by [discountCode]. `"0.00"` when none applied.
 String get discountAmount;/// What the customer pays. VAT-INCLUSIVE — do not add [vatAmount].
 String get totalPrice;/// Wallet credit consumed by this quote. `"0.00"` when none.
 String get walletApplied;/// [totalPrice] minus [walletApplied] — what the payment step
/// charges. `"0.00"` means already settled; see [isAlreadySettled].
 String get amountDue;/// The discount code the quote was priced with. Null when no code
/// was sent or the code did not apply.
 String? get discountCode;// ---- tax block: absent from the gift quote ----
/// VAT percentage as a decimal string (`"15.00"`, `"0.00"`).
 String? get vatRate;/// VAT already INSIDE [totalPrice]. Display only. Never add it.
 String? get vatAmount;/// [totalPrice] with the inclusive VAT backed out.
 String? get totalExcludingVat;// ---- delivery: shop + gift quotes ----
/// Shipping charge folded into [totalPrice]. Absent on the workshop
/// booking quote, which has nothing to ship.
 String? get deliveryFee;/// Human-readable zone the fee was priced for (`"Riyadh"`). Shop
/// quote only.
 String? get deliveryZone;// ---- gift flow only ----
/// Face value of the gift being bought. Gift quote only.
 String? get giftValue;// ---- workshop booking flow only ----
/// Workshop being priced.
 int? get workshopId;/// The specific dated slot being priced.
 int? get workshopSlotId;/// Seats requested.
 int? get peopleCount;/// Price of one seat.
 String? get unitPrice;/// Whether the celebration add-on was included in this quote.
 bool? get hasCelebration;/// Cost of the celebration add-on (quoted whether or not
/// [hasCelebration] is true — check the flag before showing it).
 String? get celebrationPrice;// ---- delivery flow only ----
/// Whether the delivery fee has ALREADY been settled.
///
/// The fee is charged once: switching a finished piece to pickup
/// and back is free, and what was paid is never refunded. `true`
/// means there is nothing left to take, and the screen says so
/// instead of asking for the money a second time. Absent on every
/// other quote.
 bool? get alreadyPaid;
/// Create a copy of PriceQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceQuoteCopyWith<PriceQuote> get copyWith => _$PriceQuoteCopyWithImpl<PriceQuote>(this as PriceQuote, _$identity);

  /// Serializes this PriceQuote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceQuote&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice)&&(identical(other.walletApplied, walletApplied) || other.walletApplied == walletApplied)&&(identical(other.amountDue, amountDue) || other.amountDue == amountDue)&&(identical(other.discountCode, discountCode) || other.discountCode == discountCode)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.totalExcludingVat, totalExcludingVat) || other.totalExcludingVat == totalExcludingVat)&&(identical(other.deliveryFee, deliveryFee) || other.deliveryFee == deliveryFee)&&(identical(other.deliveryZone, deliveryZone) || other.deliveryZone == deliveryZone)&&(identical(other.giftValue, giftValue) || other.giftValue == giftValue)&&(identical(other.workshopId, workshopId) || other.workshopId == workshopId)&&(identical(other.workshopSlotId, workshopSlotId) || other.workshopSlotId == workshopSlotId)&&(identical(other.peopleCount, peopleCount) || other.peopleCount == peopleCount)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.hasCelebration, hasCelebration) || other.hasCelebration == hasCelebration)&&(identical(other.celebrationPrice, celebrationPrice) || other.celebrationPrice == celebrationPrice)&&(identical(other.alreadyPaid, alreadyPaid) || other.alreadyPaid == alreadyPaid));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,subtotal,discountAmount,totalPrice,walletApplied,amountDue,discountCode,vatRate,vatAmount,totalExcludingVat,deliveryFee,deliveryZone,giftValue,workshopId,workshopSlotId,peopleCount,unitPrice,hasCelebration,celebrationPrice,alreadyPaid]);

@override
String toString() {
  return 'PriceQuote(subtotal: $subtotal, discountAmount: $discountAmount, totalPrice: $totalPrice, walletApplied: $walletApplied, amountDue: $amountDue, discountCode: $discountCode, vatRate: $vatRate, vatAmount: $vatAmount, totalExcludingVat: $totalExcludingVat, deliveryFee: $deliveryFee, deliveryZone: $deliveryZone, giftValue: $giftValue, workshopId: $workshopId, workshopSlotId: $workshopSlotId, peopleCount: $peopleCount, unitPrice: $unitPrice, hasCelebration: $hasCelebration, celebrationPrice: $celebrationPrice, alreadyPaid: $alreadyPaid)';
}


}

/// @nodoc
abstract mixin class $PriceQuoteCopyWith<$Res>  {
  factory $PriceQuoteCopyWith(PriceQuote value, $Res Function(PriceQuote) _then) = _$PriceQuoteCopyWithImpl;
@useResult
$Res call({
 String subtotal, String discountAmount, String totalPrice, String walletApplied, String amountDue, String? discountCode, String? vatRate, String? vatAmount, String? totalExcludingVat, String? deliveryFee, String? deliveryZone, String? giftValue, int? workshopId, int? workshopSlotId, int? peopleCount, String? unitPrice, bool? hasCelebration, String? celebrationPrice, bool? alreadyPaid
});




}
/// @nodoc
class _$PriceQuoteCopyWithImpl<$Res>
    implements $PriceQuoteCopyWith<$Res> {
  _$PriceQuoteCopyWithImpl(this._self, this._then);

  final PriceQuote _self;
  final $Res Function(PriceQuote) _then;

/// Create a copy of PriceQuote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subtotal = null,Object? discountAmount = null,Object? totalPrice = null,Object? walletApplied = null,Object? amountDue = null,Object? discountCode = freezed,Object? vatRate = freezed,Object? vatAmount = freezed,Object? totalExcludingVat = freezed,Object? deliveryFee = freezed,Object? deliveryZone = freezed,Object? giftValue = freezed,Object? workshopId = freezed,Object? workshopSlotId = freezed,Object? peopleCount = freezed,Object? unitPrice = freezed,Object? hasCelebration = freezed,Object? celebrationPrice = freezed,Object? alreadyPaid = freezed,}) {
  return _then(_self.copyWith(
subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as String,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as String,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as String,walletApplied: null == walletApplied ? _self.walletApplied : walletApplied // ignore: cast_nullable_to_non_nullable
as String,amountDue: null == amountDue ? _self.amountDue : amountDue // ignore: cast_nullable_to_non_nullable
as String,discountCode: freezed == discountCode ? _self.discountCode : discountCode // ignore: cast_nullable_to_non_nullable
as String?,vatRate: freezed == vatRate ? _self.vatRate : vatRate // ignore: cast_nullable_to_non_nullable
as String?,vatAmount: freezed == vatAmount ? _self.vatAmount : vatAmount // ignore: cast_nullable_to_non_nullable
as String?,totalExcludingVat: freezed == totalExcludingVat ? _self.totalExcludingVat : totalExcludingVat // ignore: cast_nullable_to_non_nullable
as String?,deliveryFee: freezed == deliveryFee ? _self.deliveryFee : deliveryFee // ignore: cast_nullable_to_non_nullable
as String?,deliveryZone: freezed == deliveryZone ? _self.deliveryZone : deliveryZone // ignore: cast_nullable_to_non_nullable
as String?,giftValue: freezed == giftValue ? _self.giftValue : giftValue // ignore: cast_nullable_to_non_nullable
as String?,workshopId: freezed == workshopId ? _self.workshopId : workshopId // ignore: cast_nullable_to_non_nullable
as int?,workshopSlotId: freezed == workshopSlotId ? _self.workshopSlotId : workshopSlotId // ignore: cast_nullable_to_non_nullable
as int?,peopleCount: freezed == peopleCount ? _self.peopleCount : peopleCount // ignore: cast_nullable_to_non_nullable
as int?,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String?,hasCelebration: freezed == hasCelebration ? _self.hasCelebration : hasCelebration // ignore: cast_nullable_to_non_nullable
as bool?,celebrationPrice: freezed == celebrationPrice ? _self.celebrationPrice : celebrationPrice // ignore: cast_nullable_to_non_nullable
as String?,alreadyPaid: freezed == alreadyPaid ? _self.alreadyPaid : alreadyPaid // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [PriceQuote].
extension PriceQuotePatterns on PriceQuote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PriceQuote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PriceQuote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PriceQuote value)  $default,){
final _that = this;
switch (_that) {
case _PriceQuote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PriceQuote value)?  $default,){
final _that = this;
switch (_that) {
case _PriceQuote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String subtotal,  String discountAmount,  String totalPrice,  String walletApplied,  String amountDue,  String? discountCode,  String? vatRate,  String? vatAmount,  String? totalExcludingVat,  String? deliveryFee,  String? deliveryZone,  String? giftValue,  int? workshopId,  int? workshopSlotId,  int? peopleCount,  String? unitPrice,  bool? hasCelebration,  String? celebrationPrice,  bool? alreadyPaid)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PriceQuote() when $default != null:
return $default(_that.subtotal,_that.discountAmount,_that.totalPrice,_that.walletApplied,_that.amountDue,_that.discountCode,_that.vatRate,_that.vatAmount,_that.totalExcludingVat,_that.deliveryFee,_that.deliveryZone,_that.giftValue,_that.workshopId,_that.workshopSlotId,_that.peopleCount,_that.unitPrice,_that.hasCelebration,_that.celebrationPrice,_that.alreadyPaid);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String subtotal,  String discountAmount,  String totalPrice,  String walletApplied,  String amountDue,  String? discountCode,  String? vatRate,  String? vatAmount,  String? totalExcludingVat,  String? deliveryFee,  String? deliveryZone,  String? giftValue,  int? workshopId,  int? workshopSlotId,  int? peopleCount,  String? unitPrice,  bool? hasCelebration,  String? celebrationPrice,  bool? alreadyPaid)  $default,) {final _that = this;
switch (_that) {
case _PriceQuote():
return $default(_that.subtotal,_that.discountAmount,_that.totalPrice,_that.walletApplied,_that.amountDue,_that.discountCode,_that.vatRate,_that.vatAmount,_that.totalExcludingVat,_that.deliveryFee,_that.deliveryZone,_that.giftValue,_that.workshopId,_that.workshopSlotId,_that.peopleCount,_that.unitPrice,_that.hasCelebration,_that.celebrationPrice,_that.alreadyPaid);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String subtotal,  String discountAmount,  String totalPrice,  String walletApplied,  String amountDue,  String? discountCode,  String? vatRate,  String? vatAmount,  String? totalExcludingVat,  String? deliveryFee,  String? deliveryZone,  String? giftValue,  int? workshopId,  int? workshopSlotId,  int? peopleCount,  String? unitPrice,  bool? hasCelebration,  String? celebrationPrice,  bool? alreadyPaid)?  $default,) {final _that = this;
switch (_that) {
case _PriceQuote() when $default != null:
return $default(_that.subtotal,_that.discountAmount,_that.totalPrice,_that.walletApplied,_that.amountDue,_that.discountCode,_that.vatRate,_that.vatAmount,_that.totalExcludingVat,_that.deliveryFee,_that.deliveryZone,_that.giftValue,_that.workshopId,_that.workshopSlotId,_that.peopleCount,_that.unitPrice,_that.hasCelebration,_that.celebrationPrice,_that.alreadyPaid);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PriceQuote extends PriceQuote {
  const _PriceQuote({required this.subtotal, required this.discountAmount, required this.totalPrice, required this.walletApplied, required this.amountDue, this.discountCode, this.vatRate, this.vatAmount, this.totalExcludingVat, this.deliveryFee, this.deliveryZone, this.giftValue, this.workshopId, this.workshopSlotId, this.peopleCount, this.unitPrice, this.hasCelebration, this.celebrationPrice, this.alreadyPaid}): super._();
  factory _PriceQuote.fromJson(Map<String, dynamic> json) => _$PriceQuoteFromJson(json);

// ---- common core: present in every quote ----
/// Line-items total before delivery, discount, VAT and wallet.
@override final  String subtotal;
/// Amount taken off by [discountCode]. `"0.00"` when none applied.
@override final  String discountAmount;
/// What the customer pays. VAT-INCLUSIVE — do not add [vatAmount].
@override final  String totalPrice;
/// Wallet credit consumed by this quote. `"0.00"` when none.
@override final  String walletApplied;
/// [totalPrice] minus [walletApplied] — what the payment step
/// charges. `"0.00"` means already settled; see [isAlreadySettled].
@override final  String amountDue;
/// The discount code the quote was priced with. Null when no code
/// was sent or the code did not apply.
@override final  String? discountCode;
// ---- tax block: absent from the gift quote ----
/// VAT percentage as a decimal string (`"15.00"`, `"0.00"`).
@override final  String? vatRate;
/// VAT already INSIDE [totalPrice]. Display only. Never add it.
@override final  String? vatAmount;
/// [totalPrice] with the inclusive VAT backed out.
@override final  String? totalExcludingVat;
// ---- delivery: shop + gift quotes ----
/// Shipping charge folded into [totalPrice]. Absent on the workshop
/// booking quote, which has nothing to ship.
@override final  String? deliveryFee;
/// Human-readable zone the fee was priced for (`"Riyadh"`). Shop
/// quote only.
@override final  String? deliveryZone;
// ---- gift flow only ----
/// Face value of the gift being bought. Gift quote only.
@override final  String? giftValue;
// ---- workshop booking flow only ----
/// Workshop being priced.
@override final  int? workshopId;
/// The specific dated slot being priced.
@override final  int? workshopSlotId;
/// Seats requested.
@override final  int? peopleCount;
/// Price of one seat.
@override final  String? unitPrice;
/// Whether the celebration add-on was included in this quote.
@override final  bool? hasCelebration;
/// Cost of the celebration add-on (quoted whether or not
/// [hasCelebration] is true — check the flag before showing it).
@override final  String? celebrationPrice;
// ---- delivery flow only ----
/// Whether the delivery fee has ALREADY been settled.
///
/// The fee is charged once: switching a finished piece to pickup
/// and back is free, and what was paid is never refunded. `true`
/// means there is nothing left to take, and the screen says so
/// instead of asking for the money a second time. Absent on every
/// other quote.
@override final  bool? alreadyPaid;

/// Create a copy of PriceQuote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceQuoteCopyWith<_PriceQuote> get copyWith => __$PriceQuoteCopyWithImpl<_PriceQuote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PriceQuoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriceQuote&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice)&&(identical(other.walletApplied, walletApplied) || other.walletApplied == walletApplied)&&(identical(other.amountDue, amountDue) || other.amountDue == amountDue)&&(identical(other.discountCode, discountCode) || other.discountCode == discountCode)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.totalExcludingVat, totalExcludingVat) || other.totalExcludingVat == totalExcludingVat)&&(identical(other.deliveryFee, deliveryFee) || other.deliveryFee == deliveryFee)&&(identical(other.deliveryZone, deliveryZone) || other.deliveryZone == deliveryZone)&&(identical(other.giftValue, giftValue) || other.giftValue == giftValue)&&(identical(other.workshopId, workshopId) || other.workshopId == workshopId)&&(identical(other.workshopSlotId, workshopSlotId) || other.workshopSlotId == workshopSlotId)&&(identical(other.peopleCount, peopleCount) || other.peopleCount == peopleCount)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.hasCelebration, hasCelebration) || other.hasCelebration == hasCelebration)&&(identical(other.celebrationPrice, celebrationPrice) || other.celebrationPrice == celebrationPrice)&&(identical(other.alreadyPaid, alreadyPaid) || other.alreadyPaid == alreadyPaid));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,subtotal,discountAmount,totalPrice,walletApplied,amountDue,discountCode,vatRate,vatAmount,totalExcludingVat,deliveryFee,deliveryZone,giftValue,workshopId,workshopSlotId,peopleCount,unitPrice,hasCelebration,celebrationPrice,alreadyPaid]);

@override
String toString() {
  return 'PriceQuote(subtotal: $subtotal, discountAmount: $discountAmount, totalPrice: $totalPrice, walletApplied: $walletApplied, amountDue: $amountDue, discountCode: $discountCode, vatRate: $vatRate, vatAmount: $vatAmount, totalExcludingVat: $totalExcludingVat, deliveryFee: $deliveryFee, deliveryZone: $deliveryZone, giftValue: $giftValue, workshopId: $workshopId, workshopSlotId: $workshopSlotId, peopleCount: $peopleCount, unitPrice: $unitPrice, hasCelebration: $hasCelebration, celebrationPrice: $celebrationPrice, alreadyPaid: $alreadyPaid)';
}


}

/// @nodoc
abstract mixin class _$PriceQuoteCopyWith<$Res> implements $PriceQuoteCopyWith<$Res> {
  factory _$PriceQuoteCopyWith(_PriceQuote value, $Res Function(_PriceQuote) _then) = __$PriceQuoteCopyWithImpl;
@override @useResult
$Res call({
 String subtotal, String discountAmount, String totalPrice, String walletApplied, String amountDue, String? discountCode, String? vatRate, String? vatAmount, String? totalExcludingVat, String? deliveryFee, String? deliveryZone, String? giftValue, int? workshopId, int? workshopSlotId, int? peopleCount, String? unitPrice, bool? hasCelebration, String? celebrationPrice, bool? alreadyPaid
});




}
/// @nodoc
class __$PriceQuoteCopyWithImpl<$Res>
    implements _$PriceQuoteCopyWith<$Res> {
  __$PriceQuoteCopyWithImpl(this._self, this._then);

  final _PriceQuote _self;
  final $Res Function(_PriceQuote) _then;

/// Create a copy of PriceQuote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subtotal = null,Object? discountAmount = null,Object? totalPrice = null,Object? walletApplied = null,Object? amountDue = null,Object? discountCode = freezed,Object? vatRate = freezed,Object? vatAmount = freezed,Object? totalExcludingVat = freezed,Object? deliveryFee = freezed,Object? deliveryZone = freezed,Object? giftValue = freezed,Object? workshopId = freezed,Object? workshopSlotId = freezed,Object? peopleCount = freezed,Object? unitPrice = freezed,Object? hasCelebration = freezed,Object? celebrationPrice = freezed,Object? alreadyPaid = freezed,}) {
  return _then(_PriceQuote(
subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as String,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as String,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as String,walletApplied: null == walletApplied ? _self.walletApplied : walletApplied // ignore: cast_nullable_to_non_nullable
as String,amountDue: null == amountDue ? _self.amountDue : amountDue // ignore: cast_nullable_to_non_nullable
as String,discountCode: freezed == discountCode ? _self.discountCode : discountCode // ignore: cast_nullable_to_non_nullable
as String?,vatRate: freezed == vatRate ? _self.vatRate : vatRate // ignore: cast_nullable_to_non_nullable
as String?,vatAmount: freezed == vatAmount ? _self.vatAmount : vatAmount // ignore: cast_nullable_to_non_nullable
as String?,totalExcludingVat: freezed == totalExcludingVat ? _self.totalExcludingVat : totalExcludingVat // ignore: cast_nullable_to_non_nullable
as String?,deliveryFee: freezed == deliveryFee ? _self.deliveryFee : deliveryFee // ignore: cast_nullable_to_non_nullable
as String?,deliveryZone: freezed == deliveryZone ? _self.deliveryZone : deliveryZone // ignore: cast_nullable_to_non_nullable
as String?,giftValue: freezed == giftValue ? _self.giftValue : giftValue // ignore: cast_nullable_to_non_nullable
as String?,workshopId: freezed == workshopId ? _self.workshopId : workshopId // ignore: cast_nullable_to_non_nullable
as int?,workshopSlotId: freezed == workshopSlotId ? _self.workshopSlotId : workshopSlotId // ignore: cast_nullable_to_non_nullable
as int?,peopleCount: freezed == peopleCount ? _self.peopleCount : peopleCount // ignore: cast_nullable_to_non_nullable
as int?,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String?,hasCelebration: freezed == hasCelebration ? _self.hasCelebration : hasCelebration // ignore: cast_nullable_to_non_nullable
as bool?,celebrationPrice: freezed == celebrationPrice ? _self.celebrationPrice : celebrationPrice // ignore: cast_nullable_to_non_nullable
as String?,alreadyPaid: freezed == alreadyPaid ? _self.alreadyPaid : alreadyPaid // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
