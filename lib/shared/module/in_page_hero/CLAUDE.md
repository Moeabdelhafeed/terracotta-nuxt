# CLAUDE.md — shared/module/in_page_hero

`InPageHero`: a box that flies between two places on the SAME page.

```
in_page_hero/
  in_page_hero_style.dart   — InPageHeroDefaults · InPageHeroStyle · ResolvedInPageHeroStyle
  theme/in_page_hero_theme.dart — GlobalInPageHeroTheme + InPageHeroStyle.resolve(context)
  global_in_page_hero.dart  — the controller, the endpoint widget, the flying overlay
```

## Not a route Hero

Flutter's `Hero` flies between ROUTES: two trees, one pushed over the
other, and the framework owns the flight. This flies inside one tree —
both endpoints exist the whole time, and the inactive one collapses its
space. Nothing is pushed, so nothing can be popped, and the endpoints
can be any distance apart on the same page.

- **Endpoints are INDEXED**, so a tag can have more than two: three
  stops, four, a carousel. `flyTo(i)` / `flyToNext()` / `flyToPrevious()`.
- **`maintainSpace` holds the inactive endpoint's box** — sized but
  unpainted — for a grid or a row that must not close up. It is
  answered at CONSTRUCTION as well as on every change: the first build
  used to collapse the inactive endpoint whatever the flag said, so a
  grid closed up until its first flight and then stayed open.
- **Both endpoints are always LAID OUT.** The inactive one is measured
  but not painted (`Visibility(maintainSize: true)`), because a flight
  needs a rect at both ends and a widget that is not in the tree has
  none. What collapses is the SPACE, via a hand-driven `Align` factor —
  `AnimatedSize` mutates layout during the flight and throws.
- **The SOURCE is measured first, before anything moves.** Expanding
  the target takes space, which reflows whatever the endpoints share a
  row or column with — and the source moves with it. Measuring after
  that started the flight from a place the box had never been: it
  jumped sideways and only then flew, which reads as the thing going
  backwards before it sets off.
- **The overlay goes up in the SAME frame the source stops painting**,
  holding still at the rect just measured until the target has been
  measured a frame later. It used to go up a frame after: in between,
  the source was still painted while the target's expansion had already
  reflowed the row, so the box jumped sideways, vanished, and reappeared
  where it started before flying. That was the stutter and the flash —
  one frame, both symptoms.
- **Then the target expands INSTANTLY**, in that same frame, so its rect
  is stable while the overlay travels. Nothing paints there yet, and the
  overlay is already covering the place the reader is looking at.
- **A flight is released by a `ValueNotifier<Rect?>`**, not by being
  built with its destination. Before it is set the overlay's "target" is
  the source's own rect, which is what keeps it still for the frame it
  is up early.
- **The overlay tracks the target's LIVE rect**, not the one measured at
  launch: the source is collapsing underneath, so everything below it
  moves while the flight runs.
- **Every rect is measured in the OVERLAY's space, not the screen's**
  (`_rectIn(key, overlayBox)`). The flying entry is positioned inside
  the overlay, and an overlay is not always at the screen's origin — one
  in a `Scaffold` body starts below the app bar. Measuring globally and
  positioning locally pushed every flight down by exactly that offset,
  which is what the bug looked like: the box left its endpoint and
  appeared an app-bar's height too low.

## The bag

- **`InPageHeroStyle` is all-nullable**, floor in `InPageHeroDefaults`,
  app-wide layer in `MyGlobalInPageHeroTheme.build(tokens:)`
  (`core/theme/widget_themes/global_in_page_hero_theme.dart`, wired in
  `theme.dart`). Presets: `snappy`, `lifted()`.
- **It resolves in `didChangeDependencies`, never `initState`.** The
  theme and the reader's reduce-motion setting are inherited reads, and
  the collapse controller's duration comes from them. The curve is
  applied where the factor is READ for the same reason — a
  `CurvedAnimation` built in `initState` cannot see a theme.
- **Reduced motion resolves to a ZERO duration**, and the flight is then
  skipped whole rather than run for no frames: an overlay that inserts
  and removes itself in one frame still flickers. The endpoints swap and
  the active index moves, so the page still ends up where the tap asked.
- **`crossfadeStart` / `crossfadeSpan` are knobs**, not the constants
  `0.35` and `0.3` buried in a builder. The content swaps in the MIDDLE
  of the flight, where the box is neither endpoint's size and the swap
  is hidden; `ResolvedInPageHeroStyle.crossfadeAt(t)` is the arithmetic,
  and it is tested.
- **A `BoxShape.circle` is lerped as HALF THE BOX BEING DRAWN**, not as
  a fixed huge radius. `BoxDecoration.lerp` cannot cross a `shape` and a
  `borderRadius` — the result would carry both, which asserts — so a
  circle has to become a radius first. Expressed as `9999` the morph
  looked instant: a radius is CLAMPED to half the box when painted, so
  every value above 36 on a 72-point box draws the same circle, and
  lerping 9999 → 0 stayed above the clamp for nine tenths of the flight
  before squaring off in a frame or two. Half the shortest side is the
  radius that MEANS "circle" at the size being drawn, so the lerp is
  linear in what the reader sees — and a circle stays a circle while the
  box resizes.
