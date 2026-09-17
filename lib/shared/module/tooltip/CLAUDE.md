# CLAUDE.md — lib/shared/module/tooltip

`GlobalTooltip` — a themed tooltip over Material's.

```dart
GlobalTooltip(message: 'Delete', child: icon)
GlobalTooltip.bubble(message: 'Points at me', child: icon)
```

## It renders through the POPUP engine

Not Material's `Tooltip`, and the reason is the arrow.

Material clamps a tooltip inside the screen but never reports how far it
clamped, so a bubble near an edge points at the margin beside its anchor
and nothing can correct it. The popup engine hands its surface the drift
it applied (`GlobalPopupLayout.followerOffset`), which is exactly the
number the arrow needs — see `popup/CLAUDE.md`, "The arrow follows the
drift".

That capability was proved BEFORE the move, not assumed: the arrow fix
landed on the popup module first, with its own tests.

The popup module also used to ship a SECOND tooltip —
`GlobalPopup.tooltip` plus a `GlobalPopupTooltip` surface with its own
styling. Both are gone. One tooltip, one style bag. Guard: "there is
only ONE tooltip entry point".

## What that cost

Four behaviours came free with Material and are now this module's:

| behaviour | where it lives |
| --- | --- |
| hover REST before opening | `GlobalPopupOptions.hoverOpenDelay` |
| auto-dismiss after reading | `GlobalPopupOptions.autoDismissAfter` |
| hover on pointer, long-press on touch | `GlobalPopupTrigger.hoverOrLongPress` |
| the ANCHOR's own semantics | `Semantics(tooltip:)` here |

The first three were added to the popup module, where they are useful
beyond tooltips. The fourth is the one that could have shipped as a
silent regression: a screen reader has to be able to read a control's
tooltip WITHOUT opening it, and an overlay that only announces itself
when visible cannot do that.

