// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Booking {

// ---- identity ----
/// The booking's own id — the `{id}` in
/// `GET /api/workshops/bookings/{id}`.
 int get id;// ---- the workshop and the slot ----
/// The workshop this booking is for.
 int get workshopId;/// Already-localized workshop name. Display as-is.
 String get workshopTitle;/// Workshop cover art. **Null in every capture** — as is `image`
/// on the workshop payloads themselves — so the shape is unproven.
/// [ApiImage] is the bet because it is the shape behind every
/// other image key in this API. Paint via `image.display`.
 ApiImage? get workshopImage;/// The specific dated session that was booked.
 int get workshopSlotId;/// Bare calendar date, `"2026-08-28"`. A String, not a DateTime —
/// see the class doc.
 String get bookingDate;/// Asia/Riyadh clock string, `"13:00"`. NOT a DateTime; parsing it
/// as one throws.
 String get startTime;/// Asia/Riyadh clock string, `"14:30"`. NOT a DateTime.
 String get endTime;/// Maps link for the studio. Hand it to `launchUrl` with
/// `LaunchMode.externalApplication`.
///
/// NULLABLE — verified live on 2026-08-30. The CMS leaves it empty
/// on a workshop that is not open for booking, and declared
/// required it threw inside `fromJson` and took the whole payload
/// with it. Show the map link only when there is one.
 String? get locationUrl;/// Seats booked. Capped by the workshop's `max_people_per_booking`.
 int get peopleCount;// ---- money: all decimal strings ----
/// Price of ONE seat. `"0.00"` on the catalogue-priced families —
/// that is not an error, see the class doc.
 String get unitPrice;/// Whether the celebration add-on was bought.
 bool get hasCelebration;/// Cost of the celebration add-on. Quoted whether or not
/// [hasCelebration] is true — check the flag before showing it.
 String get celebrationPrice;/// Seats + products + celebration, before discount, VAT and
/// wallet. Server-computed; do not recompute.
 String get subtotal;/// Amount taken off by [discountCode]. `"0.00"` when none.
 String get discountAmount;/// The code that was applied, or null when none was.
 String? get discountCode;/// What the booking costs. VAT-INCLUSIVE — never add [vatAmount].
 String get totalPrice;/// VAT percentage as a decimal string (`"0.00"` in the captures —
/// the demo tenant has tax switched off).
 String get vatRate;/// VAT already INSIDE [totalPrice]. Disclosure only.
 String get vatAmount;/// Wallet credit consumed. `"0.00"` when none.
 String get walletApplied;/// [totalPrice] minus [walletApplied] — what the payment step
/// charges. `"0.00"` means settled; see [isAlreadySettled].
 String get amountDue;// ---- state ----
/// Raw lifecycle value (`"pending_payment"`). Read it typed via
/// [statusEnum]; keep this string for display.
 String get status;/// Raw payment value (`"unpaid"` is the only one captured). Left
/// as a String deliberately — the vocabulary is unverified, so no
/// enum here would be honest.
 String get paymentStatus;/// When the customer scanned in at the studio. Null until they do.
 DateTime? get checkedInAt;/// When the booking was created. Full ISO-8601 with offset.
 DateTime get createdAt;/// End of the edit window — creation + the workshop's
/// `cancellation_window_hours`. Nullable: see the class doc.
/// **[canEdit] is the authority, not this timestamp** — the
/// captures show `can_edit: false` while this is still in the
/// future, because an unpaid booking cannot be edited at all.
 DateTime? get editableUntil;/// End of the payment window — only ~15 minutes after
/// [createdAt] in the captures. The seat is released after it.
/// Nullable: a paid booking has nothing left to expire.
 DateTime? get paymentExpiresAt;/// Opaque token to encode into the check-in QR. A String — never
/// parse it to int.
 String get qrValue;/// The same token, for the studio to key in by hand when a scan
/// fails. Identical to [qrValue] in every capture, but do not
/// assume that holds.
 String get checkinCode;/// Server's verdict on editability. Trust this, not [editableUntil].
 bool get canEdit;/// Server's verdict on cancellability. Trust this, not the clock.
 bool get canCancel;/// Photos attached to the booking. `[]` in every capture, so the
/// element shape is unproven — [ApiImage] is the bet, matching
/// every other image list in this API.
 List<ApiImage> get images;/// Catalogue items picked at booking time. Empty for the flat-rate
/// `make_your_piece` family; the source of [subtotal] for the
/// others.
 List<BookingProduct> get products;/// The pieces made in this session, grouped by the labels the
/// customer typed when uploading photographs.
 List<BookingPiece> get pieces;/// How many pieces this booking is expected to end up with.
///
/// A CEILING for the catalogue types — the sum of the quantities
/// bought, enforced server-side, because a key past it would be an
/// object nobody paid for.
///
/// A GUIDE for «صمم قطعتك», where nothing is bought per object.
/// **Since 2026-09-13 it counts who actually CHECKED IN**, falling
/// back to the booked `people_count` until the desk records
/// attendance: a party of four that arrives as two expects two.
/// It used to be the booked count always, which told a complete
/// booking it was short. Never a ceiling there — one person making
/// three things at a wheel is normal and accepted.
@JsonKey(name: 'expected_piece_count') int? get expectedPieceCount;/// The paint workshops that accept a piece made here.
///
/// Empty until the studio marks this booking **completed**, which
/// means fired — see [PaintableWorkshop].
@JsonKey(name: 'paintable_at') List<PaintableWorkshop> get paintableAt;// ---- pickup of the fired piece ----
/// WHEN THE STUDIO EXPECTS THE PIECE TO BE FINISHED.
///
/// **NOT IMPLEMENTED SERVER-SIDE — always null today.** Probed on
/// 2026-09-15 against booking 55 (`status: preparing`): the row
/// carries no readiness estimate of any kind, and `/docs.openapi`
/// has no `ready_at`, `ready_in`, `estimated_*` or `preparing_*`
/// anywhere. `piece_warning_days` exists but is the workshop's
/// COLLECTION warning window, not how long firing takes.
///
/// It is modelled anyway because the alternative is the app
/// promising a number it invented: «قيد التحضير» read "ready in 5
/// to 7 days" for every booking of every workshop, which is a
/// commitment the studio never made. The line now states the span
/// only when the server sends one and says nothing about timing
/// otherwise — so the day this field appears, the promise becomes
/// true without another change here.
///
/// Offset-bearing, like every other timestamp on this row. See
/// `unverified_models_test.dart`.
 DateTime? get readyAt;/// Deadline to collect the finished piece from the studio. Null in
/// every capture — it is set once the piece is fired and ready.
 DateTime? get pickupDeadline;/// Whether [pickupDeadline] has passed with the piece
/// uncollected. Present and non-null even while
/// [pickupDeadline] is null (it is simply false then).
 bool get isPickupOverdue;// ---- delivery of the fired piece: null until requested ----
/// How the piece leaves the studio. Null in every capture; left a
/// raw String because no value has been observed to build an enum
/// from. See [hasDeliveryLeg].
 String? get deliveryMethod;/// Raw shipping stage. Read it typed via [deliveryStatusEnum].
