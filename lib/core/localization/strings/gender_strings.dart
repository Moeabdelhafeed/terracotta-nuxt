import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `gender_` key prefix family — user-visible labels of
/// the [Gender] enum options.
class GenderStrings {
  GenderStrings._();

  static String get male => Tr.t('gender.male', S.current.gender_male);
  static String get female => Tr.t('gender.female', S.current.gender_female);
  static String get other => Tr.t('gender.other', S.current.gender_other);
  static String get preferNotToSay =>
      Tr.t('gender.prefer_not_to_say', S.current.gender_prefer_not_to_say);
}
