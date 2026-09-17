# CLAUDE.md — `date_time_picker/`

Date and time pickers: one wheel picker, one calendar, one range
picker, and an anchored panel that carries either.

```
date_time_picker.dart                    — barrel
date_time_picker_models.dart             — enums + the arithmetic (PickerMath, CalendarGrid, OverlayPlacement)
date_time_picker_style.dart              — DateTimePickerDefaults / DateTimePickerStyle / ResolvedDateTimePickerStyle
theme/date_time_picker_theme.dart        — GlobalDateTimePickerTheme + `style.resolve(context)`
global_date_time_picker.dart             — GlobalDateTimePicker (five surfaces)
global_date_time_range_picker.dart       — GlobalDateTimeRangePicker (four) + DateRangePreset
global_inline_calendar_range_picker.dart — the month grid everything else builds
picker_anchor.dart                       — PickerAnchor: a trigger with a panel against it
picker_dialogs.dart                      — PickerDialogs: the module's own modals + the full-screen range
picker_calendar_system.dart              — PickerCalendar + Gregorian / Hijri counting
time_dial.dart                           — TimeDial: a clock face + DialGeometry
```

App-wide defaults: `MyGlobalDateTimePickerTheme.build`, wired in
`lib/core/theme/theme.dart`.

## The bag

`caller style: > GlobalDateTimePickerTheme.style > DateTimePickerStyle.defaults`,
then the colours from the palette. Presets: `compact`, `circular`,
`flat`.

- **ONE bag for the whole family.** A calendar inside an overlay inside
  a range picker has to agree with the calendar beside it; three bags
  could not. Everything visual is here — the trigger's chrome, the
  wheels' geometry, the calendar's cells, the panel's corner.
- **`shadow: null` asks for the house shadow; `shadow: const []` is
  FLAT.** Collapsing the two makes flat impossible to ask for.
- **Colours are absent from `defaults` on purpose** — they resolve from
  `context.primaryColors` / `textColors` / `backgroundColors` at build
  time so they track role, brightness and saturation. A selected day is
  `textColors.onPrimary`, never `Colors.white`: this module hard-coded
  white on the accent in five places, and a light-primary brand made
  every one of them unreadable.
- **`MyGlobalDateTimePickerTheme` sets only SIZES**, from `AppTokens`,
  so the pickers round and space like the rest of the app and follow it
  into a wider window.
- **`PickerSurface`, not `PickerStyle`.** Where the picker lives is a
  different question from how it looks, and the old name collided with
  the `style:` every other module in this app carries.

## The arithmetic is pure

`PickerMath`, `CalendarGrid` and `OverlayPlacement` are plain functions
in the models file. None of this could be tested where it was: the
wheels need a laid-out `CupertinoPicker` and the drag hit-test needed a
real `RenderBox`, so every bug in it only ever showed up on a device.
Guards: `test/date_time_picker/picker_math_test.dart`.

- **`PickerMath.rebuild` CLAMPS the day to the month.** 31 January plus
  "February" is 31 February, which `DateTime` silently rolls into March
   — the month the reader picked would change under them.
- **`PickerMath.snapMinute`.** A value of :07 on a 15-minute wheel used
  to sit at row 0: the wheel READ "00" and the picker REPORTED :07.
  `minuteInterval` now asserts it divides 60, because 7 gives an 8-row
  wheel ending at :49 with :56 unreachable.
- **`CalendarGrid.dayNumberAt` mirrors its columns in RTL.** A sweep in
  Arabic selected the mirror image of what was under the finger.
- **`OverlayPlacement.decide` prefers BELOW**, and only flips when below
  genuinely will not fit and above is roomier — below keeps the panel
  where the thumb is and off the trigger it belongs to. It would rather
  overflow a little than draw a panel under `overlayMinHeight`.

## `PickerAnchor`

Both pickers had their own copy of the link, the key, the entry, the
animation and the above/below arithmetic, and the copies had drifted —
one measured against the screen and the other against the screen minus
30 points, so the same trigger flipped sides depending on which widget
owned it.

