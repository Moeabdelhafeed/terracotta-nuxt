# CLAUDE.md — lib/shared/module/segmented_control

Sliding-indicator SINGLE-select control (iOS-style) — drag-to-select,
arrow-key navigation, filled/outlined/tonal variants. Holds the gold
standard: themeable style bag, shared message column, style-gated
haptics, reduced motion, full RTL.

> **Status: FINISHED (July 2026).** Module holds the gold standard
> (themeable `SegmentedStyle` + `GlobalSegmentedControlTheme` with
> variant-driven indicator defaults, `FieldMessagesColumn` errors,
> style-gated haptics, localized ARB semantics, reduced motion, the
> three RTL invariants below) and the
> `shared/common/selection_fields/segmented/` catalog is complete:
> ViewModeSegmented, MapListSegmented, ChartPeriodSegmented,
> ThemeModeSegmented, StatusFilterSegmented, TimeFormatSegmented —
> localized en + ar, locale-flip safe, showcased under the Common Hub
> + playground. Deliberately NOT here: multi-select (that's
> toggle_group), scrollable segment overflow (segments must fit —
> use a dropdown past ~5).

## Boundary vs toggle_group (deliberate, keep it)

Single-select sliding look → THIS module. Multi-select or the bordered
button-set look → `GlobalToggleGroup`. See its CLAUDE.md for the full
rationale — they are not duplicates.

## Contracts

- **Fully controlled.** Displays `value` as passed, reports via
  `onChanged`, never mutates.
- **Style is the themeable bag** (`SegmentedStyle`, every field
  nullable): `caller > GlobalSegmentedControlTheme.style > defaults >
  context.<group>Colors`, materialized once per build with the VARIANT
  driving indicator defaults (filled → surface, tonal → primary 12%).
  Adding a themed field → bag, `mergedWith`, `copyWith`,
  `ResolvedSegmentedStyle`, `GlobalSegmentedControlTheme._lerpStyle`.
- **RTL is load-bearing**: the indicator is
  `AnimatedPositionedDirectional` (physical `left:` put it on the WRONG
  segment in Arabic before), the drag handler maps physical x →
  logical index through `Directionality`, and arrowLeft/arrowRight swap
  meaning under RTL. Don't regress any of the three.
- **Haptics gate on `style.enableHaptic`** (resolved, default `true`).
- **errorText/messages** render via the shared `FieldMessagesColumn`.
- **Reduced motion** collapses the slide (drag still works — the
  indicator snaps).
- Drag-to-select requires `expandEqual` (segment widths must be
  calculable).

## Showcase + tests

`/segmented-control-showcase`. Tests:
`test/segmented_control/global_segmented_control_test.dart` (resolve
merge + variant defaults, selection, RTL indicator + tap mapping,
error column).

## Overflow

- **A segment's label is `Flexible` and ellipsizes.** `expandEqual`
  hands every segment a TIGHT width while the content `Row` is
  `mainAxisSize.min`, so a label wider than its share overflowed the
  segment rather than shortening — "Archived" in a four-up control on a
  phone put a striped bar across the card. The buttons module learned
  the same thing about its own label.
- **Without `expandEqual` the row COLLAPSES**, using the toggle
  group's `ToggleOverflowRow` and its `ToggleGroupOverflowScope`. The
  two modules are a documented pair, so one copy of that machinery
  beats two that drift.
- **The panel is a vertical TOGGLE GROUP, not a vertical segmented
  control.** This module has no vertical mode and should not grow one:
  its whole identity is a sliding indicator along a track, and a track
  on its side is a different control. The button set IS that other
  face — which is what the boundary above says.
- Guard: `test/segmented_control/segmented_overflow_test.dart`, which
  also scrolls the real showcase page end to end at phone width.
