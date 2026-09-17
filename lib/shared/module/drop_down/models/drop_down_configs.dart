import 'package:flutter/material.dart';

import '../../text_field/global_text_field.dart';
import '../drop_down_models.dart';

// ---------------------------------------------------------------------------
// DropdownBehavior — caller-only interaction/layout knobs
// ---------------------------------------------------------------------------

/// Non-visual dropdown knobs — the analogue of `TextFieldBehavior`.
/// Caller-only (not themeable).
@immutable
class DropdownBehavior {
  const DropdownBehavior({
    this.enableSearch = false,
    this.searchIdentifier,
    this.inline = false,
    this.denseTrigger = false,
    this.showChevron = true,
    this.triggerTextAlign,
    this.controlsAtStart = false,
    this.maxHeight = 250,
    this.isFullScreenWidth = false,
    this.horizontalPadding = 0,
    this.maxSelections,
    this.showClearButton = false,
    this.isLoading = false,
  });

  /// Search field at the top of the open surface.
  final bool enableSearch;

  /// Identifier header for the overlay's search field.
  final String? searchIdentifier;

  /// Render the list in-tree below the trigger instead of as an overlay.
  final bool inline;

  /// Tight chevron box on the trigger (24dp instead of 32dp) — for
  /// narrow fit-width triggers (joined country/unit pickers) where the
  /// standard box's slack reads as dead space after the label.
  final bool denseTrigger;

  /// How the SELECTED value sits in the trigger box.
  ///
  /// Null keeps the reading start, which is right for a trigger whose
  /// value runs to the width of the box. A trigger sized to a floor it
  /// does not fill — a dial-code picker at its `minWidth` — reads
  /// better centred, with the slack split rather than all trailing.
  final TextAlign? triggerTextAlign;

  /// The open/close chevron on the trigger.
  ///
  /// Off for a trigger whose whole box is obviously tappable and whose
  /// content is short enough that the arrow costs more width than it
  /// earns — a dial-code picker being the case this exists for. The
  /// trigger stays a button either way; only the glyph goes.
  final bool showChevron;

  /// Chevron + clear controls render on the LEADING side of the field
  /// trigger (before the selected item's own leading widget) instead of
  /// trailing — `▾ 🇯🇴 +962`. Field trigger only; the chip trigger keeps
  /// its trailing controls.
  final bool controlsAtStart;

  /// Overlay height cap (also the inline panel cap). Forwarded to
  /// `GlobalPopupOptions.maxHeight` unless `popupOptions` sets one.
  final double maxHeight;

  /// Overlay spans the screen minus [horizontalPadding] on both edges
  /// (`GlobalPopupWidth.screenInset`) instead of matching the trigger.
  final bool isFullScreenWidth;
  final double horizontalPadding;

  /// Cap on multi-select count — unselected rows disable at the cap.
  final int? maxSelections;

  /// Clear (×) button in the trigger when a value is selected.
  final bool showClearButton;

  /// Shimmer trigger while options are being fetched.
  final bool isLoading;

