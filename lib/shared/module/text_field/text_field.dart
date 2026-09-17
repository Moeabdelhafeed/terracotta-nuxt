/// Barrel for the text_field design system.
///
/// Subtree layout (mirrors the popup module):
/// ```
/// text_field/
///   global_text_field.dart       declarative widget (domain shapes live in
///                                shared/common/text_form_fields/ wrappers)
///   controller/                  state engine (lifecycle, focus, validation,
///                                suggestions, undo/redo, voice) — part files
///   models/                      enums, style (themeable bag), behavior,
///                                validation, suggestions, features, slots,
///                                callbacks, sizing, messages, defaults
///                                + sub-barrel
///   surfaces/                    header / chips / counter / strength bar /
///                                requirements / suggestions panels
///                                + color preview
///   input_formatters/            currency / card / mask / iban / hex / expiry
///   theme/text_field_theme.dart  GlobalTextFieldTheme ThemeExtension
/// ```
library;

export 'global_text_field.dart';
export 'input_formatters/text_field_input_formatters.dart';
export 'models/text_field_models.dart';
