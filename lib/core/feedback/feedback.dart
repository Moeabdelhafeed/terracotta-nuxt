/// Feedback / bug-report module — drop-in screen, button, submitter
/// strategies, diagnostics collector, capture-current-screen, RC
/// flags, offline-queue integration.
///
/// ```dart
/// FeedbackButton.tile()                   // settings row
/// FeedbackButton.icon()                   // appbar action
/// FeedbackButton.fab()                    // floating
/// Navigator.push(... => FeedbackScreen())
/// ```
library;

// UI surfaces live in `lib/shared/module/feedback/` per the
// core-no-UI rule. The barrel re-exports them so callers can keep
// importing `core/feedback/feedback.dart` as the single entry point.
export '../../shared/module/feedback/feedback_button.dart';
export '../../shared/module/feedback/feedback_screen.dart';
export 'feedback_diagnostics.dart';
export 'feedback_options.dart';
export 'feedback_payload.dart';
export 'feedback_strings.dart';
export 'feedback_submitter.dart';
export 'feedback_type.dart';
