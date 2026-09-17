import 'package:flutter/material.dart';

import '../../../../core/constants/sizes/app_sizes.dart';

/// Single source of truth for every hard-coded `GlobalTextFormField`
/// constant — shape, borders, slots, fit-width geometry, message rows,
/// validation + suggestion timings.
///
/// ## Where a value comes from (resolution order)
///
/// 1. **Per-call** — the `style:` / config passed to the widget.
/// 2. **App-wide** — the `GlobalTextFieldTheme` ThemeExtension
///    (`MyGlobalTextFieldTheme.build` in `core/theme/widget_themes/`).
///    A runtime override mechanism, not a constant store.
/// 3. **This class** — the compile-time floor when neither sets a value.
///    Colors are the exception: they fall back to `context.<group>Colors`
///    so they track the active palette, never constants.
///
/// Tweak a module-wide default here; rebrand at runtime via the theme.
abstract final class TextFieldDefaults {
  // ─── Shape ────────────────────────────────────────────────────
  /// Corner radius when neither style nor theme provides one.
  static const double borderRadius = AppSizes.inputFieldRadius;

  /// Frosted-glass blur strength (`style.enableBlur`).
  static const double blurSigma = 10.0;

  // ─── Identifier header ────────────────────────────────────────
  /// The label ABOVE the box. Deliberately a step below body copy: it
  /// names a field the box beside it already shows, so at body size two
  /// of them stacked read as two pieces of content rather than a label
  /// and its input. The design draws it at 15, regular.
  static const double identifierFontSize = 15;
  static const FontWeight identifierWeight = FontWeight.w400;

  /// Focus lifts the weight, not the size — a header that grows shifts
  /// everything below it by a pixel on every focus change.
  static const FontWeight identifierFocusedWeight = FontWeight.w600;

  // ─── Borders ──────────────────────────────────────────────────
  /// Hairline drawn while the field is idle, so an empty field still
  /// reads as somewhere you can type before you touch it.
  static const double restingBorderWidth = 1.0;
  static const double focusedBorderWidth = 1.5;
  static const double errorBorderWidth = 1.0;

  // ─── Prefix / suffix slots ────────────────────────────────────
  /// Default slot constraints — no minimum, so the slot hugs its child
  /// instead of inflating to Material's 48×48. Callers restore a fixed
  /// tap target via `TextFieldSlots.prefixIconConstraints`.
  static const BoxConstraints tightSlotConstraints = BoxConstraints(
    minWidth: 0,
    minHeight: 0,
  );

  // ─── Fit-width sizing (`TextFieldSizing.fitWidthToContent`) ───
  /// Symmetric horizontal content padding — mirrored by the fit-width
  /// ghost so the box hugs the text with equal leading/trailing space.
  static const double fitWidthHPad = 12.0;

  /// Vertical content padding of a fit-width field with no explicit height —
  /// 16 matches the default (non-fit-width) field's box height, so a
  /// fit-width trigger sits flush beside a standard field.
  static const double fitWidthVPad = 16.0;

  /// End-side slack for the caret + border inset, so the hint never clips
  /// to an ellipsis and the `EditableText` barely scrolls.
  static const double fitWidthCaretRoom = 8.0;

  /// `InputDecorator`'s built-in gap between an icon slot and the editable
  /// area — the ghost reserves it on slotted sides (where the horizontal
  /// contentPadding itself is dropped by the decorator).
  static const double fitWidthSlotGap = 4.0;

  // ─── Content padding (module-computed paths) ──────────────────
  /// Horizontal content inset when the module computes its own padding
  /// (fixed-height + multiline-with-height paths).
  static const double contentHPad = 12.0;

  /// Vertical content inset for a multiline field with an explicit height —
  /// the height governs the box; the text top-aligns and scrolls.
  static const double multilineVPad = 12.0;

  // ─── Suggestions rows ─────────────────────────────────────────
  /// Vertical padding of a suggestion row (horizontal uses the `md` spacing
  /// token); between `spacing.sm` (8) and `spacing.md` (16) — no token match.
  static const double suggestionRowVPad = 12.0;

  // ─── Field messages (multi-state rows) ────────────────────────
  static const double messageIconSize = 14.0;

  /// Per-character reveal time for `FieldMessageAnimation.typed` rows;
  /// total duration clamps to [messageTypedMinMs]–[messageTypedMaxMs].
  static const int messageTypedMsPerChar = 18;
  static const int messageTypedMinMs = 240;
  static const int messageTypedMaxMs = 1200;

  /// Entrance travel of a `FieldMessageAnimation.slide` row, as a fraction
  /// of the row's own size.
  static const double messageSlideFraction = 0.25;

  // ─── Strength bar ─────────────────────────────────────────────
  /// Height (= corner radius) of one strength-bar segment pill.
  static const double strengthSegmentHeight = 6.0;

  /// Segment count when the bar is driven by a `strengthEstimator` with no
  /// requirements checklist (otherwise segments = requirements.length).
  static const int strengthSegmentsDefault = 4;

  // ─── Obscured input ───────────────────────────────────────────
  /// Bullet used by `InstantObscureTextController` (instant, no last-char
  /// peek). Matches Material's default obscuring character.
  static const String obscuringCharacter = '•';

  // ─── Validation ───────────────────────────────────────────────
  /// Debounce before `TextFieldValidation.asyncValidator` fires after the
  /// sync check passes.
  static const Duration asyncValidatorDebounce = Duration(milliseconds: 400);

  // ─── Suggestions ──────────────────────────────────────────────
  /// Debounce for `SuggestionsConfig.async` lookups.
  static const Duration suggestionsDebounce = Duration(milliseconds: 300);

  /// Cap on rendered suggestion rows.
  static const int suggestionsMaxItems = 5;
}
