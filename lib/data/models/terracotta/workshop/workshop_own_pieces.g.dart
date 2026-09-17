// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workshop_own_pieces.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkshopOwnPieces _$WorkshopOwnPiecesFromJson(Map<String, dynamic> json) =>
    _WorkshopOwnPieces(
      price: json['price'] as String,
      count: (json['count'] as num?)?.toInt() ?? 0,
      pieces:
          (json['pieces'] as List<dynamic>?)
              ?.map((e) => WorkshopOwnPiece.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <WorkshopOwnPiece>[],
    );

Map<String, dynamic> _$WorkshopOwnPiecesToJson(_WorkshopOwnPieces instance) =>
    <String, dynamic>{
      'price': instance.price,
      'count': instance.count,
      'pieces': instance.pieces,
    };

_WorkshopOwnPiece _$WorkshopOwnPieceFromJson(Map<String, dynamic> json) =>
    _WorkshopOwnPiece(
      id: (json['id'] as num).toInt(),
      label: json['label'] as String?,
      madeInBookingId: (json['made_in_booking_id'] as num?)?.toInt(),
      madeOn: json['made_on'] as String?,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => ApiImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ApiImage>[],
      isAvailableToPaint: json['is_available_to_paint'] as bool? ?? true,
    );

Map<String, dynamic> _$WorkshopOwnPieceToJson(_WorkshopOwnPiece instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'made_in_booking_id': instance.madeInBookingId,
      'made_on': instance.madeOn,
      'images': instance.images,
      'is_available_to_paint': instance.isAvailableToPaint,
    };
