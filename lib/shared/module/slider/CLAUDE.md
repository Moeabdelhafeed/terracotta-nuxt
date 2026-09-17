# CLAUDE.md — `slider/`

One slider, two shapes: `GlobalSlider` takes a value,
`GlobalSlider.range` takes two.

```
global_slider.dart   — the widget, the label / badge / end chips, the haptics
slider_style.dart    — SliderDefaults / SliderStyle / ResolvedSliderStyle
slider_models.dart   — the tick + indicator sub-bags, and SliderMath
slider_shapes.dart   — buildSliderTheme + the five custom Material shapes
theme/slider_theme.dart — GlobalSliderTheme + `style.resolve(context)`
```

App-wide defaults: `MyGlobalSliderTheme.build`, wired in
`lib/core/theme/theme.dart`.

## The bag

`caller style: > GlobalSliderTheme.style > SliderStyle.defaults`, then
the colours from the palette. Presets: `bare`, `prominent`, `stepped`.

- **It was HALF-nullable.** Only the colours could be omitted; every
  size carried an inline default, so a house that wanted a thicker
  track had to say so at every call site and could never change it
  centrally. There are 34 of those call sites.
- **Colours are absent from `defaults` on purpose** — they resolve
  from `context.primaryColors` / `textColors` / `backgroundColors` at
  build time so they track role, brightness and saturation. The module
  read `Theme.of(context).colorScheme` for every colour and wrote
  `Colors.white`, `Colors.black` and `Colors.grey` in five painters:
  a rebrand moved the app and left the slider where it was, and a
  gradient thumb's inner ring stayed white on a white card.
- **`MyGlobalSliderTheme` sets only SIZES**, from `AppTokens`, so a
  slider rounds like the rest of the app and follows it into a wider
  window.
- **The sub-bags are nullable too.** `SliderTickStyle` and
  `SliderIndicatorStyle` resolve into `ResolvedSliderTickStyle` /
  `ResolvedSliderIndicatorStyle` alongside the parent, so a theme can
  set the tick shape and a call site can still recolour it.
- **`showTicks` is separate from `tickStyle`.** `tickStyle != null`
  was the only switch, which meant a house that styled ticks put them
  on every slider in the app with no way to say no. Unset, it follows
  the style; set, it wins.
- **The resolved bag is materialised at the top of `build`, on the
  state, and is NOT `late`** — a painter can be asked for its
  preferred size before the first frame, and a `late` field throws
  there. `ResolvedSliderStyle.fallback` is what it holds until then;
  nothing is painted from it.

## The arithmetic is pure

`SliderMath` is plain functions in the models file. None of it could be
tested where it was — inline in six `paint` methods that need a
laid-out `RenderBox` and a live `PaintingContext`. Guards:
`test/slider/slider_math_test.dart`.

- **`activeSpan` and `tickIsActive` are the RTL fix.** All six paint
  methods DECLARED a `textDirection` and read it in NONE. A gradient
  track took the left edge as its origin unconditionally, so an Arabic
  slider at 25% drew its fill on the side the value was not; a tick's
  `center.dx <= thumbCenter.dx` marked every passed tick as unreached
  and every unreached one as passed.
- **A range's thumbs come back in VALUE order**, so naming one "start"
  says nothing about which side of the screen it is on — the range
  track takes its span by position.
- **`divisionIndex` ROUNDS**, so a finger crossing the width of one
  step ticks once. It is null on a continuous slider, which is what
  keeps a drag from buzzing.

## What it says out loud

- **There was no `Semantics` anywhere in this module.**
- **One group node**, so a reader hears the label, the value and the
  ends as one control rather than as four loose strings.
- **The badge and the end chips are `ExcludeSemantics`.** Material's
  own slider node already carries the value and the range; a badge
  saying it again is the same number twice. So is the visible label —
  the group names the control, and leaving the `Text` readable too had
  a reader say "Volume, Volume".
