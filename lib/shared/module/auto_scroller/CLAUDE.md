# CLAUDE.md — shared/module/auto_scroller

A scroll DRIVER. It owns no content: it hands a `ScrollController` to
a builder and advances that controller every frame.

```
auto_scroller/
  auto_scroller_models.dart      — AutoScrollerDefaults · AutoScrollerStyle · Resolved…
  auto_scroller_controller.dart  — GlobalAutoScrollerController
  theme/auto_scroller_theme.dart — GlobalAutoScrollerTheme + the resolve
  global_auto_scroller.dart      — GlobalAutoScroller
```

## It is NOT the marquee, and not `autoPlay`

Three things in this app make something move by itself. They do not
overlap, and the names are the only reason they sound alike:

| | what it owns | when it moves |
| --- | --- | --- |
| `GlobalMarquee` | its CHILD | only when the child overflows — it measures |
| `GlobalAutoScroller` | nothing | always, px/second, over a caller's scrollable |
| `autoPlay` / `autoAdvance` | a deck of pages | on an interval, one whole page at a time |

The marquee's contract is that a title which FITS stays still. This
never measures — it moves whatever the caller built, so the caller
MUST forward the controller or the whole thing is an expensive no-op.

## The bag

- **All-nullable `AutoScrollerStyle`**, floor in
  `AutoScrollerDefaults`, app-wide layer in
  `MyGlobalAutoScrollerTheme.build(tokens:)`
  (`core/theme/widget_themes/global_auto_scroller_theme.dart`, wired in
  `theme.dart`). Presets: `ticker`, `ambient`.
- **The rebrand hook here is a PACE, not a palette** — this module
  paints nothing. What a house needs to set once is the speed and the
  edge behaviour: a ticker drifting at 60 on one screen and 18 on
  another is the drift the bag exists to stop, and before this the
  speed was a widget parameter with a baked-in default, so it could
  only be set per call site.
- **Resolved in `didChangeDependencies`** — the extension and
  `disableAnimationsOf` are inherited reads.

## Fixed on the way

- **Nothing read reduced motion.** This is motion with no other
  purpose — nothing is being said that standing still does not say —
  so the resolve puts the speed at ZERO rather than slowing it, and
  the ticker never starts. `respectReducedMotion: false` is for a
  scroller that IS the content, such as a kiosk display nobody is
  holding.
- **A `Future.delayed` per touch outlived the widget.** Resume-after-
  release scheduled one on every pointer-up and a future cannot be
  called off, so each held the State alive until it fired — on a
  control whose entire job is to be touched. It is a cancellable
  `Timer`, cancelled in `dispose`. (The carousel had the identical
  bug; both were found in the same sweep.)
- **A hold banked up pixels.** The ticker's elapsed clock ran while it
  was stopped, so the first tick after a pause advanced by however
  long the pause had lasted — a rail held for a minute jumped a
  minute's worth on release. The clock resets when the drive
  restarts.
- **`hasClients` is not `positions.length == 1`.** `.position` asserts
  with more than one attached view, and a builder that rebuilds into a
  different tree shape briefly has two — the same assert the page
  family was fixed for.
- **It stops while off screen** (`pauseWhenOffscreen`). `TickerMode`
  only covers a covered ROUTE, so an ambient rail still built and
  merely scrolled out of view went on burning a frame a tick for
  something nobody could see.
- **`GlobalAutoScrollerController`** holds and releases it from
  outside — a dialog is up, a video in the rail is playing — and
  `restart()` is the only way back from an `AutoScrollLoopMode.stop`
  that has finished.

**Six flags hold the drive**, not one: a finger, a resting pointer,
being off screen, a screen reader, the caller, and the reader's own
semantics pause. They overlap — a finger can go down while the rail is
off screen, and lifting it must not start something nobody can see.
`_syncTicker` is the only place the ticker is started or stopped.

## The second pass