- **The measuring key rides the `CompositedTransformTarget`.** Both
  copies put it on the DEFAULT trigger's inner container, so a custom
  `triggerBuilder` left nothing to measure and the panel never opened
  at all.
- **The panel is refreshed OUT of the build phase.** The entry lives in
  the ROOT overlay, so it is not a descendant of the anchor, and marking
  a non-descendant dirty mid-build throws — which is exactly when it
  happens, since `didUpdateWidget` runs during the parent's build and
  the parent rebuilds because the panel reported a pick.
- **It is at least `overlayMinWidth` (296) wide**, whatever the trigger
  is. Pinned to a 120-point trigger the calendar drew 17 points per day
  and the header overflowed by 28. Seven columns at a readable cell is
  a physical floor, which is why that number is in `Defaults` and not
  in the bag.
- **The panel NEVER shrinks to fit.** A calendar that loses two rows
  near the bottom of a screen cannot show the dates it is being asked
  for, so it FLIPS to the other side; if it fits neither it slides onto
  the screen and overlaps its own trigger. Only the screen caps the
  height — `overlayMaxHeight` defaults to infinity, and a number there
  would cap a calendar that had room to be whole.
- **The height comes from MEASURING the panel**, not from a budget: the
  first pass lays it out against the whole screen, `_MeasureSize`
  reports what it came to, and the second pass puts it where that
  height fits. It re-measures on every content change, so a month with
  six rows gets a taller panel than one with five.
- **The ANCHOR owns the scrolling, not the panel.** A
  `SingleChildScrollView` reports the height it was GIVEN, so a panel
  that scrolled itself measured as tall as whatever it was handed — and
  the placement handed it that straight back.
- **A panel inside a panel goes FLAT.** The overlay IS the surface; the
  calendar inside it merges `DateTimePickerStyle.flat` or it draws a
  frame within a frame.
- **The root overlay does not inherit from the trigger's subtree.** It
  sits inside `MaterialApp.builder`, so `BreakpointsProvider`, the
  theme and `Directionality` reach it — a `Theme` an adopter wraps
  around one page does NOT.

## The dialogs

`PickerDialogs.date` / `.time` / `.dateAndTime` / `.range`. They replace
`showDatePicker`, `showTimePicker` and `showDateRangePicker`.

- **Those were Material's widgets, not ours.** The only way to make them
  match the app was a 60-line `Theme` wrapper reaching into
  `datePickerTheme`, `timePickerTheme` and `textButtonTheme` — and it
  still could not touch their icons, their layout, or their two-step
  date-then-time flow. It is gone, along with the `dialogBuilder`
  escape hatch that existed because of it.
- **Inside is what is everywhere else**: the same calendar, the same
  wheels, `GlobalDialog` chrome, `GlobalFilledButton` /
  `GlobalTextButton` / `GlobalIconButton`, `GlobalChip` presets.
- **Date and time are ONE dialog**, calendar over wheels. Material asked
  twice in a row, with no way back to the first without starting over
  and no way to see what had been chosen.
- **The typed side is a toggle, not a separate dialog.** A header icon
  swaps the grid for a masked `GlobalTextFormField` and back, keeping
  the value across the swap — a birthday reached by swiping a calendar
  back three hundred months is not reached at all.
- **`TypedDate` is the two ends of that mask** (`date_time_picker_models.dart`):
  which order the locale writes in, taken from `intl`'s own short-date
  pattern rather than from a list of locales, and the parse back. It
  REFUSES 31 February instead of letting `DateTime` roll it into March,
  and reads Arabic-Indic digits, which an Arabic keyboard emits.
- **`PickerSurface.material` is now `PickerSurface.dialog`**, and the
  `materialDate` / `materialTime` / `materialDateTime` factories are
  `dialogDate` / `dialogTime` / `dialogDateTime`.

## Two layouts, on the bag

- **`timeLayout`** — `wheels` (default) or `dial`. Wheels set one part
  per gesture and stay legible while they move; a clock face is faster
  to read back and is the shape a phone's own alarm has. It is honoured
  wherever a TIME is asked for: inline, in the anchored panel, and in
  both dialogs that carry one.
