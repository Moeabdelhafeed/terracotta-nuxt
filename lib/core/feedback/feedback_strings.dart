import 'package:flutter/foundation.dart';

import '../../generated/l10n.dart';
import '../localization/tr.dart';

/// User-facing strings of the feedback flow. Every field is
/// overridable at mount-time; `null` (the default) resolves to the
/// localized ARB value through [Tr] at read time — const defaults
/// can't call `Tr.t`, hence the private-field + getter shape.
///
/// `emailHint` stays a literal format template
/// (`we@yourcompany.com`) — structure preview, not prose.
@immutable
class FeedbackStrings {
  const FeedbackStrings({
    String? title,
    String? subtitle,
    String? typeLabel,
    String? severityLabel,
    String? descriptionLabel,
    String? descriptionHint,
    String? descriptionRequired,
    String? reproLabel,
    String? reproHint,
    String? emailLabel,
    this.emailHint = 'we@yourcompany.com',
    String? emailInvalid,
    String? attachmentsLabel,
    String? diagnosticsLabel,
    String? diagnosticsHint,
    String? pickGallery,
    String? pickCamera,
    String? submit,
    String? submitting,
    String? successTitle,
    String? successBody,
    String? cooldownTitle,
    String? cooldownHint,
    String? offlineQueuedTitle,
    String? offlineQueuedBody,
    String? failureTitle,
    String? failureBody,
    String? disabled,
  }) : _title = title,
       _subtitle = subtitle,
       _typeLabel = typeLabel,
       _severityLabel = severityLabel,
       _descriptionLabel = descriptionLabel,
       _descriptionHint = descriptionHint,
       _descriptionRequired = descriptionRequired,
       _reproLabel = reproLabel,
       _reproHint = reproHint,
       _emailLabel = emailLabel,
       _emailInvalid = emailInvalid,
       _attachmentsLabel = attachmentsLabel,
       _diagnosticsLabel = diagnosticsLabel,
       _diagnosticsHint = diagnosticsHint,
       _pickGallery = pickGallery,
       _pickCamera = pickCamera,
       _submit = submit,
       _submitting = submitting,
       _successTitle = successTitle,
       _successBody = successBody,
       _cooldownTitle = cooldownTitle,
       _cooldownHint = cooldownHint,
       _offlineQueuedTitle = offlineQueuedTitle,
       _offlineQueuedBody = offlineQueuedBody,
       _failureTitle = failureTitle,
       _failureBody = failureBody,
       _disabled = disabled;

  final String? _title;
  final String? _subtitle;
  final String? _typeLabel;
  final String? _severityLabel;
  final String? _descriptionLabel;
  final String? _descriptionHint;
  final String? _descriptionRequired;
  final String? _reproLabel;
  final String? _reproHint;
  final String? _emailLabel;
  final String emailHint;
  final String? _emailInvalid;
  final String? _attachmentsLabel;
  final String? _diagnosticsLabel;
  final String? _diagnosticsHint;
  final String? _pickGallery;
  final String? _pickCamera;
  final String? _submit;
  final String? _submitting;
  final String? _successTitle;
  final String? _successBody;
  final String? _cooldownTitle;
  final String? _cooldownHint;
  final String? _offlineQueuedTitle;
  final String? _offlineQueuedBody;
  final String? _failureTitle;
  final String? _failureBody;
  final String? _disabled;

