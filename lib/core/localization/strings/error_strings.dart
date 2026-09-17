import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `error_` key prefix family — the fatal error page +
/// error-boundary fallbacks.
class ErrorStrings {
  ErrorStrings._();

  static String get diagnosticsCopied =>
      Tr.t('error.diagnostics_copied', S.current.error_diagnostics_copied);

  static String get noEmailApp =>
      Tr.t('error.no_email_app', S.current.error_no_email_app);

  static String get defaultMessage =>
      Tr.t('error.default_message', S.current.error_default_message);

  static String get reportSent =>
      Tr.t('error.report_sent', S.current.error_report_sent);

  static String get reportThis =>
      Tr.t('error.report_this', S.current.error_report_this);

  static String get copyDiagnostics =>
      Tr.t('error.copy_diagnostics', S.current.error_copy_diagnostics);

  static String get emailSupport =>
      Tr.t('error.email_support', S.current.error_email_support);

  static String get offlineHint =>
      Tr.t('error.offline_hint', S.current.error_offline_hint);

  static String get boundaryReleaseTitle => Tr.t(
    'error_boundary.release_title',
    S.current.error_boundary_release_title,
  );

  static String get boundaryReleaseBody => Tr.t(
    'error_boundary.release_body',
    S.current.error_boundary_release_body,
  );

  static String get boundaryFallbackTitle => Tr.t(
    'error_boundary.fallback_title',
    S.current.error_boundary_fallback_title,
  );

  static String get diagnostics =>
      Tr.t('error.diagnostics', S.current.error_diagnostics);

  static String get reportFailed =>
      Tr.t('error.report_failed', S.current.error_report_failed);

  static String get supportEmailUnconfigured => Tr.t(
    'error.support_email_unconfigured',
    S.current.error_support_email_unconfigured,
  );
}
