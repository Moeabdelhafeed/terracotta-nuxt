// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScanResult _$ScanResultFromJson(Map<String, dynamic> json) => _ScanResult(
  id: (json['id'] as num).toInt(),
  userName: json['user_name'] as String?,
  workshopId: (json['workshop_id'] as num?)?.toInt(),
  workshopSlotId: (json['workshop_slot_id'] as num?)?.toInt(),
  workshopTitle: json['workshop_title'] as String?,
  peopleCount: (json['people_count'] as num?)?.toInt() ?? 1,
  checkedInCount: (json['checked_in_count'] as num?)?.toInt(),
  alreadyCheckedIn: json['already_checked_in'] as bool? ?? false,
  needsCount: json['needs_count'] as bool? ?? false,
);

Map<String, dynamic> _$ScanResultToJson(_ScanResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_name': instance.userName,
      'workshop_id': instance.workshopId,
      'workshop_slot_id': instance.workshopSlotId,
      'workshop_title': instance.workshopTitle,
      'people_count': instance.peopleCount,
      'checked_in_count': instance.checkedInCount,
      'already_checked_in': instance.alreadyCheckedIn,
      'needs_count': instance.needsCount,
    };