- **`semanticFormatter` is separate from `valueFormatter`.** Without
  it a screen reader read Material's raw value — "0.5" for a slider
  whose badge said "50%". It falls back to the visible formatter,
  which is right far more often than not.
- **`semanticLabel` names a slider with no visible label** — a seek
  bar, a filter row.

## Segments

`segments:` is a list of boundary VALUES. Each span between two of them
is drawn as its own rounded bar, so a track with acts, tiers or
chapters reads as several sliders handing the thumb between them.

- **It came out of the video player**, where it was the seek bar's
  private chapter track. Painting gaps ON TOP of a finished track was
  the first attempt there and it stayed a MARKED track — the pieces ran
  together under the thumb, and a notch two points wide read as a
  rendering fault. `SliderSegmentedTrackShape` replaces the track
  instead. `video_seek_bar.dart` now imports it and is 115 lines
  shorter.
- **The boundaries are on the WIDGET; the gap is on the BAG.** Where
  the second act starts is a property of the content and a theme cannot
  know it. How wide the seam is, it can.
- **The player's copy was pinned left-to-right** — a TIMELINE does not
  mirror, because time runs one way and every player that ships in
  Arabic leaves the bar running the same way. An ordinary slider is a
  VALUE and does mirror, so the shape takes a direction and the seek
  bar passes `rtl: false`.
- **A seam at either end is not a seam**, and one outside the bounds is
  dropped. Otherwise a caller passing `min` gets a zero-width bar and a
  gap where the track should start. Duplicates collapse; an unsorted
  list is sorted.
- **Half a gap comes off each side of a boundary, and none off the
  outer ends**, so the track still starts and finishes where the reader
  expects.
- **No interior seam means no custom shape at all** — one bar is not a
  segmented track, and asking for the shape would only cost a painter.
- **It has no `getPreferredRect` of its own.** `BaseSliderTrackShape`
  computes the rect Material positions the thumb and the TICK MARKS
  against, and a segmented track whose seams disagree with its own
  ticks is worse than no seams.
- A gradient still spans the WHOLE track under the segments, so a value
  keeps its colour as the thumb moves past it.

## The secondary track

`secondaryValue:` — loaded, cached, downloaded: reached by something
other than the reader.

- **Material has always had `secondaryTrackValue`** and this module
  never passed it on, so a buffered-progress bar had to be a `Stack` of
  two widgets. It is clamped like the primary.
- The segmented shape reads Material's own `secondaryOffset` rather
  than a fraction of its own, so the two agree by construction. The
  video player's copy computed it separately.

## Step labels

`stepLabels:` — one word per step, under the track.

- **It needs `divisions`, and one more label than there are
  divisions** — a 1–5 slider with four divisions has five steps.
  A mismatched count is IGNORED rather than drawn wrong: three words on
  four steps has no right answer, and drawing three of them silently
  drops one the caller wrote.
- **It is not a `spaceBetween` Row, and it is not a Stack either.**
  With `n` steps the row is `n - 1` tick spacings wide, so the two END
  cells take HALF a spacing (`flex: 1`) and the middle cells take a
  whole one (`flex: 2`): every middle cell's CENTRE is a tick, and the
  ends finish flush with the outermost ones. Exact, self-sizing, and
  it mirrors because a `Row` does.
- **The first attempt was a `Stack` of boxes centred on each tick and
  clamped inside the row.** Clamping moved the BOX and left the text
  centred in it, so "Draft" and "Master" were dragged inward until
  they collided with their neighbours — reported from a screenshot.
  There is nothing to clamp in the flex version. Guard: `no two labels
  overlap`, which fails with the exact message the screenshot showed.
- **A labelled step ANNOUNCES its word** — "Great", not "5" — because
  the word is what the reader is choosing between. An explicit
  `semanticFormatter` still wins.
- The fraction is direction-free and only the placement mirrors, which
  is the same split the track shapes make.

## The leading slot

