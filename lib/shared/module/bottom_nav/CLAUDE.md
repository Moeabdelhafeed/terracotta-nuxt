# CLAUDE.md — lib/shared/module/bottom_nav

`GlobalBottomNav` — the app's bottom navigation bar, with GoRouter
integration, seven indicator styles, prominent items, a notch, a
scrollable variant and a tablet side rail.

```dart
GlobalBottomNav(items: [BottomNavItem(icon: …, label: 'Home', route: '/home')])
```

## Contracts

- **Style is the themeable bag `BottomNavStyle`** — every field
  nullable, with `defaults` + `mergedWith` + `copyWith`, materialized
  once in `didChangeDependencies` by `style.resolve(context)` into a
  `ResolvedBottomNavStyle`.
- **Resolution order**: `caller > GlobalBottomNavTheme.style >
  BottomNavStyle.defaults`, then colours from the palette.
- **Every hard-coded number lives in `BottomNavDefaults`.** They were
  forty-odd private `_k` consts at the top of the widget file, which no
  caller and no test could name.
- **The items, the index and the callbacks are on the WIDGET.** What
  the destinations are is not how bars look.

## Gotchas

- **The colours come from the PALETTE.** The surface, the selected
  tint, and both washed-out states read
  `Theme.of(context).colorScheme` — Material's scheme rather than the
  app's, so a rebranded palette left every navigation bar behind. The
  shadow was `Colors.black` and a prominent item's glyph was
  `Colors.white`, neither of which is a colour this app owns.
- **The surface is the CONTAINER, not the surface.** A bar sits above
  the page.
- **`initState` cannot read the resolved bag.** It runs before
  `didChangeDependencies`, and resolving needs a palette, which is an
  inherited lookup. The two controllers are therefore gated on the
  CALLER's own bag — which is right anyway: a theme that switches on
  tap-bounce for a caller who never asked for it is not something this
  module offers.
- **`compact` picks the height, and a caller's `height` still wins.**
  The fallback moved into `resolve`, so build code reads one number.

## Accessibility

- **Every destination is ONE node**, and everything under it is
  excluded. There was not a single `Semantics` in the module: an
  `InkWell` around an icon and a `Text` announces the text and nothing
  else — no "selected", no "2 of 5", no "disabled" — on the one surface
  that decides where the whole app goes.
- **The badge goes into the LABEL** ("Search, 9"). An unread count is
  information, and excluding the subtree would have thrown it away with
  the decoration.
- **The position is the HINT** (`NavStrings.tabPosition`). A
  destination is one of a set, and which one it is cannot be worked out
  from its own name.
- A disabled item reports `enabled: false` and takes no tap.

## The ink

- **The ripple is MEASURED against the indicator, not guessed at.** An
  `InkWell` fills its box, so the splash was a slab running corner to
  corner of the destination. `_IndicatorInkWell` overrides
  `getRectCallback` — the same trick Material's own `NavigationBar`
  uses, so the whole cell still takes the tap — and reads the
  indicator's real rect off a `GlobalKey`. A fraction of the cell was
  the first attempt and still came out wider than the selected state,
  because the pill is CONTENT-width: icon, label and padding.
- **The `Material` belongs INSIDE the bar.** An ink feature paints on
  its Material's own canvas, which sits BENEATH that Material's child —
  so a transparent `Material` wrapped around the whole bar drew every
  splash, hover and focus ring underneath the bar's opaque background.
  Tapping looked completely dead, and keyboard focus was invisible for
  the same reason.

## Hide on scroll

- **Direction-aware, and 1:1 with the finger.** It used to hide on ANY
  scroll past a threshold and come back only after the page had been
  still for six hundred milliseconds — so reading back UP the page left
  the bar away, and the hide ran on a timer rather than with the
  gesture. `_applyDelta` scrubs the controller straight off the scroll
  delta; only the settle has a duration.
- **No `scrollController` needed inside a `Scaffold`.** The ambient
  `ScrollNotificationObserver` is the same channel Material's `AppBar`
  uses for its scrolled-under elevation, so the body's scrolling reaches
  the bar with nothing passed through the page. Pass a controller only
  outside a Scaffold.
- **It TRANSLATES; the laid-out height never changes.** Collapsing it
  hands `Scaffold` a new height every frame, so the body's viewport
  grows under a list that is already scrolled. Guard: "the BODY is not
  relaid out as it retreats" — 536 against 600 with the collapse.