- **`rangeLayout`** — `dialog` (default) or `fullScreen`. A range in a
  modal on a phone leaves the month grid squeezed between two dates and
  a pair of buttons; the full-screen one is a route with a
  `GlobalAppBar` carrying the span, and the calendar gets the room.
- **`TimeDial` is built here, not borrowed.** `showTimePicker`'s dial
  arrives with its own dialog, its own buttons and its own colours.
- **`DialGeometry` is the face's arithmetic, and it never mirrors.** A
  clock runs clockwise in every language. Only the readout above it is
  laid out by direction — and even that is pinned left-to-right,
  because an hour comes before a minute everywhere.
- **A 24-hour face has two rings**: outer 0–11, inner 12–23, at the same
  twelve angles.
- **Setting the hour moves you on to the minutes.** Otherwise the second
  half of the job needs a tap nobody expects to have to make.

## What a calendar collects

`selection` is `range` (default), `single` or `multiple`. It replaces
the `singleSelect` bool, which could not express a third case.

- **`multiple` draws no bar and offers no sweep.** Nothing spans between
  two arbitrary days, so nothing is painted between them and the
  long-press drag is off. It reports the whole set through
  `onDatesChanged`, sorted, on every toggle.
- **A multi-select calendar opens on the first day it holds** — there is
  no range to open on.

## Week numbers

`style.showWeekNumbers` adds a leading gutter. Off: it costs a column of
width, and outside the businesses that plan by week number nobody reads
it.

- **`CalendarGrid.isoWeekNumber` is the arithmetic**, and it is not
  `dayOfYear ~/ 7`. ISO weeks run Monday to Sunday and belong to the
  year holding their THURSDAY — which is why 1 January 2021 is week 53
  of 2020.
- **The gutter reads the row's FOURTH cell**, not its first. A row drawn
  from Sunday straddles two ISO weeks; the fourth cell is inside the one
  the row mostly is, whichever day it starts on.
- **It shifts where the seven columns start**, so the sweep's hit-test
  subtracts it.

## Grain

`GlobalInlineCalendarRangePicker.grain` is `day` (default), `month` or
`year`. `monthYear` and `year` existed on the WHEELS and were silently
ignored by every calendar surface — they drew a grid of days. A coarse
grain opens on its own grid and REPORTS from it rather than drilling in.

`GlobalDateTimePicker` maps its `mode` onto it, so a `monthYear` picker
is a month grid on every surface it has.

## What the fields needed

- **`PickerDialogs.duration`** — hours, minutes, optionally seconds, on
  the module's own wheels. `CupertinoTimerPicker` was the last borrowed
  picker in the app: its wheel geometry, its type scale and its
  selection band are all its own and the bag cannot reach any of them.
- **`PickerDialogs.timeRange`** takes and returns a RECORD, not a
  `DateTimeRange`. That type asserts its start is not after its end, and
  a shift from 22:00 to 06:00 is a night rather than a mistake — the
  type could not carry the case at all.
- **`showSeconds`** adds a seconds wheel to the time modes. Wheels only:
  a clock face with a second hand is a stopwatch. `TimeField.showSeconds`
  existed and no picker could set them, `showTimePicker` included.
- **`PickerDialogs.date(presets:)`** — quick chips for "Today" and
  friends. The RANGE picker had them; the commoner ask is the single
  date.

## Two calendars

`style.calendar` is `gregorian` (default) or `hijri`.

- **Only the COUNTING changes.** The value a picker reports is a
  `DateTime` either way. `PickerCalendarSystem` answers the four
  questions a month grid asks — where a month starts, how long it is,
  how to step by months, and what to call it — and `HijriSystem` rides
  `HijriDate`, which converts through the Julian Day Number and
  round-trips exactly.
- **Weekdays are absent from the abstraction on purpose.** A week is
  seven days in both calendars and `DateTime.weekday` answers for both,
  which is why the grid's column arithmetic needed no edits at all.
- **The bag is resolved in `didChangeDependencies`**, not in `build` and
  not in `initState`. Which calendar is counting decides where the first
  page even is, and `initState` cannot read an inherited widget — a
  Hijri grid opened on a Gregorian anchor and drew the wrong month.
  Changing calendar rebuilds the `PageController`, because a page index
  means a different month afterwards.
