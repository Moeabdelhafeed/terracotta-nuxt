import '../../generated/l10n.dart';
import '../localization/tr.dart';

/// Top-level category for a submission. Drives the screen's chip
/// row + decides which optional fields to surface (severity + repro
/// only show for [bug]).
enum FeedbackType {
  bug,
  suggestion,
  question,
  other;

  /// Localized chip label — resolved at read time (enum entries are
  /// const, so it can't be a stored field).
  String get label => switch (this) {
    FeedbackType.bug => Tr.t('feedback.type_bug', S.current.feedback_type_bug),
    FeedbackType.suggestion => Tr.t(
      'feedback.type_suggestion',
      S.current.feedback_type_suggestion,
    ),
    FeedbackType.question => Tr.t(
      'feedback.type_question',
      S.current.feedback_type_question,
    ),
    FeedbackType.other => Tr.t(
      'feedback.type_other',
      S.current.feedback_type_other,
    ),
  };

  /// Localized subtitle shown under the chip.
  String get subtitle => switch (this) {
    FeedbackType.bug => Tr.t(
      'feedback.type_bug_subtitle',
      S.current.feedback_type_bug_subtitle,
    ),
    FeedbackType.suggestion => Tr.t(
      'feedback.type_suggestion_subtitle',
      S.current.feedback_type_suggestion_subtitle,
    ),
    FeedbackType.question => Tr.t(
      'feedback.type_question_subtitle',
      S.current.feedback_type_question_subtitle,
    ),
    FeedbackType.other => Tr.t(
      'feedback.type_other_subtitle',
      S.current.feedback_type_other_subtitle,
    ),
  };
}

/// Severity for bug reports. Hidden for non-bug types.
enum FeedbackSeverity {
  low,
  medium,
  high,
  blocking;

  /// Localized selector label.
  String get label => switch (this) {
    FeedbackSeverity.low => Tr.t(
      'feedback.severity_low',
      S.current.feedback_severity_low,
    ),
    FeedbackSeverity.medium => Tr.t(
      'feedback.severity_medium',
      S.current.feedback_severity_medium,
    ),
    FeedbackSeverity.high => Tr.t(
      'feedback.severity_high',
      S.current.feedback_severity_high,
    ),
    FeedbackSeverity.blocking => Tr.t(
      'feedback.severity_blocking',
      S.current.feedback_severity_blocking,
    ),
  };

  /// Localized subtitle.
  String get subtitle => switch (this) {
    FeedbackSeverity.low => Tr.t(
      'feedback.severity_low_subtitle',
      S.current.feedback_severity_low_subtitle,
    ),
    FeedbackSeverity.medium => Tr.t(
      'feedback.severity_medium_subtitle',
      S.current.feedback_severity_medium_subtitle,
    ),
    FeedbackSeverity.high => Tr.t(
      'feedback.severity_high_subtitle',
      S.current.feedback_severity_high_subtitle,
    ),
    FeedbackSeverity.blocking => Tr.t(
      'feedback.severity_blocking_subtitle',
      S.current.feedback_severity_blocking_subtitle,
    ),
  };
}
