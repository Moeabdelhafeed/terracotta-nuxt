# CLAUDE.md — lib/shared/module/progress

`GlobalProgress` — six shapes behind one widget: `linear`, `circular`,
`gauge`, `stepped`, `multiSegment`, `waveFill`, plus a `countdown`.

```dart
GlobalProgress.linear(value: 0.4, semanticLabel: 'Upload')
GlobalProgress.circular(value: 0.4, style: ProgressStyle(showLabel: true))
GlobalProgress.loading()                      // indeterminate
GlobalProgress.countdown(duration: 30.seconds)
```

## The part-filled step

`stepped` with a `stepProgress` draws the current step partly full. Its
fill needs an explicit `heightFactor: 1` — without one the child is
left LOOSE on that axis, and a `ColoredBox` with no child of its own
measures zero high there, so the fill painted nothing at all and every
step read as either full or empty.

It survived because the widget tree was right the whole time: the
`FractionallySizedBox` was there with the correct `widthFactor`, and a
widget-tree test read that and passed. Only pixels catch it —
`test/progress/stepped_partial_fill_test.dart` rasterises the bar and
samples a line across it.

Note the trap is specific to childless `ColoredBox` / `DecoratedBox`: a
`Container` with a colour and no child EXPANDS to fill loose
constraints, which is why the other fills in this repo were fine.

## Contracts

