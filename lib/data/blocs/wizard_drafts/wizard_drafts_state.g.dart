// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wizard_drafts_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WizardDraftsState _$WizardDraftsStateFromJson(Map<String, dynamic> json) =>
    _WizardDraftsState(
      drafts:
          (json['drafts'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as Map<String, dynamic>),
          ) ??
          const <String, Map<String, dynamic>>{},
      steps:
          (json['steps'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
    );

Map<String, dynamic> _$WizardDraftsStateToJson(_WizardDraftsState instance) =>
    <String, dynamic>{'drafts': instance.drafts, 'steps': instance.steps};
