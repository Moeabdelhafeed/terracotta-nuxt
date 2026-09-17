# CLAUDE.md — lib/shared/module/chip

`GlobalChip` — filter, choice, tag or static label. Four factories over
one widget: `.tag`, `.outlined`, `.pill`, `.gradient`.

```dart
GlobalChip(label: 'All')                                     // static
GlobalChip(label: 'Books', selected: s, onSelected: (v) {})   // filter
GlobalChip.tag(label: 'flutter', onDeleted: remove)           // tag
```

## Contracts

- **Style is the themeable bag `ChipStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once per
  build by `style.resolve(context, variant:, selected:, enabled:)` into
  a `ResolvedChipStyle`. There were 23 flat visual parameters on the
  widget before, none of them themeable.
- **`resolve` takes the STATE, not just the context.** A chip's colours
  are a function of variant × selected × enabled — the same bag paints a
  resting outlined chip and a selected tonal one differently — so those
  are arguments rather than fields. It returns BOTH fills, because
  Material's chip wants `backgroundColor` and `selectedColor` together
  so it can cross-fade them itself.
- **Resolution order**: `caller > GlobalChipTheme.style >
  ChipStyle.defaults`, then colours from `context.<group>Colors`.
- **`ChipStyle.defaults` carries NO colours.**
- **`enableHaptic` defaults to TRUE**, like every other interactive
  module. A chip played no haptic at all before.
- **Every hard-coded number lives in `ChipDefaults`.**

## Gotchas

- **`RawChip`, not `Chip` / `ChoiceChip`.** Those are thin wrappers that
  each cover ONE of selection and deletion. A chip doing both used to be
  built as a `ChoiceChip` with the ✕ pushed inside its label — and
  `RawChip` wraps the label in an `IgnorePointer` so the whole surface is
  one tap target, which made that ✕ pure decoration: tapping it did
  nothing at all. `RawChip` takes `onSelected` AND `onDeleted` together
  and gives the delete control its own hit target. Guard: "a chip can
  both select AND delete".
- **An unselected chip is NOT shrunk.** It used to sit inside
  `AnimatedScale(scale: selected ? 1.0 : 0.97)`, so every unselected chip
  in the app rested at 97% — a permanent fractional raster of the label,
  which is what made a row of filters look soft. That is not an
  animation; it is a resting state that happened to be reached through
  one.
- **The gradient path honours `padding`.** It was a hard-coded 12/8, so
  adding a gradient silently swallowed whatever inset the caller asked
  for. `ChipDefaults.gradientPadding` is the fallback, and it exists
  because Material's chip supplies an inset that a hand-painted `Stack`
  does not.
- **The leading and trailing slots take the LABEL's colour.** A caller
  hands in a bare `Icon`, which otherwise inherits whatever ambient
  `IconTheme` the page has — so a selected chip showed a white label
  beside a dark glyph. `IconTheme.merge` (`kChipIconThemeKey`) is the
  seam, and it still loses to an `Icon` given an explicit colour, which
  is how a caller opts out.
- **The gradient surface is ALWAYS a gradient**, even in a state that
  has none of its own — `_flat(color)` is a gradient of one colour. A
  chip that gradients on selection only used to swap `gradient` for
  `color` between states, and `BoxDecoration.lerp` fades one out while
  fading the other in: mid-flight that is a half-transparent gradient
  over a half-transparent fill, which reads as a grey flash on every
  deselect. Two gradients interpolate cleanly.
- **A gradient forces the hand-painted path** — `Border` takes colours,
  not gradients, so `rs.hasGradient` switches the whole build. The
  border gradient is a `CustomPaint` stroke deflated by half its width,
  since a stroke straddles its path.
- **The count pill is a `GlobalBadge`.** It was hand-rolled here, one
  more copy of the geometry the badge sweep pulled together, so a chip
  count read at a different size from an unread count beside it. It is
  NEUTRAL, though — `chipCountBadgeStyle` washes the chip's own
  foreground rather than taking the badge's error red, because a chip
  count says "how many", not "something is wrong".
- **A selected FILLED chip drops its border**; outlined keeps one in
  both states; tonal never has one. The fill IS the shape on a filled
  chip, and an outline on top of it reads as a second control.
- **The selected label takes on-primary only on the FILLED variant.**
  Outlined and tonal keep a tinted surface, so their label carries the
  brand colour itself. A blanket on-primary was invisible on both.
- **Weight, not colour, is what marks selection on tonal and outlined.**
  Their fills barely change, so `w600` is the signal that survives.
- **A checkmark needs a chip you can actually choose.** `showCheckmark`
  is ignored without `onSelected` — a tick on a chip that cannot be
  selected promises a state it can never enter. Find it by
  `kChipCheckmarkKey`; `ScaleTransition` is not a usable finder, since
  Material mounts its own.
- **An unselected chip reserves NO space for its tick.** A
  `ScaleTransition` at scale 0 still occupies its full width — it is a
  paint-time transform — so a row of checkmark chips sat wider than a
  plain one with the label pushed off centre. The tick rides a
  `SizeTransition` as well, growing from the start edge so the label
  stays put. Guards: "an UNSELECTED checkmark chip reserves no space for
  it" and "a SELECTED one is wider by exactly the tick".
- **Two curves off one controller.** The spring is safe on the SCALE
  only: `elasticOut` overshoots past 1, which both a width and an
  opacity refuse — `SizeTransition` would jitter and `Opacity` asserts.
  The reveal (size + fade) is `easeOut`.
- **`showCheckmark: false` is passed to Material deliberately.** Ours is
  animated and coloured from the bag; Material's would be a second tick
  beside it.
- **Delete fires ONCE.** `_deleteInProgress` guards the window while the
  shrink is running, or a double tap deletes twice.
- **Reduced motion collapses the durations and drops the checkmark
  spring** — the tick still appears, it just does not bounce.
- **A static chip is not a button.** No `onSelected` means no button
  flag and no selected state in semantics; announcing "button, not
  selected" invites a tap that does nothing.

## Roles

A chip is one of three things, and the callbacks pick which — passing
both a choice and an action asserts:

| callback | role | semantics |
| --- | --- | --- |
| `onSelected` | choice / filter | button + selected state |
| `onPressed` | action | button, NO selected state |
| neither | static label | not a button at all |

`onDeleted` composes with any of them. `RawChip` is what makes that
possible: it is the only one of Material's three wrappers that takes
selection and deletion together.

## Adoption

Six surfaces hand-rolled a Material chip instead of using this module —
`faq/` (page + detail), `wizard/`, `date_time_picker/`,
`text_field/surfaces/` and `drop_down/surfaces/`. Each picked its own
radius, selected colour and delete icon, and none of them got the fixes
above. All six go through `GlobalChip` now.

- **The tags panel could not have been converted before.** The text
  field declared its OWN `ChipStyle` — six fields against this module's
  twenty-nine, under the same name — so importing both was an
  ambiguous-import error. That duplicate is gone; `ChipsConfig.style`
  and `TagsField.chipStyle` take the module's bag, and the panel merges
  its two surface defaults (solid primary, full radius) over it.
- **The dev hub built its own pills.** The category and tag strips were
  `AnimatedContainer`s doing three of this module's features by hand — a
  selected fill, an outline at rest and a leading icon following the
  label — with their own radius and duration. The first sweep missed
  them because the guard scanned `lib/shared` and stopped there; it
  covers `lib/features` now.
- **A class-name guard cannot catch a hand-rolled pill.** Nothing in the
  dev hub was named `ChoiceChip`, so the regex had nothing to find.
  `test/dev_hub/dev_hub_tags_test.dart` asserts the strips render
  `GlobalChip`s by label instead — named labels rather than a count,
  since the category strip is a lazy horizontal list and how many exist
  is not how many are built.
- **The debug overlay is exempt on purpose.** Developer-only furniture,
  deliberately plain, and converting it would only add churn.
- Guard: `test/chip/chip_adoption_test.dart` fails on any Material chip
  class named under `lib/shared/module` (outside `debug_overlay/`) or
  `lib/shared/common`, and on a second `ChipStyle` declaration.

## Known gaps

- **An elevated chip paints its shadow OUTSIDE its own box**, and takes
  exactly as much room as a flat one — so any ancestor that clips eats
  it. A horizontal strip of chips is the usual case: `ListView` and
  `SingleChildScrollView` both clip to their viewport by default, which
  shears the selected chip's shadow off flat along the bottom edge.
  `clipBehavior: Clip.none` keeps the shadow and trades one bug for a
  worse one: with clipping off entirely the chips PAST the viewport
  paint as well, so a strip inside a card runs out over the page and
  off the side of the screen. **`GlobalChipStrip`** clips on ONE axis —
  its own width, with a few points of slack above and below — and is
  what a horizontal strip should use. The date-range presets and the
  date-picker showcase's family filter do; the dev hub's category
  strip, the FAQ's category row and the loading overlay's still pass
  `Clip.none` by hand and would leak the same way given a narrower
  parent. Guards: `test/chip/global_chip_strip_test.dart`.

- **`materialTapTargetSize: shrinkWrap` is deliberate.** A chip row with
  48dp targets spaces itself like a list. It clears WCAG 2.5.8 (24×24)
  at the default size, but a caller shrinking the label style past ~11pt
  should check it again.
- **`maxWidth` truncates the LABEL only.** A long label with a count and
  a trailing widget will still push past it, because the count and the
  trailing slot are not flexible.

## Showcase + tests

`/chip-showcase`. Tests: `test/chip/global_chip_test.dart` (bag merge,
resolution order per variant and state, palette colours, the badge count
pill, gradient surface + padding, no resting shrink, select / delete /
both, checkmark gating, reduced motion, lerp, factories, semantics).
