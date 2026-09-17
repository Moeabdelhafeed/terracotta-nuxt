// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pagination_links.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaginationLinks _$PaginationLinksFromJson(Map<String, dynamic> json) =>
    _PaginationLinks(
      first: json['first'] as String?,
      last: json['last'] as String?,
      prev: json['prev'] as String?,
      next: json['next'] as String?,
    );

Map<String, dynamic> _$PaginationLinksToJson(_PaginationLinks instance) =>
    <String, dynamic>{
      'first': instance.first,
      'last': instance.last,
      'prev': instance.prev,
      'next': instance.next,
    };
