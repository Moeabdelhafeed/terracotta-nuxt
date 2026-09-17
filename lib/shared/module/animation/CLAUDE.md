# CLAUDE.md — lib/shared/module/animation

`GlobalAnimation` — one widget for GIFs, Lottie JSON and dotLottie
(`.lottie`), from an asset, a URL or a file.

```dart
GlobalAnimation.gif('assets/spinner.gif', width: 80, height: 80)
GlobalAnimation.lottie('assets/success.json', loopMode: AnimationLoopMode.playOnce)
```

## Contracts

- **Style is the themeable bag `GlobalAnimationStyle`** — every field
  nullable, with `defaults` + `mergedWith` + `copyWith`, materialized
  once in `didChangeDependencies` by `style.resolve(context)` into a
  `ResolvedAnimationStyle`.
- **Resolution order**: `caller > GlobalAnimationTheme.style >
  GlobalAnimationStyle.defaults`, then colours from the palette.
- **Every hard-coded number lives in `AnimationDefaults`.**
- **The bag keeps its `Global` prefix** where `PdfStyle` and
  `BannerStyle` drop theirs. Flutter's own `material.dart` exports an
  `AnimationStyle`, and a module that imports Material — which is all of
  them — cannot declare a second one.
- **The source, the loop mode and the speed are on the WIDGET.** What
  is playing and how it plays are not how players look.

## Gotchas

- **The colours come from the PALETTE.** The transport row read
  `Theme.of(context).colorScheme.primary` and painted its own
  background `Colors.black12` — Material's scheme and a constant, so a
  rebrand left every player's controls behind and dark mode got a black
  wash on an already-dark surface. The scrim is now the palette surface
  at `controlsScrimOpacity`, because the row sits OVER the animation,
  whose colours nothing here controls.
- **`backgroundColor` resolves to NULL, not to a surface.** An
  animation brings its own background and a box behind it is the
  exception. Defaulting it would put a rectangle under every
  transparent Lottie in the app.

## Reduce motion

- **A looping decoration is exactly what the setting is for.** Flutter
  already pauses multiframe images under `disableAnimations`, so before
  this a GIF stood still while the Lottie beside it kept playing — the
  module honoured the setting by accident on one code path and ignored
  it on the other.
- **It stops an animation starting ITSELF; it does not disable the
  controls.** Someone who presses play has asked for motion.
- **`respectReducedMotion: false` is for an animation that IS the
  content** — a chart that only reads as motion, an explainer someone
  opened on purpose. Decoration should never set it.
- A still animation looks like one that failed to load, so the widget
  says which it is to a screen reader (`pausedReducedMotion`).

## GIF playback

- **`TickerMode` is how a multiframe image pauses**, and it holds the
  frame it is on. The key used to carry `_isPlaying`, so every toggle
  rebuilt the widget, re-resolved the provider and restarted decoding:
  "pause" was really "stop, and start again from frame one on resume".
- **Speed does not apply to a GIF.** The frame delays are in the file
  and Flutter's decoder owns them. The control is Lottie-only, and the
  seek bar is hidden for GIFs for the same reason.

## The error plate FITS its box

- Glyph plus headline plus retry line is about 150dp. An animation
  smaller than that is common — a 40dp spinner, an inline badge — and
  the plate overflowed every one of them by however much it needed.
- Below `errorPlateMinHeight` it degrades to the GLYPH alone, which
  still says "this did not load" and still takes the tap. Guard: "a
  SMALL animation gets the glyph alone, and does not overflow".
- It is a BUTTON at both sizes. A plate that retries on tap and does
  not say so is a dead end to anyone not looking at it.

## Playback

- **Speed is a DIVISOR of the composition's duration**, so zero is an
  infinite `Duration` and a negative one is a negative `Duration` —
  both throw out of the controller rather than looking wrong. Clamped
  to `[minSpeed, maxSpeed]` on the way in, not left to the caller.
- **The reverse loop carries a GENERATION TOKEN.** It re-enters itself
  through a `.then`, which is the exact shape that froze the marquee: a
  controller that completes without advancing a frame turns it into an
  unbounded microtask chain, and an app with no frames, no timers and
  no exception is simply dead. Every continuation checks it is still
  the current drive; `pause` and `dispose` bump it.
- `loop` and `pingPong` use `AnimationController.repeat`, which needs
  no status listener. Only `playOnce` adds one, and removes it when it
  fires.