- **A Hijri picker SAYS the date it drew.** Reporting 19/8/2026 under a
  grid that counted ١٤٤٨ is two calendars in one field.
- **The WHEELS stay Gregorian.** They are month/day/year spinners over
  `DateTime` parts; a Hijri wheel stack would need its own bounds
  conversion and its own day counts, and nothing asks for one yet. Use
  a calendar surface for Hijri.
- **It is the CIVIL (tabular) calendar**, which tracks the
  observational, sighting-based ones to within a day. Fine for picking
  a date; not authoritative for a religious one.

## How the months are laid out

- **`monthFlow: paged`** (default) — one month, swiped, with the one
  before and the one after **peeking in at the edges, dimmed**
  (`monthPeek`, `neighbourOpacity`). A month with nothing either side of
  it gives no sense of where it sits, and no hint that the grid swipes
  at all. The view fades at both edges so the neighbours read as
  continuing rather than as stopping.
- **`monthFlow: list`** — every month in the range, stacked and
  scrolled, each naming itself. What a full page wants. It pins ONE
  weekday strip above the list, drops the month header (a header that
  cannot follow the scroll is a stale one), turns the sweep off (a
  long-press drag inside a vertical scroller loses), and opens on the
  focused month EXACTLY — every month's height is known before it is
  built, so the offset is arithmetic rather than a guess.
- **`monthPeek` is a LENGTH, and it is spent out of the panel's INSET.**
  With a peek the day view spans the panel edge to edge and the peek
  takes the room the inset had, so the focused month keeps the width it
  has without one — what it costs is twice the difference between the
  two, a few points a column. As a fraction of the view it took its
  slice from the seven columns instead, and switching the peek on read
  as adding padding. Before that the inset sat on each PAGE, which made
  the sliver a neighbour showed its own padding and no days at all.
- **`viewportFraction` is final, and a peek in points is only a fraction
  once the view has been laid out** — so the first controller is always
  built against a width of zero and is replaced as soon as there is a
  real one.
- **The peek moves the grid's origin**: peeking, the peek IS the inset;
  not peeking, the panel's own is. The sweep's hit-test reads whichever
  is running — off the view alone it put every drag a column out.
- **The edge fade is never wider than half the sliver**, or the
  neighbour is faded out of existence.
- **The preset chips ride `GlobalChipStrip`.** A bare scroll view with
  `clipBehavior: Clip.none` keeps the selected chip's shadow and lets
  the chips past the viewport paint too — the strip ran out over the
  page it sat in and off the side of the screen.
- **A narrow cell SHRINKS its number** rather than wrapping it. Two
  digits at 16 points need 32, and a seven-column grid in a 296-point
  panel gives each cell 31.

## The calendar

- **The two widgets default their bounds DIFFERENTLY, on purpose.**
  `GlobalInlineCalendarRangePicker` takes a year either side of today —
  it is a booking calendar's default. `GlobalDateTimePicker` takes fifty
  years either side on wheels and 1900–2100 elsewhere, because it backs
  date FIELDS, and a birthday is not within a year of today. The cost of
  the wide one is a 201-entry year grid and a 2412-page month view; both
  are lazy, so it is a scroll rather than a stall. Pass explicit bounds
  whenever the real window is known — every dialog the form fields open
  does.
- **Bounds default to a year EITHER SIDE of today.** They defaulted to
  today, so the calendar opened unable to show last month — and the
  range picker's own "Last 7 days" preset selected a span every day of
  which was drawn disabled.
- **The `PageView` is bounded by the date range**, not a 2400-page
  window centred on today. Unbounded, a swipe walked past `lastDate`
  into months where every cell was disabled, and the arrows did too.
  The arrows disable at the ends.
- **Every day cell is a `Semantics` button carrying its FULL date** plus
  its state — today, range start, range end, in range, unavailable, and
  how many event dots it has. There was no `Semantics` anywhere in this
  module: a screen reader heard the bare number "5".