`leading:` is a widget drawn before the label, inside the header row.

- **It belongs to the header, not to whatever wraps the slider.** The
  commons put it on a line of its own first, and it floated above the
  label with nothing beside it whenever there was no second line to
  share that row with.
- **It is decorative**, so it is wrapped in `ExcludeSemantics` — a
  speaker glyph next to the word "Volume" says the word "Volume".
- **It dims with the label**, rather than staying at full strength
  beside a greyed-out one.
- The header now draws for a slider that has a `leading` and no
  `label`.

## An out-of-range value is CLAMPED

- **It used to assert**, and the assert fires in the CALLER's build —
  so one slider took the whole page red rather than showing a wrong
  number. The showcase found this the first day: four cards shared one
  state field across four different ranges, and dragging the 0–10 one
  put 6 into a 1–5 slider.
- A range is clamped and **ORDERED** on the way through, because
  `RangeSlider` asserts its own start is not above its end — the same
  fatal place.
- `min < max` and a positive `divisions` DO still assert: neither has
  a sensible thing to clamp to.

## Haptics

- **It fired none at all.** `enableHaptic` is on the bag and defaults
  ON, like every other interactive module here.
- **It ticks per DIVISION, never per pixel.** The state remembers the
  last step it was on; a continuous slider never ticks, because a
  haptic on every frame of a drag is a buzz rather than feedback.
- **A range ticks for the end that MOVED.**

## Numbers

- **Through `AppNumbers`**, which maps `ar` onto the variant that
  actually emits Arabic-Indic digits. It was `toStringAsFixed`, which
  writes ASCII whatever the locale is — so an Arabic slider counted
  1, 2, 3 under a right-to-left track.
- **A discrete slider formats to 0 places, a continuous one to 1.**
- **The value and min/max styles use tabular figures.** A proportional
  `1` is narrower than a `0`, and the badge jittered under a dragging
  finger.

## Where the track starts and finishes

`SliderTrackGeometry` is the ONE rect every part of a bar is measured
from, and `style.trackEndInset` sets it.

- **It is ZERO by default.** The track runs the full width it is given
  and the thumb overhangs into whatever the slider sits in — which
  every slider in this app has room for, since they all sit in a padded
  card or a padded row. Reserving the thumb's radius at both ends spent
  24 points of a 300-point slider on empty space at the two places a
  reader is most likely to aim.
- **A slider whose parent CLIPS wants
  `SliderTrackGeometry.thumbSafeInset(thumbRadius)`**, or the thumb is
  cut in half at the ends. Anything larger insets the whole track.
- **The track shapes, the tick marks, the step labels AND the end
  chips all read the same number**, so moving it moves all of them
  together. The chips were padded by a fixed spacing token, which
  agreed with the track's inset only by accident and stopped agreeing
  the moment either moved.

- **Material's inset is the OVERLAY's, not the thumb's.**
  `BaseSliderTrackShape` reserves `max(overlayWidth, thumbWidth) / 2` at
  each end; the overlay is the ripple and is deliberately bigger. At
  the house sizes that is 16 points a side for a thumb that needs 10 —
  dead space at both ends of every slider in the app, which is how it
  was reported.
- **It was ASYMMETRIC too** — 14 at one end and 16 at the other — and a
  GRADIENT track, which rolled its own rect from `thumbRadius + 2`, sat
  6 points wider than the plain one beside it.
- **So a plain track is ours as well.** `_PlainTrackShape` draws what
  Material's rounded one draws and exists only to own the rect;
  everything else — gradient, segmented, range — takes the same one.
  The tick marks follow, because Material positions them against
  whatever rect the track shape returns.
- **`SliderThemeData.padding` is NOT the way to do this**, though it
  looks like it: setting it makes `BaseSliderTrackShape` add no inset
  at all, and the compensating `Padding` is applied around a render
  object that does not fill it — the track came out flush with the box
  and 2 points OUTSIDE it on one side.
