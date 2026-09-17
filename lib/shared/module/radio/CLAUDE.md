# CLAUDE.md — lib/shared/module/radio

Single-select radio (dot / filled / checkmark variants) holding the
text-field gold standard: themeable style bag, `FormField` group
wrapper sharing the checkbox family's validation vocabulary, shared
message column, reduced-motion support.

> **Status: FINISHED (July 2026).** Module holds the gold standard
> (themeable `RadioStyle` + `GlobalRadioTheme`,
> `GlobalRadioGroupFormField` on the shared `CheckboxValidation`
> vocabulary, `FieldMessagesColumn` errors, style-gated haptics,
> localized ARB semantics, reduced motion) and the
> `shared/common/selection_fields/radio/` catalog is complete:
> YesNoRadioGroup, GenderRadioGroup, AddressTypeRadioGroup — localized
> en + ar, locale-flip tested, showcased under the Common Hub +
> playground. Deliberately NOT here: app-data option lists (build
> `RadioGroupItem`s inline), a standalone radio FormField (single
> radios don't validate — groups do), more presets (copy a wrapper).

## Architecture

```
radio/
  global_radio.dart       — GlobalRadio<T> + GlobalRadioGroup<T> +
                            GlobalRadioTile<T> (barrel: exports everything)
  radio_form_fields.dart  — GlobalRadioGroupFormField<T>
  radio_models.dart       — constants, enums, RadioStyle (themeable bag)
                            + ResolvedRadioStyle
  theme/radio_theme.dart  — GlobalRadioTheme ThemeExtension

─── In core/theme/widget_themes/ ───
  global_radio_theme.dart — MyGlobalRadioTheme.build (wired in theme.dart)
```

## Contracts

- **Fully controlled.** Selected when `value == groupValue`; picks
  report via `onChanged`, never mutate. Tapping the selected radio is a
  no-op (radios don't unselect). The `FormField` wrapper seeds from
  `initialValue` ONCE (standard Flutter semantics).
- **Style is the themeable bag** (`RadioStyle`, every field nullable):
  resolution `caller > GlobalRadioTheme.style > RadioStyle.defaults >
  context.<group>Colors`, materialized once per build. Adding a themed
  field → `RadioStyle`, `mergedWith`, `copyWith`,
  `ResolvedRadioStyle`, `GlobalRadioTheme._lerpStyle`.
- **Validation reuses `CheckboxValidation`** — one vocabulary across
  the selection-controls family (`onSubmit` = `Form.validate()` only,
  live modes = every pick, `deferToParentForm`, `revalidateKey`, plus
  the locale re-validate of a SHOWING error).
- **Haptics gate on `style.enableHaptic`** (resolved, default `true`).
- **Errors + status rows** render in the shared `FieldMessagesColumn`
  on the radio, the group and the wrapper.
- **Semantics**: `selected` + `inMutuallyExclusiveGroup` + localized
  fallback label (`RadioStrings.semanticLabel`); Enter/Space activate.
- **Reduced motion** collapses the select tween and skips tap-scale.

## Gotchas

- Label row wraps radio + label in ONE `GestureDetector` (inner
  `IgnorePointer`); `GlobalRadioTile`'s InkWell owns tap + haptic.
- `RadioVariant.checkmark` visually resembles the checkbox's circle
  variant but semantics differ — radios are mutually exclusive.

## Common wrappers

`shared/common/selection_fields/radio/` — [YesNoRadioGroup],
[GenderRadioGroup] (shares the dropdown's `Gender` enum + strings),
[AddressTypeRadioGroup] (shares `AddressForm`'s enum + labels).

## Showcase + tests

`/radio-showcase`. Tests: `test/radio/global_radio_test.dart` (resolve
merge order, form-field modes, wrapper labels).