- **A COVERED ROUTE banked up pixels.** `TickerMode` MUTES a ticker
  rather than stopping it, and `Ticker.elapsed` goes on counting real
  time while muted — so the clock reset on the hold path never ran for
  it. Pushing a full-screen route, sitting three seconds and popping
  handed the first frame three seconds of travel: **310 pixels at
  100 px/s, measured**. Every tick delta is now clamped to
  `_kMaxTickDelta` (100 ms), which catches the paths a hold cannot —
  mute, a debugger pause, a janked frame.
- **Reduced motion could HIDE content.** Parking the speed at zero is
  right, but a caller who passed `NeverScrollableScrollPhysics` — what
  a ticker does, and what this module's own showcase did — then had
  everything past the fold out of reach of every gesture. The builder
  is `(context, controller, still)` now: only the CALLER can hand the
  physics back, so the module tells it. `.looping` does it itself.
- **WCAG 2.2.2 was unmet.** Moving content, auto-started, running past
  five seconds, beside other content, needs a mechanism to stop it —
  and a finger hold that resumes itself after a second is not one for
  a reader with no finger on the glass. Every moving rail publishes a
  Pause / Resume `CustomSemanticsAction`, and
  `pauseWhenAccessibleNavigation` (on) holds the drive outright while
  a screen reader is running: content walking out from under TalkBack
  cannot be read at all. **The reader's hold is its own flag** — a
  screen that resumes its rail programmatically must not undo a
  decision the reader made.
- **`pauseOnHover`** (on) — a resting pointer holds it, released with
  no resume delay, because a pointer that has LEFT is unambiguous in a
  way a lifted finger is not. Hovering to read a passing headline is
  the whole gesture on a desktop, and there is no touch there.

## Four more

- **`GlobalAutoScroller.looping(itemCount:, itemExtent:, itemBuilder:)`
  makes the wrap SEAMLESS.** `AutoScrollLoopMode.wrap` jumps to
  `minScrollExtent` and the jump shows — the pixels at each end are
  different pixels. A ticker that reads as endless needs the content
  REPEATED, and a driver that owns no content cannot repeat it, so
  this constructor owns just enough: it builds the list, 200 copies of
  it, seeds the middle lap, and corrects by exactly ONE lap — a jump
  between two identical frames. `itemExtent` is required rather than
  measured, because `ListView.builder` only ESTIMATES `maxScrollExtent`
  and that estimate moves as the drive scrolls; a lap computed from a
  moving number does not line up. `loopMode` does not apply — this
  deck has no end.
- **`edgeEaseDistance` + `edgeEaseFloor`** taper the speed into a
  turn. The floor is NOT zero: a speed easing all the way to nothing
  never arrives, and a bounce that never reaches its edge never turns
  around. Skipped for `wrap` — slowing into a teleport only advertises
  it — and off by default; the `ambient` preset asks for it, because a
  slow drift reversing on one frame reads as a stutter.
- **`startDelay`** holds the first frame back. A rail already drifting
  when the screen paints pulls the eye off whatever the reader opened
  the screen for. Zero by default: a beat is a decision about one rail.
- **`onEdge`** reports an arrival ONCE — not every frame a finished
  `stop` sits there — for rotating the content behind an endless rail
  or logging that a run finished.

## Who uses it

**Nothing in the app but `/auto-scroller-showcase`** — checked, not
assumed. `GlobalCarousel` only NAMES this module in a doc-comment
(its own drift is a page auto-advance); the page family, the
scrollable's smooth wheel and the onboarding deck all turn pages or
animate an entrance, which is not a px/second drift. So there is no
adoption sweep to run and no adoption guard here: nothing hand-rolls
what this does.

That makes it a module for ADOPTERS rather than for this template —
the ticker bar, the logo rail, the endless strip of offers a real app
puts on a home screen.

Reach for it when a caller's OWN scrollable should drift; reach for
`GlobalMarquee` when a piece of content does not fit; reach for the
page family's `autoPlay` when whole pages should turn.
