# CLAUDE.md — lib/shared/module/drop_down

Select field built as a COMPOSITION of two engines — the text field
(trigger) and the popup (overlay) — with config grouped like the
text-field gold standard.

> **Status: FINISHED (July 2026).** Module holds the text-field gold
> standard (grouped configs, validation modes, themeable
> `DropdownStyle`, owner-aware controller) and the
> `shared/common/dropdown_fields/` catalog is complete: 5 generic
> wrappers + 23 domain pickers (country/state/city, country code,
> nationality, timezone, currency, unit, gender, blood type, marital
> status, education, language, theme, color format, sort, duration,
> recurrence, day/weekday/month+hijri/year/hour), showcased under
> Common Dropdowns + the playground. Deliberately NOT pre-built:
> app-specific data pickers (use `AsyncDropdownField`), ten-line enums
> (copy the blood-type pattern), sensitive/free-text domains.

## Architecture

```
drop_down/
  global_drop_down.dart        — GlobalDropdown widget (barrel: exports everything)
  drop_down_form_fields.dart   — GlobalDropdownFormField / GlobalDropdownMultiFormField
                                 (+ _DropdownFormShell validation mixin)
  drop_down_models.dart        — DropdownItem / DropdownGroup / DropdownItemOverride /
                                 GlobalDropdownController
  models/
    drop_down_configs.dart     — DropdownBehavior / DropdownChips / DropdownSlots /
                                 DropdownValidation
    drop_down_style.dart       — DropdownStyle (themeable bag) + ResolvedDropdownStyle
  surfaces/
    dropdown_surface.dart      — open-session body (search, async, list, footer)
    dropdown_triggers.dart     — chip trigger, loading trigger, controls, header
  theme/
    drop_down_theme.dart       — GlobalDropdownTheme ThemeExtension

─── In core/theme/widget_themes/ ───
  global_drop_down_theme.dart  — MyGlobalDropdownTheme.build (wired in theme.dart)
```

* **Trigger** — a `GlobalTextFormField` in read-only picker mode. The
  selection summary is the field text; `identifier`, `errorText`,
  `messages`, `style`, `sizing` flow straight into the field, so
  dropdowns get the same header / message-column / theming treatment as
  every other field.
* **Overlay** — a `GlobalPopupController` anchored to the trigger.
  Placement, flip, keyboard-avoidance, scroll-reposition, tap-outside
  come from the popup engine; override per call via `popupOptions`.

## Configs (the grouped params)

| Config                       | Themeable?                   | Purpose                                                              |
| ---------------------------- | ---------------------------- | -------------------------------------------------------------------- |
| `style` (`TextFieldStyle`)   | ✅ via `GlobalTextFieldTheme`| TRIGGER visuals — fill, border, radius, iconColor, `enableHaptic`     |
| `dropdownStyle` (`DropdownStyle`) | ✅ via `GlobalDropdownTheme` | OPEN-SURFACE rows — accent, selected tint, flash, accent bar, item padding/text styles, checkbox size, `enableHaptic` |
| `behavior` (`DropdownBehavior`) | ✗ caller-only             | search, inline, dense trigger, controlsAtStart, maxHeight, full-screen width, maxSelections, clear button, isLoading |
| `chips` (`DropdownChips`)    | ✗                            | multi-select chip trigger: `display` / `showLeading` / `showTrailing` |
| `slots` (`DropdownSlots<T>`) | ✗                            | prefixIcon, itemBuilder, emptyBuilder, onCreateNew, infoLabel        |
| `sizing` (`TextFieldSizing`) | ✗                            | trigger box geometry                                                 |
| `popupOptions`               | ✗ (popup theme separately)   | overlay overrides, merged over computed defaults                     |
| `messages` (`List<FieldMessage>`) | ✗                       | status rows under the trigger (both trigger kinds)                   |
| `validation` (`DropdownValidation`, wrappers only) | ✗          | validator, mode, deferToParentForm, revalidateKey                    |

Top-level: `items`, `groups`, `selectedValue(s)`, `onChanged` /
`onMultiChanged`, `multiSelect`, `asyncItemsLoader` (data source, not a
slot), `hint`, `identifier`, `enabled`, `errorText`, `controller`.

