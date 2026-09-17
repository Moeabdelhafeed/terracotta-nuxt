/// Barrel for the popup design system.
///
/// Subtree layout:
/// ```
/// popup/
///   global_popup.dart            declarative widget + .menu/.tooltip/.panel/.showAt
///   global_popup_menu.dart       trigger-widget facade (popup_menu-style API)
///   popup_compat.dart            legacy popup_menu shims
///   controller/
///     global_popup_controller.dart   imperative engine
///     (the keyboard observer lives in core/keyboard/)
///   models/                      enums, options, geometry, surface style, arrow/backdrop
///   surfaces/                    base + menu + panel + tooltip widgets
///   theme/popup_theme.dart       ThemeExtension defaults
/// ```
library;

// The keyboard is not a popup concern — it lives in `core/keyboard/`
// and is re-exported here because a popup was its first caller.
export '../../../core/keyboard/keyboard_observer.dart';
export '../../../core/keyboard/keyboard_scope.dart';
export 'controller/global_popup_controller.dart';
export 'global_popup.dart';
export 'models/popup_models.dart';
export 'surfaces/popup_surfaces.dart';
export 'theme/popup_theme.dart';
