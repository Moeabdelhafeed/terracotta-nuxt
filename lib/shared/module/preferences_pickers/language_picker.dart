import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/language_strings.dart';
import '../../../core/localization/strings/preferences_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/blocs/preferences/preferences_cubit.dart';
import '../../../data/blocs/preferences/preferences_state.dart';
import '../../../data/models/common/country_code/country_code.dart';
import '../../../data/models/common/language/language.dart';
import '../../../data/services/languages_service.dart';
import '../../common/country_flag_image.dart';
import '../../common/dropdown_fields/domain/language_dropdown_field.dart';
import '../container/global_container.dart';
import '../text/global_text.dart';
import 'picker_item.dart';
import 'picker_options.dart';
import 'picker_shell.dart';

/// Locale picker. Sources options from `LanguagesService.languages`
/// — list lives in DI, populated at boot.
///
/// Each row shows the language flag + name + native locale code. Use
/// `PickerVariant.pillRow` for a compact strip in onboarding.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({
    this.options,
    this.style = const PickerStyle(),
    super.key,
  });

  static PickerOptions get _defaults => PickerOptions(
    title: PreferencesStrings.languageTitle,
    subtitle: PreferencesStrings.languageSubtitle,
    icon: Icons.language_rounded,
  );

  /// `null` renders the localized defaults.
  final PickerOptions? options;

  /// How the picker LOOKS — spacing, whether rows are ruled. The
  /// controls it draws carry their own bags; this one is thin.
  final PickerStyle style;

  @override
  Widget build(BuildContext context) {
    final languages = getIt<LanguagesService>().languages;
    final items = [
      for (final l in languages)
        PickerItem<String>(
          value: l.locale,
          // The LOCALIZED name is the label — it reads in the UI
          // language, which is what a pill and a summary tile have
          // room for. The row builder below adds the native one.
          label: LanguageStrings.nameFor(l.locale) ?? l.name ?? l.locale,
          subtitle: l.locale.toUpperCase(),
          leading: _LanguageFlag(language: l),
        ),
    ];

    return BlocBuilder<PreferencesCubit, PreferencesState>(
      // Already watching the locale — every name it draws goes
      // through `LanguageStrings`, which reads in the UI language.
      buildWhen: (a, b) => a.language.locale != b.language.locale,
      builder: (context, prefs) {
        return PickerShell<String>(
          items: items,
          value: prefs.language.locale,
          onChanged: (locale) {
            final lang = languages.firstWhere(
              (l) => l.locale == locale,
              orElse: () => prefs.language,
            );
            context.read<PreferencesCubit>().setLanguage(lang);
          },
          options: (options ?? const PickerOptions()).mergedOver(_defaults),
          style: style,
          // The app already HAS a language dropdown, and it knows more
          // than a `PickerItem` does: the flag image, the localized
          // name beside the native one, and a search string across all
          // three. The generic one built from items showed a bare
          // label, so the same preference wore two different dropdowns
          // depending on which widget a screen reached for.
          dropdownBuilder: (ctx) => LanguageDropdownField(
            value: prefs.language,
            onChanged: (lang) {
              if (lang != null) {
                ctx.read<PreferencesCubit>().setLanguage(lang);
              }
            },
          ),
          itemBuilder: (ctx, item, active) =>
              _LanguageRow(item: item, active: active, languages: languages),
        );
      },
    );
  }
}

/// The LABEL half of a language row — the flag, the localized name
/// and the native one.
///
/// It used to draw its own padding, its own bottom rule AND its own
/// check / unchecked circle. The shell owns all three now: the row is
/// a `GlobalRadio`, so a second mark beside the radio's own said the
/// same thing twice, and a screen reader heard it twice with it.
///
/// It also drew the seed's emoji flag straight into a `Text` — which
/// TOFUS on several newer iOS models, so the picker showed a row of
/// empty boxes. `LanguageDropdownField` had already hit this and
/// solved it; this row makes the same two calls it does: a flag
/// IMAGE recovered from the emoji, and both names, so the localized
/// one reads in the UI language while the native one lets a speaker
/// self-identify.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.item,
    required this.active,
    required this.languages,
  });

  final PickerItem<String> item;
  final bool active;
  final List<Language> languages;

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    final lang = languages.firstWhere(
      (l) => l.locale == item.value,
      orElse: () => Language(id: 0, locale: item.value),
    );
    final native = lang.name ?? lang.locale;
    final localized = LanguageStrings.nameFor(lang.locale) ?? native;
    return Row(
      children: [
        _LanguageFlag(language: lang),
        SizedBox(width: context.spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlobalText(
                localized,
                preset: TextPreset.bodyMedium,
                textStyle: GlobalTextStyle(
                  color: tx.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Collapses when they match — no "العربية · العربية"
              // when you are already viewing your own language.
              GlobalText(
                localized == native
                    ? lang.locale.toUpperCase()
                    : '$native · ${lang.locale.toUpperCase()}',
                preset: TextPreset.labelSmall,
                textStyle: GlobalTextStyle(color: tx.secondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The flag IMAGE, with the globe as the fallback.
///
/// Never the emoji: `LanguageDropdownField` established that they
/// tofu on newer iOS, and a picker showing empty boxes where the
/// flags should be is what sent this back for a second pass.
class _LanguageFlag extends StatelessWidget {
  const _LanguageFlag({required this.language});

  final Language language;

  @override
  Widget build(BuildContext context) {
    final iso = language.flagIsoCode;
    final bg = context.backgroundColors;
    return GlobalContainer(
      style: ContainerStyle(
        width: 32,
        height: 32,
        backgroundColor: bg.outlineVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(context.radii.sm),
        padding: EdgeInsets.zero,
      ),
      child: Center(
        child: iso == null
            ? Icon(
                Icons.language_rounded,
                size: context.iconSizes.md,
                color: context.iconColors.primary,
              )
            : CountryFlagImage(country: CountryCode(code: iso)),
      ),
    );
  }
}
