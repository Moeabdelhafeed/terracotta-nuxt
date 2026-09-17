// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Booking _$BookingFromJson(Map<String, dynamic> json) => _Booking(
  id: (json['id'] as num).toInt(),
  workshopId: (json['workshop_id'] as num).toInt(),
  workshopTitle: json['workshop_title'] as String,
  workshopImage: json['workshop_image'] == null
      ? null
      : ApiImage.fromJson(json['workshop_image'] as Map<String, dynamic>),
  workshopSlotId: (json['workshop_slot_id'] as num).toInt(),
  bookingDate: json['booking_date'] as String,
  startTime: json['start_time'] as String,
  endTime: json['end_time'] as String,
  locationUrl: json['location_url'] as String?,
  peopleCount: (json['people_count'] as num).toInt(),
  unitPrice: json['unit_price'] as String,
  hasCelebration: json['has_celebration'] as bool,
  celebrationPrice: json['celebration_price'] as String,
  subtotal: json['subtotal'] as String,
  discountAmount: json['discount_amount'] as String,
  discountCode: json['discount_code'] as String?,
  totalPrice: json['total_price'] as String,
  vatRate: json['vat_rate'] as String,
  vatAmount: json['vat_amount'] as String,
  walletApplied: json['wallet_applied'] as String,
  amountDue: json['amount_due'] as String,
  status: json['status'] as String,
  paymentStatus: json['payment_status'] as String,
  checkedInAt: json['checked_in_at'] == null
      ? null
      : DateTime.parse(json['checked_in_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  editableUntil: json['editable_until'] == null
      ? null
      : DateTime.parse(json['editable_until'] as String),
  paymentExpiresAt: json['payment_expires_at'] == null
      ? null
      : DateTime.parse(json['payment_expires_at'] as String),
  qrValue: json['qr_value'] as String,
  checkinCode: json['checkin_code'] as String,
  canEdit: json['can_edit'] as bool,
  canCancel: json['can_cancel'] as bool,
  images:
      (json['images'] as List<dynamic>?)
          ?.map((e) => ApiImage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ApiImage>[],
  products:
      (json['products'] as List<dynamic>?)
          ?.map((e) => BookingProduct.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BookingProduct>[],
  pieces:
      (json['pieces'] as List<dynamic>?)
          ?.map((e) => BookingPiece.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BookingPiece>[],
  expectedPieceCount: (json['expected_piece_count'] as num?)?.toInt(),
  paintableAt:
      (json['paintable_at'] as List<dynamic>?)
          ?.map((e) => PaintableWorkshop.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PaintableWorkshop>[],
  readyAt: json['ready_at'] == null
      ? null
      : DateTime.parse(json['ready_at'] as String),
  pickupDeadline: json['pickup_deadline'] == null
      ? null
      : DateTime.parse(json['pickup_deadline'] as String),
  isPickupOverdue: json['is_pickup_overdue'] as bool,
  deliveryMethod: json['delivery_method'] as String?,
  deliveryStatus: json['delivery_status'] as String?,
  deliveryLat: json['delivery_lat'] as String?,
  deliveryLng: json['delivery_lng'] as String?,
  deliveryPhone: json['delivery_phone'] as String?,
  deliveryAddress: json['delivery_address'] as String?,
  deliveryZone: json['delivery_zone'] as String?,
  deliveryFee: json['delivery_fee'] as String?,
  deliveryFeeWalletApplied: json['delivery_fee_wallet_applied'] as String?,
  deliveryFeeAmountDue: json['delivery_fee_amount_due'] as String?,
);

Map<String, dynamic> _$BookingToJson(_Booking instance) => <String, dynamic>{
  'id': instance.id,
  'workshop_id': instance.workshopId,
  'workshop_title': instance.workshopTitle,
  'workshop_image': instance.workshopImage,
  'workshop_slot_id': instance.workshopSlotId,
  'booking_date': instance.bookingDate,
  'start_time': instance.startTime,
  'end_time': instance.endTime,
  'location_url': instance.locationUrl,
  'people_count': instance.peopleCount,
  'unit_price': instance.unitPrice,
  'has_celebration': instance.hasCelebration,
  'celebration_price': instance.celebrationPrice,
  'subtotal': instance.subtotal,
  'discount_amount': instance.discountAmount,
  'discount_code': instance.discountCode,
  'total_price': instance.totalPrice,
  'vat_rate': instance.vatRate,
  'vat_amount': instance.vatAmount,
  'wallet_applied': instance.walletApplied,
  'amount_due': instance.amountDue,
  'status': instance.status,
  'payment_status': instance.paymentStatus,
  'checked_in_at': instance.checkedInAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'editable_until': instance.editableUntil?.toIso8601String(),
  'payment_expires_at': instance.paymentExpiresAt?.toIso8601String(),
  'qr_value': instance.qrValue,
  'checkin_code': instance.checkinCode,
  'can_edit': instance.canEdit,
  'can_cancel': instance.canCancel,
  'images': instance.images,
  'products': instance.products,
  'pieces': instance.pieces,
  'expected_piece_count': instance.expectedPieceCount,
  'paintable_at': instance.paintableAt,
  'ready_at': instance.readyAt?.toIso8601String(),
  'pickup_deadline': instance.pickupDeadline?.toIso8601String(),
  'is_pickup_overdue': instance.isPickupOverdue,
  'delivery_method': instance.deliveryMethod,
  'delivery_status': instance.deliveryStatus,
  'delivery_lat': instance.deliveryLat,
  'delivery_lng': instance.deliveryLng,
  'delivery_phone': instance.deliveryPhone,
  'delivery_address': instance.deliveryAddress,
  'delivery_zone': instance.deliveryZone,
  'delivery_fee': instance.deliveryFee,
  'delivery_fee_wallet_applied': instance.deliveryFeeWalletApplied,
  'delivery_fee_amount_due': instance.deliveryFeeAmountDue,
};