/// Null means "no delivery leg", NOT "unknown stage".
 String? get deliveryStatus;/// Destination latitude as a decimal STRING (`"24.7136000"`), not
/// a double. Parse at the map call site.
 String? get deliveryLat;/// Destination longitude as a decimal STRING, not a double.
 String? get deliveryLng;/// Contact number for the courier, in E.164 (`"+966500000000"`).
 String? get deliveryPhone;/// Free-text destination address.
 String? get deliveryAddress;/// Human-readable zone NAME the fee was priced for (`"Riyadh"`),
/// not a zone id — same as the shop order payload.
 String? get deliveryZone;/// Shipping charge as a decimal string. Priced from the zone in
/// `GET /api/delivery-zones`.
 String? get deliveryFee;/// Wallet credit consumed by the delivery charge. A SEPARATE
/// settlement from [walletApplied] — the piece and its shipping
/// are paid at different times.
 String? get deliveryFeeWalletApplied;/// [deliveryFee] minus [deliveryFeeWalletApplied] — what the
/// delivery payment step charges. Separate from [amountDue]; do
/// not add the two together and show one number.
 String? get deliveryFeeAmountDue;
/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingCopyWith<Booking> get copyWith => _$BookingCopyWithImpl<Booking>(this as Booking, _$identity);

  /// Serializes this Booking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Booking&&(identical(other.id, id) || other.id == id)&&(identical(other.workshopId, workshopId) || other.workshopId == workshopId)&&(identical(other.workshopTitle, workshopTitle) || other.workshopTitle == workshopTitle)&&(identical(other.workshopImage, workshopImage) || other.workshopImage == workshopImage)&&(identical(other.workshopSlotId, workshopSlotId) || other.workshopSlotId == workshopSlotId)&&(identical(other.bookingDate, bookingDate) || other.bookingDate == bookingDate)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.locationUrl, locationUrl) || other.locationUrl == locationUrl)&&(identical(other.peopleCount, peopleCount) || other.peopleCount == peopleCount)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.hasCelebration, hasCelebration) || other.hasCelebration == hasCelebration)&&(identical(other.celebrationPrice, celebrationPrice) || other.celebrationPrice == celebrationPrice)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.discountCode, discountCode) || other.discountCode == discountCode)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.walletApplied, walletApplied) || other.walletApplied == walletApplied)&&(identical(other.amountDue, amountDue) || other.amountDue == amountDue)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.checkedInAt, checkedInAt) || other.checkedInAt == checkedInAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editableUntil, editableUntil) || other.editableUntil == editableUntil)&&(identical(other.paymentExpiresAt, paymentExpiresAt) || other.paymentExpiresAt == paymentExpiresAt)&&(identical(other.qrValue, qrValue) || other.qrValue == qrValue)&&(identical(other.checkinCode, checkinCode) || other.checkinCode == checkinCode)&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&(identical(other.canCancel, canCancel) || other.canCancel == canCancel)&&const DeepCollectionEquality().equals(other.images, images)&&const DeepCollectionEquality().equals(other.products, products)&&const DeepCollectionEquality().equals(other.pieces, pieces)&&(identical(other.expectedPieceCount, expectedPieceCount) || other.expectedPieceCount == expectedPieceCount)&&const DeepCollectionEquality().equals(other.paintableAt, paintableAt)&&(identical(other.readyAt, readyAt) || other.readyAt == readyAt)&&(identical(other.pickupDeadline, pickupDeadline) || other.pickupDeadline == pickupDeadline)&&(identical(other.isPickupOverdue, isPickupOverdue) || other.isPickupOverdue == isPickupOverdue)&&(identical(other.deliveryMethod, deliveryMethod) || other.deliveryMethod == deliveryMethod)&&(identical(other.deliveryStatus, deliveryStatus) || other.deliveryStatus == deliveryStatus)&&(identical(other.deliveryLat, deliveryLat) || other.deliveryLat == deliveryLat)&&(identical(other.deliveryLng, deliveryLng) || other.deliveryLng == deliveryLng)&&(identical(other.deliveryPhone, deliveryPhone) || other.deliveryPhone == deliveryPhone)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.deliveryZone, deliveryZone) || other.deliveryZone == deliveryZone)&&(identical(other.deliveryFee, deliveryFee) || other.deliveryFee == deliveryFee)&&(identical(other.deliveryFeeWalletApplied, deliveryFeeWalletApplied) || other.deliveryFeeWalletApplied == deliveryFeeWalletApplied)&&(identical(other.deliveryFeeAmountDue, deliveryFeeAmountDue) || other.deliveryFeeAmountDue == deliveryFeeAmountDue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,workshopId,workshopTitle,workshopImage,workshopSlotId,bookingDate,startTime,endTime,locationUrl,peopleCount,unitPrice,hasCelebration,celebrationPrice,subtotal,discountAmount,discountCode,totalPrice,vatRate,vatAmount,walletApplied,amountDue,status,paymentStatus,checkedInAt,createdAt,editableUntil,paymentExpiresAt,qrValue,checkinCode,canEdit,canCancel,const DeepCollectionEquality().hash(images),const DeepCollectionEquality().hash(products),const DeepCollectionEquality().hash(pieces),expectedPieceCount,const DeepCollectionEquality().hash(paintableAt),readyAt,pickupDeadline,isPickupOverdue,deliveryMethod,deliveryStatus,deliveryLat,deliveryLng,deliveryPhone,deliveryAddress,deliveryZone,deliveryFee,deliveryFeeWalletApplied,deliveryFeeAmountDue]);

@override
String toString() {
  return 'Booking(id: $id, workshopId: $workshopId, workshopTitle: $workshopTitle, workshopImage: $workshopImage, workshopSlotId: $workshopSlotId, bookingDate: $bookingDate, startTime: $startTime, endTime: $endTime, locationUrl: $locationUrl, peopleCount: $peopleCount, unitPrice: $unitPrice, hasCelebration: $hasCelebration, celebrationPrice: $celebrationPrice, subtotal: $subtotal, discountAmount: $discountAmount, discountCode: $discountCode, totalPrice: $totalPrice, vatRate: $vatRate, vatAmount: $vatAmount, walletApplied: $walletApplied, amountDue: $amountDue, status: $status, paymentStatus: $paymentStatus, checkedInAt: $checkedInAt, createdAt: $createdAt, editableUntil: $editableUntil, paymentExpiresAt: $paymentExpiresAt, qrValue: $qrValue, checkinCode: $checkinCode, canEdit: $canEdit, canCancel: $canCancel, images: $images, products: $products, pieces: $pieces, expectedPieceCount: $expectedPieceCount, paintableAt: $paintableAt, readyAt: $readyAt, pickupDeadline: $pickupDeadline, isPickupOverdue: $isPickupOverdue, deliveryMethod: $deliveryMethod, deliveryStatus: $deliveryStatus, deliveryLat: $deliveryLat, deliveryLng: $deliveryLng, deliveryPhone: $deliveryPhone, deliveryAddress: $deliveryAddress, deliveryZone: $deliveryZone, deliveryFee: $deliveryFee, deliveryFeeWalletApplied: $deliveryFeeWalletApplied, deliveryFeeAmountDue: $deliveryFeeAmountDue)';
}


}

