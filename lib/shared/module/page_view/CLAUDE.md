# CLAUDE.md — shared/module/page_view (and the carousels)

Three modules, one control. `GlobalPageView`, `GlobalCarousel` and
`GlobalCarouselView` are a deck of pages with different chrome, and
they share a bag, a theme and an indicator.

```
page_view/
  page_view_models.dart        — PageViewDefaults · GlobalPageViewStyle · Resolved…
  page_transitions.dart        — the nine transforms
  page_indicator_overlay.dart  — PageIndicatorOverlay, used by ALL THREE
  page_view_controller.dart    — GlobalPageViewController (LOGICAL pages)
  page_chrome_insets.dart      — PageChromeInsets, mixed into ALL THREE
  theme/page_view_theme.dart   — GlobalPageViewTheme + the resolve
  global_page_view.dart        — GlobalPageView
```

## The bag

- **All-nullable `GlobalPageViewStyle`**, floor in `PageViewDefaults`,
  app-wide layer in `MyGlobalPageViewTheme.build(tokens:)`
  (`core/theme/widget_themes/global_page_view_theme.dart`, wired in
  `theme.dart`). Order is
  `caller > GlobalPageViewTheme.style > GlobalPageViewStyle.defaults`.
  Presets: `numbered`, `bare`.
- **ONE extension for the three.** Two would be two rebrand hooks that
  can disagree, and a house that set an indicator on the page view and
  not the carousel would get two different dots on one screen — the
  same argument the collections' shared theme makes.
- **It carries NO dot colours.** The dots' own look belongs to
  `GlobalIndicatorTheme`, beside every other dot in the app; a page
  view that filled them in would be a second place for them to be
  wrong. This bag says WHICH indicator and WHERE, and passes
  `dotStyle` straight through.
- **Resolved in `didChangeDependencies`** in all three, never
  `initState` — the extension and `disableAnimationsOf` are inherited
  reads.

## Fixed on the way

- **Each of the three carried its own copy of the indicator overlay** —
  the same thirty lines, the same `GlobalDotIndicator` /
  `GlobalPageCounter` pair, each with its own hard-coded pill radius of
  24 and padding of 12/6. Three copies drift the moment one is
  touched, which is exactly what happened to the A-Z scrubber before
  it was extracted. There is one `PageIndicatorOverlay` now;
  `test/indicator/indicator_adoption_test.dart` fails if a module
  builds its own dots again.
- **Nothing read reduced motion.** The transition collapses to a plain
  `slide` — NOT to "none": moving between pages IS the control, and
  what goes is the spinning, folding and scaling on the way. The page
  duration, the thumbnail scroll and the hover peek all zero. The
  STORY pace deliberately does not: that is the content's clock, and a
  reader who asked for less motion has not asked for the story to
  flash past.
- **It had no semantics at all.** A swipe is invisible to a screen
  reader, so a deck was a wall of unreachable content with no hint
  that there was more of it. It is one node now: the localized
  `Page 2 of 5` (the same phrase the pagination bar uses, so Arabic
  gets Arabic digits), and increase / decrease actions that actually
  turn a page.
- **`autofocus: true` stole the focus.** A page view takes focus the
  moment it is built, off whatever the reader was on — and a deck is
  even likelier than a list to sit in the middle of a page that
  already had a field focused. Tab reaches it on its own.
- **Six hard-coded numbers** — the thumbnail tile width, the strip's
  padding and height, the pill's radius and padding, the page
  animation's duration and curve — are bag fields, so a house sets
  them once.
- **A page change TICKS**, gated on `enableHaptic`, but only when a
  finger did not make it: a swipe already has the page moving under
  the thumb, so the feedback is for a tap on the indicator, a keyboard
  arrow, or a story advancing on its own.
- **The indicator sat UNDER the sticky chrome — in all three.** The header and the
  footer are overlays aligned against the same box the indicator is,
  so a footer bar drew straight over the dots. The module measures
  them after the frame that lays them out — a `LayoutBuilder` knows
  what the Stack was given, not what a caller's header chose to be —
  and insets the indicator by whatever shares its edge, the thumbnail
  strip included. Both edges are added whichever way it is aligned:
  padding on the far side grows the box away from the edge it is
  pinned to, so it costs nothing.

  The measurement is the `PageChromeInsets` mixin, shared by the page
  view and both carousels. It was written for the page view and the
  carousels had the identical bug in identical code — a third copy is
  how the indicator overlay and the A-Z scrubber drifted before they
  were extracted, so it was pulled out the first time it was needed
  twice.
