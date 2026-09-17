import 'package:flutter/material.dart';

import '../../../shared/module/feedback/feedback_style.dart';
import '../../../shared/module/feedback/theme/feedback_theme.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for `FeedbackScreen`.
///
/// The form's rhythm comes from the TOKENS, so it breathes with the
/// window like every other screen. All of it used to be written into
/// the widget as bare `SizedBox(height: 16)`.
class MyGlobalFeedbackTheme {
  MyGlobalFeedbackTheme._();

  static GlobalFeedbackTheme build({required AppTokens tokens}) {
    return GlobalFeedbackTheme(
      style: FeedbackStyle(
        sectionGap: tokens.spacing.md,
        labelGap: tokens.spacing.sm,
        contentPadding: EdgeInsets.all(tokens.spacing.md),
        thumbRadius: tokens.radii.sm,
        thumbSpacing: tokens.spacing.sm,
      ),
    );
  }
}