- **The step-label row uses the same inset**, which is the only reason
  the words sit under the marks they name. Guard:
  `test/slider/track_geometry_test.dart` → "every word sits under its
  own tick".
- **The segmented shapes take an `endInset`, not a thumb radius.** The
  video seek bar reserves NOTHING at its ends: the timeline runs the
  full width so it lines up with the clock and the controls under it,
  and the thumb overhangs into the bar's own inset instead.

## The shapes

`buildSliderTheme` is the one bridge between the bag and Material's
`SliderThemeData`, and both the single and the range slider go through
it.

- **The two custom indicators share a base.** They were two copies of
  the same 40 lines with the arrow bolted onto one.
- **The indicator is CLAMPED inside the slider's box**, and the
  bubble's arrow points at the THUMB rather than at the body's middle
  — the body has to move near the ends, and a centre-anchored arrow
  left it pointing at nothing.
- **A gradient indicator draws its body and its label in ONE layer**,
  so the fade takes both. Fading them separately let the label show
  through the body.
- **The gradient shader spans the WHOLE track**, not the filled part,
  so a given value keeps its colour as the thumb moves past it.
- **The thumb's ring is `textColors.onPrimary`**, not `Colors.white` —
  a gradient running anywhere near white erased it.

## The commons

`lib/shared/common/selection_fields/slider/` — app-owned wrappers, the
same shape `checkbox/`, `switch/` and the rest have. That folder had
five subdirs and no `slider/`, so every settings page wrote its own row
and every filter sheet its own range, each with its own English label.

- **`SettingsSliderRow` merges `SliderStyle.bare`**, because the
  settings LIST is the card and a card inside a card is a frame within
  a frame. A caller's `style:` still wins — it is merged over, not
  under.
- **`SettingsRangeRow` is a separate widget, not a flag.** The value
  type changes: one takes a `double` and reports one, the other takes
  a `RangeValues`. A row that could be either would hand every caller
  a nullable of each.
- **`SliderFormField` is the gap that was actually load-bearing.**
  Every other selection control in that folder has a `FormField` and
  the slider did not, so a "budget must be at least 100" rule lived in
  the submit handler — where the reader finds out after pressing the
  button rather than while dragging.
- **`PlaybackSpeedSlider`'s rungs are evenly spaced on the TRACK, not
  in value.** 0.5× to 1× matters as much as 1.5× to 2×, and a linear
  track gives the fast half twice the room. The widget's own value is
  an INDEX and the callback undoes it.
- **`TextScaleSlider`'s bounds are `AppTypographyScale`'s**, not a
  guess — a slider that could ask for 2.0 would be asking for a layout
  the app has never been laid out at.
- **Zero means something in two of them.** `VolumeSlider` at 0 says
  "Muted" and swaps its glyph; `RatingFilterSlider` at 0 says "Any",
  because a list that silently required one star would hide everything
  unrated. Both say it in the BADGE, where the number would have been
  — "Muted" started life as a description line under the track, which
  is a footnote rather than a readout.
- **The icon rides the slider's own `leading`**, so it sits before the
  label; `description` is the line UNDER the whole row, which is where
  `SliderFormField` puts its helper and error too.
- **`DistanceRadiusSlider` changes the WORD, never the number.**
  Converting km to miles behind the caller's back would report a
  radius it never asked for.
- Strings: `SliderStrings` (`slider_` ARB prefix, en + ar). Every
  wrapper registers a locale dependency in `build`, like the rest of
  the family — `Tr`/`S` reads are static, so a const-constructed
  instance would otherwise freeze its language until hot reload.

## Three more shapes

```
global_slider.dart          — the bar, and `GlobalSlider.vertical`
global_circular_slider.dart — the ring
circular_slider_math.dart   — CircularSliderGeometry + CircularSliderMath
global_trim_slider.dart     — a span over content you can SEE
```

### Vertical

