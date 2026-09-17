import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `button_` key prefix family — default tooltips and
/// labels of the pre-built button variants in `shared/common/buttons/`.
class ButtonStrings {
  ButtonStrings._();

  static String get addTooltip =>
      Tr.t('button.tooltip_add', S.current.button_tooltip_add);
  static String get copyTooltip =>
      Tr.t('button.tooltip_copy', S.current.button_tooltip_copy);
  static String get deleteTooltip =>
      Tr.t('button.tooltip_delete', S.current.button_tooltip_delete);
  static String get editTooltip =>
      Tr.t('button.tooltip_edit', S.current.button_tooltip_edit);
  static String get filterTooltip =>
      Tr.t('button.tooltip_filter', S.current.button_tooltip_filter);
  static String get moreTooltip =>
      Tr.t('button.tooltip_more', S.current.button_tooltip_more);
  static String get refreshTooltip =>
      Tr.t('button.tooltip_refresh', S.current.button_tooltip_refresh);
  static String get searchTooltip =>
      Tr.t('button.tooltip_search', S.current.button_tooltip_search);
  static String get sendTooltip =>
      Tr.t('button.tooltip_send', S.current.button_tooltip_send);
  static String get addFavoriteTooltip => Tr.t(
    'button.tooltip_add_favorite',
    S.current.button_tooltip_add_favorite,
  );
  static String get removeFavoriteTooltip => Tr.t(
    'button.tooltip_remove_favorite',
    S.current.button_tooltip_remove_favorite,
  );
  static String get startVoiceInputTooltip => Tr.t(
    'button.tooltip_start_voice_input',
    S.current.button_tooltip_start_voice_input,
  );
  static String get stopListeningTooltip => Tr.t(
    'button.tooltip_stop_listening',
    S.current.button_tooltip_stop_listening,
  );
  static String get readMore =>
      Tr.t('button.read_more', S.current.button_read_more);
  static String get showLess =>
      Tr.t('button.show_less', S.current.button_show_less);
  static String get iconSemanticLabel =>
      Tr.t('button.icon_semantic_label', S.current.button_icon_semantic_label);
  static String get resultSuccess =>
      Tr.t('button.result_success', S.current.button_result_success);
  static String get resultFailed =>
      Tr.t('button.result_failed', S.current.button_result_failed);
}

/// Strings for the `social_button_` key prefix family — social sign-in
/// button labels ("Continue with {provider}"; brand names stay literal).
class SocialButtonStrings {
  SocialButtonStrings._();

  static String continueWith(String provider) => Tr.t(
    'social_button.continue_with',
    S.current.social_button_continue_with(provider),
  );
}
