# CLAUDE.md — shared/module/scrollable

The scroll shell, the edge that tells you there is more, and the
chrome that floats over it.

```
scrollable/
  scrollable_models.dart      — BoundaryBehavior · ScrollableMode · EdgeFadeMode
                                · ScrollProgressPlacement · resolvePhysics
  scrollable_style.dart       — ScrollableDefaults · ScrollableStyle · EdgeFadeStyle
                                (+ the Resolved pair for each)
  scroll_in_style.dart        — ScrollInDefaults · ScrollInStyle · ResolvedScrollInStyle
                                · ScrollInMode · ScrollInStaggerMode
  theme/scrollable_theme.dart — GlobalScrollableTheme + both resolves
  global_scrollable.dart      — GlobalScrollable, the shell + the wheel + the handoff
  global_edge_fade.dart       — GlobalEdgeFade, the four modes and their painters
  global_scroll_overlays.dart — GlobalScrollOverlays: progress, scroll-to-top, "n new"
  global_scroll_in.dart       — DragAutoScroller · GlobalScrollInAnimator
                                · ScrollInStaggerCursor
```

## The bags

- **`ScrollableStyle` is all-nullable**, floor in `ScrollableDefaults`,
  app-wide layer in `MyGlobalScrollableTheme.build(tokens:)`
  (`core/theme/widget_themes/global_scrollable_theme.dart`, wired in
  `theme.dart`). Order is `caller > GlobalScrollableTheme.style >
  ScrollableStyle.defaults`. Presets: `page`, `article`, `bare`.
- **`EdgeFadeStyle` is a bag INSIDE that bag**, and it merges field by
  field rather than being replaced whole — a caller asking only for a
  bigger band must not lose the theme's mode.
- **`EdgeFadeStyle.off` says `mode: none` explicitly.** An empty bag
  would fall through to the theme, so "no fade here" has to be a
  stated answer rather than an absent one.
- **The wheel knobs are STYLE.** `smoothWheelScroll`, `wheelMultiplier`
  and `wheelSmoothness` were three flat widget parameters, so how
  scrolling FEELS was a per-call decision that no app could make once.
- **It resolves in `didChangeDependencies`, never `initState`** — the
  palette and reduce-motion are inherited reads.

## `EdgeFadeStyle` moved here from `list/`

It lived in `list/list_models.dart`. The text field, the slider, the
breadcrumbs and the dropdown all imported the LIST module to say how
their scroll edge should look, and `scrollable/` imported `list/` to
get a type it owns the implementation of. `list_models.dart` re-exports
both names, so a caller that says `list_models.dart` still compiles.

## The list had a SECOND copy of all of this

`global_list.dart` carried private `_EdgeFadeOverlay`, `_ShaderFade`,
`_OverlayFade`, `_BlurFade`, `_ListOverlays`, `_ProgressStrip`,
`_ScrollToTopFab` and `_NewItemFab` — six hundred lines duplicating
this folder, while `grid/` next door used the shared ones.

The cost was not the lines. The same `EdgeFadeStyle` drew a different
edge depending on which widget you handed it to, and every fix below
had to be made twice or it was not made at all.
`test/scrollable/scrollable_adoption_test.dart` fails on a new copy.

## Arabic

**A horizontal scrollable STARTS on the right.** `pixels == 0` is the
right-hand edge, because `Scrollable` reverses its axis direction with
the reading direction. All three pieces of chrome were pinned to the
left whatever the language:

- **The fade band** put "there is more this way" on the side there was
  nothing more on. `GlobalEdgeFade` maps the scroll's start and end
  onto the box's leading and trailing edges once, and hands the
  painters geometry.
- **The progress strip** filled left-to-right, so an Arabic reader
  watched it empty as they read. It is `AlignmentDirectional.centerStart`
  now.
- **The scroll-to-top button** sat in the right corner. It is
  `PositionedDirectional(end:)`, so it lands under the thumb.

**A VERTICAL fade is the same in both directions** — top is top in
every language, and nothing about it mirrors.

## Reduced motion

Every duration resolves to ZERO, not to something short: the overlays
appear rather than sliding, the ride to the top is a jump, and the fade
band snaps. **The wheel smoothing turns OFF entirely** — the smoothing
IS the motion, so shortening it would be missing the point; the wheel
goes back to the framework's discrete step.
`respectReducedMotion: false` is for a scrollable whose motion is the
content.