- **A page that cannot AFFORD to lose the bar keeps it.** Hiding frees
  the bar's own height, so on a page with barely more content than
  fits, hiding makes the page unscrollable — the bar goes, the scroll
  ends, and no gesture remains that could bring it back. The reader is
  stranded looking at a page with no chrome. `hideMinExtentFactor`
  requires the content to be able to lose the bar's height and still
  scroll. Guard: "a page with barely enough content KEEPS its bar".
- Depth 0 only, and pinned open while `pixels <= 0`.
- **No `ClipRect` around the translation.** It cropped the bar to its
  own box, which is exactly where the shadow is not — so the elevation
  was shaved off the top edge for as long as hide-on-scroll was on. A
  bar translated past the bottom of the screen needs no clip; the
  screen is the clip.

## The notch

- **It MORPHS into the edge.** The hand-rolled cubic-into-arc met the
  top edge at an angle, so the cut read as stamped out of the bar.
  `CircularNotchedRectangle` is the geometry Material's own
  `BottomAppBar` uses, and its s-curves leave the edge tangentially —
  the bar swells up to the button and back down.
- **It takes the BUTTON's shape, and Material 3's default is a ROUNDED
  SQUARE.** A circular fallback put a round hole under a squircle
  button on every M3 app that did not say otherwise. The order is:
  `style.notchShape`, then the `FloatingActionButton`'s own `shape`,
  then `FloatingActionButtonThemeData.shape`, then `notchFabRadius`.
  **The theme step is the one that matters in practice** — the common
  wiring gives the FAB to the `Scaffold` and hands this module a
  placeholder, so an inline `shape:` on one button is invisible here.
  Change `floatingActionButtonTheme.shape` and the notch follows.
- **The cutout is CONCENTRIC with the button, not congruent.** Two
  shapes sharing a centre do not share a radius: the outer one's is the
  inner one's PLUS the distance between them, so the cutout's corner is
  `notchFabRadius + notchMargin`. Drawing it at the button's own radius
  is the mistake — it reads tight at the corners against the button
  sitting in it.
- **The LIPS are controllable.** `notchLipRadius` fillets the two
  places the cutout meets the top edge; zero gives the sharp corner a
  plain subtraction leaves. The fillet is a quadratic whose control
  point IS that corner, so the edge leaves tangentially.
- **It is built as a PATH, not subtracted as a shape.**
  `AutomaticNotchedShape` gives neither of the two above — the corner
  and the lips are the whole point of `FabNotchedShape`.
- **Rounded corners come from INTERSECTING** the notched rectangle with
  the rounded box. Two shapes, each doing the one thing it is good at.
- **The SHADOW is painted behind the clip, not inside it.** A
  `ClipPath` cuts everything its child paints and a shadow is painted
  outside the shape by definition, so notching the bar also erased its
  elevation and the top edge went flat. `_NotchedShadowPainter` draws
  it along the same path, underneath.
- **The outline TRACES the cutout.** A `BoxDecoration` border is a
  rounded rectangle and the clip then removes the stretch crossing the
  notch, so the line stopped dead at one lip of the hole and picked up
  at the other. `_NotchedOutlinePainter` strokes the clip's own path —
  which is also the only way a gradient border follows the curve. The
  stroke is doubled because the clip cuts along its centre.

## The entrance

- **Off by default.** A bar that animates in on every route change is a
  bar that is late on every route change. `entrance` is for the one
  screen where the arrival is the point.
- Five kinds: `slide`, `fade`, `scale`, `slideFade`, `staggered`.
- **A stagger is per ITEM**, not the bar doing something in stages, so
  it wraps each destination rather than the whole surface.
- **The INDEX is already the reading position.** `Row` lays its
  children out right-to-left under RTL, so destination zero is the
  RIGHTMOST — which is where an Arabic reader starts. Mirroring the
  interval on top of that ran the stagger from the left, the wrong end
  of the bar in both directions at once. `staggerStart` in
  `core/animations/entrance.dart` is where that reasoning lives, so it
  cannot be re-derived wrongly in the next module.
- **It FOLLOWS the route's animation, rather than reacting to its
  status.** A predictive-back drag drives that animation from the
  finger, so a listener that only heard "reverse" and then ran its own
  controller on its own clock played a fixed departure over a gesture
  the reader was still holding — and had nothing to say when they let
  go and came back. Tracking the VALUE scrubs with the drag, reverses
  as it goes and returns if it is cancelled, for free.
