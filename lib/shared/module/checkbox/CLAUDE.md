# CLAUDE.md — lib/shared/module/checkbox

Tri-state checkbox (standard / circle) holding the text-field gold
standard: themeable style bag, `FormField` wrappers with
`ValidationMode` semantics, shared message column, reduced-motion
support.

> **Status: FINISHED (July 2026).** Module holds the gold standard
> (themeable `CheckboxStyle` + `GlobalCheckboxTheme`, FormField
> wrappers with the shared `ValidationMode` semantics +
> `revalidateKey`, `FieldMessagesColumn` errors, style-gated haptics,
> reduced motion, ARB semantics) and the
> `shared/common/selection_fields/checkbox/` catalog is complete:
> consent (terms / privacy / both, tappable links), age gate,
> acknowledgement, remember-me, marketing opt-in, don't-show-again,
> save-card, default-address, same-as-billing — all localized en + ar,
> locale-flip-safe, showcased under the Common Hub + playground.
> Deliberately NOT here: toggle pills (`GlobalSwitch` module),
> role-specific copy (use `AcknowledgementCheckbox`), further
> ten-liners (copy a wrapper pattern). There is deliberately NO toggle variant — switch pills live in
the dedicated `switch/` module (`GlobalSwitch`); a checkbox toggle would
only duplicate it.

App-owned wrappers (consent checkbox with tappable Terms/Privacy links,
remember-me, settings switch row) live in
[`lib/shared/common/selection_fields/`](../../common/selection_fields/) —
add purpose-shaped checkboxes there, not here.

## Architecture

```
checkbox/
  global_checkbox.dart        — GlobalCheckbox + GlobalCheckboxTile +
                                GlobalCheckboxGroup (barrel: exports everything)
  checkbox_form_fields.dart   — GlobalCheckboxFormField (bool) /
                                GlobalCheckboxGroupFormField<T>
  checkbox_models.dart        — constants, enums, CheckboxValidation,
                                CheckboxStyle (themeable bag) + ResolvedCheckboxStyle
  theme/checkbox_theme.dart   — GlobalCheckboxTheme ThemeExtension

─── In core/theme/widget_themes/ ───
  global_checkbox_theme.dart  — MyGlobalCheckboxTheme.build (wired in theme.dart)
```

## Contracts

- **Fully controlled.** `GlobalCheckbox` displays `value` as passed and
  reports taps via `onChanged`. The `FormField` wrappers seed from
  `initialValue`/`initialValues` ONCE (standard Flutter semantics) — a
  parent changing the prop later is ignored by design.
- **Style is the themeable bag** (`CheckboxStyle`, every field
  nullable): resolution `caller > GlobalCheckboxTheme.style >
  CheckboxStyle.defaults > context.<group>Colors`, materialized once
  per build (`_rs = widget.style.resolve(context, variant:)`). Adding a
  themed field → add it to `CheckboxStyle`, `mergedWith`, `copyWith`,
  `ResolvedCheckboxStyle`, and `GlobalCheckboxTheme._lerpStyle`.
- **Haptics gate on `style.enableHaptic`** (resolved, default `true`) —
  there is no widget-level haptic flag.
- **Errors + status rows render in the shared `FieldMessagesColumn`**
  (icon + status color) — `errorText` + `messages:` on the checkbox,
  the group, and both wrappers. Never a bare string.
- **Validation** (`CheckboxValidation`, wrappers only): `ValidationMode`
  reused from the text field — `onSubmit` (default) = `Form.validate()`
  only; `onInteraction`/`realTime` = every toggle; `onFocusLoss` = same
  as `onInteraction` (a tap control has no focus-loss moment); `none` =
  external `errorText` only. `deferToParentForm` hands the Form
  `AutovalidateMode.onUserInteraction` only for live modes;
  `revalidateKey` re-validates an interacted-with (or error-showing)
  field when the rules change.
- **Reduced motion** collapses the check tween to instant and skips the
  tap-scale effect.
- **Group min/max** — `GlobalCheckboxGroup` disables unchecking below
  `minSelections` and checking above `maxSelections`; select-all fills
  respecting both.

## Gotchas

- The label row wraps checkbox + label in ONE `GestureDetector` (the
  inner box goes `IgnorePointer`) — don't add a second tap handler.
- `GlobalCheckboxTile`'s checkbox is `IgnorePointer`-wrapped; the tile's
  `InkWell` owns the tap + haptic (same pattern in
  `SettingsSwitchRow`).
- Semantics: `semanticLabel ?? label ?? CheckboxStrings.semanticLabel`
  (ARB-backed) with `excludeSemantics: true` — one node per control.

## Showcase + tests

`/checkbox-showcase` — `lib/features/showcases/checkbox_showcase/`.
Tests: `test/checkbox/global_checkbox_test.dart` (resolve merge order,
wrapper validation modes, revalidateKey, group caps).
