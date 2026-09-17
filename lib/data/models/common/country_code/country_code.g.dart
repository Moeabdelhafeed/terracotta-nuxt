// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_code.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CountryCode _$CountryCodeFromJson(Map<String, dynamic> json) => _CountryCode(
  code: json['code'] as String,
  name: json['name'] as String?,
  flag: json['flag'] as String?,
  dialCode: json['dial_code'] as String?,
  minLength: (json['min_length'] as num?)?.toInt(),
  maxLength: (json['max_length'] as num?)?.toInt(),
  mobileMinLength: (json['mobile_min_length'] as num?)?.toInt(),
  mobileMaxLength: (json['mobile_max_length'] as num?)?.toInt(),
  groupSizes: (json['group_sizes'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  mobilePrefixes: (json['mobile_prefixes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$CountryCodeToJson(_CountryCode instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'flag': instance.flag,
      'dial_code': instance.dialCode,
      'min_length': instance.minLength,
      'max_length': instance.maxLength,
      'mobile_min_length': instance.mobileMinLength,
      'mobile_max_length': instance.mobileMaxLength,
      'group_sizes': instance.groupSizes,
      'mobile_prefixes': instance.mobilePrefixes,
    };
