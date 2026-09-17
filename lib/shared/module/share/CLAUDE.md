# CLAUDE.md — shared/module/share

A wrapper over `share_plus`, and deliberately a thin one: the OS sheet
is the feedback, so what this module owes is a control that looks like
the rest of the app and says what it is.

```
share/
  share_models.dart        — ShareDefaults · ShareButtonStyle · Resolved…
  theme/share_theme.dart   — GlobalShareTheme + the resolve
  global_share_button.dart — GlobalShareButton + the GlobalShare facade
```

## Two things

- **`GlobalShareButton`** in three shapes: `icon` (the default),
  `fab`, `tile`.
- **`GlobalShare`** — a static facade (`text` / `uri` / `files` /
  `run`) for a swipe action, a menu item, anywhere without a widget.

## The bag

- **All-nullable `ShareButtonStyle`**, floor in `ShareDefaults`,
  app-wide layer in `MyGlobalShareTheme.build(tokens:)`
  (`core/theme/widget_themes/global_share_theme.dart`, wired in
  `theme.dart`). Preset: `quiet`.
- **The VARIANT and the LABEL are NOT in it.** Both used to be. A
  theme that can turn every share control in the app into a floating
  action button is not a theme, it is a rewrite — where the button
  goes is the caller's decision — and what a button SAYS is content.
  They are widget parameters now, with `.icon` / `.fab` / `.tile`
  constructors for the shape.
- **The floor carries no colours.** They resolve from
  `context.primaryColors` at build time, so a share button tracks
  role, brightness and saturation. `backgroundColor` stays nullable
  even AFTER the resolve: unset means the FAB takes Material's own
  scheme colour and the tile stays transparent, which is not one
  colour to name.
- **The glyph size comes from the tokens** via the theme builder, so
  it grows with the window. It was a bare `24.0` const on the model.

## Fixed on the way

- **The FAB had no NAME.** Material publishes its own semantics node
  with the button flag and the tap; a `Semantics` wrapper above it is
  a SECOND node, so the label sat on one and the action on the other
  and a reader focusing the button heard nothing. `MergeSemantics`
  puts them together — the test caught this the first time round.
- **A failed share went nowhere.** It was logged at WARNING and
  dropped, so a share that never happened looked exactly like one the
  reader cancelled. Without an `onError` it goes to
  `FlutterError.reportError` — the same call the refreshable makes for
  a failed pull.
- **`ShareResultStatus.unavailable` was reported as an outcome and
  nothing else.** It is neither a success nor a dismissal: the
  platform has no share UI at all. It says so once in the log.
- **The tile names itself** (`semanticLabel`), and the icon variant
  already went through `GlobalIconButton`.

## Found on a device

- **Two share FABs on one page was a RED SCREEN.** Material gives
  every `FloatingActionButton` the same default hero tag, and a second
  one in the same route is "multiple heroes share the same tag". A
  share button is a COMPONENT — a page can hold several, and the
  showcase found it the moment it grew a second. `heroTag` is null by
  default, which turns the flight off; a caller who names one is the
  one who knows it is unique.
- **The FAB painted as a solid coloured square.** The resolve forced
  the foreground to `primaryColors.primary`, and Material fills a FAB
  with the primary container — so a primary glyph sat on a primary
  fill. `foregroundColor` stays NULL after the resolve now: the icon
  and tile variants fall back to the primary role, the FAB leaves it
  to Material, which picks a foreground to contrast with the fill it
  chose.
- **A tap looked like nothing happened.** Opening the OS sheet is a
  platform round-trip, long enough on a cold channel that the reader
  taps again and a second sheet queues behind the first. All three
  shapes show a spinner and refuse the second tap until the sheet has
  closed. The reset is in a `finally`, so a share that THROWS leaves a
  working button rather than one stuck spinning.

## The share sheet is ONE resource

Press a button, close the sheet, press a DIFFERENT button before the
first call has finished settling, and that second button spun for the
rest of the session: `share_plus` was asked to share while it was
still finishing the last one, and answered the second never.

Two buttons each tracking their own `_busy` flag cannot see that. The
OS sheet is a single, app-wide resource, so the state is app-wide too:

- **`GlobalShare` holds the in-flight share** and SERIALIZES. A call
  made while one is running waits for it and then goes. Refusing
  outright would be simpler and wrong — the reader asked for a share
  sheet, and a tap landing a moment early should still get one.
  `GlobalShare.isSharing` reports it.
- **Every share is under a `timeout`** (two minutes — the clock covers
  a human reading a sheet, not a network call). A platform channel
  that never answers must not leave a control spinning forever.
- **`GlobalShare.debugRunner` is the test seam.** `share_plus`
  resolves to a host implementation under `flutter_test` that answers
  nothing, so without it every test of what happens AFTER a share
  hangs — which is how the stuck state got shipped in the first place.

Two more things fell out of chasing it:

- **The haptic was AWAITED before the share.** `HapticFeedback` is a
  platform round-trip of its own, so every share waited on a tick
  nobody is waiting for — and under `flutter_test` it never returns at
  all, which is why the first attempt at these tests looked like the
  share was hanging when it had not been reached. It is fired, not
  awaited.
- **The FAB's spinner was invisible.** `GlobalProgress` paints the
  primary by default, and Material fills a FAB with the primary
  container — the same trap the glyph fell into. It reads the ambient
  `IconTheme`, which the FAB sets to whatever foreground it resolved,
  so the spinner matches the icon it replaced.
- **And then it arrived a third of a second late.** The app theme
  gives every spinner a 300ms grace period so work that finishes fast
  never flashes one. That is right for a page and exactly wrong for a
  control that has already replaced its glyph with it: the button sat
  EMPTY for those 300ms, which is the flash the rule exists to
  prevent. Both in-button spinners set `appearAfter: Duration.zero`.

## Who uses it

Nothing but `/share-showcase` — like the auto-scroller, this is a
module for ADOPTERS. `FloatingActionButton` is raw here because the
app has no FAB module; three other files build one the same way.
