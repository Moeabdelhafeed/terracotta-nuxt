# CLAUDE.md — lib/shared/module/badge

`GlobalBadge` — the app's unread marker. Wraps any child and hangs a
count, dot, label, icon or custom widget off one of its corners.

```dart
GlobalBadge.count(count: unread, child: const Icon(Icons.mail))
GlobalBadge.dot(child: avatar)
```

## This module had no consumers

Four navigation modules — `tab_bar`, `navigation_rail`, `bottom_nav`,
`drawer` — each hand-rolled their own badge and dot, and `GlobalBadge`
was used only by its own showcase. Three of the four agreed on geometry;
the drawer had already drifted on every value:

| | font | radius | h-pad | dot |
| --- | --- | --- | --- | --- |
| tab_bar / rail / bottom_nav | 9 | 8 | 5 | 6 |
| drawer | 10 | 10 | 8 | 8 |

So the same unread count was a different size depending on which surface
it appeared on — and the drawer's own mini/rail mode had a THIRD set
again, twenty lines from its row version. That is the cost this module
exists to prevent, and the reason it was brought to the gold standard
before adoption rather than after.

All four go through `GlobalBadge` now, and
`test/badge/badge_adoption_test.dart` asserts it — including that the
font size matches across surfaces, which is the thing that had drifted.
Each surface still owns WHERE it hangs a badge; only the pill is shared.

## Two shapes

- **Wrapping** (`GlobalBadge`, `.count`, `.dot`, `.label`, `.icon`) —
  hangs off a child's corner. Right for an icon in a navigation bar.
- **Standalone** (`GlobalBadge.standalone`) — an inline pill or dot with
  no child and no overhang. Right for a trailing count in a list row.

The second only exists because adoption needed it: every module wanting
that shape had hand-rolled one instead, which is a large part of how
four badges happened.

## Contracts

- **Style is the themeable bag `BadgeStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once per
  build by `style.resolve(context)` into a `ResolvedBadgeStyle`.
- **Resolution order**: `caller > GlobalBadgeTheme.style >
  BadgeStyle.defaults`, then colours from `context.<group>Colors`.
- **`BadgeStyle.defaults` carries NO colours.** They were `Colors.red`
  and `Colors.white` — the same red whatever palette the app shipped.
- **A badge is an ALERT, so it takes `statusColors.error`**, not the
  brand colour.
- **The ring matches the PAGE, not the child** (`backgroundColors.background`).
  That is what makes the badge read as lifted off whatever it is pinned
  to rather than drawn onto it.
- **Corners are directional.** `topEnd` is the right edge in English and
  the left one in Arabic — the position enum is named for the reading
  order, not the screen.

## Gotchas

- **`pulsate` is skipped under reduced motion, not shortened.** It
  repeats forever rather than settling, which is precisely what
  `disableAnimations` exists to stop. The show/hide transition collapses
  to zero duration in the same breath.
- **`hideWhenZero` is decided in `build`, not in the `.count` factory.**
  The factory has no `BuildContext`, so it cannot see a theme — deciding
  there meant `GlobalBadgeTheme(style: BadgeStyle(hideWhenZero: false))`
  could never take effect. Guard: "a zero count hides it, and the THEME
  can say otherwise".
- **The corner overhang is derived from the badge's own extent**
  (`ResolvedBadgeStyle.extentFor`), which differs per variant — a label
  pill is font-height plus padding, a dot is `dotSize`. A single constant
  would leave one variant floating and clip another.

## Showcase + tests

`/badge-showcase`. Tests: `test/badge/global_badge_test.dart` (bag merge,
resolution order, palette colours, lerp, count capping, themed
zero-hiding, RTL corner, reduced motion, semantics).
