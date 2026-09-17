# CLAUDE.md — lib/shared/module/breadcrumbs

`GlobalBreadcrumbs` — the trail that says where a page sits, and how to
get back up it.

```dart
GlobalBreadcrumbs(items: [
  BreadcrumbItem('Home', route: 'home'),
  BreadcrumbItem('Account', route: 'account'),
  BreadcrumbItem('Privacy'),          // no route — the current page
])
```

## NOT the crash trail

`UiWatchdog.breadcrumb` and the crash reporter's breadcrumbs are a
diagnostic log of where the APP has been. This is a control that says
where the READER is. They share a word and nothing else — worth knowing
before grepping for "breadcrumb" in this repo.

## Contracts

- **Style is the themeable bag `BreadcrumbsStyle`** — every field
  nullable, with `defaults` + `mergedWith` + `copyWith`, materialized
  once per build by `style.resolve(context)` into a
  `ResolvedBreadcrumbsStyle`.
- **Resolution order**: `caller > GlobalBreadcrumbsTheme.style >
  BreadcrumbsStyle.defaults`, then colours from the palette.
- **Every hard-coded number lives in `BreadcrumbsDefaults`.**
- **The items and the callback are on the WIDGET.** What the trail IS
  is not how trails look.
- **It is not a second navigator.** It says which step was pressed;
  `onTap` wins over the item's own, which wins over its route.

## Overflow is the whole problem

A trail runs out of room almost at once — five crumbs at 13pt is
already over a 400dp phone. Four strategies:

- **`collapse`** (default) — the first crumb, an ellipsis, and the last
  few. The ellipsis opens a menu holding everything it swallowed:
  **nothing is lost, only moved**, which is the rule the PDF bar's
  control groups already follow.
- **`scroll`** — the whole trail sideways, with a **fade at each end**.
  The fade is not decoration: a trail running off the edge looks exactly
  like a trail that was cut off unless something says it moves. It is
  `smart`, so the end you have reached hides its own — what is left also
  points at where there is more to see. `edgeFade: 0` turns it off.
- **`wrap`** — over as many lines as it needs.
- **`lastOnly`** — the **PARENT**, not the current page. "Up" is the
  only thing a one-crumb trail can usefully say, and the page's own
  title has already said where you are.

**The budget is read from the WINDOW**, not guessed: `maxVisibleCompact`
on a compact one, `maxVisible` above it. The same lesson
`GlobalNavStrategy` learned when a bottom bar kept its place on a
landscape phone.

**Below four there is nothing to collapse** — the first, the ellipsis
and the current one already come to three.

## Two crumbs can carry the same name

A route pushed with its own data can appear twice in one trail — a
product page reached from a related product — and both crumbs then read
"Product". Two things tell them apart, and only one of them is real:

- **`detail`** — a short qualifier, shown **only when another crumb in
  the trail carries the same label**. Because it hides itself when it is
  not needed, declaring one at the call site costs nothing on the trails
  where every label is already distinct — which is what makes it safe to
  set for every product page. It joins the spoken label too.
- **`tooltip`** — an EXTRA, for the whole name when the label had to be
  short. It is **not** the disambiguation: it needs a pointer or a long
  press to appear, so it says nothing to a reader skimming the trail or
  listening to it.

The real fix, where it is available, is still a distinct label — pass
the product's name rather than the route's. `detail` is for when the
label genuinely comes from a generic route.

## Accessibility

- **The trail is ONE landmark** with `explicitChildNodes`. A reader
  jumping by landmark should find the whole of it, not eight loose
  buttons.
- **The current page is a HEADER, not a button.** It is where the
  reader already is, so it takes no tap and announces itself as the
  place rather than as a way to get somewhere.
- **Every crumb says where it sits** (`NavStrings.tabPosition`). A step
  is one of a set, and which one it is cannot be worked out from its own
  name.
- **The ellipsis says how many it is holding.** "…" on its own tells a
  reader nothing about what is behind it.
- **The separators are excluded.** A reader hearing "chevron" between
  every step is being read the furniture.

## It mirrors for an Arabic reader

- The `Row` gives the order; the chevron carries `matchTextDirection`,
  so the glyph turns too. Direction is **not** a knob.
- `lastOnly` flips its own mark, because there it points back the way
  you came rather than onward.

## `.fromRouter` is opt-in, and shallow

- It needs `labels`: a route's NAME is a slug — `common-toasts-showcase`
  — not something to show a reader. A segment with no label is SKIPPED
  rather than shown raw.
- **It is only as deep as the router is NESTED.** Most of this app's
  ~150 routes are declared flat, so it yields a single crumb for them.
  That is the router's shape, not a fault here, and it is why the
  factory is opt-in rather than the default.

## Gotchas

- **A mark is one or the other.** `separatorText` wins and BLANKS
  `separatorIcon` during resolve, so build code never has to decide
  which of two non-null fields it is looking at.
- **The current crumb takes the ordinary text colour**, not the link
  colour, and carries its weight instead. A link colour on the page you
  are already on invites a tap that does nothing.
- **The overflow menu is placed by the ENGINE**, via
  `GlobalPopup.menu` — the anchor is a WIDGET and the layout is
  computed. It is worth knowing what that replaced, because two
  separate bugs came out of doing it by hand with `GlobalPopup.showAt`
  and a `GlobalPopupLayout` written on the spot:
  - **The anchor was in the wrong coordinate space.** `showAt` renders
    into the NEAREST overlay, and a page can install a local one —
    `ShowcasePage` does — so a global offset was out by that overlay's
    origin. Measured: the menu opened sixty points below the button,
    exactly the app bar plus the page's top padding. It needed a
    `globalToLocal` correction that the engine now makes unnecessary.
  - **`isFlipping: false` meant it could never flip**, so a trail near
    the foot of a page ran its menu off the bottom.
  Guard: "even when the overlay is a LOCAL one" still measures the gap,
  and now measures that the engine gets it right.
- **A fixed `maxHeight` was NOT the cause of that gap**, though it
  looked like it. Measured with 320 and with a content height:
  identical, 88 points either way, because the surface shrink-wraps
  whatever it is given.
- **The qualifier scan early-outs rather than building a Set.** A trail
  is a handful of crumbs, so allocating per crumb would cost more than
  the scan it replaces.
- **It found a latent `GlobalMarquee` bug.** `_checkOverflow` guarded on
  `hasClients`, which is not enough: a position is attached before it
  has been laid out, and `viewportDimension` is a null-check on a field
  only `applyViewportDimension` sets. Under a `MaterialApp.router` the
  first post-frame lands before layout and it threw "Null check operator
  used on a null value" out of a scheduler callback. The guard is
  `hasViewportDimension`, and `.fromRouter`'s tests are what prove it —
  no arrangement inside the marquee's own file could reproduce it.

## Showcase + tests

`/breadcrumbs-showcase`. `test/breadcrumbs/global_breadcrumbs_test.dart`
— bag merge, resolution order, the token-driven app theme, the palette
colours, each overflow strategy, the compact budget, the scroll fade,
the hidden count, the duplicate-label qualifier, navigation, semantics,
RTL, `.fromRouter` and lerp.

## Known gaps

- **The collapse budget is a COUNT, not a measurement.** It keeps N
  crumbs whatever they are called, so four short labels collapse where
  three long ones would have fitted. Measuring would mean a
  `LayoutBuilder` around a row whose children marquee — the arrangement
  that froze the bottom nav — so the count is deliberate until there is
  a reason to pay for the alternative.
- **No golden files**, so the separator geometry and the collapsed row
  are asserted structurally rather than by appearance.
