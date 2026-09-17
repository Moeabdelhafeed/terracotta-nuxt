// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PreferencesState _$PreferencesStateFromJson(
  Map<String, dynamic> json,
) => _PreferencesState(
  language: json['language'] == null
      ? defaultLanguage
      : Language.fromJson(json['language'] as Map<String, dynamic>),
  themeMode: json['theme_mode'] == null
      ? ThemeMode.system
      : const _ThemeModeConverter().fromJson(json['theme_mode'] as String),
  appRole:
      $enumDecodeNullable(_$AppRoleEnumMap, json['app_role']) ?? AppRole.user,
  colorSaturation:
      $enumDecodeNullable(_$ColorSaturationEnumMap, json['color_saturation']) ??
      ColorSaturation.normal,
  revealShapeKey: json['reveal_shape_key'] as String? ?? 'circle',
  revealDirectionName: json['reveal_direction_name'] as String? ?? 'expand',
  seenOnboarding: json['seen_onboarding'] as bool? ?? false,
  isFirstTime: json['is_first_time'] as bool? ?? true,
  fontScale: (json['font_scale'] as num?)?.toDouble() ?? 1.0,
  dynamicColor: json['dynamic_color'] as bool? ?? false,
);

Map<String, dynamic> _$PreferencesStateToJson(_PreferencesState instance) =>
    <String, dynamic>{
      'language': instance.language,
      'theme_mode': const _ThemeModeConverter().toJson(instance.themeMode),
      'app_role': _$AppRoleEnumMap[instance.appRole]!,
      'color_saturation': _$ColorSaturationEnumMap[instance.colorSaturation]!,
      'reveal_shape_key': instance.revealShapeKey,
      'reveal_direction_name': instance.revealDirectionName,
      'seen_onboarding': instance.seenOnboarding,
      'is_first_time': instance.isFirstTime,
      'font_scale': instance.fontScale,
      'dynamic_color': instance.dynamicColor,
    };

const _$AppRoleEnumMap = {AppRole.guest: 'guest', AppRole.user: 'user'};

const _$ColorSaturationEnumMap = {
  ColorSaturation.muted: 'muted',
  ColorSaturation.normal: 'normal',
  ColorSaturation.vibrant: 'vibrant',
};
