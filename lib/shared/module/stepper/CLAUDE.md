# CLAUDE.md — shared/module/stepper

`GlobalStepper`: one list of steps, four layouts, and a keyboard that
can walk it.

```
stepper/
  stepper_models.dart     — GlobalStepItem + the four enums
  stepper_style.dart      — StepperDefaults · StepperStyle · ResolvedStepperStyle
  theme/stepper_theme.dart— GlobalStepperTheme + StepperStyle.resolve(context)
  global_stepper.dart     — the widget, the four layouts, the painters
```

## The bag

- **`StepperStyle` is all-nullable**, with the floor in `StepperDefaults`
  and the app-wide layer in `MyGlobalStepperTheme.build(tokens:)`
  (`core/theme/widget_themes/global_stepper_theme.dart`, wired in
  `theme.dart`). Order is `caller > GlobalStepperTheme.style >
  StepperStyle.defaults`. Presets: `bare`, `prominent`.
- **It read `Theme.of(context).colorScheme` in nine places** and took
  the indicator's interior from `scaffoldBackgroundColor`, so a rebrand
  moved the app and left the stepper on Material's seed. Every colour
  now resolves from `context.primaryColors` / `textColors` /
  `backgroundColors` / `statusColors`.
- **`GlobalStepper.style` is nullable.** It used to default to
  `const StepperStyle()`, which is a caller bag that answers nothing —
  harmless only because nothing was themeable.
- **`connectorColor` stays NULLABLE after resolution.** "Unset" is a
  real answer: with no colour, each connector takes the colour of the
  steps it joins, which is not one colour. Set it and BOTH parts take
  it — the track at `connectorTrackOpacity`, so a coloured line reads
  as one line rather than a coloured half joined to a grey one.
- **`surfaceColor` is the PAGE, not the card.** The connector runs
  behind the indicator; an interior that does not match what is behind
  it draws the line straight through the middle of the circle. Put a
  stepper on a tinted card and this is the one field to set.
- **`indicatorExtent` (`indicatorSize × activeIndicatorScale`) is what
  every layout reserves**, not `indicatorSize` — the active step is
  drawn 12% larger, and a row sized to the resting circle jumps as the
  active one moves through it.

## The keyboard

- **A stepper with no `onStepTapped` is a REPORT.** It takes no focus,
  builds no `FocusableActionDetector`, and announces itself as text.
  Making a progress read-out focusable puts N presses between a
  keyboard reader and the form under it.
- **TAB reaches the run ONCE, arrows walk it** — a roving tab stop, the
  way a radio group behaves. `skipTraversal` is set per node each
  build: the tab stop is the CURRENT step, or wherever the arrows last
  left the keyboard.
- **Arrows move the keyboard, NOT the step.** Enter and Space commit.
  Moving the step on arrow would fire `onStepTapped` for every step
  passed through, and in a wizard each of those is a page transition.
- **The horizontal run MIRRORS in Arabic**; the vertical, timeline and
  alternating ones answer to up/down and do not. Only a horizontal axis
  has a reading direction.
- **But every vertical LAYOUT mirrors**, and its connectors are
  `PositionedDirectional`. The indicator column is placed by a `Row`,
  so in Arabic it moves to the right — and each connector used a raw
  `left`, leaving the lines on the left of the card while the circles
  they joined sat on the other side. Timeline's timestamp gutter and
  alternating's half-width offset are directional for the same reason.
- **Home / End jump to the ends**, skipping disabled steps like the
  arrows do — a disabled step has no node at all.
- **The focus ring paints for KEYBOARD focus only**
  (`onShowFocusHighlight`), sits OUTSIDE the circle in a `Stack` that
  does not clip, and is always in the tree with only its colour moving.
  Same rule the swipe button and the toggle group follow: a ring that
  adds a wrapper changes the tree shape at that slot.
- **A step's TITLE taps but does not focus** (`_tapOnly`). One
  `FocusNode` attaches to one widget; two focusables per step would
  make the arrows walk half-steps and a screen reader read every step
  twice.
- **Every step is ONE semantics node** — "Step 2 of 4, Details, current
  step" — built from `StepperStrings`. There was no `Semantics` in the
  module at all.

## Layouts

