// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'painting_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaintingSession _$PaintingSessionFromJson(Map<String, dynamic> json) =>
    _PaintingSession(
      bookingId: (json['booking_id'] as num?)?.toInt(),
      date: json['date'] as String?,
      workshopTitle: json['workshop_title'] as String?,
      isUpcoming: json['is_upcoming'] as bool? ?? false,
    );

Map<String, dynamic> _$PaintingSessionToJson(_PaintingSession instance) =>
    <String, dynamic>{
      'booking_id': instance.bookingId,
      'date': instance.date,
      'workshop_title': instance.workshopTitle,
      'is_upcoming': instance.isUpcoming,
    };
