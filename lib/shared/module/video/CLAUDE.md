# CLAUDE.md — lib/shared/module/video

`GlobalVideo` — a source, a frame, and a set of controls, over
`media_kit`.

```dart
GlobalVideo.network(
  url,
  title: 'Lesson 3',
  style: const VideoStyle(showSeekButtons: true),
)
```

## Contracts

- **Style is the themeable bag `VideoStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once by
  `style.resolve(context)` into a `ResolvedVideoStyle`.
- **Resolution order**: `caller > GlobalVideoTheme.style >
  VideoStyle.defaults`, then colours.
- **Every hard-coded number lives in `VideoDefaults`.**
- **The widget carries what the player IS; the bag carries how it
  looks.** Source, title, callbacks and the widgets shown instead of
  film are on the widget. Everything else moved.

## The `show*` and `enable*` flags are STYLE, not widget arguments

This is the one call that is worth explaining, because it is the reason
the refactor happened.

"Every video in this app offers a screenshot button" and "no video in
this app takes a swipe" are decisions about the APP, not about one clip
— and a theme is the only place that can say them once. Left on the
widget, `.network` took **thirty-one parameters** and forwarded every
one of them, so an adopter who wanted a house style had to repeat it at
every call site and could never change it centrally.

The four factories are now thin: they name the source and pass a bag.

## Controls float over ARBITRARY pixels

They do **not** take the palette's text colours. White on a scrim is the
only pairing that holds over both a snowfield and a night scene, which
is why every player ever shipped uses it — `context.textColors.primary`
would put dark glyphs on a dark frame the moment the theme was light.

**The accent is the exception.** `activeColor` and `thumbColor` resolve
from `context.primaryColors.primary`: it is brand, it sits on the same
scrim, and it is the thing a rebrand actually wants to change.

Everything else is a token in the bag — `iconColor`, `scrimColor`,
`trackColor`, `bufferedColor` — rather than a literal. There were
twenty-six `Colors.white`/`Colors.black` literals in the controls file
before; there is one left, and it is `Colors.transparent` in a gradient
stop.

## Accessibility

- **The player is ONE node** with `explicitChildNodes`, labelled from
  `semanticLabel ?? title`. A page with four players all announcing
  "video player" has said nothing about which is which.
- **The control glyphs go through `GlobalIcon`**, not a hand-rolled
  `Container` + `BoxDecoration` + `Icon`. `test/icon/icon_adoption_test`
  caught the mini player's disc the moment it stopped being `const`;
  the inline controls' `_Btn` had been evading the same guard because
  its `decoration:` sat behind a ternary the regex could not see. Both
  are `GlobalIcon.circle` / `.basic` now.
- **`_Btn.label` is REQUIRED, not optional.** Every control is a bare
  icon over film with no text near it to fall back on, so one that
  forgot to name itself would announce nothing at all. Making the
  parameter required is what stops that happening the next time a
  control is added. Same for the mini player's `_PipButton`.
- **Reduce motion stills the CHROME, not the film.** `fadeIn` /
  `fadeOut` collapse to zero; the video keeps playing. Reading the
  setting as "no moving pictures" would be reading it wrong — the film
  is the content. `respectReducedMotion: false` opts out.

## A second set of controls is SEEDED, not told

Fullscreen and PiP each build their own `VideoControls` over the inline
player, long after it opened. Every field they show arrives on a stream
that only emits when it CHANGES — so anything reported before that page
existed is never heard by it.

The visible half was the subtitle toggle: on the inline bar, missing in
fullscreen, because `tracks` had been reported once at open and the
fullscreen controls started with an empty list. Everything gated on a
track list had the same hole, and so did `completed` — a fullscreen
page opened over a finished video would have offered play rather than
replay.

`initState` seeds the lot from `player.state`. The streams still have
the last word; they are just no longer the FIRST word.

## The controls do not wait for the engine

Every piece of state in the controls is fed by an mpv stream. That is
the right source of truth and the wrong thing to WAIT for: the play and
mute glyphs used to change only once the native player had echoed the
new state back, so a tap felt like it had been ignored for as long as
that round trip took.

`_togglePlay` and `_toggleMute` flip the local state immediately and
fire the engine call after. The stream still has the last word — it
arrives a beat later and overwrites — so a call the engine refuses
corrects itself rather than leaving a glyph that lies.

`ResolvedVideoStyle.playingAfterTap` carries the one edge case: after
the end, the button is a REPLAY button, so the tap that follows
"completed" always means playing. Toggling there would have paused a
video that was not running.

## The buttons ARE `GlobalIconButton`

They were `GlobalIcon` for a while, on the argument that
`GlobalIconButton` resolves its colours from the app's palette and
these sit on film. That argument was weak: `ButtonStateStyle` takes
`foregroundColor` and `backgroundColor`, so the colours can simply be
passed, and two things come with the button that matter more.

- **It crossfades when the glyph changes**, which is what a play button
  toggling to a pause button should do.
- **It enforces a 48dp touch target.** These are small glyphs over
  film, and a missed tap did not do nothing — it fell through to the
  player's own double-tap handler and seeked ten seconds.

**The painted box is sized to the GLYPH, not to the target.** Left
unset it falls back to `kMinTouchTarget` — measured, 48x48 around a
20pt gear — so the ink circle and the scrim disc stood a long way off
the icon they belonged to. Setting `width` / `height` costs nothing in
accessibility: `MinTouchTarget` expands the HIT area without stretching
what is painted, which is the whole reason it exists. Measured after:
painted 32.4, hit area still 48.

**There is no gap BETWEEN the controls** (`VideoDefaults.controlGap`,
zero). Every one carries a 48dp touch target, so a 22pt glyph already
has thirteen points of clear space on each side; the six and sixteen
points the rows used to add on top of that spread the bar out twice
over. Measured on three buttons: a row 176 wide with 64 between glyph
centres became 144 wide with 48 — and 48 is the target itself, which is
the floor worth keeping.

**The corner and edge controls give up the 48dp target; the centre
keeps it.** A deliberate accessibility trade, asked for after seeing it
on a device. `MinTouchTarget` reserves 48dp in LAYOUT, and four of
those across a bar over a small player is most of its width — measured,
two bar buttons went from 96 points wide to 59.4 with
`enforceMinTouchTarget: false`. The centre transport keeps its full
target, because that is the group people aim at in a hurry and the
group whose mis-taps fell through to the double-tap seek.
`_Btn.compactTarget` is the switch, and it is named for what it costs.

**The gear carries an `onPressed` even though the popup opens it.** A
`GlobalIconButton` with no callback draws itself DISABLED, which is
what put a dull ring round it. Measured: a button with its own callback
does not swallow the popup's gesture, and keeping the bar up is a true
thing for that tap to do.

The crossfade did not work when this module asked for it: the
`AnimatedSwitcher`'s child carried a constant `ValueKey('icon')`, so
swapping `iconData` changed the child in place and animated nothing —
`morphDuration` and `morphCurve` were knobs that could not fire for the
commonest case there is. Fixed in the buttons module, guarded by
"an icon button MORPHS when its glyph changes".

## The film's gestures sit BEHIND the chrome

Not around it. The player's own `GestureDetector` used to wrap the
whole stack, which put its double-tap recogniser in the same arena as
every button inside it. A tap resolves at pointer-UP and a double-tap
resolves on the second pointer-DOWN, so tapping play twice quickly let
the double-tap win the second one and seek ten seconds instead.

As a sibling underneath, a control that is hit absorbs the pointer and
the layer below is never in the arena at all. When the chrome is hidden
its `IgnorePointer` lets everything through, which is what keeps
tap-to-show working.

## No audio OUTPUT is not a broken video

mpv reports "Could not open/initialize audio device" and keeps
reporting it — once every eight seconds, for every player on the page,
forever, which buries everything else in the log. Two things follow:

- **Repeats are not logged again.** Only a CHANGED error is.
- **The film still plays**, so this does not raise the error plate. The
  volume control is the only thing with nothing to act on, so it says
  so — `VideoStrings.noAudioDevice` — instead of pretending to work.

**And mpv is told to stop trying.** `ao=null` — its own "decode audio,
output it nowhere" — goes in on the first such failure, so the film
keeps its timing and the retry loop ends at the source rather than
being filtered out of the log downstream.

`VideoPlaybackIssue.isAudioDevice` keeps the phrase matching in one
place, and is guarded both ways: a real "Failed to open" must still
raise the plate.

## The engine starts when the widget is SEEN

One mpv instance per mounted widget was the most expensive thing this
module did. `VideoPlayerManager` caps how many players PLAY; it never
capped how many EXIST, so a page of fifteen cards stood up fifteen
engines — fifteen textures, fifteen audio-device attempts, fifteen
things for a hot restart to tear down — before anyone had scrolled to
the second one.

`_startEngine` is called from the visibility detector, which is now
wired for EVERY player rather than only for `pauseOnOffscreen` /
`pipOnOffscreen`. Until the widget is seen it shows its poster or
placeholder, which is what it showed while loading anyway — so nothing
looks different, and a player off screen simply does not exist yet.

Three things follow:

- **`initState` starts no engine.** A guard asserts it, because putting
  a `Player()` back there would silently undo this. It may CLAIM one —
  see the handback below — since an adopted player is the same engine
  still running rather than a new one.
- **`dispose` has to check.** An engine that never started has nothing
  to unregister, nothing to dispose, and no page to hand anything to.
- **`player` starts it.** A caller reaching for the engine directly
  wants one, so asking is enough — otherwise the getter would hand back
  an uninitialised field.

**The detector's key belongs to the STATE.** It used to be built from
the source string and the widget's own identity hash. A rebuilt
`GlobalVideo` is a NEW instance with a new hash, so the key changed on
every rebuild — and a changed key is not an update, it is a teardown
and a fresh mount of everything under it. Three faults came out of
that, and only the first was obvious:

- The texture was thrown away and mpv started again on every rebuild,
  which is the exact opposite of what the lazy start is for.
- On hot reload the remount ran while the controls' `LayoutBuilder` was
  in `performLayout`, and the seek bar's `Slider` parks its value
  indicator in an `OverlayPortal`. Its deferred layout box was adopted
  mid-layout: *"A _RenderDeferredLayoutBox was mutated in
  _RenderLayoutBuilder.performLayout"*.
- `_videoKey` was dragged through the same broken mount, so the render
  error was followed by a storm of GlobalKey retake assertions
  (`_elements.contains(element)`), which is the loudest part and the
  least informative — it is fallout, not the fault.

Guarded in `test/video/video_visibility_key_test.dart`, which builds a
detector twice both ways and counts mounts.
## The timeline does NOT mirror

A `Slider` mirrors under `Directionality.rtl`. Measured: tapping the far
RIGHT of an Arabic seek bar returned `0.0` where the same tap in English
returned `1.0` — the reader who aimed at the end of the film jumped to
its start.

That is right for a value that reads like text and wrong for a
TIMELINE. Time runs one way, the frames were shot in that order, and
every player that ships in Arabic — YouTube, Netflix — leaves the
timeline running left to right.

So `VideoSeekBar` pins itself LTR. Three things follow from that:

- **The gestures are PHYSICAL, and stay that way.** Left half is
  rewind, right half is forward; dragging right advances. They already
  were, by accident of using raw offsets — now they are correct on
  purpose, because a mirrored bar would have contradicted them.
- **The clocks are pinned too.** `0:15 / 2:30` puts position before
  duration, and under bidi the slash is a neutral that an RTL paragraph
  reorders around — an Arabic reader was shown the total first and read
  it as the position. Same for the drag badge, where `+` and `-` lead.
- **The CHROME still mirrors.** The bars are toolbars and belong in
  reading order; only the timeline and the numbers are pinned.

`VideoSeekBar` is a separate file for one reason: `VideoControls` needs
a `media_kit` `Player` and cannot be built under `flutter_test` at all,
so the timeline had to be liftable out to be testable. The guard
reproduces the original measurement in both directions, plus a second
test asserting a BARE `Slider` still mirrors — so if Flutter ever
changes that, the wrapper is reported as dead weight instead of
silently becoming it.

## What lives outside `video_controls.dart`

The file was 1613 lines and `build` alone was 787. Four pieces left,
each because it is self-contained rather than to hit a number:

- **`video_control_button.dart`** — `VideoControlButton`, the control
  glyph. No state, no dependency on the controls around it.
- **`video_gesture_overlays.dart`** — the five badges a gesture puts on
  the film: the double-tap ripple, the long-press speed pill, the
  volume / brightness column, the scrub clock and the thumbnail plate.
  Each takes its numbers rather than reading them, `scale` included.
- **`video_settings_menu.dart`** — what the menu OFFERS and what a
  choice MEANS. Both halves are pure, which is the point: see below.
- **`formatVideoDuration`** in `video_models.dart` — the clock, shared
  by the seek badge, the thumbnail and the bottom bar.

**The menu left because taking it out made it testable.** `VideoControls`
cannot be built under `flutter_test` at all, so the rules deciding
whether the gear is worth offering had no coverage of any kind. As a
pure function they have seventeen tests — including the ones that say
`auto` and `no` are libmpv's placeholders rather than choices, and that
one audio track is not a choice while one subtitle track is, because
Off is always beside it.

It takes the three flags it needs rather than the whole
`ResolvedVideoStyle`, which has no `copyWith` and forty-odd required
fields — asking for the bag would have made it untestable again. Engine
calls route through a `run` callback, so a test records
`setAudioTrack(2)` instead of needing libmpv.

## The bar fits itself

Optional controls are ONE ordered list (`_VideoBarControl`). Each takes
a slot while there is room and becomes a menu item when there is not,
so adding a control is appending an entry rather than re-reasoning
about whether a 140-point player still has space.

- **Nothing is hidden, only MOVED.** That is the deal that makes
  dropping a control acceptable at all.
- **The gear is the overflow anchor.** It was already top-right holding
  the track settings; controls lead its menu because they are actions
  and because one that just left the bar is what is being looked for.
- **The transport is NOT in the list.** Play is not a control anyone
  should have to open a menu for.
- **The fit runs before either bar is built.** The gear lives in the
  top bar and the controls it holds live in the bottom one, so the
  decision cannot wait for either to be laid out. The clock it fits
  around is MEASURED (`TextPainter`) — `0:15 / 2:30` and
  `1:02:15 / 2:14:30` are not the same width.
- The rule itself is `core/utils/layout/bar_fit.dart`, shared with the
  PDF viewer's bottom bar. `slots` exists for the viewer's zoom PAIR;
  nothing here is paired, so nothing here claims two.

## Only CONTROLS may take a pointer

A decorated box takes the pointer. The two scrim gradients are pure
decoration running the full width of the player, and they were
swallowing every gesture that began near an edge — so with the bar
showing, a swipe to seek and a hold for 2x both did nothing. Reported
from a device, and measured in
`test/video/video_chrome_hit_test.dart`, which reproduces the layering
because `VideoControls` cannot be built at all.

Both scrims are wrapped in `IgnorePointer`. The wrap goes INSIDE the
`Positioned` — that is parent data for the `Stack` and has to stay its
direct child, and putting the ignore outside throws at runtime where no
analyzer will catch it.

What still absorbs, correctly, is the controls themselves: a gesture
that starts on the 48dp play button belongs to the button. That is the
same rule every player follows, and it is why the transport is a row of
small targets rather than a band.

## Where the transport and the clock go is a DECISION

Two enums in the bag, both defaulting to the shape the player already
had, so nobody who never asked sees a change.

- **`VideoTransportPlacement`** — `centered` (big, over the film: the
  standard mobile shape, and a 48dp play button in the middle is the
  easiest target on a small player), `bar` (inline, reads like a
  desktop player, leaves the film uncovered), or `barCentered` (inline
  and in the MIDDLE, with the other controls split to either side —
  the music-player shape, where the thing pressed most is found
  without looking).
  - Inline, the transport comes BEFORE the clock: the transport is
    what a reader reaches for, the clock is what they read.
  - **Play leads the seek pair only in `bar`**, where the row is read
    left to right and the control being reached for should be the
    first thing the eye lands on. Wherever the transport is CENTRED —
    over the film or in the middle of the bar — rewind comes first,
    because the point of centring is that PLAY is in the middle, and a
    group starting with play puts it off to one side of its own
    centre. `barCentered` shipped doing exactly that: the group was
    centred and the button was not.
  - **The clock uses TABULAR figures.** A 1 is narrower than a 0 in
    most faces, so a clock ticking past `:10` changed width and the
    timeline beside it grew and shrank a pixel at a time. Applied over
    whatever `timeLabelStyle` gave, not instead of it.
  - Every inline control gives up the 48dp RESERVATION
    (`compactTarget`). The play button was missing it, so one control
    held 48 points of layout beside neighbours holding 32 — which is
    what made the row look padded out. The hit area is unchanged;
    `MinTouchTarget` expands it without stretching what is painted.
  - `barCentered` fits each SIDE against its own half rather than
    splitting a finished list. The halves are `Expanded`, so the flex
    divides what is left after the TRANSPORT and nothing else —
    everything drawn inside a half comes out of that half alone.
- **`VideoClockPlacement`** — `below`, `beforeTimeline`,
  `afterTimeline`, or `split` (elapsed at the start, total at the end,
  each number at the end it describes).

**The row's arithmetic is a value, not four inline expressions.**
`VideoBarBudget` exists because these sums were wrong three times, each
by a few pixels, each found on a device rather than in a test — the
transport's trailing gap was never subtracted, the clock was measured
in a different font from the one it renders in, and the pinned control
was taken out BEFORE halving when it is drawn entirely on one side.
The sums are trivial; remembering which cost comes out of which side is
not, and `test/video/video_bar_budget_test.dart` now lays the row out
and checks that what was allowed actually fits.

**Fullscreen never folds into the overflow either.** It was last in
the fitted list, so it was the FIRST thing dropped — a player with
eight controls switched on had no way into fullscreen except a menu,
which is not where anyone looks for it. It is the control that changes
every other one, so it keeps a reserved slot at the END of the row,
and its width comes out of the fit's budget rather than being offered
to something else.

**The transport never folds into the overflow.** `_barControls` is what
collapses; play is not a control anyone should have to open a menu for.
But it does take room, so `_inlineTransportSlots` is subtracted from
the fit's budget — and the clock is only subtracted when it actually
sits in the control row. Offering slots that are already spent is how a
bar overflows by exactly the width of the thing it forgot.

**One builder serves both placements.** `_transportControls(compact:)`
— centred and inline are the same controls at different sizes, and
building them twice is how the two drift apart. Inline drops the
centre button's scrim disc: the bar is already a scrim, and a disc on a
disc reads as a button stuck to the background.

## Taps are timed by hand

`GestureDetector` cannot show/hide on the first tap. A double-tap
recogniser in the arena holds every single tap for `kDoubleTapTimeout`
before it can win, so the chrome answered 300ms late — which reads as a
tap being ignored, and the impatient second one became a double-tap and
seeked instead.

A `Listener` drives it, seeing pointers without joining the arena. That
is safe HERE and nowhere else: this layer sits UNDER the chrome, and a
`Stack` stops hit-testing at the first child that reports a hit, so a
pointer landing on a control never reaches it. The pan and the long
press stay on the detector — those do need to win an arena, not least
against a scrolling page.

What the recogniser used to rule out is now ruled out by hand: a drag,
a hold, a gesture already claimed by swipe or dismiss, movement past
`kTouchSlop`, a press past `kLongPressTimeout`.

**A scrub moves the picture**, throttled to
`VideoDefaults.liveScrubInterval`. The badge and the plate both said
where the drag would land while the film sat on the frame it started
on. Seeking every pixel is a decode per frame of finger movement and
stalls a network stream; the exact seek still fires on release.

## What the player offers beyond playing

- **Keep-awake** while playing, from the RESOLVED style — so
  `GlobalVideoTheme` can turn it off house-wide. It is cached on the
  state and refreshed in `didChangeDependencies` / `didUpdateWidget`,
  because the flag is read from an mpv stream that arrives between
  frames when there is no context to resolve with. Reading
  `widget.style` directly was the shortcut, and it ignored the theme. `VideoWakelock` is COUNTED, because a
  page holds several players and the last to pause must not switch the
  screen off under one still going; releasing a hold never taken is
  ignored, or a widget disposed mid-playback leaves it stuck on. The
  device call is a seam wired in `bootstrap` — this module must not
  reach the device layer, and an un-wired seam is inert, which keeps
  widget tests off a platform channel.
- **Keys**: space/K, arrows, M, F, Escape. Through
  `FocusableActionDetector`, not a bare `Shortcuts`: shortcuts only
  fire for a subtree that HAS focus and a video is not a text field, so
  nothing would ever give it any. Focus follows the pointer.
- **Quality** is just another track list — mpv reports video tracks the
  way it reports audio ones. Named by HEIGHT, since a raw id says
  nothing and mpv only sometimes gives a title.
- **Screen lock**, fullscreen only. Locked, the control layer is NOT
  BUILT rather than built and ignored: an inert gesture layer still
  swallows the pointer, and the one button that undoes this has to
  receive it.
- **Chapters** are on the WIDGET, not the bag — where the second act
  starts is a property of the content and a theme cannot know it. The
  timeline is CUT into segments rather than marked. Painting gaps ON
  TOP of a finished track was the first attempt and it stayed a marked
  track — the pieces ran together under the thumb. A
  `SliderTrackShape` replaces the track instead, drawing each chapter
  as its own rounded bar through inactive, buffered and active in
  turn, so it reads as several sliders handing the thumb between them.
  That shape now lives in `slider/slider_shapes.dart` as
  `SliderSegmentedTrackShape` — every slider in the app can be cut, and
  the private copy that was here is gone. The seek bar passes
  `rtl: false`, because the bar is pinned left-to-right for the reason
  below and an ordinary slider is not.
  A seam takes half its gap from each side, and none from the outer
  ends, so the track still starts and finishes where the reader
  expects. The current chapter is
  named under the title, and follows the DRAG while one is in progress
  — the reader is asking where they are about to land.
- **Resume** is `initialPosition` + `onPositionChanged`, and the module
  keeps nothing: `lib/shared/module` has no storage. It is passed as
  `Media(start:)`, NOT a seek after opening — mpv opens at the position
  that way, where a seek issued straight after `open` raced the file
  being loaded and was dropped. The symptom was a demo that said 0:20
  and played from zero. In a playlist only the item it STARTS on
  resumes; the ones after are new viewings. Reporting is
  throttled to `positionReportInterval` because the position stream
  fires several times a second and the other end is a write to disk.
- **Auto-play next** is OFF by default, alone among these. Autoplay
  nobody asked for is the most complained-about behaviour a player has,
  so an app opts in — and the countdown can be stopped.

## The play control MORPHS; the others crossfade

A crossfade between play and pause reads as a flicker: two glyphs of
similar mass in the same place, 200ms of one becoming the other, and it
looks like a redraw rather than a change. The transport uses
`AnimatedIcons.play_pause`, which folds the triangle into the bars —
the same control visibly changing its mind.

Replay is NOT in that pair. Material has no play-to-replay morph, and
after the end the button is a different control rather than the same
one in another state, so it crossfades to the replay glyph. Everything
else on the bar keeps the ordinary `GlobalIconButton` crossfade, which
is right for glyphs that are not two states of one thing.

**A control may show a VALUE instead of a glyph.** `VideoTextControl`
is how the speed cycler reads `1.5x`: a stopwatch icon makes the reader
open it to find out where they are. It takes a bar slot like any other
control and folds into the menu the same way. The cycler WRAPS —
stopping at the fastest strands anyone who overshoots, and the way back
would be the menu they were avoiding — and it steps through the same
`speeds` the menu offers, so the two cannot disagree. Off by default:
it is a second route to something the gear already has.

## What lives outside the controls file

`video_controls.dart` is long, so what left it was chosen for what it
buys rather than for the line count:

- **`video_control_button.dart`** — the glyph, the text control, and
  the morphing play button.
- **`video_gesture_overlays.dart`** — the five badges a gesture puts
  on the film.
- **`video_seek_bar.dart`** — the timeline, its chapter segments and
  the A–B loop region.
- **`video_settings_menu.dart`** — everything the gear OFFERS and what
  a choice MEANS. Pure, and therefore the only part of the menu that
  can be tested at all.
- **`video_shortcuts.dart`** — the key map. It takes ONE callback:
  every key does something to playback, and playback is not that
  widget's business.

## media_kit draws its OWN subtitles, and does not any more

`Video` renders a subtitle view over the texture by default, so every
line appeared TWICE — theirs mid-frame in a fixed style, ours in the
bar — and theirs painted an empty plate between cues. It is switched
off at all three call sites (inline, fullscreen, PiP).

Ours stays because it is the themeable one: it reads `subtitleStyle`,
sits with the bar, moves when the bar appears, disappears when there is
nothing to say, and takes the reader's size.

**One builder for both plates.** The bar's and the one that stands in
for it when the bar is hidden were the same eleven lines twice — and a
size control reaching only one of them would look broken exactly half
the time.

**The plate is CONTENT, so it takes no pointer.** A long line grows the
bar upwards until it reaches the centre transport, and a decorated box
absorbs — so the play button was right there and would not answer. Same
rule as the scrims: only controls absorb.

**The BOX takes the reader's size too.** Scaling the glyphs and leaving
the padding put a 200% line in a 100% plate with its descenders against
the edge.

**A gap between cues is EMPTY, not blank.** mpv reports a LIST of lines
and the gap between two cues arrives as blank ones; joining those gives
`"\n"`, which is not empty, so the plate drew itself around nothing.
Trimmed on the way in.

**Size and delay are separate menu sections** even though both are a
pair of nudges and a reset. One is about whether the subtitles can be
READ and the other about whether they are in TIME with the film; a
reader reaching for one is not reaching for the other.

## Presets are named BAGS, not modes

`VideoStyle.minimal`, `.cinema`, `.lesson`. Everything a preset decides
— which controls exist, where they sit — is what the bag already
carries, so a preset merges with a theme and loses to a per-call
override like any other bag, and adds no code path to keep true.

**What is NOT a preset is a different interaction model.** A reel pages
between clips, taps to pause rather than to show chrome, and has no
timeline at all. That is a widget that USES `GlobalVideo` — the way the
fullscreen page and the PiP window already do — and adding it here as a
flag would put an `if` through every build method in the module. The
ownership handback exists precisely so a player can outlive the widget
showing it, which is what paging between clips needs.

## The controls an app can switch on

All OFF by default. Every one is a decision about a particular app, and
a player that arrives with eight extra controls has made them for
everyone.

- **Subtitles on / off** (`showSubtitleToggle`) — one tap, for an
  audience that switches them constantly. The gear still chooses WHICH.
  Back on means the first REAL track, because "off" forgot which one
  was chosen.
- **Chapter list** (`showChapterList`), **sleep timer**
  (`showSleepTimer`) and **subtitle delay** (`showSubtitleOffset`) are
  menu-only. A list of chapters, a set of durations and a pair of
  nudges are not glyphs, and putting them on the bar would mean
  inventing one.
- **Replay from start** (`showReplayButton`), **fit / fill**
  (`showZoomToggle`) and **A–B loop** (`showAbLoop`) are bar controls
  like any other, and fold into the menu the same way.
- **Cast** is a HOOK — `onCastPressed` on the widget. AirPlay and Cast
  are native route pickers that differ per platform, and a module that
  shipped one would be shipping a guess about which. The control
  appears only when an app has something for it to do.

**Nothing appears that cannot work.** The subtitle controls need REAL
subtitle tracks, the chapter list needs chapters, cast needs a
callback. A control for something the file does not have is a control
that lies.

**"Real" is load-bearing, and getting it wrong shipped twice.** `auto`
and `no` are libmpv placeholders present on EVERY file, including one
with no subtitles at all — so `_subtitleTracks.isNotEmpty` is true for
every film ever opened. It put a subtitles toggle on a film that had
none, which then did nothing when pressed, and it offered a Subtitles
section in the gear holding nothing but the Off it was already on. The
audio list had this documented and the subtitle list still had the
bug; `VideoSettings.isRealTrackId` is the one place that knows.

**One control walks the whole A–B cycle** — mark A, mark B, clear.
Three buttons for one loop is a bar nobody reads. Marking B before A is
taken as the pair the reader meant rather than refused: that is how
someone who found the end first would do it.

**"End of this video" is not a clock.** It waits for `completed`
instead of counting down, and it BEATS auto-play-next — someone who set
a sleep timer did not ask for another video.

**Subtitle delay goes straight to mpv.** `Player` has no
`setSubtitleDelay`; `sub-delay` is the property, in seconds, through
`NativePlayer.setProperty`.

## Pinch to zoom, drag to pan

The map gesture, and the one people try on a picture without being
told. **Pan is enabled only ONCE ZOOMED**: at 1x a drag belongs to the
player — that is where seek, volume and brightness live, and a pan that
swallowed them would trade three gestures for one nobody asked for.

`boundaryMargin` is what keeps a zoomed picture reachable near an edge.
Without it the film springs back and half a zoomed frame can never be
looked at.

**Fit and fill are separate for the inline player and the fullscreen
page.** They are different frames, and cropping one is not a request
about the other.

## Controls are sized against the FRAME

`ResolvedVideoStyle.scaleFor(height)` scales every glyph, badge and
label against a 220pt reference, clamped to 0.8–1.5. A player in a list
cell and a fullscreen one cannot be handed the same 28pt icon — and
neither can be handed a 2pt one, which is what the clamp is for.

## Whoever is SHOWING the player owns it

The symptom: enter fullscreen, the picture goes black, the seek bar
FREEZES while the controls still respond, and it recovers on the way
back. One player or fifteen made no difference. Entering from LANDSCAPE
was always fine — that needs no rotation, so nothing reflows the page
underneath.

The inline widget is destroyed while its fullscreen page is still up,
and `dispose` disposed the player that page was showing. Coming back
rebuilt the widget with a fresh player, which is exactly why it always
"recovered".

**Keep-alive does not prevent it.** That was the obvious fix and it is
wrong: the trace records `keepAlive=true` at the push and
`destroyed while fullscreen` 411ms later, so whatever removes the
element is not a sliver cull. `AutomaticKeepAliveClientMixin` is still
here because it costs nothing and covers the case where it IS a cull,
but it is not what makes this correct.

What makes it correct is that the player stops caring why the widget
went away. **Ownership moves** (`VideoOwnership`): the inline widget
normally disposes the player, but if it dies while the page is up it
hands the player over and disposes nothing, and the page disposes it on
the way out instead. Exactly one of the two always does — guarded both
directions in `test/video/video_ownership_test.dart`, because disposing
twice throws and disposing neither leaks.

**And the page hands it BACK.** Disposing the orphaned player when the
page closed was the other half of this and it was wrong in a way that
only showed on the way out: leaving fullscreen went black for a beat
and restarted the clip from zero, because the widget that came back was
a new state that had to build a new engine. Entering was fine, which
made it look like an exit bug rather than the same handoff missing its
second half.

So the page PARKS the player (`HandbackSlot`, `video_handback.dart`)
and the widget replacing the one that died claims it in `initState` —
before waiting to be seen, because this widget IS the return from
fullscreen and a claim delayed to the next visibility tick is a
half-second of audio with no picture. Nothing is created and nothing is
re-opened; `_adopt` seeds from `_player.state` what `_openMedia` would
have set, since the streams only report CHANGES and this one already
happened.

The slot is deliberately small and deliberately strict, because both
failure modes are bad: two widgets claiming one player dispose it
twice, and nobody claiming it leaves mpv and its audio running with
nothing on screen. So a claim empties the slot, a mismatched key gets
nothing, and a reaper disposes anything unclaimed after five seconds —
the case where the reader pops the whole page from inside fullscreen
and never comes back. Policy guarded in
`test/video/video_handback_test.dart`, which parks strings because a
`Player` needs libmpv.

**Popping the page from `dispose` was the old answer and it was wrong.**
It is what made the fullscreen button look like it opened a page and
immediately came back. Worth knowing it could never have worked in its
original form either: it called `Navigator.of(context)` on an element
that is already defunct, and the bare `try` around it swallowed the
throw.

**Leaving fullscreen is DEFERRED, and that is not optional.** The page
reports its exit from `dispose`, which runs while UNMOUNTING — the tree
is locked and no element may be marked dirty. A `setState` there throws
"setState() called when widget tree was locked", and the throw left
`_isFullscreen` stuck TRUE. Two faults came out of that one stuck flag:
the inline picture never came back (the `Video` is only built when the
flag is false), and the next press took the `if (_isFullscreen)` branch
and popped instead of pushing. `_leaveFullscreen` waits for the end of
the frame; mechanism guarded in `video_exit_callback_test.dart`.

**The handoff traces itself.** Four diagnoses on this path were wrong,
every one reasoned from logs that did not record what the code decided.
It now prints, debug-only, who pushed and whether it was keeping itself
alive, whether it was destroyed while fullscreen, and whether it left
normally. That trace is what finally ruled out the cull.

## ONE `Video` per controller, ever

A `VideoController` owns a single texture, and two `Video` widgets
pointing at it do not share it. The fullscreen page came up PITCH BLACK
with the film audibly playing, because an opaque route does not unmount
what it covers — the inline player was still behind it, still holding
the texture. The inline one stands down while `_isFullscreen` is set,
and takes it back on the way out (`onExit` fires from the page's
`dispose`, so every pop path is covered, including the drag-dismiss).

## Fullscreen insets the CONTENT, not the gradients

The bars sit inside `viewPadding`, which is the one that still reports
the housing in immersive mode — `padding` is zeroed there. The
gradients still reach the edge, which is the rule the rest of the app
follows: the SURFACE covers the inset, the CONTENT sits inside it.
`MyApp` has already un-mirrored the landscape notch, so this is the
real side rather than 62 points given up on both.

**Leaving fullscreen restores `kAppOrientations`, not
`DeviceOrientation.values`.** `values` includes upside-down, which both
native configs omit on a phone — so exiting one page silently widened
what the whole app allowed. That constant now lives beside
`initSystemChrome` so anything else that narrows orientations can put
back what the app actually had.

## Fullscreen and PiP carry the SAME bag

Neither is a second theme to keep in step. Fullscreen forces
`showFullscreenButton: true` on its copy and changes nothing else — a
control the reader had a moment ago should not vanish because the frame
grew, and turning it off there would leave a page with no way back
except a drag nobody was told about.

## The settings menu is placed by the ENGINE

`GlobalPopup.menu` takes the anchor as a WIDGET and computes the layout,
so flipping, edge-clamping and content sizing come for free and the menu
matches every other popup in the app.

It used to call `GlobalPopup.showAt` with a `GlobalPopupLayout` built on
the spot — `isAbove: false`, `isFlipping: false`, `anchorSize:
Size.zero`. That is the engine's job, and saying it by hand said it
wrong three ways: a menu that could never flip ran off the bottom of a
player near the foot of a page, a surface told its anchor was a
zero-sized point could not line up with the button, and the placement
was pinned to `Alignment.topRight` where `bottomEnd` is DIRECTIONAL —
in Arabic the bar mirrors and the button moves to the left, so the menu
opened away from it.

**The auto-hide clock stops while the menu is open.** A reader reading
a menu is not idle.

The menu does NOT fade with the controls — measured, the popup renders
in the overlay and is not a descendant of the fade. The mechanism was
one step removed: the bar hid three seconds after playback started,
and the tap that brought it back landed OUTSIDE the menu and dismissed
it, which looks exactly like a menu closing itself.

`_menuOpen` is a FLAG rather than a one-shot cancel in `onOpen`,
because several things re-arm the clock — the `completed` stream calls
`_showCtrls`, and so does the end of a seek — and any of them would
have hidden the bar again. The rule itself is
`ResolvedVideoStyle.shouldAutoHide`, a pure function, because it is the
only part of the auto-hide that can be tested at all: three reasons not
to arm it, and each is someone who is not idle — a paused player is
waiting for the reader, a finger on the seek bar is mid-scrub, an open
menu is being read.

**Close-on-scroll is left ON.** It was briefly turned off on a theory
that a player reporting its dimensions a beat after mount
(`VideoOutput.Resize`, `0x0` then `1280x720`) moved the page's scroll
position and dismissed the menu. Measured, that is not what happens:
content grown above an anchor keeps the menu open, and it closes only
once the anchor is pushed off screen — which is the popup doing the
right thing. The theory is recorded here because it is a plausible one
to have again.

**The anchor button carries no `onTap`.** The popup owns the gesture.
`_Btn.enabled` exists for exactly this: the glyph must not dull itself
as though nothing will happen.

## Gotchas

- **The resolved bag lives on the STATE, not inside `build`.** The
  gesture handlers and the auto-hide timer read it, and those run
  between builds. It is refreshed in `didChangeDependencies` (theme,
  reduce-motion) and in `didUpdateWidget` (a new bag from the caller).
- **And it is NOT `late`.** That combination shipped broken:
  `initState` starts the auto-hide timer, which reads the bag, but a
  style can only be resolved in `didChangeDependencies` — it needs the
  inherited theme — and that runs after. Every player threw
  `LateInitializationError` on its first frame. It starts from
  `ResolvedVideoStyle.fallback` now, a context-free bag nothing ever
  actually sees, because `didChangeDependencies` still runs before the
  first build. The trap is structurally impossible rather than
  documented.
- **The drag axis has a dead zone.** Below `dragAxisSlop` the axis is a
  coin toss, and guessing wrong seeks when the reader meant to change
  the volume.
- **A scrub preview is a network round trip per frame.** It waits for
  the finger to settle (`thumbnailDebounce`) rather than firing on every
  pixel.

## Showcase + tests

`/video-showcase`. `test/video/global_video_test.dart` — bag merge,
resolution order, the palette accent, the white-on-scrim glyphs, the
token-driven app theme, reduce motion, the frame scale, lerp, and the
widget/bag split.

## Known gaps

- **The engine cannot be started in a unit test.** `media_kit` wants a
  real platform, so nothing here drives actual playback — and that is
  not a theoretical gap: the `late` bug above reached a device because
  `VideoControls` cannot be built under `flutter_test` at all. Its
  guard is a SOURCE scan for `late ResolvedVideoStyle`, which is crude
  and is still the only thing standing between this and a repeat.
  Playback itself is device-tested.
- **Hot RESTART crashes when a player is alive, and we cannot fix it.**
  `SIGABRT` on the `*/mpv core` thread, every time, with the abort
  inside `DLRT_GetFfiCallbackMetadata` under mpv's `append_event`.
  media_kit registers a Dart `NativeCallable.listener` with
  `mpv_set_wakeup_callback` so mpv can tell it an event is waiting. Hot
  restart kills the isolate WITHOUT running any Dart, so nothing clears
  that callback — its own `dispose` does exactly that, in the orderly
  case — and the still-running mpv core thread then calls a trampoline
  whose isolate is gone. `NativeReferenceHolder` is media_kit's answer
  (the next run finds the leaked handles and disposes them: "Found 2
  reference(s)"), and the abort happens during that window.
  Debug-only: there is no hot restart in release, and a cold start is
  clean. media_kit 1.2.6 is the current version, so there is nothing to
  upgrade to. **Hot reload is fine** — the isolate survives, so the
  callback stays valid. Starting the engine late made this rarer rather
  than gone: fifteen live handles became two, and one is enough.
- **No golden files**, so the controls' geometry is asserted
  structurally rather than by appearance.
- **`VideoControls` is ~2365 lines**, and that number has now gone up
  twice. Everything separable HAS been separated: the button, the
  gesture badges, the seek bar, the settings-menu content, the
  keyboard layer. What is left is one state class and one ~600-line
  `build`, and the two bars inside it read about fifteen fields each —
  extracting them means a fifteen-parameter wall or a context object
  that is the same thing wearing a hat. It is honestly a long file
  rather than a badly split one, and the next person should weigh that
  wall themselves rather than assume it is worth paying.
- **The gesture badges keep their ONE-OFF numbers** — the ripple's
  24pt glyph, the level column's 36pt width. Only the numbers that
  repeated across badges were named (`badgePaddingH`, `badgePaddingV`,
  `badgeGap`), because those were the ones free to drift from each
  other. A one-off says what it is where it is used, and naming it
  adds a constant nobody can reuse. Guarded by counting: no
  frame-scaled number may appear twice in that file.
- **Subtitles are exercised through `SubtitleConfig.data`**, not a
  file with an embedded track. No public sample MP4 reliably carries
  one, and a fetched `.vtt` is another URL that can 404 the way the
  clip already did — so the showcase carries the WebVTT inline. What
  that does not cover is a track mpv finds in the container itself,
  which is the path an adopter's own media takes.