## Validation semantics (wrappers)

`ValidationMode` is reused from the text field, reinterpreted for a
picker:

| Mode                          | Trigger                                   |
| ----------------------------- | ----------------------------------------- |
| `onSubmit` (default)          | `Form.validate()` only                    |
| `onFocusLoss`                 | overlay CLOSES (with or without a pick)   |
| `onInteraction` / `realTime`  | every selection change                    |
| `none`                        | external `errorText` only                 |

- `deferToParentForm` mirrors the field: only live modes hand the Form
  `AutovalidateMode.onUserInteraction`.
- Errors render in the trigger's message column (icon + status color),
  never Material's plain string — including chip mode.
- `revalidateKey`: rules changed at runtime re-validate an
  interacted-with (or error-showing) dropdown immediately.
- The on-close validate runs post-frame so a same-tap selection lands in
  the field value before the validator reads it.

## Contracts + gotchas

- **Fully controlled.** The trigger displays `selectedValue(s)` as
  provided; selections are reported via callbacks, never mutated
  internally. The `FormField` wrappers own their value after
  `initialValue` seeds it ONCE (standard Flutter FormField semantics) —
  a parent changing `initialValue` later is ignored by design.
- **`_knownItems` session cache.** Async-loaded picks aren't in `items`;
  the state caches every picked item so the trigger can resolve labels.
  Values with no resolvable item render as the hint — never pruned back
  into parent state.
- **Chip-trigger exception.** `chips.display: true` uses a custom
  wrap-height trigger (the text field is single-line). It's styled from
  the same resolved `TextFieldStyle` and renders the SAME message column
  (`FieldMessagesColumn` — shared widget exported by the text-field
  module).
- **Open-state border.** While open, the trigger paints the FOCUSED
  border on its resting state — the picker-mode focus node can't take
  real focus.
- **Haptics.** Trigger-side (open / clear / chip delete) gate on the
  resolved `TextFieldStyle.enableHaptic`; surface rows (select / toggle)
  gate on `DropdownStyle.enableHaptic`. Both default `true`.
- **One controller per dropdown.** Attaching a `GlobalDropdownController`
  to a second dropdown asserts in debug.
- **didUpdateWidget → overlay refresh.** Parent rebuilds push new
  items/selection/options into an OPEN overlay via `_popupCtrl.refresh`;
  keep that path when adding params.
- **Search resets on close for free** — the surface is disposed with the
  session.
- **Surface height morphs.** The open surface wraps its content in an
  `AnimatedSize` ABOVE the height cap (popup + inline) — searching,
  async results landing and the multi-select footer appearing tween the
  panel height instead of jumping. Keep the cap INSIDE the
  `AnimatedSize` (see `_morph`) or long lists lay out past the clip and
  scrolling breaks. Reduced motion collapses the tween to instant.
- **Async loading = shimmer rows**, not a spinner — three item-shaped
  `GlobalShimmer` bars using the resolved item padding, mirroring the
  trigger's `DropdownLoadingTrigger` treatment.

## Theming

```dart
ThemeData(extensions: [
  GlobalDropdownTheme(
    style: DropdownStyle(accentBarWidth: 0, enableHaptic: false),
  ),
]);
```

`MyGlobalDropdownTheme.build` (core/theme/widget_themes/) is the
app-wide hook; colors/text styles stay null there so they track the
active palette at build time. Resolution:
`caller dropdownStyle > GlobalDropdownTheme > DropdownStyle.defaults >
context colors`. If you add a themed field: add it to `DropdownStyle`,
`mergedWith`, `copyWith`, `ResolvedDropdownStyle`, and
`GlobalDropdownTheme._lerpStyle`.

## Pre-built wrappers

`lib/shared/common/dropdown_fields/` — SimpleDropdownField,
SearchableDropdownField, MultiSelectDropdownField, AsyncDropdownField,
GroupedDropdownField. Domain pickers (country, governorate, time
format…) live inside their owning common text-form-field widgets.

## Showcase + tests

`/dropdown-showcase` — `lib/features/showcases/dropdown_showcase/`.
Widget tests: `test/drop_down/`.