- **The sweep's hit-test reads the same numbers the layout uses.**
  `_headerExtent` and `style.rowExtent` are derived once, so a taller
  cell can no longer make every drag select the row above. It was a
  hard-coded `24 + 8` beside a cell size the caller could change.
- **The arrows mirror THEMSELVES.** `Icons.chevron_left` and
  `chevron_right` carry `matchTextDirection: true`, so picking the
  glyph by hand as well flipped them twice and put them back the way
  they started. A widget-level check of `icon` cannot catch that — it
  reads the field, not the paint.
- **The weekday strip is NARROW names**, each in a `FittedBox`.
  Arabic's short names are whole words — الاثنين, الثلاثاء — and seven
  of them across a phone ran into each other.
- **Numbers go through `AppNumbers`**, which maps `ar` onto the variant
  that actually emits Arabic-Indic digits — plain `ar` writes ASCII
  ones, so an Arabic calendar counted 1, 2, 3. Years are PADDED, not
  grouped, or 2026 becomes ٢٬٠٢٦. Formatted dates go through
  `PickerFormat`, which rewrites the digits and leaves the month names
  on the app's own locale — switching the whole format to the
  native-digit variant would take that variant's month names too.
- **The year grid's `ScrollController` is created ONCE.** It used to be
  disposed and rebuilt inside `build`, which throws the moment a
  rebuild lands on an attached one.
- **The month / year grids SIZE to their contents**, capped by the
  window, and scroll past the cap with a fade at the cut. A fixed box
  left a band of white under twelve months and hid the tail of a long
  year list behind an edge that did not scroll. `gridViewHeight` is the
  ceiling, not the height.
- **Each month page clips.** The view is as tall as the FOCUSED month,
  and that updates the moment a turn starts, so the outgoing month can
  be a row taller than the box it is sliding out of. Hijri makes this
  routine: 29- and 30-day months change the row count far more often
  than Gregorian ones do.
- **A max / min range GREYS OUT what it will not allow**, rather than
  refusing on the second tap. `onRangeValidationError` fires for a
  SWEEP, where there is nothing to grey out in advance, and its message
  comes from `DatePickerStrings` — it used to be interpolated English
  in a module that ships Arabic.

## The wheels

- **A no-op update emits nothing.** `_syncControllers` jumps the wheels,
  each jump reports its new index synchronously, and reporting THAT back
  to the parent while it is mid-build is a `setState() during build`
  crash.
- **An echoed value does not fight the finger.** The picker remembers
  the last value it emitted and ignores that one coming back; the old
  guard was a one-shot bool, so a GENUINE external change arriving while
  it was set got swallowed instead.
- **`dateAndTime` carries a YEAR wheel.** Without one there was no way
  to set a year in that mode at all. Six wheels share the row on flex
  weights.
- **AM / PM come from `DateFormat.dateSymbols.AMPMS`**, not from the
  ARB. `intl` already knows those two words per locale and a copy would
  only drift.
- **Each wheel is its own semantics node with `explicitChildNodes`.**
  Merged, a minute wheel's label is the word "Minute" followed by all
  sixty of them.
- **The header's title is centred on the ROW**, via `NavigationToolbar`
  — the widget an `AppBar` uses for exactly this. A `spaceBetween` Row
  centred it BETWEEN the two buttons, so "Cancel" and "Done" being
  different widths pushed it off the middle of the picker.
- **Done wears the accent as a surface**, Cancel does not. They used to
  be tinted text sitting level with tinted text, reading as a pair of
  equals when only one of them is what the header is for.

## The keyboard

It had `Semantics` on every cell and no way to reach one without a
pointer — which made it WORSE than the Material picker it replaced,
because that one arrows around a month.

- **One focus node for the GRID**, not forty-two focusable cells: arrow
  keys move a cursor, Enter or Space takes it. Tab through six weeks of
  days is not navigation.
- **The cursor is a third state**, drawn with `focusRingColor` and
  distinct from the selection and from today — it says where the next
  key press will act, which neither of the others carries. It only
  appears once a key is pressed, and only while the grid has focus.
- **Left is the NEXT day in Arabic.** Arrows that moved by screen
  direction walked backwards through the month.
