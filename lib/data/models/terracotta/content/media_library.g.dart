// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_library.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaLibrary _$MediaLibraryFromJson(Map<String, dynamic> json) =>
    _MediaLibrary(
      group: json['group'] as String,
      media: readSections(json['media']),
    );

Map<String, dynamic> _$MediaLibraryToJson(_MediaLibrary instance) =>
    <String, dynamic>{'group': instance.group, 'media': instance.media};
