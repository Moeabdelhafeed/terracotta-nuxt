import '../../../generated/l10n.dart';
import '../number_formatter.dart';
import '../tr.dart';

/// Strings for the `legal_` key prefix family — legal/about page titles
/// and error states.
class LegalStrings {
  LegalStrings._();

  static String get titleAbout =>
      Tr.t('legal.title_about', S.current.legal_title_about);
  static String get titlePrivacy =>
      Tr.t('legal.title_privacy', S.current.legal_title_privacy);
  static String get titleTos =>
      Tr.t('legal.title_tos', S.current.legal_title_tos);
  static String get titleLicenses =>
      Tr.t('legal.title_licenses', S.current.legal_title_licenses);
  static String get titleEula =>
      Tr.t('legal.title_eula', S.current.legal_title_eula);
  static String get titleRefund =>
      Tr.t('legal.title_refund', S.current.legal_title_refund);
  static String get titleCredits =>
      Tr.t('legal.title_credits', S.current.legal_title_credits);
  static String get titleContact =>
      Tr.t('legal.title_contact', S.current.legal_title_contact);

  static String pageUnavailable(String title) =>
      Tr.t('legal.page_unavailable', S.current.legal_page_unavailable(title));

  static String pageLoadFailed(String title) =>
      Tr.t('legal.page_load_failed', S.current.legal_page_load_failed(title));

  static String get sectionLabel =>
      Tr.t('legal.section_label', S.current.legal_section_label);

  /// "Version 1.2.0", or with the build when the platform reports one.
  /// Through `AppNumbers`, because a version is DIGITS and Arabic
  /// writes its own.
  static String version(String version, String build) => build.isEmpty
      ? Tr.t(
          'legal.version',
          S.current.legal_version(AppNumbers.localizeDigits(version)),
        )
      : Tr.t(
          'legal.version_build',
          S.current.legal_version_build(
            AppNumbers.localizeDigits(version),
            AppNumbers.localizeDigits(build),
          ),
        );

  static String get pageDisabledBody =>
      Tr.t('legal.page_disabled_body', S.current.legal_page_disabled_body);

  static String get checkConnectionBody => Tr.t(
    'legal.check_connection_body',
    S.current.legal_check_connection_body,
  );
}