- **Following is armed by the ROUTE, not by the entrance.** The
  entrance is shorter than the page transition, so arming when it
  finished snapped the bar back to wherever the route had got to and
  then jumped it to rest — two jumps, which is the flash at the end of
  the slide. It arms once the route reports `completed`.
- **`EntranceKind` is SHARED with the app bar** (`GlobalAppBar.entrance`),
  so the two ends of a screen can be told to arrive the same way.
- **The last destination starts at `staggerSpread`**, not at the end.
  Past halfway and the tail of a five-item bar arrives after the page
  has already settled.
- **Reduce motion sets the value rather than zeroing the duration.**
  A zero-length entrance still rebuilds every frame on the way to
  nowhere.

## Sizing

- **The device's corner is for a FLOATING bar only.** A floating bar
  sits inside the screen's rounded corners and has to agree with them.
  A flush bar is against the bottom edge, where the screen's corners
  are the screen's — rounding its TOP corners to a radius measured off
  the hardware's BOTTOM ones is copying a number from the wrong two
  corners, and it rounded every flush bar in the app. Flush is square
  now unless a caller says otherwise.
- **The pill's corner follows the bar's**, so the two read as
  concentric rather than as unrelated shapes.
- **The app theme sets no radius at all**: the bag cannot tell a
  theme's value from a caller's, so a token radius there won and the
  device radius never got a look in.
- **`DeviceRadius.debugSetCorners` is the test seam.** The real value
  comes from a platform channel, so under `flutter_test` every corner
  is zero and `hasRoundedCorners` is false — which quietly makes any
  test of "what happens on a rounded device" pass whatever the code
  does. The first version of this guard did exactly that.

- **The indicator has a FLOOR, not a fixed width.** Sized purely to its
  content a pill is as wide as its own label — "Search" came out ten
  points wider than "Home" — and the press highlight matches the pill
  exactly, so the unevenness showed up twice. `indicatorWidth` evens out
  every label that fits and lets the rest grow. A TIGHT width evens all
  of them and clips the ones that do not fit, which is worse than the
  problem.
- **No `LayoutBuilder` around the pill.** A builder there re-runs
  whenever the marquee measures its child, and the marquee measures
  whenever it is rebuilt: the two chase each other and the frame never
  completes. It is a hang, not a slow test. `ConstrainedBox` is clamped
  against the parent's constraints for free.
- **`bottomInsetFactor` scales the CONTENT, never the surface.** The
  bar's box is always as tall as the full inset so its colour reaches
  the screen edge; the row sits its scaled padding up from the bottom
  of it. Scaling the surface left the last points of the strip painted
  by whatever is behind the bar — a pale band under a dark bar.
  Bottom-aligned for the same reason: top-aligned, the gap the factor
  is meant to shrink is below the row either way and the knob does
  nothing.
- **`bottomInsetFactor` scales the home-indicator inset.** The 34 points
  are the SYSTEM's and honouring all of them is correct — and also a lot
  of empty bar under the labels, because the indicator is a thin line
  rather than 34 points of hardware. Clamped to 0..1.
- **`_rs` is re-resolved in `didUpdateWidget` too.** Materialized only
  in `didChangeDependencies`, a caller who changed `style` at runtime
  kept the old bag until something unrelated invalidated an inherited
  widget — which looks exactly like the bag being ignored. The test that
  caught it was measuring the same stale value three times and calling
  them equal.

## Icon reactions

- **A glyph reacts to press, focus and hover** (`iconReaction`, `grow`
  by default). Distinct from the tap BOUNCE, which fires once on
  selection: this tracks the pointer's state for as long as it is
  there, which is what makes a destination feel like a control rather
  than a picture of one.
- **The reaction wraps the GLYPH, not the tap target.** Outside, it
  sits between the ink's reference box and the indicator — and
  `getRectCallback` measures THROUGH it, so pressing a destination grew
  the glyph and the highlight by the same amount and the highlight
  stopped matching the pill it lands in.
- **The ink drives it.** The ink owns the focus node, so it is the only
  thing that knows about keyboard focus; a `Focus` of the reaction's
  own sits BELOW that node and never hears it, because focus travels
  down from the node that has it. That is why focus did nothing.