## The progress strip

Always a horizontal band across the box. It used to become a
three-pixel VERTICAL sliver down the left edge for a horizontal
scrollable, which nothing else in the app does. `progressPlacement`
puts it at the top (the default, like every reading-progress bar) or
the bottom.

It also **paints its fill at full height explicitly**: a `DecoratedBox`
with no child of its own measures ZERO against a loose constraint, and
the fill paints nothing at all — the same bug the story bar had, and
one a widget-tree test walks straight past.

## Fixed on the way

- **Scrolling no longer rebuilds the content.** The overlays called
  `setState` on every pixel of every scroll, and the child sits inside
  their `Stack` — so the entire list underneath was rebuilt once a
  frame for the sake of a three-pixel strip. The position lives in a
  `ValueNotifier` that only the two overlays listen to.
- **`Ticker.dispose` threw on a page torn down mid-glide.** The wheel
  ticker was disposed while still active, which the framework refuses;
  it takes a fast scroll and an immediate back gesture to hit.
- **The wheel ticker ignored `TickerMode`.** It was constructed as a
  raw `Ticker` rather than through `createTicker`, so a glide kept
  running under a pushed route.
- **The scroll-to-top button had no name.** A bare `InkWell` in a
  `Material` — the one control that floats over every long page in the
  app said nothing to a screen reader and offered no tooltip to a
  pointer. Hidden chrome is now out of the semantics tree and refuses
  taps, rather than being a transparent target at the corner.
- **Colours come from the palette.** The scrim fade took
  Material's surface and the inner shadow a raw `Colors.black @ 0.18`;
  the buttons and the progress strip took `colorScheme.primary`. A
  rebrand moved the app and left every scroll edge behind.
- **The "n new" pill was English.** It and the button's name go
  through `ScrollStrings` now.
- **The blur band was a stack of BARS.** Its layers TILED — layer `i`
  covered its own four-pixel slice and nothing else — and a slice that
  thin blurred with a sigma of eight pulls in the clamped edge pixel
  over and over, so each one smeared into a horizontal stripe. The
  layers overlap now (see below).

## How the blur band is built

A `BackdropFilter` reads everything painted before it in the same
layer, so **a sibling drawn earlier is part of its backdrop** — and
overlapping filters compose. Blurs compose in QUADRATURE: two passes of
σ are one pass of σ√2.

- Every layer starts AT the edge and reaches progressively less far in.
  Layer sigmas are picked so the cumulative sigma follows `σ·t²` across
  the band: essentially nothing where the band meets the content (no
  step at the inner boundary), the full amount at the edge.
- **No layer is blurred by more than half its own height.** Past that,
  `TileMode.clamp` repeats the edge pixel instead of mixing real
  content — which is the streak. The cap costs a little strength at the
  very edge and is worth it.
- `ScrollableDefaults.blurStrips` is the layer count. Each one is a
  `saveLayer`, so it is a cost rather than a quality dial.
- Guard: `test/scrollable/edge_fade_blur_test.dart` — the layers share
  an edge, no sigma exceeds half its layer, and the deepest layer's
  sigma is under 1.

## What it costs per frame

- **`shader` is one saveLayer the size of the viewport, per paint** —
  and it is SKIPPED outright while neither band is showing. It used to
  build regardless, painting an all-white gradient that changes not one
  pixel: content that fits its viewport, or a `smart` fade resting at
  the only end there is, paid for it every frame. `ShowcasePage` puts a
  shader fade on every page in the app, so this was the most-paid-for
  nothing in the codebase.
- **Only the shader mode short-circuits.** The other three animate
  their bands out over `style.duration`, and a widget that unmounts the
  moment its band turns off has no frames left to do that in. Their
  resting cost is a `Stack` and two zero-opacity boxes, which is not a
  saveLayer — `Opacity` at zero skips painting its child outright, and
  `_BlurFade` builds no `BackdropFilter` while its controllers sit at
  zero.
- **`blur` is the expensive one**: `ScrollableDefaults.blurStrips`
  layers per band, each a saveLayer AND a backdrop read, and both bands
  can be up at once. Right on a bounded panel, wrong on a page shell.
  Lower the layer count before lowering the sigma — fewer layers cost
  less and only soften the ramp.