  String get title =>
      _title ?? Tr.t('feedback.title', S.current.feedback_title);
  String get subtitle =>
      _subtitle ?? Tr.t('feedback.subtitle', S.current.feedback_subtitle);
  String get typeLabel =>
      _typeLabel ?? Tr.t('feedback.type_label', S.current.feedback_type_label);
  String get severityLabel =>
      _severityLabel ??
      Tr.t('feedback.severity_label', S.current.feedback_severity_label);
  String get descriptionLabel =>
      _descriptionLabel ??
      Tr.t('feedback.description_label', S.current.feedback_description_label);
  String get descriptionHint =>
      _descriptionHint ??
      Tr.t('feedback.description_hint', S.current.feedback_description_hint);
  String get descriptionRequired =>
      _descriptionRequired ??
      Tr.t(
        'feedback.description_required',
        S.current.feedback_description_required,
      );
  String get reproLabel =>
      _reproLabel ??
      Tr.t('feedback.repro_label', S.current.feedback_repro_label);
  String get reproHint =>
      _reproHint ?? Tr.t('feedback.repro_hint', S.current.feedback_repro_hint);
  String get emailLabel =>
      _emailLabel ??
      Tr.t('feedback.email_label', S.current.feedback_email_label);
  String get emailInvalid =>
      _emailInvalid ??
      Tr.t('feedback.email_invalid', S.current.feedback_email_invalid);
  String get attachmentsLabel =>
      _attachmentsLabel ??
      Tr.t('feedback.attachments_label', S.current.feedback_attachments_label);
  String get diagnosticsLabel =>
      _diagnosticsLabel ??
      Tr.t('feedback.diagnostics_label', S.current.feedback_diagnostics_label);
  String get diagnosticsHint =>
      _diagnosticsHint ??
      Tr.t('feedback.diagnostics_hint', S.current.feedback_diagnostics_hint);
  String get pickGallery =>
      _pickGallery ??
      Tr.t('feedback.pick_gallery', S.current.feedback_pick_gallery);
  String get pickCamera =>
      _pickCamera ??
      Tr.t('feedback.pick_camera', S.current.feedback_pick_camera);
  String get submit =>
      _submit ?? Tr.t('feedback.submit', S.current.feedback_submit);
  String get submitting =>
      _submitting ?? Tr.t('feedback.submitting', S.current.feedback_submitting);
  String get successTitle =>
      _successTitle ??
      Tr.t('feedback.success_title', S.current.feedback_success_title);
  String get successBody =>
      _successBody ??
      Tr.t('feedback.success_body', S.current.feedback_success_body);
  String get cooldownTitle =>
      _cooldownTitle ??
      Tr.t('feedback.cooldown_title', S.current.feedback_cooldown_title);
  String get cooldownHint =>
      _cooldownHint ??
      Tr.t('feedback.cooldown_hint', S.current.feedback_cooldown_hint);
  String get offlineQueuedTitle =>
      _offlineQueuedTitle ??
      Tr.t(
        'feedback.offline_queued_title',
        S.current.feedback_offline_queued_title,
      );
  String get offlineQueuedBody =>
      _offlineQueuedBody ??
      Tr.t(
        'feedback.offline_queued_body',
        S.current.feedback_offline_queued_body,
      );
  String get failureTitle =>
      _failureTitle ??
      Tr.t('feedback.failure_title', S.current.feedback_failure_title);
  String get failureBody =>
      _failureBody ??
      Tr.t('feedback.failure_body', S.current.feedback_failure_body);
  String get disabled =>
      _disabled ?? Tr.t('feedback.disabled', S.current.feedback_disabled);

  // ─── Flow-level strings (not part of the themeable config) ─────────

  static String get attachmentTooLarge => Tr.t(
    'feedback.attachment_too_large',
    S.current.feedback_attachment_too_large,
  );

  static String get sendFeedback =>
      Tr.t('feedback.send_feedback', S.current.feedback_send_feedback);

  static String get errorNoEmailApp => Tr.t(
    'feedback.error_no_email_app',
    S.current.feedback_error_no_email_app,
  );

  static String errorEmailOpenFailed(String error) => Tr.t(
    'feedback.error_email_open_failed',
    S.current.feedback_error_email_open_failed(error),
  );

  static String get errorNoEndpoint =>
      Tr.t('feedback.error_no_endpoint', S.current.feedback_error_no_endpoint);
}
