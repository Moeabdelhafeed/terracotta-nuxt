import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `education_` key prefix family — user-visible labels
/// of the [EducationLevel] enum options.
class EducationStrings {
  EducationStrings._();

  static String get primary =>
      Tr.t('education.primary', S.current.education_primary);
  static String get middle =>
      Tr.t('education.middle', S.current.education_middle);
  static String get secondary =>
      Tr.t('education.secondary', S.current.education_secondary);
  static String get diploma =>
      Tr.t('education.diploma', S.current.education_diploma);
  static String get bachelor =>
      Tr.t('education.bachelor', S.current.education_bachelor);
  static String get master =>
      Tr.t('education.master', S.current.education_master);
  static String get doctorate =>
      Tr.t('education.doctorate', S.current.education_doctorate);
}
