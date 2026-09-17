// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complaint.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Complaint _$ComplaintFromJson(Map<String, dynamic> json) => _Complaint(
  id: (json['id'] as num).toInt(),
  type: json['type'] as String,
  message: json['message'] as String,
  reference: json['reference'] as String?,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  resolvedAt: json['resolved_at'] == null
      ? null
      : DateTime.parse(json['resolved_at'] as String),
);

Map<String, dynamic> _$ComplaintToJson(_Complaint instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'message': instance.message,
      'reference': instance.reference,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'resolved_at': instance.resolvedAt?.toIso8601String(),
    };
