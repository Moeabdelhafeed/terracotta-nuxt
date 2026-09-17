// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_piece.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookingPiece _$BookingPieceFromJson(Map<String, dynamic> json) =>
    _BookingPiece(
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
      paintingSession: json['painting_session'] == null
          ? null
          : PaintingSession.fromJson(
              json['painting_session'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$BookingPieceToJson(_BookingPiece instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'made_in_booking_id': instance.madeInBookingId,
      'made_on': instance.madeOn,
      'images': instance.images,
      'is_available_to_paint': instance.isAvailableToPaint,
      'painting_session': instance.paintingSession,
    };