- **Style is the themeable bag `ProgressStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once in
  `didChangeDependencies` by `style.resolve(context, type:)` into a
  `ResolvedProgressStyle`.
- **`resolve` takes the TYPE**, because the natural SIZE depends on the
  shape and the bag cannot know which shape it is being read for: 48 for
  a ring, 120 for a gauge, 100 for a droplet — and `null` for a bar,
  which takes the width it is handed. That is also why `defaults`
  carries no `size`.
- **Resolution order**: `caller > GlobalProgressTheme.style >
  ProgressStyle.defaults`, then colours from the palette.
- **Every hard-coded number lives in `ProgressDefaults`.** There were
  twenty-eight `_k` constants at the top of the widget file.
- **`value` and `bufferValue` are DATA, not style.** The buffer used to
  sit on the style bag beside the thickness and the corner radius; it
  changes every frame of a video and belongs with `value`.
- **A buffer works WITHOUT a total.** `bufferValue` with
  `indeterminate` draws how much is loaded behind a sweep that admits
  it does not know how much there is — the streaming case.
- **`stepProgress` part-fills the CURRENT step.**
  `GlobalStoryIndicator` is this widget now: it drew its own stack of
  containers per segment, which is the same bar with a different set of
  bugs available to it. What is left there is the part a progress bar
  has no business knowing — that each segment is a page you can tap.

## Gotchas

- **The colours come from the PALETTE**, not `Theme.of(context).colorScheme`.
  A bar tracked Material's scheme rather than the app's role,
  brightness and saturation. Guard: "the fill is the palette primary,
  not the ColorScheme".
- **The on-fill label colour is `colorScheme.onPrimary`**, not
  `Colors.white` — which is invisible on a light-coloured bar.
- **A centred label is drawn TWICE**, clipped either side of the fill
  edge, because the text crosses that edge as the value climbs and one
  colour would vanish against one side or the other.
- **A DERIVED track follows the fill through `colorThresholds`; a NAMED
  one does not.** Otherwise a bar that turns red keeps a blue track
  behind it. `trackFollowsFill` on the resolved bag is which case it is.
- **The lowest threshold at or above the value wins**, so
  `{0.3: red, 0.6: orange, 1.0: green}` reads "red up to 30%". A value
  above every threshold keeps the last.
- **`colorThresholds` cannot be `const`** — a map keyed by `double`
  never can be, since `double` overrides `==`. `const ProgressStyle(
  colorThresholds: …)` will not compile; drop the `const`.
- **A side label reserves the width of the WIDEST thing it can say**,
  measured from `format(0)` and `format(1)` and cached. It was a flat
  forty pixels, which is only ever right by accident: too much for a
  percentage — a visible hole after "65%" — and nowhere near enough for
  `"500 MB / 500 MB"`, where the box then grew with the value and the
  bar jumped anyway, which is the exact thing a reserve exists to stop.
  The reserve is a MINIMUM, so a formatter whose widest output sits
  somewhere in the middle still fits.
- **And its slack sits OUTSIDE.** The text aligns toward the BAR, so
  what is left falls against the page edge rather than between the
  label and the thing it labels.
- **The legend carries the bar's REMAINDER too.** Without a matching
  spacer the legend shared out the full width while the segments above
  it only covered what was filled, so every caption drifted right of
  the block it names — by more the emptier the bar.
- **`GlobalProgress.loading` FORCES `indeterminate`.** Passing any
  style used to replace the one the factory set, so
  `loading(style: ProgressStyle(color: red))` quietly became a
  determinate bar stuck at zero.
- **A gradient on `stepped` spans the WHOLE row**, not each step. Each
  active step draws a full-width gradient and clips its own slice out
  of it; painting the ramp per step turns the row into stripes.
- **Segment flex is the fraction × 1000.** `Expanded.flex` is an `int`,
  and a tenth of a percent is finer than a bar this size can show.
- **The indeterminate ring turns TWO WHOLE times per cycle.** A
  fractional count leaves the arc somewhere other than where it
  started, so the loop visibly jumps every time it repeats.
- **A segment `Row` needs `CrossAxisAlignment.stretch`.** A
  `ColoredBox` takes its CHILD's size, and the row's default centre
  alignment hands it a loose height — so every segment measured zero
  and the bar vanished, leaving a row of legend dots under a heading
  with nothing above them. Guard: "the BAR is drawn, not just its
  legend".

## Motion

- **Tickers exist only while something needs them.** The pulse and the
  wave controllers are created and disposed as their flags change, so
  nothing repaints forever for a feature nobody turned on. Guard:
  "nothing ticks for a plain determinate bar".
- **Reduced motion stops the value transition, the pulse and the wave —
  but NOT the indeterminate sweep.** Everything else is decoration; the
  sweep is the only thing saying work is happening, and a still one
  says the app has hung.
- With animation off, a new value LANDS rather than crawling.
- **An indeterminate indicator can APPEAR LATE** (`appearAfter`). Work
  that finishes inside the grace period never shows a spinner at all —
  a flash of one reads as a glitch rather than as loading. It takes no
  space while waiting, so nothing jumps when it arrives. Zero in the
  module's defaults; the APP theme sets 300ms, which covers every
  spinner in one line. Determinate shapes are never held: they have
  something to say from the first frame.
- **`onComplete` fires ONCE, on arrival at 1** — not on every frame the
  value spends there, and again only if it drops back and returns.
- **The countdown holds with the app.** It kept ticking in the
  background, so a five-minute clock came back already finished. Same
  fix as the banner's auto-dismiss. `paused` holds it by hand, and a
  new `duration` restarts it rather than rescaling it.

## Localization + reading direction

- **The default label is `AppNumbers.percent`**, which follows
  `Intl.getCurrentLocale` — so an Arabic locale gets its own digits and
  percent sign instead of `'${(v * 100).round()}%'` hard-coded in
  Western numerals with the symbol on the right.
- **The countdown pads through the number pattern**, not
  `padLeft('0')`, which would put an ASCII zero beside an Arabic-Indic
  digit: `١:07`.
- **Switching the app to Arabic was NOT enough on its own.** `S.load`
  sets `Intl.defaultLocale` to the language tag — `'ar'` — and plain
  `ar` formats in WESTERN digits. `AppNumbers.preferNativeDigits`
  (on) maps such a language to the variant that uses its own script,
  `ar → ar_EG`. Set it false for Western digits in every language.
  Which locales differ is not guessable and the list is verified, not
  assumed: see the doc on `AppNumbers`.
- **A bar fills from the START of the reading order**
  (`followTextDirection`, on). One that fills leftward in an RTL layout
  reads as DRAINING — it empties toward the side you read from. Turn it
  off where the axis is not the reading order: a wall-clock timeline, a
  chart axis, a scrubber whose artwork does not mirror.
  - `stepped` and `multiSegment` get this from `Directionality` for
    free, because they are `Row`s. `linear` and `gauge` are hand
    painted, and a `Canvas` has no reading direction — they are
    mirrored with a `Transform`.
  - The LABEL stays out of that transform. Mirroring it would reverse
    the text.
  - A ring and a droplet are never mirrored; they have no reading
    order, and Material does not mirror them either.

## Accessibility

- **The node carries the value, and the painted read-out is excluded.**
  It announced nothing at all before: the percentage was painted text
  inside an unlabelled box. `semanticLabel` says what is being measured
  — without it a reader hears a bare percentage attached to nothing.
- **An indeterminate bar has no value**, it has `CommonStrings.loading`.
  "0%" is a lie; nothing knows how far along it is.
- **A multi-segment bar reads out its PARTS** — "Photos: 35%, Videos:
  25%". A single percentage is true of the whole and says nothing about
  the thing it is showing, which is a breakdown.

## Showcase + tests

`/progress-showcase`, whose value slider is PINNED — every determinate
demo reads it, and a control that scrolls away is one you have to
scroll back to. (`ShowcasePage.pinnedHeader`, available to any page.)

Tests:

- `test/progress/global_progress_test.dart` — bag merge, resolution
  order, the app theme wiring, the palette colours, thresholds and the
  track that follows them, per-shape natural sizes, semantics, reduced
  motion, ticker lifecycle, the split label, RTL mirroring and lerp.
- `test/progress/progress_painters_test.dart` — the geometry, through a
  recording `Canvas` rather than goldens: a golden catches a change but
  will not say WHICH number moved, and drifts across platforms. Sweep
  angles, the stroke inset, the travelling indeterminate bar, tick
  spacing, the water level, and that the wave's clipper follows the
  same surface the painter draws.
- `test/progress/progress_adoption_test.dart` — the sweep.
- `test/localization/number_formatter_test.dart` — the native-digit
  mapping and its opt-out.

## Adoption

Material's own indicators read `ProgressIndicatorThemeData`, not
`GlobalProgressTheme`, so a rebrand that changes every bar in the app
leaves them untouched. Thirty-eight of them were swept out of the
module tree — media pickers, video controls, toast, list, wizard, PDF,
chip, dialog, buttons, the text field, the drop-down and the banner's
own countdown.

Guard: `test/progress/progress_adoption_test.dart`, over `lib/shared`,
`lib/core` and `lib/features`. Two exceptions, both allow-listed with
the reason AND checked to still say "by DESIGN" at the call site:

- **`lib/core/*`** — `core` must not import `shared/module`. That is
  the architecture, not an oversight, so the loading primitives and the
  build-lock screen keep Material's.
- **`debug_overlay/`** — a developer tool with its own palette that
  deliberately does not follow the app's theme.

## Known gaps

None outstanding.

## Overlap that is NOT duplication

- **`GlobalStepper` is a different thing.** It carries titles, content
  panels, continue/cancel and four orientations including a timeline —
  a form flow. `GlobalProgress.stepped` is a segmented BAR with
  optional captions. Do not merge them; a stepper that could not show
  content would be useless, and a progress bar that dragged a flow
  engine behind it would be absurd.