  DropdownBehavior copyWith({
    bool? enableSearch,
    String? searchIdentifier,
    bool? inline,
    bool? denseTrigger,
    bool? controlsAtStart,
    double? maxHeight,
    bool? isFullScreenWidth,
    double? horizontalPadding,
    int? maxSelections,
    bool? showClearButton,
    bool? isLoading,
  }) {
    return DropdownBehavior(
      enableSearch: enableSearch ?? this.enableSearch,
      searchIdentifier: searchIdentifier ?? this.searchIdentifier,
      inline: inline ?? this.inline,
      denseTrigger: denseTrigger ?? this.denseTrigger,
      controlsAtStart: controlsAtStart ?? this.controlsAtStart,
      maxHeight: maxHeight ?? this.maxHeight,
      isFullScreenWidth: isFullScreenWidth ?? this.isFullScreenWidth,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      maxSelections: maxSelections ?? this.maxSelections,
      showClearButton: showClearButton ?? this.showClearButton,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ---------------------------------------------------------------------------
// DropdownChips — multi-select chip trigger options
// ---------------------------------------------------------------------------

/// Chip-trigger options — the analogue of `ChipsConfig`. Only meaningful
/// for multi-select dropdowns.
@immutable
class DropdownChips {
  const DropdownChips({
    this.display = false,
    this.showLeading = false,
    this.showTrailing = false,
  });

  /// Multi-select trigger shows deletable chips instead of summary text.
  final bool display;

  /// Render each item's leading widget inside its chip.
  final bool showLeading;

  /// Render each item's trailing widget inside its chip.
  final bool showTrailing;
}

// ---------------------------------------------------------------------------
// DropdownSlots — builder hooks + info label
// ---------------------------------------------------------------------------

/// Builder hooks and auxiliary widgets — the analogue of `TextFieldSlots`.
@immutable
class DropdownSlots<T> {
  const DropdownSlots({
    this.prefixIcon,
    this.itemBuilder,
    this.emptyBuilder,
    this.onCreateNew,
    this.infoLabel,
    this.onInfoLabelTap,
  });

  /// Fixed leading icon on the trigger, independent of the selected item
  /// — so a dropdown reads like a labelled field (address governorate,
  /// category picker). A selected item's own `leading` (e.g. a flag)
  /// still wins when present.
  final IconData? prefixIcon;

  /// Custom overlay row builder.
  final Widget Function(BuildContext, DropdownItem<T>, bool selected)?
  itemBuilder;

  /// Custom overlay empty state.
  final Widget Function(BuildContext)? emptyBuilder;

  /// "Create \"query\"" row when the search matches nothing.
  final ValueChanged<String>? onCreateNew;

  /// Info icon next to the identifier header (text field slot).
  final String? infoLabel;
  final VoidCallback? onInfoLabelTap;
}

// ---------------------------------------------------------------------------
// DropdownValidation — Form-wrapper validation semantics
// ---------------------------------------------------------------------------

/// Validation config for the `GlobalDropdown*FormField` wrappers — the
/// analogue of `TextFieldValidation`, with [ValidationMode] reinterpreted
/// for a picker:
///
/// | Mode                        | Dropdown trigger                        |
/// | --------------------------- | --------------------------------------- |
/// | `onSubmit`                  | `Form.validate()` only                  |
/// | `onFocusLoss`               | overlay CLOSES (with or without a pick) |
/// | `onInteraction` / `realTime`| every selection change                  |
/// | `none`                      | external [errorText] only               |
///
/// `deferToParentForm` mirrors the text field: only the live modes hand
/// the Form `AutovalidateMode.onUserInteraction`; `onSubmit` /
/// `onFocusLoss` stay `disabled` so a Form above doesn't force
/// per-change validation.
@immutable
class DropdownValidation<V> {
  const DropdownValidation({
    this.validator,
    this.errorText,
    this.mode = ValidationMode.onSubmit,
    this.deferToParentForm = true,
    this.revalidateKey,
  });

  /// Sync validator over the current value (single: `T?`,
  /// multi: `List<T>?`).
  final String? Function(V?)? validator;

  /// External error — overrides any internal validation result.
  final String? errorText;

  final ValidationMode mode;

  /// When `true`, live modes hand the parent Form
  /// `AutovalidateMode.onUserInteraction`. Set `false` for standalone
  /// wrappers outside a Form.
  final bool deferToParentForm;

  /// Change signal for the VALIDATION RULES themselves — validator
  /// closures are recreated every build, so the wrapper can't tell a
  /// rebuild from a rule change. Encode the rule inputs
  /// (`revalidateKey: (country.code, isBusiness)`); when the key differs
  /// between updates, an interacted-with (or error-showing) dropdown
  /// re-validates immediately.
  final Object? revalidateKey;

  /// Live modes validate on every selection change.
  bool get validatesOnChange =>
      mode == ValidationMode.onInteraction || mode == ValidationMode.realTime;

  /// Focus-loss maps to "overlay closed".
  bool get validatesOnClose => mode == ValidationMode.onFocusLoss;
}
