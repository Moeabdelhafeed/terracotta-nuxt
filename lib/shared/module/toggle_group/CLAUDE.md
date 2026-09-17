# CLAUDE.md — lib/shared/module/toggle_group

Bordered BUTTON-SET selection control — multi-select, icon-only,
vertical orientation, dividers. Holds the gold standard: themeable
style bag, shared message column, style-gated haptics, reduced motion.

> **Status: FINISHED (July 2026).** Module holds the gold standard
> (themeable `ToggleGroupStyle` + `GlobalToggleGroupTheme` incl.
> `itemPadding`, `FieldMessagesColumn` errors, style-gated haptics,
> localized ARB semantics, per-button `Semantics(selected:)`, reduced
> motion) and the `shared/common/selection_fields/toggle_group/`
> catalog is complete: SortDirectionToggle, WeekdaysToggleGroup,
> PriceTierToggle, TextFormatToggle, TextAlignToggle (RTL icon swap),
> NotificationChannelsToggle, DayPartToggle, SizeFilterToggle,
> CountFilterToggle (null = Any), StarRatingToggle — localized en +
> ar where labels aren't tokens, locale-flip safe, showcased under
> the Common Hub + playground. Dense sets pass `itemPadding` (the
> default 16 crushes 7 buttons on a phone). Deliberately NOT here: a
> merge with segmented_control (see boundary below), app-data option
> lists (build `ToggleGroupItem`s inline).

## Boundary vs segmented_control (deliberate, keep it)

Two modules, one rule:

- **Single-select with the sliding-indicator look** →
  `GlobalSegmentedControl` (drag-to-select, arrow-key nav, iOS feel).
