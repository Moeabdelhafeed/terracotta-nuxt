import 'package:flutter/material.dart';

/// The floor for `FeedbackScreen`.
abstract final class FeedbackDefaults {
  /// Space between one section of the form and the next.
  static const sectionGap = 16.0;

  /// Space between a label and the field under it.
  static const labelGap = 8.0;

  /// The form's own padding.
  static const contentPadding = EdgeInsets.all(16);

  /// An attachment thumbnail. Square, because a screenshot's own
  /// aspect is not known until it is picked and a row of mismatched
  /// tiles reads as broken.
  static const thumbSize = 72.0;
  static const thumbRadius = 8.0;
  static const thumbSpacing = 8.0;

  /// The disc behind an attachment's remove button.
  ///
  /// It sits ON the screenshot, so it cannot take a palette colour —
  /// the same call the media picker and the video controls make.
  static const removeScrimOpacity = 0.54;
  static const removeIconSize = 14.0;
}

/// How `FeedbackScreen` LOOKS.
///
/// Every field is nullable: unanswered means "ask the theme, then the
/// floor".
///
/// Separate from `FeedbackOptions`, which says what the form ASKS —
/// which types, which fields, how many attachments, how long the
/// cooldown is. That one is behaviour and lives in `core/feedback/`
/// with the payload and the submitter; this one is the look, and it
/// had no home at all: twenty-odd gaps, a thumbnail size and a corner
/// were written into the screen.
@immutable
class FeedbackStyle {
  const FeedbackStyle({
    this.sectionGap,
    this.labelGap,
    this.contentPadding,
    this.thumbSize,
    this.thumbRadius,
    this.thumbSpacing,
    this.removeScrimOpacity,
    this.removeIconSize,
  });

  /// The floor — the only place a compile-time constant lives.
  static const defaults = FeedbackStyle(
    sectionGap: FeedbackDefaults.sectionGap,
    labelGap: FeedbackDefaults.labelGap,
    contentPadding: FeedbackDefaults.contentPadding,
    thumbSize: FeedbackDefaults.thumbSize,
    thumbRadius: FeedbackDefaults.thumbRadius,
    thumbSpacing: FeedbackDefaults.thumbSpacing,
    removeScrimOpacity: FeedbackDefaults.removeScrimOpacity,
    removeIconSize: FeedbackDefaults.removeIconSize,
  );

  /// Tighter, for a form in a sheet rather than on a route.
  static const compact = FeedbackStyle(
    sectionGap: 10,
    labelGap: 6,
    contentPadding: EdgeInsets.all(12),
    thumbSize: 56,
  );

  final double? sectionGap;
  final double? labelGap;
  final EdgeInsets? contentPadding;
  final double? thumbSize;
  final double? thumbRadius;
  final double? thumbSpacing;
  final double? removeScrimOpacity;
  final double? removeIconSize;

  /// Field-by-field: whatever `other` answers wins, and what it leaves
  /// null keeps this bag's answer.
  FeedbackStyle mergedWith(FeedbackStyle? other) {
    if (other == null) return this;
    return FeedbackStyle(
      sectionGap: other.sectionGap ?? sectionGap,
      labelGap: other.labelGap ?? labelGap,
      contentPadding: other.contentPadding ?? contentPadding,
      thumbSize: other.thumbSize ?? thumbSize,
      thumbRadius: other.thumbRadius ?? thumbRadius,
      thumbSpacing: other.thumbSpacing ?? thumbSpacing,
      removeScrimOpacity: other.removeScrimOpacity ?? removeScrimOpacity,
      removeIconSize: other.removeIconSize ?? removeIconSize,
    );
  }

  FeedbackStyle copyWith({
    double? sectionGap,
    double? labelGap,
    EdgeInsets? contentPadding,
    double? thumbSize,
    double? thumbRadius,
    double? thumbSpacing,
    double? removeScrimOpacity,
    double? removeIconSize,
  }) => FeedbackStyle(
    sectionGap: sectionGap ?? this.sectionGap,
    labelGap: labelGap ?? this.labelGap,
    contentPadding: contentPadding ?? this.contentPadding,
    thumbSize: thumbSize ?? this.thumbSize,
    thumbRadius: thumbRadius ?? this.thumbRadius,
    thumbSpacing: thumbSpacing ?? this.thumbSpacing,
    removeScrimOpacity: removeScrimOpacity ?? this.removeScrimOpacity,
    removeIconSize: removeIconSize ?? this.removeIconSize,
  );

  @override
  bool operator ==(Object other) =>
      other is FeedbackStyle &&
      other.sectionGap == sectionGap &&
      other.labelGap == labelGap &&
      other.contentPadding == contentPadding &&
      other.thumbSize == thumbSize &&
      other.thumbRadius == thumbRadius &&
      other.thumbSpacing == thumbSpacing &&
      other.removeScrimOpacity == removeScrimOpacity &&
      other.removeIconSize == removeIconSize;

  @override
  int get hashCode => Object.hash(
    sectionGap,
    labelGap,
    contentPadding,
    thumbSize,
    thumbRadius,
    thumbSpacing,
    removeScrimOpacity,
    removeIconSize,
  );
}

/// A [FeedbackStyle] with every question answered.
@immutable
class ResolvedFeedbackStyle {
  const ResolvedFeedbackStyle({
    required this.sectionGap,
    required this.labelGap,
    required this.contentPadding,
    required this.thumbSize,
    required this.thumbRadius,
    required this.thumbSpacing,
    required this.removeScrimOpacity,
    required this.removeIconSize,
  });

  final double sectionGap;
  final double labelGap;
  final EdgeInsets contentPadding;
  final double thumbSize;
  final double thumbRadius;
  final double thumbSpacing;
  final double removeScrimOpacity;
  final double removeIconSize;
}