- **The loop's WRAP teleported.** In continuous mode the indicator
  derives `from = floor(value)`, `to = ceil(value)`, so it can only
  animate between ADJACENT dots — right while a finger drags between
  two pages, wrong across a wrap, where the value goes 3.99 to 0.0 in
  a frame and the first dot lights instantly. The module hands the
  last segment back by passing `continuousIndex: null`, and the
  indicator's own controller animates it — which is where `chain` and
  every other discrete effect live.
- **The story only paused on a LONG PRESS, and only when
  `storyTapToAdvance` was also on** — the handlers hung off the
  tap-half detectors, so turning taps off turned pausing off with
  them, and a drag between pages left the clock running (a segment
  could advance out from under the finger). It is a `Listener` on the
  deck now: pointer down pauses, up or cancel resumes. A `Listener`
  takes no part in the gesture arena, so the drag and the taps are
  untouched.
- **`ScrollController.position` asserts with more than one attached
  view**, and a page view briefly has two: adding a header or footer
  changes the depth of the `Stack` the `PageView` sits in, so for one
  frame the outgoing and incoming views are both attached.
  `hasClients` is not the same question — every read goes through
  `_hasSinglePosition` now.
- **The story controller read the bag from `initState`**, which runs
  before `didChangeDependencies` resolves it — a
  `LateInitializationError` on any story that did not set
  `storyDefaultDuration` itself. It starts in
  `didChangeDependencies`.
- **The chrome inset went STALE.** The measurement was scheduled only
  while a header or footer builder existed, so REMOVING a footer left
  its height behind and the indicator kept floating above a bar that
  was no longer there. It is scheduled whenever there is chrome to
  measure OR a stale measurement to clear.
- **`SafeArea` applied the device's inset wherever the deck was put.**
  A page view in a card halfway down a page is not at the screen edge,
  so the home indicator's height pushed the footer up and left a strip
  of content showing underneath it. The module measures its own global
  rect against the window and only asks for the inset on an edge it
  actually reaches — the header, the footer and the thumbnail strip
  all follow the same rule. An ancestor that already consumed the
  padding makes it a no-op anyway; nothing promises there is one.
- **`storyDefaultDuration` and `hoverPeekDuration` are nullable now**
  and fall through to the bag, so the pace is set once rather than at
  every call site.

## Four additions

- **`autoPlay`** — the deck turns itself every
  `GlobalPageViewStyle.autoPlayInterval`. Neither this module nor
  either carousel had it, so every banner in every app hand-rolled a
  `Timer` and re-invented pause-on-interaction, pause-on-background
  and dispose. On a deck that does not `loop` it **stops at the last
  page** rather than rewinding: a banner that snaps back to the start
  reads as a bug.
- **`GlobalPageViewController`** drives it in LOGICAL pages. Flutter's
  own `PageController` counts VIRTUAL ones — a looping deck starts at
  `items.length * 1000` so it can wrap in both directions — so a
  caller's `jumpToPage(2)` landed a thousand laps from where they
  meant. `next` / `previous` wrap when the deck loops and stop at the
  ends when it does not, and `pauseAutoPlay` is the hold for reasons
  only the screen knows (a dialog, a video playing inside a page).
- **`pauseWhenOffscreen`** stops a story or an auto-play that has been
  scrolled out of view. `TickerMode` only covers a covered ROUTE, so a
  deck still built and merely off screen went on burning pages nobody
  could see — the same call `GlobalAnimation.pauseWhenOffscreen`
  makes. Only wrapped when there IS a clock to hold: a
  `VisibilityDetector` is not free.
- **The arrow keys MIRROR.** A horizontal deck in Arabic puts page 0
  on the right and advances leftward, so the arrow that means "next"
  is the LEFT one — pressing right used to go forward there, against
  both the content and the swipe that produced it. A vertical deck
  keeps its keys: up and down have no reading direction.

**A `ChangeNotifier` must not fire during build.** `_syncClock` runs
from `didChangeDependencies`, which is inside the build phase, so
notifying the controller there marked its `ListenableBuilder` dirty
mid-build — `setState() or markNeedsBuild() called during build`, and
the showcase guard caught it. Only the callers that change a HOLD
notify, and those run from a gesture or a visibility callback.

**The clock is held by three independent flags** — a finger, being off
screen, and the caller — because they overlap. A finger can go down
while the deck is off screen, and releasing it must not start a story
nobody can see; one bool could not say that. `_syncClock` is the only
place either the story controller or the auto-play timer is turned on
or off.

## The carousels got the same pass

They shared the bag, the theme and the indicator overlay but not the
gold pass itself, which is the same shape as a module going gold while
the things built on it quietly do not.