- **Multi-select, or the bordered button-set look** →
  `GlobalToggleGroup` (`.single` exists for single-select IN this
  visual style — that's a look choice, not a duplicate).

They are NOT merged because the machinery genuinely differs (sliding
`AnimatedPositionedDirectional` indicator + drag mapping vs per-button
fills + dividers) — unlike the checkbox's removed toggle variant, which
was a duplicate implementation of `GlobalSwitch`.

## Contracts

- **Fully controlled.** Displays `selectedValues` as passed; reports
  the new list via `onChanged`, never mutates.
- **Style is the themeable bag** (`ToggleGroupStyle`, every field
  nullable): `caller > GlobalToggleGroupTheme.style > defaults >
  context.<group>Colors`, materialized once per build. Adding a themed
  field → bag, `mergedWith`, `copyWith`, `ResolvedToggleGroupStyle`,
  `GlobalToggleGroupTheme._lerpStyle`.
- **Haptics gate on `style.enableHaptic`** (resolved, default `true`).
- **errorText/messages** render via the shared `FieldMessagesColumn`.
- **A11y**: group-level localized label + per-button
  `Semantics(selected:)`; InkWell supplies focus + Enter/Space
  activation natively; icon-only buttons expose the item label.
- **Reduced motion** collapses all tweens.

## Overflow

`overflow: ToggleGroupOverflow.collapse` is the DEFAULT. What did not
fit used to overflow: a striped `RenderFlex overflowed` bar and buttons
past the edge nobody could reach.

- **It MIRRORS.** A custom `RenderBox` lays out from x = 0 whatever the
  locale, so an Arabic group came out in English order with the "+N" on
  the wrong end — a `Row` would have mirrored for free, this has to be
  told. The offsets are assigned only once the total width is known,
  because in Arabic the FIRST button is the one against the right edge.
- **`ToggleOverflowRow`** (`toggle_group_overflow.dart`) is a custom
  `RenderBox`: it measures every button at its natural width, keeps the
  ones that fit, and hands the rest to a **"+N"** button that opens
  them stacked. Not a `Wrap` — a toggle group is ONE bordered strip and
  a second line is two strips with one border round both. Not a
  scroller — nothing on screen would say there is more, and a selected
  item scrolled out of view reads as unselected.
- **The panel is this same widget, vertical.** Every state it can show
  comes along for free, and a reader who has been tapping bordered
  buttons recognises what opened.
- **In an ICON-ONLY group the button is an icon**, not "+N". A label in
  a set of icon squares came out half as wide again — visibly not one
  of them. The count moves to the tooltip and the announcement, where
  it was anyway.
- **The panel's items are EXACTLY the size of real ones** — measured,
  not approximately. Two points out on each axis, from two separate
  causes:
  - **Height** is the row's INNER height, `rs.height` less the border
    on both sides. `rs.height` is the whole strip; forcing it made
    every menu item taller than the button it came out of (40 against
    38).
  - **Width** needs `GlobalPopupWidth.minAnchor()`. The default matches
    the ANCHOR, so the panel came out exactly as wide as the "+N" — and
    inside its own border every item lost another two points (40
    against 42). `IntrinsicWidth` then gives them all one width.
  Guard: `a panel item is EXACTLY the size of a row button`, which
  compares the two `InkWell`s.
- **The panel AUTOFOCUSES its first item.** A menu that opens without
  taking the keyboard with it cannot be used from one.
- **The panel has NO surface of its own.** The group inside already
  draws the border, the radius and the dividers; a popup card round
  that is a frame within a frame. It is handed the SAME bag as the
  row, so a caller's overrides reach it too — what opens should look
  like the strip stood on its end.
- **They are butted together, border to border.** Overlapping them by
  one border did leave a single clean line, but it read as the panel
  sitting ON the strip rather than under it.
- **Opening UPWARDS reverses the list**, so the item nearest the
  trigger is the one that would have come first and the order still
  reads outward from the strip.
- **The strip and the panel JOIN along the edge between them**, and
  they give up different amounts of it. The STRIP loses one corner —
  its bottom-end when the panel opens downwards — because only that
  corner touches the panel, and squaring the far end would just make
  the group look clipped. The PANEL loses the whole edge, both corners,
  because that edge lies entirely against the strip's side and a curve
  at either end of it reads as a seam. It mirrors in Arabic, and both
  sides are `AnimatedContainer`s, so the corners MORPH rather than
  snapping. `layout.isAbove` is the source; the trigger hears it
  through a `ValueNotifier` because the overlay is not one of its
  descendants, and takes its corner back on `onClose`.
- **The panel is nudged one BORDER past the trigger.** The popup
  aligns it to the ANCHOR's box, and the anchor is the "+N" — which
  sits inside the strip's border. Aligned to the button, the panel's
  outline landed a point short of the strip's and the join had a
  visible jog. The nudge puts the two outlines on one line. The
  surface's own clip is off for it, or the clip would shave the border
  off the side it moves towards.
- **The direction for that nudge comes from the GROUP, not the
  overlay.** An overlay entry sits above the page in the tree, so
  `Directionality.of` on its context reads the app's default — LTR even
  on an Arabic page — and the nudge went the wrong way. Guards in both
  directions.
- **A strip given a TIGHT width does not hug its content.** The row
  reports `used`, then `constraints.constrain` stretches it, and the
  buttons sit at the start with the slack after the "+N" — so the panel
  lines up with the trigger while the STRIP runs on past it. Give the
  group a loose constraint (`Flexible`, not `Expanded`, and not a
  `SizedBox` of a fixed width) if that gap is not wanted.
- **The popup's SURFACE takes the joined radius too.** It clips what it
  holds, so with its own default radius it rounded the joined edge back
  off — the group inside reported square corners while the screen
  showed curved ones. Guard: `a panel that FLIPS above squares its
  bottom edge — clip included`, which walks every clipping `Material`
  inside the panel rather than trusting one of them.
- **The panel paints its OWN background**, exactly behind the group.
  Left to the popup's surface it was sized by the popup, and a sliver
  of its colour showed past the bottom edge of the group inside it.
- **The "+N" gets its focus state from a node the popup is handed.**
  With no tap handler it has no `InkWell` focus to paint from, and the
  popup owns the tab stop — so `GlobalPopup` grew an `anchorFocusNode`
  and the button paints the same wash the InkWell would have.
- **The "+N" has NO tap of its own**, and carries its own leading
  divider. An `InkWell` with a callback takes the focus AND consumes
  Enter through its own `ActivateIntent`, so the button was focusable
  and pressing it did nothing; and with no rule before it, a collapsed
  button sat flush against the one before it — read as one wide button
  when both were filled. The popup around it owns the pointer and the
  keyboard both, which needed `GlobalPopup` to grow Enter/Space on its
  TAP trigger: that trigger is raw pointer events, so a keyboard could
  reach the anchor and do nothing with it.
- **The "+N" wears the SELECTED state** when one of the items behind it
  is on. A selection the reader cannot see is one they will assume is
  gone.
- **Hidden buttons leave the FOCUS tree as well as the semantics one.**
  They stay in the WIDGET tree because the row has to measure them to
  know they do not fit — which left them as traversal stops, so Tab
  walked through buttons nobody could see and stopped on each. The
  `ExcludeFocus` is always in the tree and only its flag moves: adding
  or removing the wrapper would change the tree SHAPE at that slot and
  remount the button under it. The "+N" is excluded the same way when
  there is nothing behind it.
- **Hidden buttons leave the SEMANTICS tree.** They stay in the widget
  tree — the row has to measure them — but offering them out here as
  well as inside the panel is offering them twice, and the outer one
  does not answer to a tap.
- **Dividers ride WITH their button** in the overflow row, or a hidden
  button leaves its rule behind as a hairline against the "+N". On the
  plain row they stay siblings, because an `expandEqual` button is an
  `Expanded` and an `Expanded` inside a shrink-wrapping inner Row has
  no free space to expand into.
- **`expandEqual` (the default) is exempt.** It fills the track rather
  than overflowing it — the buttons squeeze and the labels ellipsize,
  which is its own trade and not this one.
- **A row measures during LAYOUT and reports after the frame**, through
  `setState`. The "+N" and its panel are built BEFORE the measurement,
  so without the rebuild the first collapse showed "+0" over an empty
  panel.

### Groups narrow together

`ToggleGroupOverflowScope` takes the SMALLEST count any of its members
can fit and holds all of them to within ONE of it.

Not to the minimum exactly: that threw away room already on the screen
— a set of four beside a set of two collapsed to two and left a whole
button's worth of space empty. Within one of each other they still
read as a pair. Two groups on one card that
collapse at different moments look broken rather than responsive.

- `coordinateOverflow: false` opts out — a pair of sort arrows has no
  business shrinking because seven weekdays beside it ran out of room.
- **`GlobalSegmentedControl` is in the same scope**, and imports the
  same layout. The two modules are a documented pair; one copy of the
  machinery beats two that drift.
- **A group in a `Row` needs `Flexible`.** A `Row` hands its children
  UNBOUNDED width, so each group thinks it fits and the ROW overflows
  instead — which is exactly what the reported bug was. Nothing in the
  module can see that from the inside.
- The scope's handle is resolved in `didChangeDependencies` and KEPT:
  a member deregisters in `dispose`, and an ancestor lookup from there
  is unsafe.

## Focus, hover and the ripple

They are the `InkWell`'s own. There is no custom ring, and the one
that was here has been removed.

- **The FILL sits outside the `Material`, and that is the whole fix.**
  An `InkWell` paints its splash, hover and focus onto the nearest
  `Material` — BELOW everything the InkWell wraps. With the fill as the
  InkWell's child, an opaque button covered all three: no ripple, no
  hover and no focus on any button with a background, which is every
  selected one. Nothing was wrong with the focus; it was being painted
  underneath. The order is fill → `Material` → `InkWell` → padded
  content.
- **`focusColor` and `hoverColor` take the button's own FOREGROUND** —
  `onPrimary` over a filled button, the text colour over an empty one
  — so neither wash disappears into an accent fill.
- **Focus is heavier than hover** (`kToggleGroupFocusOpacity` vs
  `kToggleGroupHoverOpacity`). At the same weight the two are
  indistinguishable, and they say different things: hover hints that
  something is interactive, focus says where the keyboard IS.
- **Both clips use a SAVE LAYER.** Plain `Clip.antiAlias` clips ink
  with a soft edge and leaves a hairline of the hover wash outside the
  curve — a few pixels of bleed in exactly the corners meant to be cut.
  The button's clip and the strip's both had it, since the ink passes
  through the two of them.
- **The ink is clipped to the BUTTON's shape**, not the group's: the
  strip's radius LESS the border width at its two ends, square in the
  middle. Clipped to the outer radius instead, a splash bulges past the
  border it is sitting inside.
- **CORNER BY CORNER, not side by side.**
  `BorderRadius.horizontal`/`vertical` take one radius for a whole
  side, and the strip's radius stops being symmetric the moment a panel
  squares one corner of it — the menu's first item has a rounded
  top-start and a square top-end, and a side-at-a-time radius rounded
  both.
- **Every corner the strip gives up, its INK gives up too.** The
  buttons were handed `rs.borderRadius`, which never changes, so the
  strip squared a corner while the splash inside carried on rounding
  it. They take the CURRENT radius now — which is also why the open
  side is plain state rather than a `ValueNotifier`: a builder around
  the container alone never reached the buttons.
- **A long press is CLAIMED**, on any button that has a tooltip.
  Unclaimed it fell through and the menu shut instead of showing the
  label. The other half of that was in the tooltip module — see below.
- **The "+N" ripples but cannot take focus.** With no tap handler at
  all it looked dead when pressed; with a focusable one it ate Enter
  through its own `ActivateIntent`. It has `onTap` for the ripple and
  `canRequestFocus: false` so the popup keeps the tab stop and the
  key. Without the
  clip a splash on the first button squares off the rounded corner it
  is sitting in. `isFirst` / `isLast` are what is VISIBLE — once the
  row has collapsed, the last button on screen is the "+N".

## Showcase + tests

`/toggle-group-showcase`. Tests:
`test/toggle_group/global_toggle_group_test.dart` (resolve merge,
single/multi plumbing, error column) and
`test/toggle_group/toggle_group_overflow_test.dart` (collapse, the
panel, coordination, the focus ring).