/// @nodoc
abstract mixin class $BookingCopyWith<$Res>  {
  factory $BookingCopyWith(Booking value, $Res Function(Booking) _then) = _$BookingCopyWithImpl;
@useResult
$Res call({
 int id, int workshopId, String workshopTitle, ApiImage? workshopImage, int workshopSlotId, String bookingDate, String startTime, String endTime, String? locationUrl, int peopleCount, String unitPrice, bool hasCelebration, String celebrationPrice, String subtotal, String discountAmount, String? discountCode, String totalPrice, String vatRate, String vatAmount, String walletApplied, String amountDue, String status, String paymentStatus, DateTime? checkedInAt, DateTime createdAt, DateTime? editableUntil, DateTime? paymentExpiresAt, String qrValue, String checkinCode, bool canEdit, bool canCancel, List<ApiImage> images, List<BookingProduct> products, List<BookingPiece> pieces,@JsonKey(name: 'expected_piece_count') int? expectedPieceCount,@JsonKey(name: 'paintable_at') List<PaintableWorkshop> paintableAt, DateTime? readyAt, DateTime? pickupDeadline, bool isPickupOverdue, String? deliveryMethod, String? deliveryStatus, String? deliveryLat, String? deliveryLng, String? deliveryPhone, String? deliveryAddress, String? deliveryZone, String? deliveryFee, String? deliveryFeeWalletApplied, String? deliveryFeeAmountDue
});


$ApiImageCopyWith<$Res>? get workshopImage;

}
/// @nodoc
class _$BookingCopyWithImpl<$Res>
    implements $BookingCopyWith<$Res> {
  _$BookingCopyWithImpl(this._self, this._then);

  final Booking _self;
  final $Res Function(Booking) _then;

/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workshopId = null,Object? workshopTitle = null,Object? workshopImage = freezed,Object? workshopSlotId = null,Object? bookingDate = null,Object? startTime = null,Object? endTime = null,Object? locationUrl = freezed,Object? peopleCount = null,Object? unitPrice = null,Object? hasCelebration = null,Object? celebrationPrice = null,Object? subtotal = null,Object? discountAmount = null,Object? discountCode = freezed,Object? totalPrice = null,Object? vatRate = null,Object? vatAmount = null,Object? walletApplied = null,Object? amountDue = null,Object? status = null,Object? paymentStatus = null,Object? checkedInAt = freezed,Object? createdAt = null,Object? editableUntil = freezed,Object? paymentExpiresAt = freezed,Object? qrValue = null,Object? checkinCode = null,Object? canEdit = null,Object? canCancel = null,Object? images = null,Object? products = null,Object? pieces = null,Object? expectedPieceCount = freezed,Object? paintableAt = null,Object? readyAt = freezed,Object? pickupDeadline = freezed,Object? isPickupOverdue = null,Object? deliveryMethod = freezed,Object? deliveryStatus = freezed,Object? deliveryLat = freezed,Object? deliveryLng = freezed,Object? deliveryPhone = freezed,Object? deliveryAddress = freezed,Object? deliveryZone = freezed,Object? deliveryFee = freezed,Object? deliveryFeeWalletApplied = freezed,Object? deliveryFeeAmountDue = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,workshopId: null == workshopId ? _self.workshopId : workshopId // ignore: cast_nullable_to_non_nullable
as int,workshopTitle: null == workshopTitle ? _self.workshopTitle : workshopTitle // ignore: cast_nullable_to_non_nullable
as String,workshopImage: freezed == workshopImage ? _self.workshopImage : workshopImage // ignore: cast_nullable_to_non_nullable
as ApiImage?,workshopSlotId: null == workshopSlotId ? _self.workshopSlotId : workshopSlotId // ignore: cast_nullable_to_non_nullable
as int,bookingDate: null == bookingDate ? _self.bookingDate : bookingDate // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,locationUrl: freezed == locationUrl ? _self.locationUrl : locationUrl // ignore: cast_nullable_to_non_nullable
as String?,peopleCount: null == peopleCount ? _self.peopleCount : peopleCount // ignore: cast_nullable_to_non_nullable
as int,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,hasCelebration: null == hasCelebration ? _self.hasCelebration : hasCelebration // ignore: cast_nullable_to_non_nullable
as bool,celebrationPrice: null == celebrationPrice ? _self.celebrationPrice : celebrationPrice // ignore: cast_nullable_to_non_nullable
as String,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as String,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as String,discountCode: freezed == discountCode ? _self.discountCode : discountCode // ignore: cast_nullable_to_non_nullable
as String?,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as String,vatRate: null == vatRate ? _self.vatRate : vatRate // ignore: cast_nullable_to_non_nullable
as String,vatAmount: null == vatAmount ? _self.vatAmount : vatAmount // ignore: cast_nullable_to_non_nullable
as String,walletApplied: null == walletApplied ? _self.walletApplied : walletApplied // ignore: cast_nullable_to_non_nullable
as String,amountDue: null == amountDue ? _self.amountDue : amountDue // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String,checkedInAt: freezed == checkedInAt ? _self.checkedInAt : checkedInAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,editableUntil: freezed == editableUntil ? _self.editableUntil : editableUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentExpiresAt: freezed == paymentExpiresAt ? _self.paymentExpiresAt : paymentExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,qrValue: null == qrValue ? _self.qrValue : qrValue // ignore: cast_nullable_to_non_nullable
as String,checkinCode: null == checkinCode ? _self.checkinCode : checkinCode // ignore: cast_nullable_to_non_nullable
as String,canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,canCancel: null == canCancel ? _self.canCancel : canCancel // ignore: cast_nullable_to_non_nullable
as bool,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<ApiImage>,products: null == products ? _self.products : products // ignore: cast_nullable_to_non_nullable
as List<BookingProduct>,pieces: null == pieces ? _self.pieces : pieces // ignore: cast_nullable_to_non_nullable
as List<BookingPiece>,expectedPieceCount: freezed == expectedPieceCount ? _self.expectedPieceCount : expectedPieceCount // ignore: cast_nullable_to_non_nullable
as int?,paintableAt: null == paintableAt ? _self.paintableAt : paintableAt // ignore: cast_nullable_to_non_nullable
as List<PaintableWorkshop>,readyAt: freezed == readyAt ? _self.readyAt : readyAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pickupDeadline: freezed == pickupDeadline ? _self.pickupDeadline : pickupDeadline // ignore: cast_nullable_to_non_nullable
as DateTime?,isPickupOverdue: null == isPickupOverdue ? _self.isPickupOverdue : isPickupOverdue // ignore: cast_nullable_to_non_nullable
as bool,deliveryMethod: freezed == deliveryMethod ? _self.deliveryMethod : deliveryMethod // ignore: cast_nullable_to_non_nullable
as String?,deliveryStatus: freezed == deliveryStatus ? _self.deliveryStatus : deliveryStatus // ignore: cast_nullable_to_non_nullable
as String?,deliveryLat: freezed == deliveryLat ? _self.deliveryLat : deliveryLat // ignore: cast_nullable_to_non_nullable
as String?,deliveryLng: freezed == deliveryLng ? _self.deliveryLng : deliveryLng // ignore: cast_nullable_to_non_nullable
as String?,deliveryPhone: freezed == deliveryPhone ? _self.deliveryPhone : deliveryPhone // ignore: cast_nullable_to_non_nullable
as String?,deliveryAddress: freezed == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as String?,deliveryZone: freezed == deliveryZone ? _self.deliveryZone : deliveryZone // ignore: cast_nullable_to_non_nullable
as String?,deliveryFee: freezed == deliveryFee ? _self.deliveryFee : deliveryFee // ignore: cast_nullable_to_non_nullable
as String?,deliveryFeeWalletApplied: freezed == deliveryFeeWalletApplied ? _self.deliveryFeeWalletApplied : deliveryFeeWalletApplied // ignore: cast_nullable_to_non_nullable
as String?,deliveryFeeAmountDue: freezed == deliveryFeeAmountDue ? _self.deliveryFeeAmountDue : deliveryFeeAmountDue // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiImageCopyWith<$Res>? get workshopImage {
    if (_self.workshopImage == null) {
    return null;
  }

  return $ApiImageCopyWith<$Res>(_self.workshopImage!, (value) {
    return _then(_self.copyWith(workshopImage: value));
  });
}
}


