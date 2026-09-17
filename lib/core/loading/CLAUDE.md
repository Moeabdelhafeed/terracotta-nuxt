# CLAUDE.md — core/loading

The app-wide loading overlay, its scoped sibling, and the cubit that
owns both.

```
loading/
  loading_cubit.dart          — the token stack, the timings, the state
  loading_token.dart          — one live loading scope
  loading_state.dart          — what the overlay renders from
  loading_options.dart        — BEHAVIOUR: timings and policy
  loading_style.dart          — LoadingDefaults · LoadingStyle · Resolved…
  loading_surface.dart        — WHERE it appears: scrim / topBar / dim
  theme/loading_theme.dart    — GlobalLoadingTheme + the resolve
  loading_overlay.dart        — the fullscreen overlay
  loading_scope.dart          — the same thing over one box
  loading_dio_interceptor.dart — a token per in-flight request
```

## Surface, style, options

Three words that were doing two jobs between them.

- **`LoadingSurface`** (was `LoadingStyle`) says WHERE the overlay
  appears and how much it blocks: a full `scrim`, a non-blocking
  `topBar`, or a lighter `dim`.
- **`LoadingStyle`** is now the themeable bag: the scrim's colour and
  alpha, the blur, the spinner's size and colour, the bar's height,
  the fade.
- **`LoadingOptions`** keeps BEHAVIOUR only: `appearAfter`,
  `minVisible`, `autoTimeout`, `barrierDismissible`, `contentBuilder`.
  Timing and policy — a house does not rebrand those, and it very much
  does rebrand the scrim.

The rename follows the date-time picker, which had to untangle the
same collision; the buttons module already owns a separate
`ButtonLoadingStyle` besides.

## Why it needed a theme extension most

The overlay is mounted ONCE, in `MyApp`. Its look was `LoadingOptions`
fields passed at that mount, so an app could not theme its own loading
state at all — one of the few surfaces every single user sees, and the
only one with no hook.

- **All-nullable `LoadingStyle`**, floor in `LoadingDefaults`,
  app-wide layer in `MyGlobalLoadingTheme.build(tokens:)`
  (`core/theme/widget_themes/global_loading_theme.dart`, wired in
  `theme.dart`). Presets: `quiet`, `blocking`.
- **Resolved once per build and handed down** — the painted layer, the
  centrepiece and the top bar all take the resolved bag rather than
  reading the theme apiece.
- **The colours come from the PALETTE.** The scrim was
  `colorScheme.scrim` and the spinner `colorScheme.primary` —
  Material's answers rather than the app's role-aware ones.
- **`LoadingScope` wears the same bag.** A scoped loader that scrims a
  card differently from the one that scrims the app is two loading
  states in one product.

## Reduced motion stops the FADE, not the spinner

The overlay's fade resolves to zero. The spinner keeps turning, and
that is deliberate: it is the only thing on screen saying the app is
alive, and a still one reads as a freeze — the opposite of what a
reader who asked for less motion wants.

## The top bar clears the status bar

It was pinned to absolute `top: 0` with a comment saying it
deliberately overlaps the status bar so the progress "hugs the screen
edge". That reads well on a desktop and fails on a phone: edge-to-edge
is on (`initSystemChrome`), so three pixels at y=0 sit behind the
clock. A progress bar nobody can see is not a progress bar.

It is offset by the top inset now. `topBarClearsStatusBar: false`
brings the flush look back — which is what desktop and web get either
way, since their inset is zero.

## Still raw on purpose

`CircularProgressIndicator` and `LinearProgressIndicator` are used
directly here, where everywhere else in the app would use
`GlobalProgress`. `core/` must not import `shared/module/`, and this
is the loader that sits beneath everything else — including the module
layer. `spinnerBuilder` on the bag is how a house brands it.

## Blocking means blocking — all three ways in

A scrim stops FINGERS. It never stopped anything else, and the whole
point of `blockInput` is that the app is unreachable while the work
runs:

- **`ExcludeSemantics`** — a screen reader could swipe straight
  through the scrim and press every button under it, which is exactly
  the double-submit the scrim exists to prevent.
- **`Focus(canRequestFocus: false, descendantsAreFocusable: false,
  descendantsAreTraversable: false)`** — `AbsorbPointer` blocks
  pointers only, so Tab still walked the blocked form on desktop and
  web, and a hardware keyboard still typed into it.
- **`PopScope(canPop: !blocking)`** — a blocking save could be popped
  away mid-flight by a back gesture, leaving the token holding an
  overlay over a screen that is gone.

All three wrap the **content**, not the overlay: the overlay is that
content's SIBLING in the same `Stack`, so wrapping itself would only
block the spinner. One `blocking` flag gates them together — visible,
a scrim or dim surface, and the top token asking for it.

## A leaked token is REPORTED, not just logged

`autoTimeout` force-disposes a token that outlived its cap, and used
to only `Logger.m.w` about it. A warning in a debug console is not a
report, and a leaked token in the wild is a spinner nobody can
dismiss. `LoadingOptions.onTimeout(label, tag)` fires alongside the
log — Crashlytics, an analytics event, whatever the house uses. It is
called BEFORE the dispose, while the token's own options still name
the caller that forgot.

## The clock is `package:clock`

`DateTime.now()` is gone from the token's `createdAt` and from the
sweep. Anything that AGES a value is otherwise untestable — a test
cannot make a wall clock say five seconds have passed — and the
timing here (a debounce, a floor, a sweep, interacting over a stack)
is the fiddliest logic in the module and the part that fails
silently: a spinner that flashes, a spinner that never leaves.
`test/loading/loading_cubit_test.dart` drives all of it under
`fakeAsync`, which is what `clock.now()` makes possible.
