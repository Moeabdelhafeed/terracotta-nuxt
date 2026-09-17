# CLAUDE.md — shared/module/indicator

Two widgets: a row of pagination dots, and a story bar.

```
indicator/
  indicator_models.dart     — DotIndicatorEffect (15) + DotShape (5)
  indicator_math.dart       — mirroring, the scroll clamp, the edge fades
  indicator_style.dart      — IndicatorDefaults · DotIndicatorStyle · StoryIndicatorStyle (+ Resolved pair)
  theme/indicator_theme.dart— GlobalIndicatorTheme + both resolves
  global_indicator.dart     — GlobalDotIndicator, the effects, the painters
  global_page_counter.dart  — GlobalPageCounter: "3 / 5", the other way to say it
  story_player.dart         — StoryPlayerController: the clock a story runs on
  global_story_indicator.dart — GlobalStoryIndicator, over GlobalProgress.stepped
```

## The bags

- **`DotIndicatorStyle` is all-nullable**, floor in `IndicatorDefaults`,
  app-wide layer in `MyGlobalIndicatorTheme.build(tokens:)`
  (`core/theme/widget_themes/global_indicator_theme.dart`, wired in
  `theme.dart`). Order is `caller > GlobalIndicatorTheme.dotStyle >
  DotIndicatorStyle.defaults`. Presets: `subtle`, `pill`, `outlined`.
- **The story bar has its OWN bag** (`StoryIndicatorStyle`) on the same
  theme extension. It is a different widget with different needs, and
  it had five flat parameters instead.
- **It resolves in `didChangeDependencies`, never `initState`** — the
  palette and reduce-motion are inherited reads, and the transition
  controller's duration comes from them.
- **Colours come from the palette.** It read
  `Theme.of(context).colorScheme` for both, so a rebrand moved the app
  and left the dots on Material's seed.
- **Except the STORY bar, which is white on purpose.** It sits over
  photographs, so a palette colour would vanish on the wrong image —
  the same call the video and scanner modules make about chrome over
  media.
- **`reservedHeight` is one number for every effect**, so swapping one
  for another — or running the jumping arc — does not shove whatever is
  above and below the row up and down.

## The story bar RUNS

`GlobalStoryIndicator` draws a position; `GlobalStoryIndicator.player`
plays one, driven by a `StoryPlayerController`.

- **Per-segment durations.** `durations:` takes one entry per segment —
  a photo is quick and a video is as long as the video. `duration:` is
  the single fallback for the rest.
- **It ticks on the VSYNC**, not on a `Timer`. Every caller that drove
  the bar itself wrote the same loop slightly differently, and a
  60-millisecond period moves the fill in 2% jumps: visibly steppy
  against a bar that is three pixels tall.
- **The bar it draws through was painting NO fill at all.**
  `GlobalProgress`'s part-filled step left its child loose on the
  vertical axis, so a childless `ColoredBox` measured zero high — every
  segment read as full or empty, which is exactly the state a story bar
  spends all its time in. The widget tree was right the whole time,
  which is why a widget-tree test passed over it; only
  `test/progress/stepped_partial_fill_test.dart`, which rasterises and
  samples pixels, catches it.
- **`pause` holds where it stopped**, and `play` carries on from there.
  A pause that rewound the segment would punish the reader for looking
  away.
- **`holdFor(duration)` pauses and starts again by itself** — for an
  interruption that is not the reader taking over: a toast, a sheet, a
  tap that shows something briefly. `isHeld` tells the two apart, and a
  `goTo` while held still resumes, because nobody asked it to stop.
- **`previous()` restarts the CURRENT segment** when it is part-way
  through, and only goes back a segment near the start — which is what
  a back tap means in every story reader.
- **The last segment stays FULL** and reports `onCompleted`, rather
  than snapping back to empty.
- **The hold gesture belongs to the SCREEN, not the bar.** A story is
  paused by holding the media; the bar is three pixels tall. The module
  exposes `pause` / `play` and the screen decides what counts as an
  interruption.
- **`isPlaying` is INTENT, not the ticker's state.** A segment that has
  just finished is not animating, and asking the ticker was how the
  auto-advance stalled: it set up the next segment, checked "were we
  playing?", got false from a controller that had just completed, and
  left the story on a full bar.
- **The advance is scheduled, not called from the status listener.** A
  controller mutated from inside its own status dispatch swallows the
  change.
- A `loop: true` story never lets the tree go idle, so a test around
  one has to `pump` rather than `pumpAndSettle`.

## What a reader hears

The module had NO `Semantics` in twelve hundred lines — the one widget
on a carousel whose whole job is to say where you are said nothing.

- **The ROW is the node; the dots are decoration.** Fifteen effects
  draw a different number of boxes for the same five pages, so
  announcing each of them would read the count wrong in eleven.
- **A row with no `onTap` is a read-only report**, and takes no focus:
  it must not be a tab stop on the way to the content.
- **A tappable one is an ADJUSTABLE** — a value with a next and a
  previous, which is what a reader's swipe-up and swipe-down do to it.
  The three (`value`, `increasedValue`, `decreasedValue`) have to be
  given together: a node carrying `onIncrease` and no `increasedValue`
  asserts.
- **The keyboard moves a page**: arrows, Home and End. The horizontal
  row mirrors, so the key that moves forward is the one pointing at the
  next dot, not the one named "next".
- **The story bar reports where AND how far** — the percentage as a
  `value` rather than in the label, so it is not re-announced sixty
  times a second — and each of its segments is a button, because that
  is the one part of a story a reader can act on.