- **The chrome sits behind a `RepaintBoundary`.** The progress strip is
  a new width sixty times a second; without the boundary it shares a
  layer with the content, so the whole list is re-rasterised for the
  sake of three pixels. (The per-pixel *rebuild* was a separate bug —
  see above. This is the paint.)
- **The scroll listeners are cheap.** The fade's `setState`s only when
  a boundary is crossed, not per pixel; the overlays write a
  `ValueNotifier` that two small builders read.
- **The wheel glide costs one `jumpTo` per frame**, which is what a
  finger drag costs, and the ticker stops itself on arrival.
- Guard: `test/scrollable/scrollable_perf_test.dart`.

## The wheel

`smoothWheelScroll` intercepts `PointerScrollEvent` and lerps the
position toward a moving target, instead of taking the framework's
discrete jump per notch.

- It wins by **hit-test order**: the `Listener` lives INSIDE the
  scrollable's content, so it registers with the global
  `PointerSignalResolver` first, and only the first registration fires.
- **Touch drags are untouched** — those go through `onPointerMove`, a
  different path.
- **`.custom` skips it.** Slivers do not host arbitrary box widgets, so
  there is nowhere inside the viewport to put the deeper `Listener`;
  sliver scrollables keep the framework's wheel handling.

## Nested handoff

`passThroughAtEdge: true` on an outer `GlobalScrollable` catches
`OverscrollNotification` from descendants and applies the delta to its
own position, so a bounded inner list hands scroll off to the page
without the reader lifting a finger.

- The outer advertises `GlobalScrollableScope`, and descendants read it
  to switch to **clamping** physics — bouncing would absorb the drag
  into a rubber band and no notification would ever arrive.
- A **drag** overscroll carries `dragDetails` and is applied directly;
  a **fling** has none and a velocity, so the remaining velocity goes
  to `goBallistic` and the page keeps coasting.
- **Same axis only.** A horizontal carousel inside a vertical page must
  not bleed into the page's scroll.

## Scroll-in: how a row arrives

`GlobalScrollInAnimator` plays a tile's entrance when it first crosses
a fraction of visibility. `GlobalList` and `GlobalGrid` drive it.

- **It fires on VISIBILITY, not on build, and that is the whole
  point.** An `initState`-driven entrance plays offscreen:
  virtualisation mounts a row a few hundred pixels before it enters the
  viewport, so by the time the reader scrolls to it, it has already
  finished arriving.
- **Its bag is `ScrollInStyle`**, all-nullable, floor in
  `ScrollInDefaults`, app-wide layer on the same
  `GlobalScrollableTheme` (`scrollInStyle`). Presets: `subtle`, `wave`.
  The list and the grid each carried their own copy of these numbers,
  so a house that wanted a calmer entrance had to say so at every call
  site.
- **`animation` is the SWITCH**, and the theme deliberately leaves it
  unset: a house sets the rhythm, never turns an entrance on for a list
  that never asked for one.
- **Reduced motion PLACES the row** rather than shortening its
  entrance, and drops the cascade with it — a stagger made instant is a
  delay before something appears rather than a cascade. It covers
  `continuous` mode too, where binding the transition to the scroll
  would otherwise animate every row on every frame of every scroll.
  Nothing here read the setting at all before: an entrance fires once
  per row and a list has hundreds, which makes it the most repeated
  motion in the app.
- **With nothing to play, no `VisibilityDetector` goes in the tree.**
  Each one is a registration the detector walks on every frame it
  schedules.
- **The queued cascade slot is a cancellable `Timer`.** It was a bare
  `Future.delayed`, so a list torn down mid-cascade left one pending
  callback per queued row — and every widget test around one failed on
  "a Timer is still pending even after the widget tree was disposed".
- **The detector's interval is LOWERED, never set.** It is a global
  singleton, and the list wrote 50ms into it from `initState`: that
  stomped whatever the app or a test chose and never put it back, so a
  test parking it at zero to keep its teardown clean had it reset by
  the next list to mount. `ScrollInDefaults.quickenVisibilityReports`
  only ever moves it down.
- **`ScrollInStaggerCursor` takes its clock.** It read a bare
  `DateTime.now()`, which made every rule in it — the idle reset, the
  queue cap, the row anchor — a decision about elapsed milliseconds
  that no test could make happen. None of the algorithm had a test
  before; all of it does now.