- **A LABEL that changes size on selection re-measures**, which the
  marquee then re-measures, so the text visibly re-clips while the pill
  is still easing. Selected and unselected share a font size; weight
  and colour carry the selection, which is what Material's own bar
  does.
- **The TWEEN carries the reaction, not the transform.** Applying it
  straight from the state snaps between values, which is a flicker
  rather than feedback.
- **A disabled destination does not react.** Feedback from a control
  that will not act is a lie.
- Press beats hover beats focus, because that is the order they arrive
  in and the strongest signal should win.

## Animated assets

- **`lottieAsset` is driven by the same trigger** as a Material morph.
  It used to render only while its destination was SELECTED and play
  once, so it could not answer a press or a hover, and an unselected
  destination showed nothing at all.
- **The file owns its duration**; the controller only plays it, so the
  duration is set in `onLoaded` rather than guessed at.
- **`lottieRepeat` is off.** A loop under a finger is a spinner, not
  feedback — the point of a morph is that it has somewhere to arrive.
- **Reduce motion holds the END frame** rather than playing to it. The
  asset is the content, and a still frame of it still says which state
  the destination is in.

## Animated icons

- **`animatedIcon` is a glyph that MORPHS**, where `iconReaction` only
  nudges a static one about. Two different things, and they compose: a
  morphing icon can still grow under a press.
- **`animatedIconTrigger` says what moves it.** A morph has a state at
  each end, so its meaning is entirely in what drives it: `selection`
  makes the morph the selected state, `press` is a momentary flourish,
  `hover` is a pointer thing and does nothing on a touch screen without
  a keyboard.
- **Selection starts where it BELONGS.** The controller is built at 1
  for an already-selected destination; starting every one at zero
  morphs the whole bar on mount for no reason.

## The selection EASES

- **The glyph's colour LERPS.** It was handed straight to the `Icon`,
  so the selection landed instantly while the pill, the label weight
  and the indicator were all still moving — one part of the item
  arriving before the rest of it.
- **The glyph CROSS-FADES between its two shapes**, keyed on the icon
  so the switcher knows they differ. A plain swap is a cut in the
  middle of a transition everything else is easing.
- **The gradient covers the whole destination**, label included. On the
  glyph alone it left the label in a flat colour under a gradient icon,
  which reads as two states of one destination.

## Nothing overflows the bar

- **Only the HEIGHT is fitted.** `FittedBox(scaleDown)` was the first
  answer and it was the wrong one: it unbounds BOTH axes, so a long
  label never reaches the width that would make it ellipsise or
  marquee. It lays out at full natural length, makes the destination
  enormously wide, and the fit then shrinks the whole thing — glyph
  included — to something unreadable. `_FitHeight` hands the incoming
  WIDTH straight down, so the label solves its own problem the way it
  already knows how, and scales only when the content is too TALL,
  which is the axis with no other answer.
- **NOT on a prominent one**: an unbounding fit and the lift's
  `OverflowBox` cannot coexist. The
  circle is clamped to what the bar can hold instead.
- **Unbounded constraints are the price of the fit**, and nothing under
  it may want an infinite size. The empty label slot held
  `width: double.infinity` to keep the row open, which is a stretch
  under normal constraints and a hard layout error under these — a
  cascade of five "given an infinite size" throws on any bar without
  labels. It shrinks instead; the indicator's own minimum is what holds
  the row open now. Guard: "a destination with NO label survives being
  fitted".

## Prominent destinations

- **A lifted circle must not claim the height it PAINTS.**
  `Transform.translate` moves the paint and leaves the layout where it
  was, so 48 of circle plus a label in a 64dp bar overflowed by exactly
  the four points the lift was meant to save. An `OverflowBox` inside a
  shorter `SizedBox` is what makes the lift free.
- **The BAR grows to cover the lift.** Flutter hit-tests a render box
  against its size and never outside it, so a circle painted above the
  bar was a picture of a button: the tap went through to the page
  underneath, which on a `Scaffold` means the content silently took it.
  A bar with a prominent destination is `prominentOffset` taller, and
  both its layers start that far down — the surface and the row sit
  exactly where they did, and the strip the circle rises into is inside
  the bar's own box. Guard: "the lifted part of the circle is the
  destination".
- **`_TapAbove` is what makes the strip count**, in two places: once
  around the row, because the row's box still begins below the strip,
  and once around the prominent item, because its own box does too. It
  CLAMPS a position in the strip onto the top edge and offers it as an
  ordinary hit, so nothing that was not already a target becomes one.
