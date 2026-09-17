import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `faq_` key prefix family — help-center / FAQ pages.
class FaqStrings {
  FaqStrings._();

  static String get helpCenter =>
      Tr.t('faq.help_center', S.current.faq_help_center);
  static String get searchHint =>
      Tr.t('faq.search_hint', S.current.faq_search_hint);
  static String get noMatchingAnswers =>
      Tr.t('faq.no_matching_answers', S.current.faq_no_matching_answers);
  static String get wasThisHelpful =>
      Tr.t('faq.was_this_helpful', S.current.faq_was_this_helpful);
  static String get markedHelpful =>
      Tr.t('faq.marked_helpful', S.current.faq_marked_helpful);
  static String get feedbackRecorded =>
      Tr.t('faq.feedback_recorded', S.current.faq_feedback_recorded);
  static String get helpful => Tr.t('faq.helpful', S.current.faq_helpful);
  static String get notHelpful =>
      Tr.t('faq.not_helpful', S.current.faq_not_helpful);
  static String get loadFailed =>
      Tr.t('faq.load_failed', S.current.faq_load_failed);
  static String get noArticlesYet =>
      Tr.t('faq.no_articles_yet', S.current.faq_no_articles_yet);
  static String get thanksMarkedHelpful =>
      Tr.t('faq.thanks_marked_helpful', S.current.faq_thanks_marked_helpful);
  static String get thanksFeedbackRecorded => Tr.t(
    'faq.thanks_feedback_recorded',
    S.current.faq_thanks_feedback_recorded,
  );
  static String get all => Tr.t('faq.all', S.current.faq_all);
  static String get recent => Tr.t('faq.recent', S.current.faq_recent);
  static String get stillNeedHelp =>
      Tr.t('faq.still_need_help', S.current.faq_still_need_help);
}
