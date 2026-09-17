// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faq_history_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FaqHistoryState _$FaqHistoryStateFromJson(Map<String, dynamic> json) =>
    _FaqHistoryState(
      recent:
          (json['recent'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      feedback:
          (json['feedback'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
    );

Map<String, dynamic> _$FaqHistoryStateToJson(_FaqHistoryState instance) =>
    <String, dynamic>{'recent': instance.recent, 'feedback': instance.feedback};