/// Adds pattern-matching-related methods to [Booking].
extension BookingPatterns on Booking {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Booking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Booking() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Booking value)  $default,){
final _that = this;
switch (_that) {
case _Booking():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Booking value)?  $default,){
final _that = this;
switch (_that) {
case _Booking() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int workshopId,  String workshopTitle,  ApiImage? workshopImage,  int workshopSlotId,  String bookingDate,  String startTime,  String endTime,  String? locationUrl,  int peopleCount,  String unitPrice,  bool hasCelebration,  String celebrationPrice,  String subtotal,  String discountAmount,  String? discountCode,  String totalPrice,  String vatRate,  String vatAmount,  String walletApplied,  String amountDue,  String status,  String paymentStatus,  DateTime? checkedInAt,  DateTime createdAt,  DateTime? editableUntil,  DateTime? paymentExpiresAt,  String qrValue,  String checkinCode,  bool canEdit,  bool canCancel,  List<ApiImage> images,  List<BookingProduct> products,  List<BookingPiece> pieces, @JsonKey(name: 'expected_piece_count')  int? expectedPieceCount, @JsonKey(name: 'paintable_at')  List<PaintableWorkshop> paintableAt,  DateTime? readyAt,  DateTime? pickupDeadline,  bool isPickupOverdue,  String? deliveryMethod,  String? deliveryStatus,  String? deliveryLat,  String? deliveryLng,  String? deliveryPhone,  String? deliveryAddress,  String? deliveryZone,  String? deliveryFee,  String? deliveryFeeWalletApplied,  String? deliveryFeeAmountDue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Booking() when $default != null:
return $default(_that.id,_that.workshopId,_that.workshopTitle,_that.workshopImage,_that.workshopSlotId,_that.bookingDate,_that.startTime,_that.endTime,_that.locationUrl,_that.peopleCount,_that.unitPrice,_that.hasCelebration,_that.celebrationPrice,_that.subtotal,_that.discountAmount,_that.discountCode,_that.totalPrice,_that.vatRate,_that.vatAmount,_that.walletApplied,_that.amountDue,_that.status,_that.paymentStatus,_that.checkedInAt,_that.createdAt,_that.editableUntil,_that.paymentExpiresAt,_that.qrValue,_that.checkinCode,_that.canEdit,_that.canCancel,_that.images,_that.products,_that.pieces,_that.expectedPieceCount,_that.paintableAt,_that.readyAt,_that.pickupDeadline,_that.isPickupOverdue,_that.deliveryMethod,_that.deliveryStatus,_that.deliveryLat,_that.deliveryLng,_that.deliveryPhone,_that.deliveryAddress,_that.deliveryZone,_that.deliveryFee,_that.deliveryFeeWalletApplied,_that.deliveryFeeAmountDue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int workshopId,  String workshopTitle,  ApiImage? workshopImage,  int workshopSlotId,  String bookingDate,  String startTime,  String endTime,  String? locationUrl,  int peopleCount,  String unitPrice,  bool hasCelebration,  String celebrationPrice,  String subtotal,  String discountAmount,  String? discountCode,  String totalPrice,  String vatRate,  String vatAmount,  String walletApplied,  String amountDue,  String status,  String paymentStatus,  DateTime? checkedInAt,  DateTime createdAt,  DateTime? editableUntil,  DateTime? paymentExpiresAt,  String qrValue,  String checkinCode,  bool canEdit,  bool canCancel,  List<ApiImage> images,  List<BookingProduct> products,  List<BookingPiece> pieces, @JsonKey(name: 'expected_piece_count')  int? expectedPieceCount, @JsonKey(name: 'paintable_at')  List<PaintableWorkshop> paintableAt,  DateTime? readyAt,  DateTime? pickupDeadline,  bool isPickupOverdue,  String? deliveryMethod,  String? deliveryStatus,  String? deliveryLat,  String? deliveryLng,  String? deliveryPhone,  String? deliveryAddress,  String? deliveryZone,  String? deliveryFee,  String? deliveryFeeWalletApplied,  String? deliveryFeeAmountDue)  $default,) {final _that = this;
switch (_that) {
case _Booking():
return $default(_that.id,_that.workshopId,_that.workshopTitle,_that.workshopImage,_that.workshopSlotId,_that.bookingDate,_that.startTime,_that.endTime,_that.locationUrl,_that.peopleCount,_that.unitPrice,_that.hasCelebration,_that.celebrationPrice,_that.subtotal,_that.discountAmount,_that.discountCode,_that.totalPrice,_that.vatRate,_that.vatAmount,_that.walletApplied,_that.amountDue,_that.status,_that.paymentStatus,_that.checkedInAt,_that.createdAt,_that.editableUntil,_that.paymentExpiresAt,_that.qrValue,_that.checkinCode,_that.canEdit,_that.canCancel,_that.images,_that.products,_that.pieces,_that.expectedPieceCount,_that.paintableAt,_that.readyAt,_that.pickupDeadline,_that.isPickupOverdue,_that.deliveryMethod,_that.deliveryStatus,_that.deliveryLat,_that.deliveryLng,_that.deliveryPhone,_that.deliveryAddress,_that.deliveryZone,_that.deliveryFee,_that.deliveryFeeWalletApplied,_that.deliveryFeeAmountDue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int workshopId,  String workshopTitle,  ApiImage? workshopImage,  int workshopSlotId,  String bookingDate,  String startTime,  String endTime,  String? locationUrl,  int peopleCount,  String unitPrice,  bool hasCelebration,  String celebrationPrice,  String subtotal,  String discountAmount,  String? discountCode,  String totalPrice,  String vatRate,  String vatAmount,  String walletApplied,  String amountDue,  String status,  String paymentStatus,  DateTime? checkedInAt,  DateTime createdAt,  DateTime? editableUntil,  DateTime? paymentExpiresAt,  String qrValue,  String checkinCode,  bool canEdit,  bool canCancel,  List<ApiImage> images,  List<BookingProduct> products,  List<BookingPiece> pieces, @JsonKey(name: 'expected_piece_count')  int? expectedPieceCount, @JsonKey(name: 'paintable_at')  List<PaintableWorkshop> paintableAt,  DateTime? readyAt,  DateTime? pickupDeadline,  bool isPickupOverdue,  String? deliveryMethod,  String? deliveryStatus,  String? deliveryLat,  String? deliveryLng,  String? deliveryPhone,  String? deliveryAddress,  String? deliveryZone,  String? deliveryFee,  String? deliveryFeeWalletApplied,  String? deliveryFeeAmountDue)?  $default,) {final _that = this;
switch (_that) {
case _Booking() when $default != null:
return $default(_that.id,_that.workshopId,_that.workshopTitle,_that.workshopImage,_that.workshopSlotId,_that.bookingDate,_that.startTime,_that.endTime,_that.locationUrl,_that.peopleCount,_that.unitPrice,_that.hasCelebration,_that.celebrationPrice,_that.subtotal,_that.discountAmount,_that.discountCode,_that.totalPrice,_that.vatRate,_that.vatAmount,_that.walletApplied,_that.amountDue,_that.status,_that.paymentStatus,_that.checkedInAt,_that.createdAt,_that.editableUntil,_that.paymentExpiresAt,_that.qrValue,_that.checkinCode,_that.canEdit,_that.canCancel,_that.images,_that.products,_that.pieces,_that.expectedPieceCount,_that.paintableAt,_that.readyAt,_that.pickupDeadline,_that.isPickupOverdue,_that.deliveryMethod,_that.deliveryStatus,_that.deliveryLat,_that.deliveryLng,_that.deliveryPhone,_that.deliveryAddress,_that.deliveryZone,_that.deliveryFee,_that.deliveryFeeWalletApplied,_that.deliveryFeeAmountDue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Booking extends Booking {
  const _Booking({required this.id, required this.workshopId, required this.workshopTitle, this.workshopImage, required this.workshopSlotId, required this.bookingDate, required this.startTime, required this.endTime, this.locationUrl, required this.peopleCount, required this.unitPrice, required this.hasCelebration, required this.celebrationPrice, required this.subtotal, required this.discountAmount, this.discountCode, required this.totalPrice, required this.vatRate, required this.vatAmount, required this.walletApplied, required this.amountDue, required this.status, required this.paymentStatus, this.checkedInAt, required this.createdAt, this.editableUntil, this.paymentExpiresAt, required this.qrValue, required this.checkinCode, required this.canEdit, required this.canCancel, final  List<ApiImage> images = const <ApiImage>[], final  List<BookingProduct> products = const <BookingProduct>[], final  List<BookingPiece> pieces = const <BookingPiece>[], @JsonKey(name: 'expected_piece_count') this.expectedPieceCount, @JsonKey(name: 'paintable_at') final  List<PaintableWorkshop> paintableAt = const <PaintableWorkshop>[], this.readyAt, this.pickupDeadline, required this.isPickupOverdue, this.deliveryMethod, this.deliveryStatus, this.deliveryLat, this.deliveryLng, this.deliveryPhone, this.deliveryAddress, this.deliveryZone, this.deliveryFee, this.deliveryFeeWalletApplied, this.deliveryFeeAmountDue}): _images = images,_products = products,_pieces = pieces,_paintableAt = paintableAt,super._();
  factory _Booking.fromJson(Map<String, dynamic> json) => _$BookingFromJson(json);

// ---- identity ----
/// The booking's own id — the `{id}` in
/// `GET /api/workshops/bookings/{id}`.
@override final  int id;
// ---- the workshop and the slot ----
/// The workshop this booking is for.
@override final  int workshopId;
/// Already-localized workshop name. Display as-is.
@override final  String workshopTitle;
/// Workshop cover art. **Null in every capture** — as is `image`
/// on the workshop payloads themselves — so the shape is unproven.
/// [ApiImage] is the bet because it is the shape behind every
/// other image key in this API. Paint via `image.display`.
@override final  ApiImage? workshopImage;
/// The specific dated session that was booked.
@override final  int workshopSlotId;
/// Bare calendar date, `"2026-08-28"`. A String, not a DateTime —
/// see the class doc.
@override final  String bookingDate;
/// Asia/Riyadh clock string, `"13:00"`. NOT a DateTime; parsing it
/// as one throws.
@override final  String startTime;
/// Asia/Riyadh clock string, `"14:30"`. NOT a DateTime.
@override final  String endTime;
/// Maps link for the studio. Hand it to `launchUrl` with
/// `LaunchMode.externalApplication`.
///
/// NULLABLE — verified live on 2026-08-30. The CMS leaves it empty
/// on a workshop that is not open for booking, and declared
/// required it threw inside `fromJson` and took the whole payload
/// with it. Show the map link only when there is one.
@override final  String? locationUrl;
/// Seats booked. Capped by the workshop's `max_people_per_booking`.
@override final  int peopleCount;
// ---- money: all decimal strings ----
/// Price of ONE seat. `"0.00"` on the catalogue-priced families —
/// that is not an error, see the class doc.
@override final  String unitPrice;
/// Whether the celebration add-on was bought.
@override final  bool hasCelebration;
/// Cost of the celebration add-on. Quoted whether or not
/// [hasCelebration] is true — check the flag before showing it.
@override final  String celebrationPrice;
/// Seats + products + celebration, before discount, VAT and
/// wallet. Server-computed; do not recompute.
@override final  String subtotal;
/// Amount taken off by [discountCode]. `"0.00"` when none.
@override final  String discountAmount;
/// The code that was applied, or null when none was.
@override final  String? discountCode;
/// What the booking costs. VAT-INCLUSIVE — never add [vatAmount].
@override final  String totalPrice;
/// VAT percentage as a decimal string (`"0.00"` in the captures —
/// the demo tenant has tax switched off).
@override final  String vatRate;
/// VAT already INSIDE [totalPrice]. Disclosure only.
@override final  String vatAmount;
/// Wallet credit consumed. `"0.00"` when none.
@override final  String walletApplied;
/// [totalPrice] minus [walletApplied] — what the payment step
/// charges. `"0.00"` means settled; see [isAlreadySettled].
@override final  String amountDue;
// ---- state ----
/// Raw lifecycle value (`"pending_payment"`). Read it typed via
/// [statusEnum]; keep this string for display.
@override final  String status;
/// Raw payment value (`"unpaid"` is the only one captured). Left
/// as a String deliberately — the vocabulary is unverified, so no
/// enum here would be honest.
@override final  String paymentStatus;
/// When the customer scanned in at the studio. Null until they do.
@override final  DateTime? checkedInAt;
/// When the booking was created. Full ISO-8601 with offset.
@override final  DateTime createdAt;
/// End of the edit window — creation + the workshop's
/// `cancellation_window_hours`. Nullable: see the class doc.
/// **[canEdit] is the authority, not this timestamp** — the
/// captures show `can_edit: false` while this is still in the
/// future, because an unpaid booking cannot be edited at all.
@override final  DateTime? editableUntil;
/// End of the payment window — only ~15 minutes after
/// [createdAt] in the captures. The seat is released after it.
/// Nullable: a paid booking has nothing left to expire.
@override final  DateTime? paymentExpiresAt;
/// Opaque token to encode into the check-in QR. A String — never
/// parse it to int.
@override final  String qrValue;
/// The same token, for the studio to key in by hand when a scan
/// fails. Identical to [qrValue] in every capture, but do not
/// assume that holds.
@override final  String checkinCode;
/// Server's verdict on editability. Trust this, not [editableUntil].
@override final  bool canEdit;
/// Server's verdict on cancellability. Trust this, not the clock.
@override final  bool canCancel;
/// Photos attached to the booking. `[]` in every capture, so the
/// element shape is unproven — [ApiImage] is the bet, matching
/// every other image list in this API.
 final  List<ApiImage> _images;
/// Photos attached to the booking. `[]` in every capture, so the
/// element shape is unproven — [ApiImage] is the bet, matching
/// every other image list in this API.
@override@JsonKey() List<ApiImage> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

/// Catalogue items picked at booking time. Empty for the flat-rate
/// `make_your_piece` family; the source of [subtotal] for the
/// others.
 final  List<BookingProduct> _products;
/// Catalogue items picked at booking time. Empty for the flat-rate
/// `make_your_piece` family; the source of [subtotal] for the
/// others.
@override@JsonKey() List<BookingProduct> get products {
  if (_products is EqualUnmodifiableListView) return _products;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_products);
}

/// The pieces made in this session, grouped by the labels the
/// customer typed when uploading photographs.
 final  List<BookingPiece> _pieces;
/// The pieces made in this session, grouped by the labels the
/// customer typed when uploading photographs.
@override@JsonKey() List<BookingPiece> get pieces {
  if (_pieces is EqualUnmodifiableListView) return _pieces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pieces);
}

/// How many pieces this booking is expected to end up with.
///
/// A CEILING for the catalogue types — the sum of the quantities
/// bought, enforced server-side, because a key past it would be an
/// object nobody paid for.
///
/// A GUIDE for «صمم قطعتك», where nothing is bought per object.
/// **Since 2026-09-13 it counts who actually CHECKED IN**, falling
/// back to the booked `people_count` until the desk records
/// attendance: a party of four that arrives as two expects two.
/// It used to be the booked count always, which told a complete
/// booking it was short. Never a ceiling there — one person making
/// three things at a wheel is normal and accepted.
@override@JsonKey(name: 'expected_piece_count') final  int? expectedPieceCount;
/// The paint workshops that accept a piece made here.
///
/// Empty until the studio marks this booking **completed**, which
/// means fired — see [PaintableWorkshop].
 final  List<PaintableWorkshop> _paintableAt;
/// The paint workshops that accept a piece made here.
///
/// Empty until the studio marks this booking **completed**, which
/// means fired — see [PaintableWorkshop].
@override@JsonKey(name: 'paintable_at') List<PaintableWorkshop> get paintableAt {
  if (_paintableAt is EqualUnmodifiableListView) return _paintableAt;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_paintableAt);
}

// ---- pickup of the fired piece ----
/// WHEN THE STUDIO EXPECTS THE PIECE TO BE FINISHED.
///
/// **NOT IMPLEMENTED SERVER-SIDE — always null today.** Probed on
/// 2026-09-15 against booking 55 (`status: preparing`): the row
/// carries no readiness estimate of any kind, and `/docs.openapi`
/// has no `ready_at`, `ready_in`, `estimated_*` or `preparing_*`
/// anywhere. `piece_warning_days` exists but is the workshop's
/// COLLECTION warning window, not how long firing takes.
///
/// It is modelled anyway because the alternative is the app
/// promising a number it invented: «قيد التحضير» read "ready in 5
/// to 7 days" for every booking of every workshop, which is a
/// commitment the studio never made. The line now states the span
/// only when the server sends one and says nothing about timing
/// otherwise — so the day this field appears, the promise becomes
/// true without another change here.
///
/// Offset-bearing, like every other timestamp on this row. See
/// `unverified_models_test.dart`.
@override final  DateTime? readyAt;
/// Deadline to collect the finished piece from the studio. Null in
/// every capture — it is set once the piece is fired and ready.
@override final  DateTime? pickupDeadline;
/// Whether [pickupDeadline] has passed with the piece
/// uncollected. Present and non-null even while
/// [pickupDeadline] is null (it is simply false then).
@override final  bool isPickupOverdue;
// ---- delivery of the fired piece: null until requested ----
/// How the piece leaves the studio. Null in every capture; left a
/// raw String because no value has been observed to build an enum
/// from. See [hasDeliveryLeg].
@override final  String? deliveryMethod;
/// Raw shipping stage. Read it typed via [deliveryStatusEnum].
/// Null means "no delivery leg", NOT "unknown stage".
@override final  String? deliveryStatus;
/// Destination latitude as a decimal STRING (`"24.7136000"`), not
/// a double. Parse at the map call site.
@override final  String? deliveryLat;
/// Destination longitude as a decimal STRING, not a double.
@override final  String? deliveryLng;
/// Contact number for the courier, in E.164 (`"+966500000000"`).
@override final  String? deliveryPhone;
/// Free-text destination address.
@override final  String? deliveryAddress;
/// Human-readable zone NAME the fee was priced for (`"Riyadh"`),
/// not a zone id — same as the shop order payload.
@override final  String? deliveryZone;
/// Shipping charge as a decimal string. Priced from the zone in
/// `GET /api/delivery-zones`.
@override final  String? deliveryFee;
/// Wallet credit consumed by the delivery charge. A SEPARATE
/// settlement from [walletApplied] — the piece and its shipping
/// are paid at different times.
@override final  String? deliveryFeeWalletApplied;
/// [deliveryFee] minus [deliveryFeeWalletApplied] — what the
/// delivery payment step charges. Separate from [amountDue]; do
/// not add the two together and show one number.
@override final  String? deliveryFeeAmountDue;

/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingCopyWith<_Booking> get copyWith => __$BookingCopyWithImpl<_Booking>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Booking&&(identical(other.id, id) || other.id == id)&&(identical(other.workshopId, workshopId) || other.workshopId == workshopId)&&(identical(other.workshopTitle, workshopTitle) || other.workshopTitle == workshopTitle)&&(identical(other.workshopImage, workshopImage) || other.workshopImage == workshopImage)&&(identical(other.workshopSlotId, workshopSlotId) || other.workshopSlotId == workshopSlotId)&&(identical(other.bookingDate, bookingDate) || other.bookingDate == bookingDate)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.locationUrl, locationUrl) || other.locationUrl == locationUrl)&&(identical(other.peopleCount, peopleCount) || other.peopleCount == peopleCount)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.hasCelebration, hasCelebration) || other.hasCelebration == hasCelebration)&&(identical(other.celebrationPrice, celebrationPrice) || other.celebrationPrice == celebrationPrice)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.discountCode, discountCode) || other.discountCode == discountCode)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.walletApplied, walletApplied) || other.walletApplied == walletApplied)&&(identical(other.amountDue, amountDue) || other.amountDue == amountDue)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.checkedInAt, checkedInAt) || other.checkedInAt == checkedInAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editableUntil, editableUntil) || other.editableUntil == editableUntil)&&(identical(other.paymentExpiresAt, paymentExpiresAt) || other.paymentExpiresAt == paymentExpiresAt)&&(identical(other.qrValue, qrValue) || other.qrValue == qrValue)&&(identical(other.checkinCode, checkinCode) || other.checkinCode == checkinCode)&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&(identical(other.canCancel, canCancel) || other.canCancel == canCancel)&&const DeepCollectionEquality().equals(other._images, _images)&&const DeepCollectionEquality().equals(other._products, _products)&&const DeepCollectionEquality().equals(other._pieces, _pieces)&&(identical(other.expectedPieceCount, expectedPieceCount) || other.expectedPieceCount == expectedPieceCount)&&const DeepCollectionEquality().equals(other._paintableAt, _paintableAt)&&(identical(other.readyAt, readyAt) || other.readyAt == readyAt)&&(identical(other.pickupDeadline, pickupDeadline) || other.pickupDeadline == pickupDeadline)&&(identical(other.isPickupOverdue, isPickupOverdue) || other.isPickupOverdue == isPickupOverdue)&&(identical(other.deliveryMethod, deliveryMethod) || other.deliveryMethod == deliveryMethod)&&(identical(other.deliveryStatus, deliveryStatus) || other.deliveryStatus == deliveryStatus)&&(identical(other.deliveryLat, deliveryLat) || other.deliveryLat == deliveryLat)&&(identical(other.deliveryLng, deliveryLng) || other.deliveryLng == deliveryLng)&&(identical(other.deliveryPhone, deliveryPhone) || other.deliveryPhone == deliveryPhone)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.deliveryZone, deliveryZone) || other.deliveryZone == deliveryZone)&&(identical(other.deliveryFee, deliveryFee) || other.deliveryFee == deliveryFee)&&(identical(other.deliveryFeeWalletApplied, deliveryFeeWalletApplied) || other.deliveryFeeWalletApplied == deliveryFeeWalletApplied)&&(identical(other.deliveryFeeAmountDue, deliveryFeeAmountDue) || other.deliveryFeeAmountDue == deliveryFeeAmountDue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,workshopId,workshopTitle,workshopImage,workshopSlotId,bookingDate,startTime,endTime,locationUrl,peopleCount,unitPrice,hasCelebration,celebrationPrice,subtotal,discountAmount,discountCode,totalPrice,vatRate,vatAmount,walletApplied,amountDue,status,paymentStatus,checkedInAt,createdAt,editableUntil,paymentExpiresAt,qrValue,checkinCode,canEdit,canCancel,const DeepCollectionEquality().hash(_images),const DeepCollectionEquality().hash(_products),const DeepCollectionEquality().hash(_pieces),expectedPieceCount,const DeepCollectionEquality().hash(_paintableAt),readyAt,pickupDeadline,isPickupOverdue,deliveryMethod,deliveryStatus,deliveryLat,deliveryLng,deliveryPhone,deliveryAddress,deliveryZone,deliveryFee,deliveryFeeWalletApplied,deliveryFeeAmountDue]);

