import '../../../generated/l10n.dart';
import '../tr.dart';

/// Feature namespace for strings shared across the app. See
/// `localization/README.md`-style pattern below:
///
///  - Flat key → `Tr.t('key', S.current.key)` via a getter.
///  - Parameterized → `Tr.t('key', S.current.key(args))` via a method.
///  - Pluralized → `Tr.plural('key', count, S.current.key(count))`.
///
/// Getters (not static fields) so locale switches re-render — fields
/// with initializers cache the first locale forever.
class CommonStrings {
  CommonStrings._();

  static String get cancel => Tr.t('common_cancel', S.current.common_cancel);
  static String get done => Tr.t('common_done', S.current.common_done);
  static String get ok => Tr.t('common_ok', S.current.common_ok);
  static String get error => Tr.t('common_error', S.current.common_error);
  static String get success => Tr.t('common_success', S.current.common_success);
  static String get retry => Tr.t('common_retry', S.current.common_retry);
  static String get loading => Tr.t('common_loading', S.current.common_loading);
  static String get selectTime =>
      Tr.t('common_select_time', S.current.common_select_time);
  static String get skip => Tr.t('common.skip', S.current.common_skip);
  static String get somethingWentWrong => Tr.t(
    'common.something_went_wrong',
    S.current.common_something_went_wrong,
  );
  static String get tryAgain =>
      Tr.t('common.try_again', S.current.common_try_again);
  static String get contactSupport =>
      Tr.t('common.contact_support', S.current.common_contact_support);
  static String get close => Tr.t('common.close', S.current.common_close);
  static String get pause => Tr.t('common_pause', S.current.common_pause);
  static String get resume => Tr.t('common_resume', S.current.common_resume);
  static String get continueLabel =>
      Tr.t('common.continue', S.current.common_continue);
  static String get dismiss => Tr.t('common.dismiss', S.current.common_dismiss);
  static String get expand => Tr.t('common.expand', S.current.common_expand);
  static String get collapse =>
      Tr.t('common.collapse', S.current.common_collapse);
  static String get undo => Tr.t('common.undo', S.current.common_undo);

  /// Past tense — the confirmation AFTER something was dismissed, which
  /// is where an undo is offered.
  static String get dismissed =>
      Tr.t('common.dismissed', S.current.common_dismissed);
  static String get clear => Tr.t('common.clear', S.current.common_clear);
  static String get clearAll =>
      Tr.t('common.clear_all', S.current.common_clear_all);
  static String get remove => Tr.t('common.remove', S.current.common_remove);
  static String get save => Tr.t('common.save', S.current.common_save);
  static String get saving => Tr.t('common.saving', S.current.common_saving);
  static String get edit => Tr.t('common.edit', S.current.common_edit);
  static String get add => Tr.t('common.add', S.current.common_add);
  static String get delete => Tr.t('common.delete', S.current.common_delete);
  static String get copy => Tr.t('common.copy', S.current.common_copy);
  static String get copiedToClipboard =>
      Tr.t('common.copied_to_clipboard', S.current.common_copied_to_clipboard);
  static String get noResults =>
      Tr.t('common.no_results', S.current.common_no_results);
  static String get refresh => Tr.t('common.refresh', S.current.common_refresh);
  static String get search => Tr.t('common.search', S.current.common_search);
  static String get share => Tr.t('common.share', S.current.common_share);
  static String get next => Tr.t('common.next', S.current.common_next);

  /// «عدد ٢» — how many of one thing.
  ///
  /// COMMON, not the booking's: the catalogue counts a piece with it
  /// and the shop checkout counts a cart line with it, and they are the
  /// same two words.
  static String count(int count) =>
      Tr.t('common_count', S.current.common_count(count));
  static String get back => Tr.t('common.back', S.current.common_back);
  static String get tapToRetry =>
      Tr.t('common.tap_to_retry', S.current.common_tap_to_retry);
  static String get settings =>
      Tr.t('common.settings', S.current.common_settings);
  static String get openSettings =>
      Tr.t('common.open_settings', S.current.common_open_settings);
  static String get paste => Tr.t('common.paste', S.current.common_paste);
  static String get stop => Tr.t('common.stop', S.current.common_stop);
  static String get previous =>
      Tr.t('common.previous', S.current.common_previous);
  static String get reset => Tr.t('common.reset', S.current.common_reset);
  static String get later => Tr.t('common.later', S.current.common_later);
  static String get update => Tr.t('common.update', S.current.common_update);
  static String get open => Tr.t('common.open', S.current.common_open);
  static String get submit => Tr.t('common.submit', S.current.common_submit);
  static String get help => Tr.t('common.help', S.current.common_help);
}
