import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `color_field` prefix family — call sites resolve
/// these keys through this class instead of `Tr.t` directly.
class ColorFieldStrings {
  ColorFieldStrings._();

  static String get pickerTitle =>
      Tr.t('color_field.picker_title', S.current.color_field_picker_title);

  static String get required =>
      Tr.t('color_field.required', S.current.color_field_required);

  static String invalidFormat(String hint) => Tr.t(
    'color_field.invalid_format',
    S.current.color_field_invalid_format(hint),
  );
}