## Two ways to say a position

- **`GlobalDotIndicator`** for a handful of pages.
- **`GlobalPageCounter`** past that: a dot row does not scale, and
  `scrollingDots` only pushes the problem further out. A count says it
  in two characters at any length.
- It lived as a raw `Text` in THREE modules — the page view, the
  carousel and the carousel view — each with its own
  `TextStyle(fontSize: 12)`, none themeable, and all three writing
  ASCII digits so Arabic read `3 / 5` beside `٣ / ٥` on the same
  screen. It goes through `AppNumbers` now, takes the same
  `DotIndicatorStyle` for its colour, and uses tabular figures so the
  row does not jitter as pages turn.
- `test/indicator/indicator_adoption_test.dart` fails on a new
  hand-written `'${current + 1} / $total'`.

## Arabic

- **The row MIRRORS**, dot one on the right. The pages a dot row names
  live in a `PageView`, which is a scrollable, and scrollables reverse
  — so a row that did not mirror ran opposite to its own content.
- **It used to mirror for SOME effects only.** `scale`, `colour`, `swap`
  and the rest of the per-dot effects build a `Row`, which mirrors on
  its own; `worm`, `slide` and `jumping` position everything absolutely
  and did not. The same widget gave two different answers depending on
  which effect it was drawing.
- **Every position now goes through `_physicalIndex`**, and the
  overlay's inactive rail takes the same mapping, so the marker and the
  dots under it agree.
- **A VERTICAL row does not mirror.** It is turned by a `RotatedBox`
  and runs top-to-bottom in every language; there is no reading
  direction on that axis.

## Reduced motion

Resolves the duration to ZERO, so every effect lands on its end state
in one frame rather than racing there. A dot row re-animates on every
page change, which makes it the most frequently repeated motion in a
carousel or an onboarding flow. `respectReducedMotion: false` is for an
indicator whose motion IS the content.

## Fixed on the way

- **The scrolling strip's edge fades follow what is PAST them.** A fade
  says "there is more this way", and at the first dot there is not — it
  dimmed a dot the reader can see all of and promised a strip that is
  not there. `IndicatorMath.edgeFades` decides per end.
- **`drop` leaves a dot behind.** The active dot used to be the cell's
  only dot: it fell out, the cell stayed EMPTY, and the inactive dot
  snapped into existence one transition later — a dot that appeared
  from nowhere. The cell now keeps its resting dot the whole way and
  the active one falls away over it, which is also what makes a flight
  back to that cell look right.
- **`splash`'s ring no longer takes part in layout.** It sized its own
  cell, so the row spread apart as the ring expanded and snapped shut
  the moment the next transition moved the ring elsewhere — the dots
  either side visibly jumped back into place. The cell stays the dot's
  size and the ring paints outside it through an `OverflowBox`.
- **`onHover` had never worked.** Its `LayoutBuilder` read the variable
  it was being assigned to, and a closure captures the VARIABLE rather
  than its value — so the builder returned a `MouseRegion` wrapping the
  `LayoutBuilder` that contained it, nesting forever until layout threw
  `RenderBox was not laid out`. Nothing exercised it, so it stayed
  broken; `GlobalPageView`'s hover-peek was calling into it.
- **`IndicatorMath` holds the geometry** — the mirroring, the scroll
  clamp, the edge fades. None of it could be checked inside the widget,
  and every bug in it surfaced only on a device: one in Arabic only,
  another only at the two ends of a long strip.

## Effects

Fifteen, and they fall in two families that behave differently:

- **Per-dot** (`scale`, `color`, `swap`, `morph`, `rotate`, `flash`,
  `drop`, `bounce`, `splash`, `chain`, `expanding`) — a `Row` of dots,
  each animating in place. These honour `itemBuilder`.
- **Overlay** (`worm`, `slide`, `jumping`) — a rail of inactive dots
  with one marker positioned over it. Their motion bears no relation to
  per-dot content, so they ignore `itemBuilder`.
- `scrollingDots` is its own thing: a strip that scrolls to keep the
  active dot near the middle, for counts too high to show at once.

## Who uses it

`GlobalPageView`, `GlobalCarousel` and `GlobalCarouselView` all pass a
`DotIndicatorStyle?` straight through, so what a caller does not answer
falls through to the theme. Their `numbered` variant now takes the
palette accent too — it was reading `Theme.of(context).colorScheme`.

- Showcase: `/indicator-showcase`. ONE slider drives every effect on
  the page — drag it to scrub them all at once, or step with the arrows
  to watch the transition. It used to give each effect its own
  `PageView`: fifteen pagers, fifteen controllers, and no way to
  compare two of them without swiping each separately.
- Guards: `test/indicator/indicator_style_test.dart` (the three layers,
  the palette, the story bar's white, reduced motion, the snap),
  `test/indicator/indicator_math_test.dart` (the geometry, with no
  widgets in the way), `test/indicator/global_indicator_test.dart` (all
  fifteen effects, all five shapes, mirroring, taps, clamping, drop's
  resting dot, splash's stable row, the story bar),
  `test/indicator/story_player_test.dart` (per-segment durations,
  pause and resume, holdFor, the back-tap rule, completion),
  `test/indicator/indicator_a11y_test.dart` (what a reader hears, the
  keyboard, the counter's digits),
  `test/indicator/indicator_adoption_test.dart` and
  `test/indicator/indicator_showcase_test.dart`.