## Contracts
- **Style is the themeable bag `TooltipStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once per
  build by `style.resolve(context, shape:)` into a
  `ResolvedTooltipStyle`. There were fourteen flat visual parameters on
  the widget before.
- **`resolve` takes the SHAPE, and NOT the side.** The offset depends on
  the shape and the bag cannot know it: a bubble stands further off the
  child, its arrow standing in the gap. The side used to be an argument
  too, to aim a `ShapeBorder`'s arrow — the popup engine owns the side
  now and may flip it after the bag is built, so a side baked in here
  would be a lie half the time.
- **`defaults` carries no colours and no vertical offset** — the first
  come from the palette, the second from the shape.
- **Every hard-coded number lives in `TooltipDefaults`.**

## Gotchas

- **The surface INVERTS against the page.** A light page gets
  `primaryHighContrast` (near-black); a dark page gets the raised
  `container`, because a near-black bubble on a dark page disappears
  into it. Only the dark one draws a border, for the same reason — the
  light one has its shadow.
- **The label colour is `textColors.onPrimary`, not `Colors.white`.** It
  was the literal, and the stock palette's onPrimary IS white, which is
  exactly why that survived. The test asserts identity with the palette
  rather than difference from the literal, since the two only diverge on
  a rebranded palette and a test cannot rebrand the app.
- **A `tooltipWidget` or `richMessage` needs a `semanticLabel`.** A span
  is not a string and a subtree is not a string, so neither has a
  plain-text form to announce.
- **The surface renders the arrow — `GlobalPopupOptions.arrow` does
  NOT.** That field is read only by the popup's own `.menu` / `.panel`
  factories, which forward it to the surface they build. A custom
  `overlay:` builder hands it to its own surface, and the first version
  of this one set it on the options instead, so every bubble drew no
  tail at all. Guard: "renders an arrow".
- **The label keeps its PLAIN padding.** Material drew the arrow inside
  the box, so the body had to give up `arrowSize` on the pointing side
  or the tail painted over the text. The popup reserves that band
  outside the body — keeping the old inset just padded the bubble twice.
- **`verticalOffset` is measured from the child's EDGE.** Material
  measured its own from the anchor's CENTRE, so its default 24 was ~4
  clear of a 40dp icon button; carried over unchanged the tooltip
  floated half a control away. 8 now, 16 for a bubble. Guard: "sits
  CLOSE to the child by default".
- **`verticalOffset` is the distance to the BODY**, and the gap handed
  to the popup is `gapFor(shape)`: a bubble asks for `arrowSize` less,
  because the tail stands in that gap. The tip lands where a rectangle's
  edge would.
- **A caller's `decoration` wins outright, shape included** — it
  REPLACES the surface. The popup surface
  goes transparent and carries only the layout constraints, with the
  decoration painted inside it — and no arrow, since an arrow belongs to
  a border this module drew.
- **A slid bubble still points at its anchor**, and does not slide into
  place: the tail's travel is bounded by the SURFACE's straight edge,
  not the anchor's width, and it reads the clamp in the same layout pass
  that applies it. Both were wrong at first — see `popup/CLAUDE.md`,
  "The arrow follows the drift". Guards: "a slid bubble still points AT
  its anchor", "and the tail does not slide into place after the fact".
- **`screenMargin` is a scalar**, not `EdgeInsets`: it feeds the popup's
  `screenPadding`, which is one number.
- **It asks the popup for a CONTENT width, every time.** The engine's
  default strategy is `matchAnchor`, and a tooltip's anchor is usually a
  40dp icon button — so leaving `width` unset shipped tooltips one
  character wide, each label a vertical stack of letters. It sizes to its
  text up to `maxWidth` (240dp), which is a reading measure, not a
  container. Guard: "sizes to its CONTENT, not to a narrow anchor".
- **`waitDuration` is the point of a tooltip on a toolbar.** It is what
  stops one firing while a pointer crosses on its way somewhere else.

## Triggers

`TooltipTrigger` decides what opens it:

- `hoverOrLongPress` — the default, and what Material does.
- `hoverOnly` — the long-press gesture stays free for the host. The
  media picker's tiles long-press to open a menu, and a tooltip
  claiming that gesture takes the menu with it.
- `none` — nothing opens it, but the anchor keeps the SEMANTICS. For an
  icon-only control that is the whole value.

`announceOnAnchor: false` is for a host that already publishes the
tooltip on its own node — `GlobalIconButton` excludes its inner tree and
re-exposes the string itself, so leaving it on nests two nodes carrying
the same text.

## Known gaps

- **`find.byTooltip` does not find these.** It matches Material's
  `Tooltip` / `RawTooltip` widgets specifically. Tests find by the
  announced tooltip instead — `byTooltipText` in the app-bar and drawer
  suites — which is the thing both implementations share and the thing a
  screen reader actually reads.
- **No RTL flip for the arrow**, and none needed: it points up or down,
  and vertical does not mirror. RTL is covered for the two things that
  DO change: a directional `padding` resolves against the surface's own
  direction, and the surface still centres on its anchor.

## Adoption

Eight modules used Material's `Tooltip` raw — the drawer's mini rail,
the popup, both media-picker surfaces, the navigation rail, the audio
player, the icon and the toggle group — each inheriting Material's grey
instead of the app's surface, with Material's timings. All go through
`GlobalTooltip` now. Guard: "no module uses Material's Tooltip raw",
which fails on a new one anywhere under `lib/shared` outside
`debug_overlay/`.

## Showcase + tests

`/tooltip-showcase` — including a **Triggers** card (all three), an
**Edge Clamping** pair: three anchors pinned across the screen, and a
drag demo whose slider walks the anchor edge to edge with the tooltip
open, with `screenMargin` and shape as live knobs. The drag demo works
only because the anchor REBUILDS: the follower tracks it at paint time,
but the clamp is placement, recomputed from
`GlobalPopup.didUpdateWidget`. A `const` anchor slides off the screen —
measured. Guard: "it re-clamps when the anchor MOVES under an open
tooltip".

Tests: `test/tooltip/global_tooltip_test.dart` (bag
merge, resolution order, palette colours, both brightnesses, the
bubble's offset / arrow direction / decoration type / body inset, a
caller decoration winning, the WidgetSpan path, the content assert,
lerp, and the adoption guard), plus: every remaining bag field
asserted against what the OPEN surface renders — gradient, border
radius and the label's text style, the three that had no such
assertion after four others turned out to have been resolved and
dropped — and the FLIP: an anchor pinned to the bottom of the screen
opens above it with the tail on the bottom edge, since after a flip the
side is the engine's, not the caller's preference.

## It never evicts another popup

`closeOthersOnOpen: false`. The popup default is to close everything
else on open, which is right for a menu replacing a menu and wrong for
a label — holding an item in an open menu to read its tooltip shut the
menu. Reported from a collapsed toggle group.
