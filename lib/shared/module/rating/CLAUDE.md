# CLAUDE.md — lib/shared/module/rating

`GlobalRating` — a row of stars. Read-only display, or tap / drag /
keyboard input at full, half or quarter precision.

```dart
GlobalRating(value: 4.5)                                 // display
GlobalRating(value: v, onChanged: (n) => setState(...))  // input
```

Omitting `onChanged` IS display mode: it drops the pointer handlers, the
focus node and the semantic actions in one move, so a read-only rating
cannot be dragged, tabbed to, or nudged by an assistive gesture.

## Contracts

- **Style is the themeable bag `RatingStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once per
  build by `style.resolve(context)` into a `ResolvedRatingStyle` whose
  themed fields are non-null. Build code reads `rs.ratedColor`; there
  are no `?? Colors.amber` ladders left at use sites.
- **Resolution order**: `caller > GlobalRatingTheme.style >
  RatingStyle.defaults`, then colours from `context.<group>Colors`.
- **`RatingStyle.defaults` carries NO colours.** A filled star takes
  `statusColors.warning` — the palette's own amber — so it tracks role,
  brightness and saturation. It was `Colors.amber`, the same yellow on
  every palette an app might ship.
- **An empty star is an OUTLINE, not a faded fill.** It used to be
  `outline @ 25%`, which vanished against the coloured card ratings
  usually sit on.
- **`enableHaptic` defaults to TRUE**, matching every other interactive
  module. It defaulted to false, so the app's own haptic preference
  never reached a star.
- **Every hard-coded number lives in `RatingDefaults`.** Values an app
  would rebrand belong in `RatingStyle`; geometry that only changes when
  the module changes stays in `RatingDefaults`.

## Gotchas

- **A POINTER ceilings, a keyboard rounds — and they are different
  questions.** Star three spans 2.0–3.0, so rounding a tap at 2.2 gives
  TWO stars: the user presses the third star and watches the second one
  light. `RatingPrecision.snapUp` is what pointers use, and at half
  precision it hands back the star's left half then its right, which is
  the whole point of half stars. `snap` (nearest) is for values nobody
  pointed at — a keyboard step, an incoming value.
- **The row is MIRRORED in RTL, and a raw pixel offset does not know
  that.** `Row` lays star 0 at the right edge in Arabic, so
  `localPosition.dx` counts the stars backwards: tapping the first star
  a reader sees scored five. `_valueAt` flips the offset against the
  measured row width. Guard: "the row is MIRRORED in RTL" — the same
  physical point scores 1 in LTR and 5 in RTL.
- **The width it flips against excludes the trailing gap.**
  `widthFor(count)` is `count * size + (count - 1) * spacing`; using
  `count * itemExtent` drifts by a whole star across five.
- **Arrow keys follow the reading direction too.** Right-arrow raises
  the value in LTR and LOWERS it in RTL, or the keys walk the opposite
  way to the stars they are moving through.
- **The focus ring is nearly opaque** (`RatingDefaults.focusRingOpacity`
  on `primaryColors.primary`). It was the rated colour at 12% — a wash
  of amber over amber stars, which is invisible. Same finding as the tab
  bar's focus overlay, and the reason both are deliberately louder than
  Material's default. Find it by `kRatingFocusRingKey`.
- **The value is not the finger.** A drag updates the stars live but
  calls `onChanged` ONCE, on release — a rating wired to a network
  write would otherwise fire five times crossing the row.
- **Semantics is one slider, not five icons.** The stars sit under
  `ExcludeSemantics`; the row exposes `slider`, `value`,
  `increasedValue` / `decreasedValue` and the increase / decrease
  actions. A whole value is formatted as `4`, not `4.0` — a screen
  reader spells the decimal out.
- **Strings are localized** through `RatingStrings` (`rating_` ARB
  prefix), not built in English at the call site.
- **A disabled row FADES; a disabled tab recolours.** The opposite call
  to `tab_bar`, and deliberate: a star has no badge or label inside it
  to render unreadable, and `disabledOpacity` is a style knob. The count
  label sits outside the fade, since it is still information.
- **The hover wash and focus ring scale WITH the star**
  (`hoverRadiusFraction` / `focusRadiusFraction`). A fixed radius looks
  wrong at one end of a 16dp–64dp range or the other.
- **A custom `halfRatedWidget` only serves an exact half.** Any other
  fraction goes through `_FractionClipper`, which cannot know what a
  caller's glyph should look like at 0.3.

## Motion

Four moving parts, each a knob on `RatingStyle`, each skipped WHOLE
under reduced motion rather than shortened:

| knob | default | what it does |
| --- | --- | --- |
| `selectPop` | on | the star you pick overshoots and settles |
| `fillCrossfade` | on | the rated glyph fades in over the outline |
| `dragLift` | on | the star under a dragging finger lifts |
| `staggerFill` | **off** | a rising value fills one star after another |
| `staggerClear` | **off** | a falling value empties from the last star back |

- **The pop keys on the REQUEST, not on the value.** `_requested` is
  set when this widget's own tap, drag or key press asks for a value,
  and cleared in `didUpdateWidget` once that exact value comes back. A
  value arriving any other way — a server, a parent, a list scrolling
  into view — settles quietly. Keying on "the value changed" instead
  makes a list of fifty ratings pop every row as you scroll past it,
  which is the version of this idea that gets ripped out a week later.
  Guard: "a value that ARRIVES does not celebrate".
- **It also only pops if the value actually LANDED.** The widget is
  controlled, so a parent that ignores `onChanged` leaves the stars
  where they were — popping anyway would confirm something that did not
  happen.
- **The pop is asymmetric**: up fast on `easeOut`, back slower on
  `easeOutBack` (`popRiseFraction` / `popFallFraction`). Even weights
  read as a twitch.
- **The outline is always painted and the fill fades in over it.** The
  glyph used to be SWAPPED on the frame the value landed, so only the
  scale animated and the star itself snapped. `_RatingIcon` is still
  stateless — it renders a fraction and knows nothing about how that
  fraction arrived; `_StarSlot` owns everything that moves.
- **A stagger never delays a live drag.** The wave is for a value that
  arrives; delaying the stars under a moving finger makes the row lag
  the gesture. `_buildStars` passes `Duration.zero` while `_isDragging`.
  Guard: "never delays a live drag".
- **Clearing runs BACKWARDS** (`staggerDelay(reversed: true)`), decided
  by comparing old and new value in `didUpdateWidget`. Forward, an
  emptying row reads as a second and smaller rating.
- **Both staggers default OFF**, and should stay off for anything that
  renders in a list. They are for a "rate us" prompt, where the row is
  the only thing on screen. `/rating-showcase` → Motion has both.

## Known gaps

- **The pointer maths assumes a uniform row.** `itemExtent` is
  `size + spacing`, so a caller who wraps individual stars in extra
  padding will find taps land a fraction off. Style the row through
  `RatingStyle`, not around it.
- **Hover is per-star, selection is per-row.** Hovering star four
  washes only star four, rather than previewing the four-star value the
  way some review widgets do. Deliberate: the preview belongs to the
  drag, which shows the real value live.

## Showcase + tests

`/rating-showcase`. Tests: `test/rating/global_rating_test.dart` (snap
vs snapUp, tap position, RTL mirroring both for pointer and keyboard,
drag commit, display + disabled modes, focus ring, bag merge, resolution
order, palette colours, reduced motion, lerp, semantics, and the four
motion knobs including the request-vs-arrival distinction).
