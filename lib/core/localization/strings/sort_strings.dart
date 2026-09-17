import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `sort_` key prefix family — user-visible labels of
/// the [CommonSort] presets.
class SortStrings {
  SortStrings._();

  static String get newest => Tr.t('sort.newest', S.current.sort_newest);
  static String get oldest => Tr.t('sort.oldest', S.current.sort_oldest);
  static String get priceLowHigh =>
      Tr.t('sort.price_low_high', S.current.sort_price_low_high);
  static String get priceHighLow =>
      Tr.t('sort.price_high_low', S.current.sort_price_high_low);
  static String get nameAz => Tr.t('sort.name_az', S.current.sort_name_az);
  static String get nameZa => Tr.t('sort.name_za', S.current.sort_name_za);
  static String get rating => Tr.t('sort.rating', S.current.sort_rating);
  static String get relevance =>
      Tr.t('sort.relevance', S.current.sort_relevance);
}
