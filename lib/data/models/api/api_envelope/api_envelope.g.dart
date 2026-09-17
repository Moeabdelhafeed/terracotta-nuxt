// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApiEnvelope<T> _$ApiEnvelopeFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => _ApiEnvelope<T>(
  status: readStatusFlag(json, 'status') as bool? ?? true,
  statusCode: (json['status_code'] as num?)?.toInt(),
  message: json['message'] as String?,
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
  meta: json['meta'] as Map<String, dynamic>?,
  errors: flatErrors(json['errors']),
  fieldErrors: keyedErrors(json['errors']),
);

Map<String, dynamic> _$ApiEnvelopeToJson<T>(
  _ApiEnvelope<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'status': instance.status,
  'status_code': instance.statusCode,
  'message': instance.message,
  'data': _$nullableGenericToJson(instance.data, toJsonT),
  'meta': instance.meta,
  'errors': instance.errors,
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);