- **Material ships none**, so the track is the horizontal one turned a
  quarter — which keeps the drag maths, the divisions, the value
  indicator and the semantics actions rather than reinventing four
  things.
- **Pinned LTR inside the rotation.** A slider mirrors under
  `Directionality.rtl`, and a mirrored track turned on its side runs
  DOWNWARDS — an Arabic reader would drag up for less. Up is up in
  every language, the same argument the video timeline makes.
- **BOTH axes are bounded.** `RotatedBox` hands its child the parent's
  constraints FLIPPED and a `Slider` fills the height it is given, so
  with only a height set the "vertical" slider came out 778 points
  across. `extent` is a LENGTH for the same reason: rotating a widget
  does not rotate its constraints.
- **Max at the TOP.** A column reading 0 at the top says the drag goes
  the other way.

### Circular

`CircularSliderGeometry(startAngle:, sweepAngle:)` — presets `top` (a
full turn from twelve), `gauge` (a gap at the bottom), `arc` (a half).
A NEGATIVE sweep counts anticlockwise. Slots: `centerBuilder`,
`thumbBuilder`, `trackMarks`, `segments`.

- **A range's pair is a RECORD, not `RangeValues`.** That type asserts
  its start is not above its end, and 22:00 to 06:00 is the eight hours
  THROUGH midnight rather than the sixteen the other way.
  `spanContains` and `spanLength` wrap on a closed dial.
- **Thumb picking is by ANGLE, not by value.** 23:30 and 00:30 are half
  an hour apart and nearly a whole scale apart numerically — picking by
  value grabs the wrong thumb every time a range straddles the top.
- **Which thumb is decided ONCE, on touch-down.** Re-deciding each
  frame makes the two swap under a fast drag: the moment one passes the
  other, "nearest" is the one being left behind.
- **It wins the gesture ARENA on the ring, and declines it everywhere
  else.** A plain `GestureDetector` loses a vertical drag to an
  enclosing scroll view, and the dial went dead exactly where a reader
  is likeliest to grab it — near the top and bottom, where the tangent
  runs the way the page scrolls. Claiming the whole square box instead
  would pin a page that has a dial in it, so `_RingPanRecognizer`
  accepts on the track and rejects in the hole, the corners and the
  gap.
- **A touch in the hole is ignored** — that is where the readout lives.
  The band a finger may land in is the ring plus its thumb, never less
  than `SliderDefaults.ringTouchSlop`; asking for it within 28 points
  of the CENTRE-LINE meant the outer edge of the thumb was already
  outside.
- **Both key axes step it** — up or right is clockwise, down or left is
  anticlockwise, Home and End are the ends. It does NOT mirror: a dial
  turns the way a clock does in every language.
- **A closed dial WRAPS under the keyboard.** Midnight is one step past
  23:45, and stopping there puts the early hours out of reach without
  going the long way round. An open one clamps.
- **A range has two thumbs and ONE focus node.** Space, Enter or Tab
  swaps which the arrows move, and the focus ring says which that is —
  a second traversal stop inside a control the reader thinks of as one
  thing is worse.
- **`Semantics` OUTSIDE `Focus`.** A `Focus` introduces a node of its
  own; with it on top, the dial's label, value and actions were a level
  down where nothing looked for them.
- **The segment gap is in POINTS, converted to radians against the
  radius** — a fixed angle is a hairline on a small dial and a canyon
  on a big one.
- **The fill is drawn PER SEGMENT**, intersected with each arc, so
  every filled piece gets the same round cap the empty one under it
  has. It used to be drawn whole and the seams cut back out of it with
  `BlendMode.clear` — which took the filled segments' CAPS with them,
  so a segmented ring's fill ended flat and short of its own arc. The
  clearing pass and its `saveLayer` are both gone; `_paddedSpans` and
  `_fillSpans` are two lists of intervals and the paint is their
  overlap.
- **A wrapped range is TWO intervals**, not one — 22:00 to 06:00 is the
  eight hours through midnight, and as a single interval it is the
  sixteen the other way.
