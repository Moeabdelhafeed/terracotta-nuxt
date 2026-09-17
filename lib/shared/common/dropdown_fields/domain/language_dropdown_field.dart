import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../core/localization/strings/language_strings.dart';
import '../../../../data/models/common/country_code/country_code.dart';
import '../../../../data/models/common/language/language.dart';
import '../../../../data/services/languages_service.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../country_flag_image.dart';
import '../generic/simple_dropdown_field.dart';

/// Language picker — items pulled from [LanguagesService] at build
/// time. Each item shows the NATIVE name (self-identifying in any UI
/// locale — "العربية" stays "العربية" in an English UI). No emoji
/// flag: they render as tofu on several newer iOS models, and a flag
/// misrepresents multi-country languages anyway.
class LanguageDropdownField extends StatelessWidget {
  const LanguageDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  final Language? value;
  final ValueChanged<Language?>? onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final langs = getIt<LanguagesService>().languages;
    final items = langs.map((l) {
      final iso = l.flagIsoCode;
      final native = l.name ?? l.locale;
      final localized = LanguageStrings.nameFor(l.locale) ?? native;
      return DropdownItem<Language>(
        value: l,
        // `flag  <localized>  <native>` — the localized name reads in
        // the UI language, the native one lets a speaker self-identify.
        // When they match (viewing your own language, or no
        // translation) the trailing collapses — no 'العربية العربية'.
        label: localized,
        // Flag IMAGE (emoji tofus on newer iOS models); globe icon
        // when the seed carries no flag.
        leading: iso != null
            ? CountryFlagImage(country: CountryCode(code: iso))
            : Icon(
                Icons.language_rounded,
                size: 20,
                color: context.iconColors.primary,
              ),
        trailing: localized == native
            ? null
            : Text(
                native,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.textColors.secondary,
                ),
              ),
        searchText: '$native $localized ${l.locale}',
      );
    }).toList();
    return SimpleDropdownField<Language>(
      items: items,
      value: value,
      onChanged: onChanged,
      label: label ?? DropDownStrings.languageLabel,
      hint: hint ?? DropDownStrings.languageHint,
      enabled: enabled,
      errorText: errorText,
    );
  }
}
