# CLAUDE.md — lib/shared/module/marquee

Auto-scrolling container for content that does not fit. Holds the
gold standard: nullable themeable bag, theme extension, resolved style,
reduced motion.

- **`GlobalMarquee`** — wraps ANY child (text, a Row, chips) and scrolls
  it along one axis when, and only when, it overflows.
- **`GlobalMarquee.text`** — convenience for the common case.
- `GlobalText(marquee: MarqueeStyle())` — the usual entry point. See
  `../text/CLAUDE.md`.

## Contracts

- **It only scrolls when content is actually CONCEALED.** Overflow is
  measured from the scroll extent after layout; a child that fits gets
  no animation, no timers and no fade. This is the difference between a
  marquee and a distraction.
- **Speed is a VELOCITY (px/s), never a duration.** A fixed duration
  makes long content race and short content crawl — the usual reason a
  marquee looks cheap. Scroll time is derived from distance ÷ speed.
- **Loop holds BOTH fades on; only bounce ramps them.** A loop has no
  ends — content enters one side and leaves the other at every instant —
  so deriving the ramps from the offset made them blink out for a frame
  each time the cycle reset to 0: the offset said "nothing hidden on the
  left" while the trailing copy was still covering it.
- **In bounce, fades follow the scroll offset, and only the concealing edge.**
  Ramps grow over one `fadeWidth` of travel, so an edge dims as content
  slides under it and is absent while nothing is hidden there. Fading
  both ends unconditionally is the tell of a cheap implementation.
- **The fade is `BlendMode.dstOut`, so only ALPHA matters.** It punches
  real transparency out of the child and therefore works over any
  background. A `fadeColor` knob used to exist and was a no-op — dstOut
  never reads the source colour. Do not reintroduce it.
- **Style is the themeable bag** (`MarqueeStyle`, every field nullable):
  `caller > GlobalMarqueeTheme.style > MarqueeStyle.defaults > tokens`,
  materialized in `didChangeDependencies` as a `ResolvedMarqueeStyle`.
  Adding a field → bag, `mergedWith`, `copyWith`,
  `ResolvedMarqueeStyle`, `GlobalMarqueeTheme._lerpStyle`.
- **Token lookups DEGRADE.** `resolve()` reads spacing only when a
  `BreakpointsProvider` is present. A marquee can render in a toast or
  overlay outside the app shell, and must not require the responsive
  stack to draw.
- **Reduced motion stops it dead.** No scroll, no timers — the content
  is laid out statically and clipped. A permanently moving element is
  exactly what `disableAnimations` exists to prevent.
- **Semantics carry the WHOLE string**, not the visible slice, via
  `semanticLabel`.

## Gotchas

- Needs a **bounded** cross-axis extent. Inside an unbounded Row the
  child always "fits", so it never scrolls.
- **Loop scrolls ONE CYCLE, not the full extent.** The content is
  `[copy][gap][copy]`; the seam is invisible only at `copy + gap`, where
  the second copy sits exactly where the first began. Animating to
  `maxScrollExtent` (the end of the SECOND copy) and resetting to 0
  shows two different things and reads as a jump. The cycle is derived
  from the metrics — `(max + viewport + gap) / 2` — so no child
  measurement is needed. Guard: the "loop seam" test.
- `MarqueeMode.loop` duplicates the child with a `gap`; `bounce`
  reverses at each end and does not duplicate. Prefer `bounce` for
  labels — a gap sliding through a sentence reads as a glitch — and
  `loop` for tickers.
- Pausing is gesture-based (`pauseOnHover` / `pauseOnTouch`), so the
  marquee consumes pan gestures. Do not nest it inside a horizontally
  scrollable parent.

## Showcase + tests

`/marquee-showcase`, plus the "Marquee on overflow" card in
`/text-showcase`. Tests: `test/marquee/global_marquee_test.dart` (merge
precedence, resolve completeness, fits-vs-overflows gating, the
reduced-motion fallback, API guards, semantics).

## The freeze: a superseded drive must do NOTHING

`ScrollPosition.beginActivity` DISPOSES the activity it replaces, and
disposing a `DrivenScrollActivity` **completes its `done` future**. So
a second `_animate` while one is in flight does not replace it — it
WAKES it. A microtask later the superseded `.then` jumps and starts
another drive, which completes the one that just started, whose `.then`
runs a microtask later, and so on. Each turn schedules exactly one
more: the queue never drains, the isolate never returns to the event
loop, and there are no more frames, no timers and no exception. A
silent hard freeze needing a full restart — and nothing in the log,
because nothing was thrown.

Two things fed it, and both are fixed:

- **`_drive`, a generation token.** Every callback checks it is still
  the current generation before doing anything, so a superseded drive
  is inert. `_stopScrolling` retires the generation too, because the
  `jumpTo` it performs is itself a completion.
- **`didUpdateWidget` compared the wrong things** — the OLD bag's
  NULLABLE fields against the newly RESOLVED ones, so a marquee left on
  its defaults saw `null != 50.0` and tore itself down and back up on
  every rebuild of any ancestor. That is what supplied the second
  `_animate`. It compares old raw bag to new raw bag now.

Guards: `test/marquee/global_marquee_test.dart`, group `re-entry`.
With only the comparison broken the offset sits pinned a few pixels in
forever; with the token gone as well the test does not finish at all,
which is exactly what the freeze looked like. Note the marquee under
test is deliberately **not** `const` — an identical const instance is
skipped by `Element.updateChild`, so `didUpdateWidget` never runs and
the test would pass against the bug.

`UiWatchdog` (`lib/core/error/ui_watchdog.dart`) exists because of this
bug: it reports a stalled UI isolate from a second isolate, since the
stuck one cannot report anything.

## Re-entry is always DEFERRED

Three paths used to call `_animate` again with no time passing: the
loop's reset when `distance <= 0`, the bounce's turn when it was
already at its target, and a cycle whose computed duration rounded to
zero — that last one completing on the next MICROTASK, which starves
the frame loop just as thoroughly as a synchronous recursion does.

Any of them can spin forever when the numbers degenerate, which a
viewport being resized mid-scroll is enough to produce — and it takes
the UI thread with it rather than dropping a frame. Every one of them
goes through `_scheduleNextCycle` now: a marquee whose numbers stop
making sense does nothing until the next frame.