- **A `trackMark` inside a SEAM is dropped.** Marking the same values
  the ring is cut at is the first thing anyone tries, and every dot
  then sat dead centre of a gap looking like debris — a mark with no
  track under it is a dot floating in a hole.
- **`centerBuilder` and `thumbBuilder` dim with the ring.** The painter
  fades what IT draws; a readout at full strength inside a greyed-out
  dial reads as the one live thing on it. The trimmer's `background`
  does the same.
- **A ROUND cap hangs half the ring's thickness past the arc it
  finishes**, so every seam's two caps grew towards each other until
  they met and the gaps closed up — a "segmented" ring with no visible
  seams. Each arc is pulled back by the overhang so the CAP lands on
  the boundary. Guard: `a ROUND cap does not close the gap it sits
  beside`, which measures the sweep against the gap AND both caps —
  the first version only checked it was under a quarter turn, and the
  bug survived it.
- **On a CLOSED dial the first and last boundary are the SAME point**,
  so the seam between them is interior like any other. It was the one
  seam with no gap at all, and its two caps sat on top of each other.

### Trim

`GlobalTrimSlider` — a span over a `background` the caller draws: a
filmstrip, a waveform, a night's sleep stages, a chart.

- **What makes it a different widget from `GlobalSlider.range`** is
  that the track is CONTENT. The handles frame it, a scrim dims what
  falls outside, and the background is inset by the handles so nothing
  the reader is trimming sits underneath one.
- **`minSpan` PUSHES the other end rather than refusing.** At the floor
  a trimmer should keep moving; one that goes dead reads as broken.
  `maxSpan` caps the same way, from whichever end did not move.
- **Crossing over SWAPS the handles.** An inverted pair from the caller
  is ordered on the way in.
- **Dragging the middle slides the whole window, keeping its LENGTH**,
  and stops at the ends instead of being squashed against them.
- **A tap inside the span scrubs the playhead** when there is one —
  which is what a tap on the film means in every editor — and the
  playhead cannot leave the span.
- **Haptics fire at a LIMIT only**: an end, `minSpan` or `maxSpan`.
  That is the one thing a trimmer has to say through a fingertip.
- **The frame is four SOLID pieces — two bars and two rails — never
  one rectangle with its middle punched out.** `BlendMode.clear` does
  not respect widget layers: the background sits in the SAME layer as
  the painter, so clearing the middle ERASED the film the reader is
  trimming and left a white hole where the selected frames should be.
- **A pill says what is changing, while it changes.** A handle says its
  own value, the whole span says its LENGTH, the playhead says where
  playback is — a trimmer with no readout is a picture of a decision
  the reader cannot check. It rides inside the span rather than above
  the strip, because a trimmer is usually the bottom of an editor and a
  bubble on its top edge lands on the frame being looked at.
  `showDragReadout: false` turns it off.
- **Arrows move the FOCUSED handle**, Space or Tab cycles start → end →
  span → playhead, Home and End take it to the ends. Three or four
  traversal stops inside one strip is not navigation.
- **A drag hands the arrows the handle it just moved** — otherwise a
  reader who drags one end then reaches for the keyboard moves the
  other.
- **Left is EARLIER whatever the language.** The strip is a TIMELINE
  and the content under it does not mirror, which is the argument the
  video seek bar already makes.
- **The span rules are a PURE resolver.** The semantics node has to say
  what an increase WOULD read before the reader commits to it, and the
  framework asserts that a node carrying `value` and an increase action
  carries `increasedValue` too.
- It claims its own arena for the same reason the ring does: a trimmer
  lives inside something that scrolls.

## Holding a key

`KeyRepeater` (`key_repeater.dart`), used by the ring and the trimmer.

- **Flutter forwards a `KeyRepeatEvent` only when the PLATFORM repeats,
  and it does not on every one** — so a held arrow gave exactly one
  step and then nothing, which reads as the control being stuck.
  Driving the repeat here means the same behaviour everywhere.