- **The strip belongs to the BAR, not the page.** It is bar height now,
  so a tap in it goes to the destination under it rather than through.
  That widens every destination's target upward by twelve points, which
  is the right direction for a 48dp guideline.

## The rail is the SCAFFOLD's decision

- **`enableSideRail` is gone, and could never have worked.** It asked
  the bar to swap itself for a rail past a width. A widget handed to
  `Scaffold.bottomNavigationBar` cannot move itself to
  `body: Row([rail, body])` — measured, it produced a rail filling the
  whole 1200×800 screen with the page collapsed to `LTRB(571, 0, 628,
  0)` behind it. Material's own `NavigationRail` did exactly the same
  thing there; the look was the second problem, not the first.
- **`GlobalScaffold` is where the choice belongs.** It switches on
  `context.windowSize` and rebuilds the STRUCTURE, which is the only
  place the decision can be made.
- **`railStyleFrom` / `railItemFrom` keep the two looking alike**
  (`bottom_nav_as_rail.dart`). The bar is themeable through
  `GlobalBottomNavTheme` and the rail's bag is not, so before this,
  crossing the boundary changed the app's LOOK rather than its layout —
  the bar followed a rebrand and the rail stayed on Material's numbers.
  Guard: "and it wears the BAR's theme".
- **`topBar` maps to `trailingBar`, not to `leadingBar`.** The bar's top
  edge is the one FACING THE CONTENT, and on a rail that is the trailing
  edge. Mapping by name, since "top" and "leading" both mean first, puts
  the line on the wrong side of every destination.

## Labels

- **A label too long for its destination SCROLLS** rather than trailing
  off. A destination is a fifth of the screen wide, so it not fitting
  is the ordinary case, and an ellipsis on two words leaves something
  that names nothing. `GlobalMarquee` only moves what actually
  overflows. `marqueeLabels: false` opts out.

## Reduce motion

- **Chrome that moves is the first thing the setting means to quiet.**
  The indicator arrives instead of travelling, the tap does not bounce,
  and hide-on-scroll cuts instead of sliding. The selection still
  changes — only the motion goes.
- Every duration in the tree runs through `_motion`, which is
  `Duration.zero` under the setting. Guard: "the indicator ARRIVES
  instead of travelling".
- `respectReducedMotion: false` is the way out, for a bar that is
  itself the content rather than chrome.

## Showcase + tests

`/bottom-nav-showcase`. Two test files, for two different jobs:

- `test/bottom_nav/global_bottom_nav_test.dart` — the CONTRACT: bag
  merge, resolution order, the token-driven app theme, the palette
  colours, the semantics of a destination, reduce motion, lerp, the
  corner, the fit and the prominent hit test.
- `test/bottom_nav/bottom_nav_lottie_test.dart` — what the DECODER
  actually does, against the animation module's hand-built 2-second
  fixture. `Lottie.asset` resolves through `DefaultAssetBundle`, so a
  test bundle serving the file under a made-up key needs no entry in
  `pubspec.yaml`. The contract tests asserted a `LottieBuilder` was in
  the tree, which is equally true of a path that never loads — the
  duration reaching the controller, the trigger driving it and reduce
  motion holding the end frame were all eye-only before this.

## Known gaps

- **The notch outline is stroked, not inset.** It traces the right path,
  but a very wide `borderWidth` will read heavier along the notch than a
  `BoxDecoration` border would elsewhere.

- **The seven indicator styles are eye-only.** Nothing asserts that
  `sliding` slides or that `notch` cuts a notch; the tests cover the
  contract, the semantics and the geometry that has caused bugs, not
  the painting. A golden-file suite is the answer and there is none in
  this repo yet.
- **The rail drops what it has no counterpart for**: `animatedIcon`,
  `animatedIconTrigger`, `lottieRepeat`, the icon reaction, the marquee
  and the entrance. `railItemFrom` carries everything the rail module
  does have; the rest would need the same work doing there.
- **`NavigationRailStyle` is pre-gold-standard** — non-nullable fields,
  no `resolve`, no theme extension of its own. `railStyleFrom` is what
  stands in for one, and it only helps a caller that goes through it.
  A rail built with a bare `NavigationRailStyle()` is still on
  Material's numbers.
- **`_resolveIndex` swallows every GoRouter error.** Outside a router
  it silently falls back to the internal index, which is right, but a
  genuine router failure looks the same.