## The handle

- **`AnimationHandle` is the surface meant to be used.** Driving a
  player from outside used to mean a `GlobalKey<GlobalAnimationState>`
  and calling methods on a `State`, which works and also hands the
  caller every private field in the class. `GlobalAnimationState`
  implements the handle; `onStateChanged` and `stateStream` carry an
  `AnimationStateSnapshot`.
- **A GIF reports no progress and no duration.** Flutter's decoder owns
  the frame clock and does not say which frame it is on, so the
  snapshot says zero and null rather than guessing.

## Off-screen

- **A player scrolled out of view PAUSES** (`pauseWhenOffscreen`, on).
  `TickerMode` already stops one whose ROUTE is covered, but a Lottie
  in a list kept drawing frames nobody could see. Pausing holds the
  frame, so scrolling back is a resume.
- **One paused BY HAND stays paused** when it comes back. Scrolling
  past something is not permission to start it.
- `VisibilityDetector` batches its callbacks behind a timer, so a
  widget test that pumps a player has to set
  `VisibilityDetectorController.instance.updateInterval = Duration.zero`
  or the harness fails it for a pending timer.

## Accessibility

- The transport buttons are `GlobalIconButton`s, so they carry
  tooltips, semantic labels and a 48dp target.
- **The seek bar is a SLIDER**, with the percentage as its value and
  arrow-key increase/decrease wired. It was a coloured line with a tap
  handler — reachable by pointer only, and silent.
- **The speed pill says what it CHANGES.** "1x" alone tells a reader
  the current value and nothing about what tapping it would do, so the
  label is "Playback speed" and the value is the multiplier.
- The percentage read-out is excluded from semantics — the slider
  beside it already announces the same number, and two nodes saying
  "34%" is worse than one.
- **A NAMED animation is content; an unnamed one is DECORATION** and
  leaves the semantics tree entirely rather than sitting in it
  unlabelled. Same rule `GlobalImage` uses. The transport row and the
  ERROR PLATE are exempt from the exclusion — they are controls, and a
  plate that retries on tap has to be reachable by something other than
  a pointer.
- **A named animation under reduce motion says it is paused**, because
  a still one is otherwise indistinguishable from one that failed.
- **A slider needs `increasedValue` / `decreasedValue`** beside its
  actions or Flutter throws once per frame from inside the semantics
  flush. `asSlider` asserts on this now; it used to take the actions
  with nowhere to put the values.

## Showcase + tests

`/animation-showcase`. Two test files, for two different jobs:

- `test/animation/global_animation_test.dart` — the CONTRACT: bag
  merge, resolution order, the token-driven app theme, the palette
  colours, reduce motion, the speed clamp, the error plate and lerp.
- `test/animation/animation_fixture_test.dart` — what the DECODERS
  actually do, against a hand-built 2-second Lottie and a 2-frame GIF
  in `fixtures/`. Composition duration, speed dividing it, play/pause
  moving the handle, seeking, off-screen pausing, laps and semantics.

The fixture file exists because the contract tests could not reach a
loaded animation, and a whole source kind was broken underneath them —
see the first known gap.

## Known gaps

- **`AnimationSourceType.file` was broken for Lottie until a fixture
  caught it.** `FileLottie` takes an `Object` and casts it to `File`
  internally, so passing a path compiled fine and threw "type 'String'
  is not a subtype of type 'File'" at load — every file-sourced Lottie,
  always. The fixtures exist because of this.
- **The GIF fixture is 1x1.** At 4x4 the LZW table widens partway
  through a frame and a fixed-width hand encoding stops being valid; a
  1x1 frame is three codes and stays in the initial width.
- **A GIF cannot be sped up, slowed down or seeked.** The frame delays
  are in the file and Flutter's decoder owns the clock. `speed` on a
  GIF asserts rather than being quietly ignored, and the seek bar is
  hidden for them.
- **Lottie image assets are not remapped.** A `.lottie` archive with
  embedded PNGs resolves them through the lottie package's own loader;
  nothing here intercepts it, so an archive with broken image paths
  renders without them rather than reporting it.
- **`onLoop` counts value WRAPS, not engine laps.** `repeat` emits no
  status, so a lap is inferred from the controller value crossing its
  end. A seek across the boundary while playing would count one.
