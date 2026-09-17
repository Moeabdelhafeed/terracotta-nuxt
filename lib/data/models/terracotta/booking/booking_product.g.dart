// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookingProduct _$BookingProductFromJson(Map<String, dynamic> json) =>
    _BookingProduct(
      workshopProductId: (json['workshop_product_id'] as num?)?.toInt(),
      workshopBookingPieceId: (json['workshop_booking_piece_id'] as num?)
          ?.toInt(),
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      image: json['image'] == null
          ? null
          : ApiImage.fromJson(json['image'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: json['unit_price'] as String,
    );

Map<String, dynamic> _$BookingProductToJson(_BookingProduct instance) =>
    <String, dynamic>{
      'workshop_product_id': instance.workshopProductId,
      'workshop_booking_piece_id': instance.workshopBookingPieceId,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'image': instance.image,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
    };