- Page up / down turn the month and the view follows; Home / End go to
  its ends; the cursor clamps to `firstDate` / `lastDate` and will not
  take a day the predicate refuses.
- **Escape closes the anchored panel**, and focus goes back where it
  was. A backdrop tap was the only way out, which is no way out for a
  keyboard. The panel unfocuses BEFORE its entry is torn down — the
  other order leaves the focus manager with a child whose scope has
  gone, and it asserts.
- **`autofocus` is false inline and true in a dialog or panel.** A
  calendar in a page would pull focus off whatever the reader was
  doing; one that just opened IS what they are doing.
- **The dial's keys act on the READOUT**, since a face is a pointer
  affordance: up / down step the live half by the minute interval,
  left / right swap which half that is.

## Who uses it

Everything. An audit of the whole tree found five calls to Flutter's own
pickers, all of them in `shared/common/text_form_fields/domain/`, and
they are gone:

| field | was | is |
|---|---|---|
| `DateField` (dialog) | `showDatePicker` | `PickerDialogs.date` |
| `DateField` (sheet) | `CalendarDatePicker` in a `GlobalBottomSheet` | `GlobalDateTimePicker.calendar`, flat |
| `TimeField` | `showTimePicker` | `PickerDialogs.time` |
| `DateTimeField` | `showDatePicker` THEN `showTimePicker` | `PickerDialogs.dateAndTime` — one dialog |
| `DateRangeField` | two independent single-date dialogs | a shared button opening `PickerDialogs.range` |

`DateRangeField` and `TimeRangeField` inherit the first three through
their child fields; `PaymentCardForm` inherits `DateField`'s.

- **`selectableDayPredicate` had to be added.** The calendar always had
  it; the wheels and the dialogs did not, so a field with an
  "allowed weekdays" rule could only enforce it after the fact in a
  validator. It is on `GlobalDateTimePicker`, `PickerDialogs.date` and
  `PickerDialogs.dateAndTime` now, and only the calendar surfaces honour
  it — a wheel of day numbers has nothing to grey.
- **`TimeField.pickerEntryMode` became `pickerLayout`.** It selected
  Material's dial-vs-keyboard; the module's dialog has no keyboard side
  because the FIELD is the keyboard side and it is already masked. What
  is left is `TimePickerLayout.wheels` or `.dial`.
- **The fields now need `BreakpointsProvider` in `MaterialApp.builder`.**
  A dialog is inserted into the ROOT overlay, which sits inside
  `builder` but ABOVE `home` — a provider under `home` does not reach
  it. `MyApp` already puts it in the right place; a test harness or an
  adopter's own `MaterialApp` has to as well.
- **`DurationField` picks on OURS too now** — `PickerDialogs.duration`
  over `GlobalDurationPicker`. A duration is still not a date: nothing
  about it clamps to a calendar and 90 minutes is a legal answer where
  90 o'clock is not, which is why it is a widget of its own rather than
  a mode on `GlobalDateTimePicker`.
- **`TimeRangeField` opens ONE dialog** — `PickerDialogs.timeRange` —
  instead of two that knew nothing about each other.
- Guard: `test/date_time_picker/picker_adoption_test.dart` — no file
  outside this module may name `showDatePicker`, `showTimePicker`,
  `showDateRangePicker`, `CalendarDatePicker` and friends.

## NOT SEEN RUNNING

Every behaviour here is covered by `test/date_time_picker/` — 243 tests,
including real widget tests, because unlike the scanner and the media
picker this module needs no camera and no platform channel to build.
What the tests cannot stand in for:

- The **drag-to-sweep** gesture end to end, its edge-scroll page turn
  and its cooldown. The arithmetic is tested; the gesture is not.
- The dialogs on a **real keyboard** — the masked field's caret
  behaviour under a platform IME is not something a widget test sees.
- The clock face under a real **drag**, and its haptics.
- The keyboard on a real **desktop** — the shortcuts are tested through
  `sendKeyEvent`, which is not the same as a platform key map.
- A Hijri calendar read by someone who uses one.
- **Reduced motion**, and the wheels' haptics.
- Any of it **rotated**, or in Arabic on a real device.
