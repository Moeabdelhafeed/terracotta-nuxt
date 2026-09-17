// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_calendar.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AvailabilityCalendar _$AvailabilityCalendarFromJson(
  Map<String, dynamic> json,
) => _AvailabilityCalendar(
  maxAvailableSeats: (json['max_available_seats'] as num).toInt(),
  blockedDates:
      (json['blocked_dates'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$AvailabilityCalendarToJson(
  _AvailabilityCalendar instance,
) => <String, dynamic>{
  'max_available_seats': instance.maxAvailableSeats,
  'blocked_dates': instance.blockedDates,
};