- **Both stole the focus on mount** (`autofocus: true`) — and a
  carousel is usually one thing among many on a page.
- **Neither had a single `Semantics` node.** Both are one node now
  saying `Page 2 of 5`, with increase / decrease that turn an item.
- **The arrow keys mirror in Arabic** in both, and a page change ticks
  when a finger did not make it.
- **`GlobalCarouselView` read `ScrollController.position` behind
  `hasClients`** at three sites — the assert the page view had already
  been fixed for.
- **Both take the shared `GlobalPageViewController`** (as
  `carouselController` / `viewController`), and both hold a story or an
  auto-advance while scrolled off screen.
- The carousel's thumbnail scroll and its programmatic moves take the
  bag's durations, so reduced motion reaches them.

**Two halves of one bug, both fixed.**

- **The LANDING.** `GlobalCarouselView.animateToPage` computed a pixel
  offset from `maxScrollExtent` — and that extent MOVES while the
  carousel scrolls, because a weighted layout resizes as the hero slot
  grows and the peeks shrink (533 to 178 on a five-item deck,
  measured). The offset was right for the extent it came from and
  meant a different item on arrival: asking for item 1 landed on item
  3. It drives `CarouselController.animateToItem` now, which knows the
  weights. Looping still maps a logical index onto the nearest virtual
  slot first, or a wrap would rewind the whole strip.
- **The READBACK.** `_onScroll` derived the current item with a stride
  of `maxScrollExtent / (n - 1)`, which assumes the last item sits at
  the end of the scroll — true only when ONE item fills the viewport.
  A uniform-weight deck reported item 4 for a scroll that had reached
  item 2. It replicates the framework's own arithmetic now:
  `pixels / (viewport * weights.first / weights.sum)`, which is
  literally what a carousel position does. Exact for weighted and
  uniform alike, and for a DRAG — the half `animateToItem` cannot
  cover, since only the readback can say where a finger stopped.

The correction is NOT offset by the hero slot: `animateToItem` already
leaves its target as the LEADING item, so adding it counted the slot
twice and every weighted landing read one high. That was one test
away from shipping.

## The family paces itself the same way

- **`GlobalCarouselView` can auto-play at all now.** The page view had
  `autoPlay`, the carousel had `autoAdvance`, and the third sibling
  could only move itself in story mode. It holds for a finger, for
  being off screen and for the controller, and it STOPS rather than
  rewinding — which for a strip showing three items at once means
  stopping when the scroll runs out, not at index `n - 1`.
- **The carousel's timings fall through to the bag.**
  `autoAdvanceInterval`, `autoAdvanceCurve` and `autoAdvanceDuration`
  were non-nullable with baked-in defaults, so a house could not set
  the pace once and the family shipped two different intervals (four
  seconds against the page view's bag-driven five). They resolve to
  `autoPlayInterval`, `pageCurve` and `pageDuration` now, so reduced
  motion reaches the auto-advance too.
- **A `Future.delayed` outlived the widget.** The carousel's
  pause-on-interaction resumed through one, and a future cannot be
  called off: every touch scheduled another, each holding the State
  alive until it fired, on the one control that is touched constantly.
  The `mounted` check stopped the crash and not the leak. It is a
  cancellable `Timer`, cancelled in `dispose`.
- **The auto-advance timer read the bag from `initState`**, which runs
  before `didChangeDependencies` resolves it — the same
  `LateInitializationError` trap the page view's story controller fell
  into, found by the same kind of test.

## Both showcases stopped demonstrating the indicator

One opened on `expanding`, the other on `worm` — `GlobalDotIndicator`'s
effects, already in `/indicator-showcase`, and the same wrong boundary
the page view showcase had. These pages say WHERE the indicator sits
and what the deck does; how a dot moves lives with the dots.

## It had NO tests

Seven hundred lines, sixty parameters, story mode, loop, thumbnails,
pinch, dismiss and nine transitions — and not one test. The
characterisation suite came with the gold pass:
`test/page_view/global_page_view_test.dart` covers the bag, the three
layers, the theme lerp, reduced motion, the semantics node and its
actions, the focus behaviour, and the pages actually turning.

## The showcase shows the PAGE VIEW

It used to open with three sections — dots, expanding pill, worm —
which are `GlobalDotIndicator`'s effects, already demonstrated in
`/indicator-showcase`. A showcase that re-demonstrates another
module's feature set teaches the wrong boundary: this page says which
indicator to ask for and where it sits, and the effects live where the
effects live.

- Showcase: `/page-view-showcase`.
