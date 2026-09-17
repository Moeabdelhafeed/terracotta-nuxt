# CLAUDE.md — lib/shared/module/app_bar

Two widgets over one style bag:

- **`GlobalAppBar`** — a `PreferredSizeWidget` wrapping Material's
  `AppBar`. Variants (standard / transparent / gradient), search mode,
  subtitle + leading icon, dynamic height, and a `hideOnScroll()`
  wrapper.
- **`GlobalSliverAppBar`** — the `SliverAppBar` counterpart for
  `CustomScrollView` / `NestedScrollView`: expanded title, background
  art, collapse and stretch modes.

Both read the SAME `AppBarStyle`, so a rebrand lands on both.

## Contracts

- **Style is the themeable bag `AppBarStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once per
  build by `style.resolve(context, variant:)` into a
  `ResolvedAppBarStyle` whose themed fields are non-null. Build code
  reads `rs.foregroundColor` directly; there are no `?? cs.onSurface`
  ladders left at use sites.
- **Resolution order**: `caller > GlobalAppBarTheme.style >
  AppBarStyle.defaults`, then colors from `context.<group>Colors`.
- **`AppBarStyle.defaults` carries NO colors.** They resolve from the
  palette at build time so the bar tracks role, brightness and
  saturation; a constant would freeze it against all three. Same reason
  `MyGlobalAppBarTheme` sets no colors either.
- **The variant participates in resolution**, which is why `resolve`
  takes it. Transparent and gradient bars have no surface behind them,
  so their background is transparent and their foreground is white
  regardless of the palette — that is derivation, not a default, and an
  explicit `backgroundColor` / `foregroundColor` still wins over it.
- **`toolbarHeight` is CALLER-ONLY.** `PreferredSizeWidget.preferredSize`
  is a getter with no `BuildContext`, so it cannot read a theme. A
  themed height would change what the bar PAINTS while `preferredSize`
  kept reporting the old number and the Scaffold laid out to it.
  `GlobalAppBarTheme` asserts against it rather than ignoring it
  silently. Use `style.preferredToolbarHeight` — the one path that
  answers without a context.
- **A bar that paints its own background hands Material a transparent
  one.** Gradient, `borderRadius` and `borderGradient` all render in
  `flexibleSpace`; an opaque `AppBar` would paint straight over it.
  `ResolvedAppBarStyle.paintsOwnBackground` is the single predicate.
- **A gradient STROKE is two boxes**, not a border: `BoxDecoration`
  cannot stroke a gradient, so the outer box is the stroke and an inset
  child carries the fill.
- **Every hard-coded number lives in `AppBarDefaults`.** They used to be
  private `_kFoo` constants duplicated across both widget files, free to
  drift. Values an app would rebrand belong in `AppBarStyle`; geometry
  that only changes when the module changes stays in `AppBarDefaults`.
- **The back affordance is sized to the touch target.** `MinTouchTarget`
  centres a button's PAINTED box inside a 48dp hit box, so anything
  smaller gains `(48 - size) / 2` of dead space per side. At the old
  38dp the back button sat 9dp from the bar's edge while an unstyled
  action sat at 4dp — same padding, different-looking gap. Both are 48
  now. `style.backButtonSize` / `backIconSize` bring the compact chip
  back per call site or app-wide. Guard: the "leading vs actions
  symmetry" group.

- **`titleSpacing` is 0, so the title's start inset is the module's
  job.** Zeroing Material's 16dp middle spacing is what lets a title sit
  tight against a leading widget. With NO leading there is nothing to
  sit against and the title lands on the bar's edge, so
  `AppBarDefaults.titleStartPad` puts the 16 back — start-aligned bars
  only, since padding one side of a CENTRED title pushes it off centre.
  Guard: the "title inset" group.

- **Titles marquee rather than truncate**, per `style.titleOverflow`
  (default `LabelOverflow.marquee`, `marqueeTitle` tunes the scroll).
  A bar has exactly one title and it names the page, so an ellipsis
  there is unreadable with no way to reveal the rest. Reduced motion
  truncates. Note this mounts a `SingleChildScrollView` per title — a
  test asserting a page has exactly one scroll view will now see two,
  and should scope its finder to the body.
- **A centred title is balanced against the leading slot.** Material
  centres the title in the band BETWEEN leading and actions, so a back
  button with nothing opposite shifted the title ~11dp right of the
  bar's real centre. When `centerTitle` is on with a leading widget and
  NO actions, an invisible `AppBarDefaults.leadingSlotWidth` action is
  added as a counterweight. Real actions are never displaced — the
  counterweight only stands in for missing ones.
  `style.balanceCenteredTitle: false` opts out.

- **A11y is not optional here.** The back button carries
  `MaterialLocalizations.backButtonTooltip` — Flutter already translates
  it, so nothing goes in the ARB — and the TITLE (never the subtitle) is
  a header landmark via `asHeader()`. Two headers in one bar make the
  landmark useless.
- **`HideOnScrollAppBar` needs no controller inside a `Scaffold`.**
  Flutter mounts a `ScrollNotificationObserver` above both the body and
  the bar — the same channel Material's own `AppBar` uses for
  scrolled-under elevation — so the body's scrolling reaches the bar
  with nothing threaded through the page, and it survives the scrollable
  being replaced or nested. Pass `scrollController` only OUTSIDE a
  Scaffold. Only `depth == 0` notifications count, so an inner carousel
  cannot drive the page's chrome.
- **The bar is SCRUBBED, not triggered.** Its offset tracks the scroll
  delta one-to-one: a slow drag moves it slowly, a flick takes it away
  at once. Direction decides — down hides, up shows immediately — and
  letting go settles to the nearer edge so it is never left half-drawn.
  It stays open while `pixels <= 0`, since a bar hidden above the first
  item has nothing to reveal.
- **It animates `heightFactor`, not a translate.** A translated bar
  leaves its old space reserved, so the body would not follow it up.
- **Reduced motion** shortens only the SETTLE; the scrub is the user's
  own gesture and is never something `disableAnimations` should freeze.

## Gotchas

- **`dynamicHeight` replaces Material's `AppBar` with a custom layout**,
  so it paints its own shadow from `elevation` (via
  `AppBarDefaults.dynamicShadowBlurFactor`) rather than handing an
  elevation to `AppBar`. Anything that only Material's `AppBar` provides
  is absent in that mode.
- **The sliver variant resolves with the STANDARD variant on purpose.**
  Its background is a widget (`background:`), not the `gradient` field,
  so the overlay treatment would be wrong. The light-foreground case is
  handled separately: a light foreground means the header art carries
  the contrast, and once collapsed that art is gone — hence
  `AppBarDefaults.darkCollapsedBackground`.
- **`showBack` still yields nothing when the route cannot pop.** It is
  an opt-out, not a force.
- **A `Scaffold` with a drawer gets a hamburger, but never at the cost
  of the back button.** This bar passes
  `automaticallyImplyLeading: false`, which it must, since it builds its
  own back affordance; that ALSO turned off Material's automatic
  hamburger, so a drawer could only be opened by swiping from the screen
  edge. On a pushed route the back button filled the slot and hid the
  gap completely, which is why it survived so long.

  Material resolves the clash by preferring the drawer, because it
  assumes a drawer lives at the ROOT of a stack. Copying that verbatim
  strands anyone on a pushed route with a drawer: no back button, and
  "how do I leave this page" is the worse of the two failures. So:

  | route | leading | actions |
  | --- | --- | --- |
  | root, drawer | hamburger | — |
  | pushed, drawer | back | hamburger appended |
  | pushed, no drawer | back | — |

  The drawer button is appended even when the caller supplied actions — a
  crowded bar is a smaller problem than a drawer with no button — and
  `leading:` still takes the slot outright.

  Only the LEADING side needs any of this: `automaticallyImplyLeading`
  does not govern actions, so Material still adds its own END-drawer
  button when `actions` is empty. Guard: the "drawer affordances" group.
- **The built-in search field is bare ON PURPOSE.** `app_bar` is a
  PRIMITIVE module, so it may not import `shared/common/` — debounce,
  recents, suggestions, scopes and voice all live in `SearchTextField`,
  which is a commons wrapper. Pass one through the `searchField` slot,
  or use `SearchAppBar` (`shared/common/app_bars/`), which exists for
  exactly this and keeps the dependency running one way.
- **The search field blends into the bar** — transparent fill, no
  border in any state. It IS the bar's content, so a fill paints a
  second surface over the bar's own and a focus ring boxes text the user
  is obviously already editing. `focused` must be zeroed BY NAME:
  `TextFieldStyle.defaults` and the app-wide theme both set it, and a
  state-specific side always overlays `base`. Same treatment on both the
  bare field and `SearchAppBar`, so swapping one for the other is not
  also a visual change. The horizontal content inset goes with them —
  with no fill and no border there is no box for it to sit inside, and
  it would only push the query out of line with every other screen's
  title. The vertical inset stays; it centres the text in the toolbar.
  The bar's own trailing pad goes too, so the field spans the full width
  and the clear button's TOUCH BOX ends flush with the edge. The box
  stays a full 40dp target — the gap left around the glyph is a11y, not
  decoration, and shrinking it would trade a tap target for looks.
- **The search field owns a fallback controller.** Passing none is fine;
  an inline `TextEditingController()` in `build` would be recreated every
  frame and never disposed.

## Showcase + tests

`/app-bar-showcase`. Tests: `test/app_bar/global_app_bar_test.dart`
(bag merge, resolution order, variant-derived colors, own-background
handoff, `preferredSize`, lerp, sliver parity).

## Hide on scroll

- **It is the DEFAULT on a short window.** A landscape phone is 402
  points tall and the bar takes 56 of them — fourteen per cent of the
  axis there is none of. `AppBarStyle.hideOnScroll` is a nullable
  TRI-STATE: null is "auto", which `resolve` turns into
  `WindowHeightClass.fromHeight(...).isCompact`; `true` and `false` pin
  it either way for a page that knows better. It is deliberately NOT in
  `defaults` — a compile-time floor has no window to measure, and a
  `false` there would make the auto case unreachable.
- **Height class, not `Orientation`.** "Landscape" on a tablet is 768
  points tall, where the bar is seven per cent and chrome that moves
  for no reason is worse than chrome that sits still. The short-window
  case is the one that has the problem, and a small desktop window in
  portrait has it too.
- **Hiding gives nothing back unless the body is BEHIND the bar.**
  Measured: a page without `extendBodyBehindAppBar` keeps a 346-point
  list in a 402-point window whether the bar is showing or not, and the
  56 points it vacates just sit there empty. `ShowcasePage` extends when
  the window is short and moves its top inset INSIDE the scroll view —
  on the shell it is a fixed gap outside the scrollable, so the bar
  would retreat behind a strip that never moves. Guard: "a short window
  puts the scroll BEHIND the bar".
- **`_HideOnScroll` is shared, and `_HideOnScrollScope` stops it
  doubling.** `.hideOnScroll()` on a short window would otherwise put
  one translation around another and the bar would leave at twice the
  scroll rate. Guard: "an EXPLICIT wrapper does not hide it twice" —
  measured over a 20-point drag held rather than released, because 200
  points drives BOTH translations past the end of the bar, both read
  zero, and the first version of that test passed with the guard
  removed.
- **Measure Material's `AppBar`, not `GlobalAppBar`.** The translation
  now lives inside `GlobalAppBar.build`, so the module's own box is
  above it and never moves — `getRect` there reads 56 whatever the bar
  is doing.
- **The bar TRANSLATES; its laid-out height never changes.** It used to
  collapse by `heightFactor`, and `Scaffold` hands the app bar's
  RENDERED height to the body as MediaQuery top padding — so every
  pixel the bar shrank pulled the body up a second pixel, on top of the
  scroll. Content moved at twice the scroll rate for as long as the bar
  was retreating, which reads as the bar lagging behind the page. The
  bar was 1:1 with the finger the whole time; the body was not.
  Guard: "the bar and the CONTENT move at the same rate".
- **The scrub is the gesture, not an animation.** `_ctrl.value` is
  driven straight from the scroll delta, so only the SETTLE has a
  duration — and reduce-motion zeroes that settle without freezing the
  drag, which is the reader's own finger.
- **The bar is TALLER than its `preferredSize`.** `Scaffold` renders an
  app bar at `preferredSize.height + MediaQuery.padding.top` and the
  bar draws its toolbar below that inset. So the translation is a
  FRACTION of the child's own height, and the scrub normalises against
  `preferredSize + inset`: a `SizedBox(height: preferredSize)` squashed
  the toolbar out of the frame on every device with a status bar, and a
  pixel translation by `preferredSize` alone would leave the notch
  strip on screen for ever.
- **A test view has NO status bar**, which is how that squash shipped
  green — every assertion was measuring a device with no `padding.top`
  to lose. `scrollHost(topInset:)` is the case that catches it.
- **The Scaffold needs `extendBodyBehindAppBar: true`.** The bar
  translates out of a box that keeps its height, so without it the
  vacated space sits there empty and the page looks like it lost its
  bar and gained a gap. It cannot be otherwise: `preferredSize` is read
  once per layout and cannot animate, and a bar that shrank its own
  height would relayout the body every frame — the body moving at twice
  the scroll rate, which is the artefact that made this look like
  lagging in the first place.
- **Measure what is SHOWN, not the wrapper.** The wrapper's rect is
  constant by design; the visible extent is the child bar's rect
  bottom.
- **A page that cannot AFFORD to lose the bar keeps it.** Hiding frees
  the bar's own height, so on a page with barely more content than
  fits, hiding makes the page unscrollable — the bar goes, the scroll
  ends, and no gesture remains that could bring it back.
  `hideMinExtentFactor` requires the content to be able to lose the
  bar's height and still scroll.
- Depth 0 only: an inner carousel or nested list must not drive the
  page's chrome.
- Pinned open while `pixels <= 0`, including during a bounce
  overscroll — a bar hidden above the first item has nothing to reveal.

## Entrance

- **`GlobalAppBar(...).entrance(EntranceKind.slide)`**, mirroring
  `.hideOnScroll()` — the bar stays stateless and the wrapper owns the
  controller.
- **A top bar arrives from ABOVE.** "In from its own edge" is a
  different direction at each end of the screen, so the slide is
  negative here where the bottom nav's is positive.
- **`EntranceKind` is SHARED with the bottom nav**
  (`core/animations/entrance.dart`), so the two ends of a screen can be
  told to arrive the same way and "staggered" means one thing in the
  codebase rather than two.
- **`staggered` falls back to `slideFade`.** A bar is one row, not a
  row of peers, so there is nothing in it to stagger — it arrives as
  one thing rather than pretending to.
- **It plays BACKWARDS as the page leaves**, driven off the route's own
  animation status.
- **Reduce motion SETS the value** rather than zeroing the duration. A
  zero-length entrance still rebuilds every frame on its way to
  nowhere.
- The wrapper forwards `preferredSize`: a `PreferredSizeWidget` that
  lies about its height lays the Scaffold out at the wrong one.