- **The platform's own repeat is SWALLOWED**, or every step would fire
  twice where the platform does send them.
- **It waits 400ms before the first repeat**, so a deliberate tap fires
  once.
- **It ACCELERATES, capped.** Crossing a three-minute timeline one
  fiftieth at a time is a long hold; a constant rate makes the fine end
  useless or the coarse end unreachable.
- **Losing focus stops it.** Nothing is left to hear the key-up, so it
  would repeat for ever.
- The BAR keeps Material's own key handling, which goes through
  `Actions` and repeats with the platform.

## Who uses it

An audit of the whole tree found eleven raw `Slider`s outside this
module. Three were sliders in a PAGE and are gone:

| was | is |
|---|---|
| `FontScaleSlider` — a bare `Slider` + a hand-rolled min / value / max row | `GlobalSlider`, `SliderStyle.bare` |
| the tooltip showcase's anchor control | `GlobalSlider` |
| the popup showcase's arrow playground | `GlobalSlider` |

- **`FontScaleSlider` was the one that mattered.** Its row WAS
  `GlobalSlider`'s header and end labels, written again — no
  `Semantics` (a reader heard the raw factor "1.15"), its own
  `fontSize: 11`, and `'70%'` / `'200%'` hard-coded, so an Arabic
  reader got ASCII digits under an Arabic page. Its preview wrote
  `'Scale: 115%'` the same way.
- **It builds `GlobalSlider` and not the commons' `TextScaleSlider`**,
  which is the same control — a MODULE reaching into `shared/common/`
  inverts the layering.
- **The exemptions are reasons, not grandfathering.** Chrome that
  draws on its OWN surface with its OWN bag stays: the video timeline,
  the audio seek bar, the scanner's zoom over a camera preview, the
  PDF page jumper. `GlobalSlider`'s container, badge and end labels are
  all wrong on top of film. The debug overlay is exempt by the same
  agreement the chip test makes.
- Guard: `test/slider/slider_adoption_test.dart`, which also fails on
  an exemption whose file is gone, or one that no longer builds a
  `Slider` at all — a migrated file keeping its licence to regress.

## Deliberately not built

Each of these is a decision, not a gap. If one of them turns into a
real ask, the reason it was left out is the thing to re-read first.

- **`stepLabels` on a VERTICAL slider.** The constructor hard-nulls it
  rather than half-drawing one: a column of words beside a rotated
  track is a different layout, not the same row turned on its side, and
  it would need its own collision rules. Nothing asks for it.
- **Commons for the RING and the TRIMMER.**
  `selection_fields/slider/` wraps the bar only. A `SleepScheduleDial`
  or a `ClipTrimmer` is the natural next pair, but a preset needs a
  house style to preset — and neither has a second caller yet.
- **Haptics on a CONTINUOUS dial.** Only division crossings tick, the
  same rule the bar follows: a buzz per pixel of a drag is not
  feedback. A dial with no divisions has nothing to tick AT.
- **`GlobalSlider.stepped<T>`** — a discrete slider reporting a `T`
  out of a list instead of a `double`. `QualitySlider` and
  `PlaybackSpeedSlider` each hand-roll that index-to-value conversion
  today. TWO call sites is not an abstraction; a third would be.

## NOT SEEN RUNNING

Covered by `test/slider/` — 258 tests, including the painters, which are
read through `paints..everything(...)` rather than through a golden.
What the tests cannot stand in for:

- The commons under a real **screen reader**, and their Arabic read by
  someone who uses it.

- The haptics on a real device — the test asserts the channel call, not
  the buzz.
- The value indicator during a real **drag**: it only paints while
  `activationAnimation` is running, and a widget test drives that
  animation rather than a finger.
- Any of it **rotated**, or in Arabic on a real device.
- A slider under a platform **screen reader** — the semantics tree is
  asserted, its narration is not.
