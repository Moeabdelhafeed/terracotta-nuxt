import '../../../generated/l10n.dart';
import '../tr.dart';

/// Colour names.
///
/// Not received from anywhere — see `ColorName`, which picks the
/// nearest of these for a bare hex string, because the shop API sends
/// colourways with no label attached.
class ColorStrings {
  ColorStrings._();

  static String get black =>
      Tr.t('color_name_black', S.current.color_name_black);

  static String get white =>
      Tr.t('color_name_white', S.current.color_name_white);

  static String get grey => Tr.t('color_name_grey', S.current.color_name_grey);

  static String get beige =>
      Tr.t('color_name_beige', S.current.color_name_beige);

  static String get brown =>
      Tr.t('color_name_brown', S.current.color_name_brown);

  static String get terracotta =>
      Tr.t('color_name_terracotta', S.current.color_name_terracotta);

  static String get orange =>
      Tr.t('color_name_orange', S.current.color_name_orange);

  static String get red => Tr.t('color_name_red', S.current.color_name_red);

  static String get pink => Tr.t('color_name_pink', S.current.color_name_pink);

  static String get purple =>
      Tr.t('color_name_purple', S.current.color_name_purple);

  static String get navy => Tr.t('color_name_navy', S.current.color_name_navy);

  static String get blue => Tr.t('color_name_blue', S.current.color_name_blue);

  static String get teal => Tr.t('color_name_teal', S.current.color_name_teal);

  static String get green =>
      Tr.t('color_name_green', S.current.color_name_green);

  static String get olive =>
      Tr.t('color_name_olive', S.current.color_name_olive);

  static String get yellow =>
      Tr.t('color_name_yellow', S.current.color_name_yellow);
}