- **The entry carries a RESOLVED bag**, so the flight uses what the
  SOURCE endpoint resolved — one flight, one set of numbers, rather than
  two endpoints disagreeing about how long it takes.

## Shared parts

By default a flight crossfades the two children WHOLE: the small card's
icon dissolves where it is while the large card's icon appears where it
will be. Close layouts read fine; a piece that has to move a long way
reads as a blink.

`InPageHeroPart(id:)` marks the same piece in both children, and it
becomes one object instead — measured at both ends, drawn ON TOP of the
flying box, travelling and scaling its own way across it.

- **Both ends or nothing.** An id present in only one child has nowhere
  to travel from or to, so it is ignored and stays in the crossfade.
- **A flown part hides inside the children.** `_HeroFlightScope` carries
  the set of ids the overlay is drawing; a copy whose id is in that set
  paints nothing (but keeps its size, so the layout around it does not
  close up). Without that the reader sees the piece twice.
- **The source's parts are measured in the same breath as the source
  itself**, before the target expands — a rect taken after the reflow
  is a rect from a layout nobody saw.
- **And the target part's rect is read EVERY FRAME**, exactly like the
  box's. The source is giving up its space underneath, so everything
  below it moves while the flight runs — including the endpoint the
  part is flying into. Flying to the rect measured at launch landed the
  part one source-height low and snapped it into place on arrival, and
  only in ONE direction: collapsing the source moves what is below it,
  so flying downward drifted and flying back did not.
- **A part is SCALED, not re-laid out.** A 40-point icon growing to 80
  is exactly a scale, and re-laying out mid-flight would reflow the
  thing being animated. That makes it right for an icon, an avatar, a
  thumbnail — and soft for text that changes size a lot, which is
  better left to the crossfade.
- **It crossfades on the same curve as the children underneath**, so a
  part whose two sides differ swaps when the rest of the card does, and
  one whose sides match simply appears to travel. A lock that becomes a
  tick still flies the same path — it moves AND swaps, rather than
  having to choose.
- **Every id present at both ends flies**, each on its own path over the
  same box: an icon and a title can travel independently.
- **`InPageHeroPart.morph` is the way to actually MORPH.** A crossfade
  cannot: two icon glyphs are filled outlines with no correspondence
  between them, which is why Flutter ships fourteen pre-authored pairs
  (`AnimatedIcons.play_pause` and friends) rather than morphing any icon
  into any other. The builder hands the problem to the caller, who knows
  what their two ends have in common — an `AnimatedIcon` driven by `t`,
  or a `TextStyle` whose `fontSize` is lerped.
- **A built part is laid out at its TRUE size every frame**, so it is
  neither scaled nor crossfaded. That is what removes the softness from
  flying text: `fontSize` lerped and re-laid out stays sharp where a
  scaled bitmap does not.
- **`restingT` is what each END looks like** — 0 at one, 1 at the other,
  anything between for a middle stop. Both ends must use `.morph`; one
  facing a plain part has no second value to travel to and falls back to
  the crossfade.
- **A colour change rides along the same way a glyph change does** —
  by crossfading the part's two sides while it travels. Size comes from
  the rects, colour and content from the crossfade, and neither needs
  configuring.

## Nesting a whole hero

An `InPageHero` inside another one's child is SAFE, but it does not get
a flight of its own: it rides along in the crossfade, and its own
controller never moves. `InPageHeroPart` is the way to make a piece
travel — a nested hero is for a piece with its OWN two endpoints.

- **A copy registers nothing.** The overlay draws copies of BOTH
  endpoints' children, and a copy is a whole second element tree: a
  nested hero in one used to register itself under the real endpoint's
  tag and index, overwrite it, and un-register on the way out — leaving
  the inner controller silently inert after one flight of the hero
  around it. `_HeroFlightScope` marks the overlay's subtree; inside it a
  hero registers nothing, listens to nothing, and paints its child
  plainly.
- **The two crossfade layers are KEYED.** Without that the incoming
  child inherits the outgoing one's `State` the moment the outgoing one
  is dropped, which reaches a nested hero as a CHANGED INDEX — the
  second way the registry was being corrupted.

## The controller

- **`flyTo` returns a `Future` that completes on LANDING.** It used to
  return nothing, so a caller who wanted to focus a field or scroll
  after the flight guessed with a `Future.delayed` of the duration they
  hoped was in force. Every early exit completes it too — an unknown
  tag, a missing endpoint, a flight that could not be measured — and so
  does `dispose`, so nothing is left waiting on a controller that no
  longer exists.
- **A flight requested MID-AIR is ignored, not queued.** Interrupting
  one leaves the source collapsed and the target expanded with nothing
  in between.
- **`_abort` notifies.** An endpoint that scrolled out of the tree
  between the request and the frame after it cannot be measured; the
  notification puts every endpoint back where the active index says it
  belongs.

- Showcase: `/in-page-hero-showcase`. Its "What morphs" section
  isolates ONE property per card — colour, corner, shape, border, size,
  gradient, flight shadow — so it is checkable which of them the flight
  actually animates, and "The child" covers the crossfade, a changed
  aspect ratio and `maintainSpace`.
- Guards: `test/in_page_hero/in_page_hero_test.dart` (the three layers,
  reduced motion, the crossfade arithmetic, flying, teardown) and
  `test/in_page_hero/in_page_hero_showcase_test.dart`.
