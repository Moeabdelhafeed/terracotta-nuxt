// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_history_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchHistoryState _$SearchHistoryStateFromJson(Map<String, dynamic> json) =>
    _SearchHistoryState(
      entries:
          (json['entries'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>).map((e) => e as String).toList(),
            ),
          ) ??
          const <String, List<String>>{},
    );

Map<String, dynamic> _$SearchHistoryStateToJson(_SearchHistoryState instance) =>
    <String, dynamic>{'entries': instance.entries};
