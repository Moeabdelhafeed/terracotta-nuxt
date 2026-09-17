// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workshop_slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkshopSlot _$WorkshopSlotFromJson(Map<String, dynamic> json) =>
    _WorkshopSlot(
      workshopSlotId: (json['workshop_slot_id'] as num).toInt(),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      booked: (json['booked'] as num?)?.toInt(),
      remaining: (json['remaining'] as num?)?.toInt(),
      isFull: json['is_full'] as bool?,
      hasConflict: json['has_conflict'] as bool?,
      isNonCancellable: json['is_non_cancellable'] as bool?,
      cancelUntil: json['cancel_until'] as String?,
    );

Map<String, dynamic> _$WorkshopSlotToJson(_WorkshopSlot instance) =>
    <String, dynamic>{
      'workshop_slot_id': instance.workshopSlotId,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'capacity': instance.capacity,
      'booked': instance.booked,
      'remaining': instance.remaining,
      'is_full': instance.isFull,
      'has_conflict': instance.hasConflict,
      'is_non_cancellable': instance.isNonCancellable,
      'cancel_until': instance.cancelUntil,
    };