@override
String toString() {
  return 'Booking(id: $id, workshopId: $workshopId, workshopTitle: $workshopTitle, workshopImage: $workshopImage, workshopSlotId: $workshopSlotId, bookingDate: $bookingDate, startTime: $startTime, endTime: $endTime, locationUrl: $locationUrl, peopleCount: $peopleCount, unitPrice: $unitPrice, hasCelebration: $hasCelebration, celebrationPrice: $celebrationPrice, subtotal: $subtotal, discountAmount: $discountAmount, discountCode: $discountCode, totalPrice: $totalPrice, vatRate: $vatRate, vatAmount: $vatAmount, walletApplied: $walletApplied, amountDue: $amountDue, status: $status, paymentStatus: $paymentStatus, checkedInAt: $checkedInAt, createdAt: $createdAt, editableUntil: $editableUntil, paymentExpiresAt: $paymentExpiresAt, qrValue: $qrValue, checkinCode: $checkinCode, canEdit: $canEdit, canCancel: $canCancel, images: $images, products: $products, pieces: $pieces, expectedPieceCount: $expectedPieceCount, paintableAt: $paintableAt, readyAt: $readyAt, pickupDeadline: $pickupDeadline, isPickupOverdue: $isPickupOverdue, deliveryMethod: $deliveryMethod, deliveryStatus: $deliveryStatus, deliveryLat: $deliveryLat, deliveryLng: $deliveryLng, deliveryPhone: $deliveryPhone, deliveryAddress: $deliveryAddress, deliveryZone: $deliveryZone, deliveryFee: $deliveryFee, deliveryFeeWalletApplied: $deliveryFeeWalletApplied, deliveryFeeAmountDue: $deliveryFeeAmountDue)';
}


}

