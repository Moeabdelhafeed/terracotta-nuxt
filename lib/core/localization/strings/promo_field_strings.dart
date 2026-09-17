import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `promo_field_` prefix family (promo-code field hint +
/// actions + empty message) — call sites go through this class.
class PromoFieldStrings {
  PromoFieldStrings._();

  static String get hint =>
      Tr.t('promo_field.hint', S.current.promo_field_hint);
  static String get apply =>
      Tr.t('promo_field.apply', S.current.promo_field_apply);
  static String get remove =>
      Tr.t('promo_field.remove', S.current.promo_field_remove);
  static String get empty =>
      Tr.t('promo_field.empty', S.current.promo_field_empty);
}
