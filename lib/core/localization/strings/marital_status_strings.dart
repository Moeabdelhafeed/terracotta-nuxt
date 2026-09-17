import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `marital_` key prefix family — user-visible labels
/// of the [MaritalStatus] enum options.
class MaritalStatusStrings {
  MaritalStatusStrings._();

  static String get single => Tr.t('marital.single', S.current.marital_single);
  static String get married =>
      Tr.t('marital.married', S.current.marital_married);
  static String get divorced =>
      Tr.t('marital.divorced', S.current.marital_divorced);
  static String get widowed =>
      Tr.t('marital.widowed', S.current.marital_widowed);
}