/// @nodoc
abstract mixin class _$BookingCopyWith<$Res> implements $BookingCopyWith<$Res> {
  factory _$BookingCopyWith(_Booking value, $Res Function(_Booking) _then) = __$BookingCopyWithImpl;
@override @useResult
$Res call({
 int id, int workshopId, String workshopTitle, ApiImage? workshopImage, int workshopSlotId, String bookingDate, String startTime, String endTime, String? locationUrl, int peopleCount, String unitPrice, bool hasCelebration, String celebrationPrice, String subtotal, String discountAmount, String? discountCode, String totalPrice, String vatRate, String vatAmount, String walletApplied, String amountDue, String status, String paymentStatus, DateTime? checkedInAt, DateTime createdAt, DateTime? editableUntil, DateTime? paymentExpiresAt, String qrValue, String checkinCode, bool canEdit, bool canCancel, List<ApiImage> images, List<BookingProduct> products, List<BookingPiece> pieces,@JsonKey(name: 'expected_piece_count') int? expectedPieceCount,@JsonKey(name: 'paintable_at') List<PaintableWorkshop> paintableAt, DateTime? readyAt, DateTime? pickupDeadline, bool isPickupOverdue, String? deliveryMethod, String? deliveryStatus, String? deliveryLat, String? deliveryLng, String? deliveryPhone, String? deliveryAddress, String? deliveryZone, String? deliveryFee, String? deliveryFeeWalletApplied, String? deliveryFeeAmountDue
});


@override $ApiImageCopyWith<$Res>? get workshopImage;

}
/// @nodoc
class __$BookingCopyWithImpl<$Res>
    implements _$BookingCopyWith<$Res> {
  __$BookingCopyWithImpl(this._self, this._then);

  final _Booking _self;
  final $Res Function(_Booking) _then;

/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workshopId = null,Object? workshopTitle = null,Object? workshopImage = freezed,Object? workshopSlotId = null,Object? bookingDate = null,Object? startTime = null,Object? endTime = null,Object? locationUrl = freezed,Object? peopleCount = null,Object? unitPrice = null,Object? hasCelebration = null,Object? celebrationPrice = null,Object? subtotal = null,Object? discountAmount = null,Object? discountCode = freezed,Object? totalPrice = null,Object? vatRate = null,Object? vatAmount = null,Object? walletApplied = null,Object? amountDue = null,Object? status = null,Object? paymentStatus = null,Object? checkedInAt = freezed,Object? createdAt = null,Object? editableUntil = freezed,Object? paymentExpiresAt = freezed,Object? qrValue = null,Object? checkinCode = null,Object? canEdit = null,Object? canCancel = null,Object? images = null,Object? products = null,Object? pieces = null,Object? expectedPieceCount = freezed,Object? paintableAt = null,Object? readyAt = freezed,Object? pickupDeadline = freezed,Object? isPickupOverdue = null,Object? deliveryMethod = freezed,Object? deliveryStatus = freezed,Object? deliveryLat = freezed,Object? deliveryLng = freezed,Object? deliveryPhone = freezed,Object? deliveryAddress = freezed,Object? deliveryZone = freezed,Object? deliveryFee = freezed,Object? deliveryFeeWalletApplied = freezed,Object? deliveryFeeAmountDue = freezed,}) {
  return _then(_Booking(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,workshopId: null == workshopId ? _self.workshopId : workshopId // ignore: cast_nullable_to_non_nullable
as int,workshopTitle: null == workshopTitle ? _self.workshopTitle : workshopTitle // ignore: cast_nullable_to_non_nullable
as String,workshopImage: freezed == workshopImage ? _self.workshopImage : workshopImage // ignore: cast_nullable_to_non_nullable
as ApiImage?,workshopSlotId: null == workshopSlotId ? _self.workshopSlotId : workshopSlotId // ignore: cast_nullable_to_non_nullable
as int,bookingDate: null == bookingDate ? _self.bookingDate : bookingDate // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,locationUrl: freezed == locationUrl ? _self.locationUrl : locationUrl // ignore: cast_nullable_to_non_nullable
as String?,peopleCount: null == peopleCount ? _self.peopleCount : peopleCount // ignore: cast_nullable_to_non_nullable
as int,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,hasCelebration: null == hasCelebration ? _self.hasCelebration : hasCelebration // ignore: cast_nullable_to_non_nullable
as bool,celebrationPrice: null == celebrationPrice ? _self.celebrationPrice : celebrationPrice // ignore: cast_nullable_to_non_nullable
as String,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as String,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as String,discountCode: freezed == discountCode ? _self.discountCode : discountCode // ignore: cast_nullable_to_non_nullable
as String?,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as String,vatRate: null == vatRate ? _self.vatRate : vatRate // ignore: cast_nullable_to_non_nullable
as String,vatAmount: null == vatAmount ? _self.vatAmount : vatAmount // ignore: cast_nullable_to_non_nullable
as String,walletApplied: null == walletApplied ? _self.walletApplied : walletApplied // ignore: cast_nullable_to_non_nullable
as String,amountDue: null == amountDue ? _self.amountDue : amountDue // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String,checkedInAt: freezed == checkedInAt ? _self.checkedInAt : checkedInAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,editableUntil: freezed == editableUntil ? _self.editableUntil : editableUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentExpiresAt: freezed == paymentExpiresAt ? _self.paymentExpiresAt : paymentExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,qrValue: null == qrValue ? _self.qrValue : qrValue // ignore: cast_nullable_to_non_nullable
as String,checkinCode: null == checkinCode ? _self.checkinCode : checkinCode // ignore: cast_nullable_to_non_nullable
as String,canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,canCancel: null == canCancel ? _self.canCancel : canCancel // ignore: cast_nullable_to_non_nullable
as bool,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<ApiImage>,products: null == products ? _self._products : products // ignore: cast_nullable_to_non_nullable
as List<BookingProduct>,pieces: null == pieces ? _self._pieces : pieces // ignore: cast_nullable_to_non_nullable
as List<BookingPiece>,expectedPieceCount: freezed == expectedPieceCount ? _self.expectedPieceCount : expectedPieceCount // ignore: cast_nullable_to_non_nullable
as int?,paintableAt: null == paintableAt ? _self._paintableAt : paintableAt // ignore: cast_nullable_to_non_nullable
as List<PaintableWorkshop>,readyAt: freezed == readyAt ? _self.readyAt : readyAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pickupDeadline: freezed == pickupDeadline ? _self.pickupDeadline : pickupDeadline // ignore: cast_nullable_to_non_nullable
as DateTime?,isPickupOverdue: null == isPickupOverdue ? _self.isPickupOverdue : isPickupOverdue // ignore: cast_nullable_to_non_nullable
as bool,deliveryMethod: freezed == deliveryMethod ? _self.deliveryMethod : deliveryMethod // ignore: cast_nullable_to_non_nullable
as String?,deliveryStatus: freezed == deliveryStatus ? _self.deliveryStatus : deliveryStatus // ignore: cast_nullable_to_non_nullable
as String?,deliveryLat: freezed == deliveryLat ? _self.deliveryLat : deliveryLat // ignore: cast_nullable_to_non_nullable
as String?,deliveryLng: freezed == deliveryLng ? _self.deliveryLng : deliveryLng // ignore: cast_nullable_to_non_nullable
as String?,deliveryPhone: freezed == deliveryPhone ? _self.deliveryPhone : deliveryPhone // ignore: cast_nullable_to_non_nullable
as String?,deliveryAddress: freezed == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as String?,deliveryZone: freezed == deliveryZone ? _self.deliveryZone : deliveryZone // ignore: cast_nullable_to_non_nullable
as String?,deliveryFee: freezed == deliveryFee ? _self.deliveryFee : deliveryFee // ignore: cast_nullable_to_non_nullable
as String?,deliveryFeeWalletApplied: freezed == deliveryFeeWalletApplied ? _self.deliveryFeeWalletApplied : deliveryFeeWalletApplied // ignore: cast_nullable_to_non_nullable
as String?,deliveryFeeAmountDue: freezed == deliveryFeeAmountDue ? _self.deliveryFeeAmountDue : deliveryFeeAmountDue // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiImageCopyWith<$Res>? get workshopImage {
    if (_self.workshopImage == null) {
    return null;
  }

  return $ApiImageCopyWith<$Res>(_self.workshopImage!, (value) {
    return _then(_self.copyWith(workshopImage: value));
  });
}
}

// dart format on
