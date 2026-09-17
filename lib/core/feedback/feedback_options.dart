import 'package:flutter/material.dart';

import 'feedback_payload.dart';
import 'feedback_strings.dart';
import 'feedback_submitter.dart';
import 'feedback_type.dart';

/// How the screen should handle screenshot attachments.
enum FeedbackScreenshotMode {
  /// Hide the attachment row entirely.
  off,

  /// Gallery picker only.
  gallery,

  /// Camera only.
  camera,

  /// Both — gallery + camera.
  all,
}

@immutable
class FeedbackOptions {
  const FeedbackOptions({
    this.enabled = true,
    this.types = const [
      FeedbackType.bug,
      FeedbackType.suggestion,
      FeedbackType.question,
      FeedbackType.other,
    ],
    this.showSeverity = true,
    this.showRepro = true,
    this.showEmail = true,
    this.requireEmailFor = const {},
    this.screenshotMode = FeedbackScreenshotMode.all,
    this.maxAttachments = 3,
    this.maxAttachmentBytes = 1024 * 1024,
    this.compressQuality = 75,
    this.cooldown = const Duration(seconds: 60),
    this.collectLogs = true,
    this.logTailLines = 40,
    this.strings = const FeedbackStrings(),
    this.submitter,
    this.headerBuilder,
    this.fieldsBuilder,
    this.footerBuilder,
    this.resultBuilder,
    this.contentBuilder,
    this.onSubmitted,
  });

  /// Master compile-time switch. Independent of RC
  /// `feedback_enabled`. Either `false` disables feedback.
  final bool enabled;

  /// Available type chips. Pass a subset / reorder to taste.
  final List<FeedbackType> types;

  final bool showSeverity;
  final bool showRepro;
  final bool showEmail;

  /// Set of types that require a non-empty email. Defaults empty
  /// (email always optional). Common: `{FeedbackType.question}`.
  final Set<FeedbackType> requireEmailFor;

  final FeedbackScreenshotMode screenshotMode;
  final int maxAttachments;

  /// Max compressed size per attachment. Bigger files are rejected
  /// with a hint to reduce.
  final int maxAttachmentBytes;

  /// JPEG quality used by `flutter_image_compress`. Lower = smaller
  /// uploads. 75 is a sane default.
  final int compressQuality;

  /// Per-user cooldown between submissions. Prevents spam.
  final Duration cooldown;

  /// Auto-collect tail of `Logger` ring buffer when attaching
  /// diagnostics.
  final bool collectLogs;
  final int logTailLines;

  final FeedbackStrings strings;

  /// Override the strategy used to send. When null, the screen picks
  /// based on RC: API endpoint when set, else mailto.
  final FeedbackSubmitter? submitter;

  /// Replace the header card (title + subtitle).
  final WidgetBuilder? headerBuilder;

  /// Replace every field. Receives the current draft + a setter so
  /// the override can wire its own widgets to the same state.
  final Widget Function(
    BuildContext context,
    FeedbackPayload draft,
    void Function(FeedbackPayload next) update,
  )?
  fieldsBuilder;

  /// Replace the footer (submit button + cancel).
  final Widget Function(
    BuildContext context,
    bool submitting,
    VoidCallback onSubmit,
  )?
  footerBuilder;

  /// Replace the post-submit success / failure / queued UI.
  final Widget Function(BuildContext context, FeedbackResult result)?
  resultBuilder;

  /// Total override. Receives `submit(draft)` so the custom UI can
  /// still drive submission.
  final Widget Function(
    BuildContext context,
    Future<FeedbackResult> Function(FeedbackPayload draft) submit,
  )?
  contentBuilder;

  /// Called after submission completes (any result kind). Use for
  /// analytics, follow-up navigation, deep-link to the help center.
  final void Function(FeedbackPayload payload, FeedbackResult result)?
  onSubmitted;

  FeedbackOptions copyWith({
    bool? enabled,
    List<FeedbackType>? types,
    bool? showSeverity,
    bool? showRepro,
    bool? showEmail,
    Set<FeedbackType>? requireEmailFor,
    FeedbackScreenshotMode? screenshotMode,
    int? maxAttachments,
    int? maxAttachmentBytes,
    int? compressQuality,
    Duration? cooldown,
    bool? collectLogs,
    int? logTailLines,
    FeedbackStrings? strings,
    FeedbackSubmitter? submitter,
  }) {
    return FeedbackOptions(
      enabled: enabled ?? this.enabled,
      types: types ?? this.types,
      showSeverity: showSeverity ?? this.showSeverity,
      showRepro: showRepro ?? this.showRepro,
      showEmail: showEmail ?? this.showEmail,
      requireEmailFor: requireEmailFor ?? this.requireEmailFor,
      screenshotMode: screenshotMode ?? this.screenshotMode,
      maxAttachments: maxAttachments ?? this.maxAttachments,
      maxAttachmentBytes: maxAttachmentBytes ?? this.maxAttachmentBytes,
      compressQuality: compressQuality ?? this.compressQuality,
      cooldown: cooldown ?? this.cooldown,
      collectLogs: collectLogs ?? this.collectLogs,
      logTailLines: logTailLines ?? this.logTailLines,
      strings: strings ?? this.strings,
      submitter: submitter ?? this.submitter,
      headerBuilder: headerBuilder,
      fieldsBuilder: fieldsBuilder,
      footerBuilder: footerBuilder,
      resultBuilder: resultBuilder,
      contentBuilder: contentBuilder,
      onSubmitted: onSubmitted,
    );
  }
}
