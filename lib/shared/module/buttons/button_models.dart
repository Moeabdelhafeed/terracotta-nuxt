/// Button style models for variant-based styling.
///
/// Re-exports the 3 immutable style classes for button state visuals.
/// Most callers import this barrel, but each file can be imported
/// individually for tree-shaking.
library;

export 'button_loading_style.dart';
export 'button_result.dart';
export 'button_state_style.dart';
export 'label_overflow.dart';
export 'swipe_button_style.dart';
export 'theme/buttons_theme.dart';

/// Underline behaviour for `GlobalTextButton(link: true)`.
enum LinkUnderline {
  /// Always ruled, like a link in running text. The safe default:
  /// colour alone as the sole affordance fails WCAG 1.4.1.
  always,

  /// Rules in on hover/focus and out again — fine for a standalone
  /// action that is already visually obvious.
  onHover,

  /// Never ruled. Only for links whose context makes them unmistakable.
  never,
}