- **`DragAutoScroller.speedAt` is pure**, so the edge ramp can be
  checked without a drag, a ticker or a viewport.
- **`ListItemAnimation` lives in `scrollable_models.dart`** — the
  animator used to import the LIST module to name its own parameter.
  `list_models.dart` re-exports it.
- **`slideFromStart` / `slideFromEnd` MIRROR; `slideFromLeft` /
  `slideFromRight` do not.** The same split the navigation transitions
  make. A row that arrives from the side its own control is on should
  not swap when the app is translated; content that arrives "from the
  beginning" is at a different edge in a different language, and there
  was no way to say so. `ListItemAnimationDirection.resolveDirection`
  maps the pair onto a physical side once, at build time, and every
  switch downstream sees only physical members. `.flipped` covers the
  pair too, so a direction-aware list scrolling back in Arabic gets the
  mirror of the mirror.

## `cacheExtent` is `.custom` only

A `SingleChildScrollView` builds its child whole: there is no
virtualisation, no cache, and no parameter to pass it to. Setting
`style.cacheExtent` on the box constructor did nothing, silently —
worse than not offering it, because a caller tuning a janky list would
have moved the number, measured no change, and concluded the number
does not matter. The box constructor asserts now, and only on a value
the CALLER set: a theme may set it app-wide for the sliver scrollables
that can use it without every box one in the app asserting.

## The sweep

**Everything that scrolls a PAGE or a PANEL goes through the shell** —
and the interesting half of that rule is what does not.

Eleven bodies were converted: the three system pages, the update gate,
both legal screens, the FAQ page and its detail page, the feedback
form, the wizard, and the settings page's two-column body. Every one
had been a bare `SingleChildScrollView` or `ListView` with its own
padding and the platform's own physics.

What stays raw, with a reason each in
`test/scrollable/scrollable_adoption_sweep_test.dart`:

- **Virtualised item lists** — a `ListView.builder` over a hundred rows
  is `GlobalList`'s job, not the shell's. The shell wraps ONE child.
  That is a separate adoption question with a separate answer.
- **Chrome** — a chip strip, a rail of destinations, a breadcrumb
  trail. An edge fade and a scroll-to-top button belong to a page;
  these are furniture ON one. Several already wrap their own
  `GlobalEdgeFade`, which is the right amount of the shell for them.
- **Overlay bodies** — a dialog, a sheet, an anchored panel. They
  measure themselves against their own constraints and several drive a
  drag of their own; the shell's chrome would be drawn over the top of
  theirs.
- **Content-package internals** — a code fence or a formula scrolling
  sideways inside one rendered block, not a scroll over the document.
- **`system_pages/error_app.dart` and `core/error/debug_error_widget`**
  — they run when `bootstrap()` itself threw, or where the tree is
  already broken, so they must not touch the palette. Every wrapper in
  the app resolves colours through it.

The guard also keeps the allow-list honest: an entry whose file is
gone, or whose site has since been converted, fails — a licence nobody
needs is one the next raw scrollable in that file slips through under.

## Who uses it

`ShowcasePage` wraps every showcase body in one. `GlobalList` and
`GlobalGrid` use `GlobalEdgeFade` + `GlobalScrollOverlays` directly;
the text field, the dropdown, the breadcrumbs and the slider take an
`EdgeFadeStyle`.

- Showcase: `/scrollable-showcase`, one section per decision the shell
  makes — the edge (one panel, five modes, live size / sigma / smart /
  axis / direction), the chrome, the presets, the physics, the wheel
  (A/B plus live tuning), slivers, the nested handoff and position
  restoration. It used to be a flat run of one-off demos with its own
  private heading and caption widgets; it is `ShowcaseSection` +
  `ShowcaseDemoCard` + `ShowcaseVariantPicker` + the settings rows now,
  like every other page.
- Guards: `test/scrollable/scrollable_style_test.dart` (the three
  layers, the field-by-field fade merge, the palette, reduced motion,
  the presets, the snap), `test/scrollable/global_scrollable_test.dart`
  (physics resolution, the chrome, the strip, the content NOT
  rebuilding, teardown mid-glide),
  `test/scrollable/scrollable_rtl_test.dart` (all three pieces of
  chrome in Arabic), `test/scrollable/scrollable_a11y_test.dart` (what
  a reader hears), `test/scrollable/scrollable_adoption_test.dart`
  (no second copy, and the type lives here).