| Orientation   | What it is for                                            |
| ------------- | --------------------------------------------------------- |
| `horizontal`  | The checkout run. Titles under the marks.                 |
| `vertical`    | A form. Content and actions belong to the ACTIVE step.    |
| `timeline`    | A history. Timestamps in a left gutter.                   |
| `alternating` | A wide, sparse story. Sides swap down the run.            |

- **`StepperConnectorStyle.none` now draws nothing.** It used to fall
  through to the solid branch, so the one value whose whole job was to
  remove the line was the one that did not.
- **`connectorProgress` reports something CONTINUOUS** — an upload, a
  delivery — rather than a step someone is standing on. Keyed by the
  index of the step BEFORE the connector.
- **`sequentialAnimation` only bites on a jump of more than one step**,
  and the connectors overlap at `sequentialOverlap` so the fill reads
  as one motion rather than a queue.
- **The sequential delay is a cancellable `Timer`.** All three helper
  widgets used a bare `Future.delayed`, which outlives the widget: a
  stepper torn down mid-jump left a pending callback the test binding
  reports and a real app pays for.
- **`currentStep` may point PAST the end**, and that is the
  everything-is-done state — every step reads as completed. Comparisons
  use the raw number; nothing INDEXES with it (`_isReachable`
  bounds-checks). One shared control driving several steppers of
  different lengths hits this on every build.
- **A connector meets the indicator's RESTING edge**, and
  `connectorInset` moves it: positive opens a gap, negative tucks it
  under. Zero by default — the line touches the circle, and the ACTIVE
  circle, drawn 12% larger, covers the last two points of it, which is
  what makes a run read as one line with a bead on it. The lane itself
  is centre-to-centre, so `connectorInset: -indicatorSize / 2` is the
  old behaviour: half a circle's worth of line under every indicator,
  invisible behind an opaque one and drawn straight through a
  translucent `stepBuilder` one.
- **One knob, two measurements.** `connectorStart` is from the
  indicator's CENTRE (horizontal runs, which lay out centre-to-centre);
  `connectorTop` is from its TOP (vertical, timeline, alternating,
  which position from the row's top edge).
- **`_AnimatedCustomConnector` expands its `Stack`** (`StackFit.expand`).
  It defaulted to loose constraints and `topStart`, so a fitted custom
  connector shrank to its natural width against the LEFT edge of the
  indicator column instead of running down the middle.
- **`collapsible` folds a FINISHED step's subtitle and content away**,
  never the active one — that is the step being worked on.
- **`scrollable` FOLLOWS the active step.** However the step moved — a
  tap, a caller's Next button, the keyboard — the run centres on it, so
  the steps either side stay visible and it still reads as a run. It
  reveals on the FIRST frame too, for a stepper that opens mid-run: a
  resumed form, a deep link into the middle of a flow. The offset is
  measured from the START of the scroll view, which is the right edge
  in Arabic, so one number works both ways. The controller is built
  lazily — most steppers are not scrollable.

## Reader settings

- **Reduced motion is NOT `style.animated`.** That flag is what the
  CALLER asked for; `MediaQuery.disableAnimationsOf` is what the READER
  did. Either one zeroes every duration in the tree, which also zeroes
  the sequential connector delays (they are multiples of it) and turns
  the scrollable run's reveal into a jump. It is read in `build`, not
  `initState` — an inherited read cannot happen there.
- **Digits go through `AppNumbers`.** The number inside an indicator
  was a raw `'${index + 1}'`, so Arabic read `1 2 3` while every other
  number on the page read `١ ٢ ٣`. The semantics string was always
  fine; only the painted glyph was wrong.
- **One step, one feel.** A step's title and its indicator both commit
  through `_activate`, so both buzz. The title used to call the
  callback directly and skip the haptic.

## Who else uses it

`GlobalWizard` builds one for its `numbered` and `vertical` variants,
so the theme layer reaches those too. Nothing else in the app draws a
step run.

- Showcase: `/stepper-showcase`. The step control is the page's
  `pinnedHeader`, because every demo reads the same step and a control
  that scrolls away can only be used by scrolling back to it.
- Guards: `test/stepper/stepper_style_test.dart` (the three layers, the
  palette, the snap), `test/stepper/global_stepper_test.dart` (taps,
  the keyboard, semantics, the four layouts, teardown).
