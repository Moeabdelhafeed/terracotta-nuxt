// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScanBooking _$ScanBookingFromJson(Map<String, dynamic> json) => _ScanBooking(
  id: (json['id'] as num).toInt(),
  userName: json['user_name'] as String?,
  peopleCount: (json['people_count'] as num?)?.toInt() ?? 1,
  status: json['status'] as String? ?? 'confirmed',
  checkedInAt: json['checked_in_at'] == null
      ? null
      : DateTime.parse(json['checked_in_at'] as String),
  checkedInCount: (json['checked_in_count'] as num?)?.toInt(),
  hasCelebration: json['has_celebration'] as bool? ?? false,
  piecesCount: (json['pieces_count'] as num?)?.toInt() ?? 0,
  expectedPieceCount: (json['expected_piece_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$ScanBookingToJson(_ScanBooking instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_name': instance.userName,
      'people_count': instance.peopleCount,
      'status': instance.status,
      'checked_in_at': instance.checkedInAt?.toIso8601String(),
      'checked_in_count': instance.checkedInCount,
      'has_celebration': instance.hasCelebration,
      'pieces_count': instance.piecesCount,
      'expected_piece_count': instance.expectedPieceCount,
    };

_ScanSession _$ScanSessionFromJson(Map<String, dynamic> json) => _ScanSession(
  workshopId: (json['workshop_id'] as num).toInt(),
  workshopSlotId: (json['workshop_slot_id'] as num).toInt(),
  workshopTitle: json['workshop_title'] as String?,
  startTime: json['start_time'] as String?,
  endTime: json['end_time'] as String?,
  capacity: (json['capacity'] as num?)?.toInt(),
  totalPeople: (json['total_people'] as num?)?.toInt() ?? 0,
  checkedInCount: (json['checked_in_count'] as num?)?.toInt() ?? 0,
  canStart: json['can_start'] as bool? ?? false,
  canFinish: json['can_finish'] as bool? ?? false,
  canCheckIn: json['can_check_in'] as bool? ?? true,
  sessionFinishedAt: json['session_finished_at'] == null
      ? null
      : DateTime.parse(json['session_finished_at'] as String),
  bookings:
      (json['bookings'] as List<dynamic>?)
          ?.map((e) => ScanBooking.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ScanBooking>[],
);

Map<String, dynamic> _$ScanSessionToJson(_ScanSession instance) =>
    <String, dynamic>{
      'workshop_id': instance.workshopId,
      'workshop_slot_id': instance.workshopSlotId,
      'workshop_title': instance.workshopTitle,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'capacity': instance.capacity,
      'total_people': instance.totalPeople,
      'checked_in_count': instance.checkedInCount,
      'can_start': instance.canStart,
      'can_finish': instance.canFinish,
      'can_check_in': instance.canCheckIn,
      'session_finished_at': instance.sessionFinishedAt?.toIso8601String(),
      'bookings': instance.bookings,
    };

_ScanDay _$ScanDayFromJson(Map<String, dynamic> json) => _ScanDay(
  date: json['date'] as String?,
  sessions:
      (json['sessions'] as List<dynamic>?)
          ?.map((e) => ScanSession.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ScanSession>[],
);

Map<String, dynamic> _$ScanDayToJson(_ScanDay instance) => <String, dynamic>{
  'date': instance.date,
  'sessions': instance.sessions,
};
