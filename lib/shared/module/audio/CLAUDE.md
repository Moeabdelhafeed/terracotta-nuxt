# CLAUDE.md — lib/shared/module/audio

`GlobalAudioPlayer` — a source, a waveform, and a set of controls, over
`just_audio` (and `video_player` for containers just_audio cannot
demux).

```dart
GlobalAudioPlayer(
  source: AudioSourceSpec.url(url),
  variant: AudioPlayerVariant.full,
  style: const AudioStyle(showLoop: false),
)
```

## Contracts

- **Style is the themeable bag `AudioStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once by
  `style.resolve(context)` into a `ResolvedAudioStyle`.
- **Resolution order**: `caller > GlobalAudioTheme.style >
  AudioStyle.defaults`, then colours from the palette.
- **Every hard-coded number lives in `AudioDefaults`.**
- **The widget carries what the player IS; the bag carries how it
  looks.** Source, variant, samples and callbacks are on the widget.

## The bag was HALF standardised, which is worse than neither

Colours could be omitted, but every size and flag carried an inline
default (`barWidth = 2.5`, `showSpeed = true`). A theme could not set
one without every call site overriding it back — the same shape
`NavigationRailStyle` had, and the same reason it could not be
rebranded.

All nullable now. **Null means "did not say"**, which is what lets a
caller change one thing without silently restoring defaults for
everything else.

## The resolve happens ONCE, and nothing downstream asks again

Each variant used to answer the leftover questions itself out of
`Theme.of(context).colorScheme` — four times for the same accent — and
`AudioWaveform` did it a fifth time. So a waveform inside a themed
player could disagree with the player around it.

`_PlayerChrome.build` resolves once and hands a `ResolvedAudioStyle`
down. **`AudioWaveform` takes a resolved bag** for exactly that reason:
it cannot be handed a half-answered one.

`forWaveformHeight` exists because the compact and message variants
draw a shorter waveform and that is the ONLY thing they change. A
`copyWith` on the resolved bag would invite restating anything.

## Colours resolve from the PALETTE, not from `Theme.of`

`context.primaryColors`, `context.textColors`,
`context.backgroundColors` — so they track role, brightness and
saturation. There were two `Colors.white` literals and four
`Theme.of(context).colorScheme` reads, which is how a player drew white
glyphs on a light surface.

**The play button's glyph is checked against the ACCENT**, not the
page: it sits inside a filled circle, so `estimateBrightnessForColor`
runs on the fill (or the gradient's first stop) rather than the
surface behind it. `surfaceColor` is on the resolved bag for that.

## Every control names itself

The module had **zero** `Semantics` before the gold-standard pass —
every control is a bare glyph with no text beside it, so a reader met a
row of unnamed buttons.

- **The play button says which STATE it is in.** Play, Pause, Loading
  and Error are four different things to a reader.
- **`_CircleIcon.label` is REQUIRED**, not optional. An optional one is
  a control that forgets, and this module already shipped a row of
  them.
- **A tooltip is NOT a label.** A tooltip is what a POINTER discovers,
  and the readers who need this have no pointer. `-15s` stays the
  tooltip; "Back 15 seconds" is the label.
- **The skip buttons name their DISTANCE**, because the step is
  configurable and the reader is choosing between 10 and 30 seconds.
- **The chips report their STATE.** A reader has no colour to tell them
  the loop is on. The speed chip also carries a name: `1.5×` is a
  value, and alone it does not say what it is the speed OF.
- **The slider announces a TIME.** Material announces a bare
  percentage, and "43%" of an unnamed thing is not a position.
- **The waveform is a slider when it can be scrubbed and DECORATION
  when it cannot.** A picture of a sound is not something to announce,
  and a reader tabbing a page should not meet it.

## A seek SWEEPS; playback does not

The waveform animates the playhead to a tapped position and follows
playback exactly. Those are opposite requirements and the difference is
the size of the step: playing forward at 1x moves it a fraction of a
bar per frame, and animating that would make the playhead lag its own
audio; a tap moves it a third of the way across in one frame, and that
reads as a jump. Anything past `seekSweepThreshold` is a seek.

That was reported as the progress "tracking the change but not
animating" — the value was right on every frame and nothing appeared to
move, because there was nothing between the two positions.

**Each bar grows from its own CENTRE as the playhead crosses it**, over
the time that bar represents. A horizontal wipe across a two-and-a-half
point bar is not something an eye can see: at forty bars over a
three-minute track each one is worth four seconds, and all of that
happened inside a sliver. Growing outwards spends the bar's whole
height on the same information, so the waveform reads as playing rather
than as a fill creeping along it.

## The playhead moves in PIXELS, not in bars

The waveform rounded the playhead to a whole bar index, so the fill
only moved when it crossed one — about once a second on a thirty-second
clip in a 140-point message bubble. It read as a waveform that was not
animating, punctuated by a bar flipping colour all at once, and it was
reported exactly that way.

The bar the playhead is INSIDE is drawn twice: unplayed underneath, the
played part clipped over it. `barFillFraction` is the whole of that
decision and none of the drawing, which is why it is a pure function
outside the painter — a painter cannot be asked what it drew, and a
source scan cannot see a rounding change. A guard that only read the
source missed exactly this mutation when it was tried.

**The chrome draws the DECODED samples.** It read `widget.samples`,
which skips the decode entirely, so a player told to decode its own
waveform drew the generic fallback shape forever and every clip in a
list looked identical. The handle already answers
`decoded ?? caller ?? fallback`; the chrome asks it now.

## A seek HOLDS the visual across itself

`scrubEnd` cleared the scrub fraction and then issued the seek, so
`progress` fell back to the old position for as long as the engine took
to move. A tap at 80% left the bar sitting at 20%, creeping forward
under the ticker, and then snapping across when the player finally
reported — read as a tap that had not taken.

It holds the fraction at the TARGET across the seek, and re-anchors the
interpolator before letting go. That second half is not optional: the
ticker extrapolates from the last position the platform reported, and
on iOS/macOS that arrives about once a second, so without it the bar
falls back to wherever the old stamp had crept to.

**`scrubEnd` overlaps with ITSELF, and that was the flash.** A tap
fires `onTapDown` — which starts and ends a scrub — while the drag
recogniser cancels around it, ending a second one. Both await a seek,
and the one that started FIRST can finish LAST, releasing its own stale
target over the newer one. Measured in the log: `prog` went 0.305, then
0.487, then 0.305 again, in sixteen milliseconds.

A generation counter fixes it: a call that has been superseded while
its seek was in flight releases nothing. And a drag-end carrying `-1`
with nothing buffered is not a seek at all — the recogniser is
cancelling a gesture that never became one, which happens on every tap,
so it now returns rather than seeking to where the playhead already is.

Three fixes before this one were each real and none of them was this.
Holding the visual, guarding the platform's stale report, and guarding
the read all had to happen; none of them could stop a second call
writing a stale value after the first had finished. It took the trace
to see it.

**The guard is on the READ, not on the writes.** Guarding each write
meant every future write had to remember, and several already did not:
the ticker, a play/pause transition re-stamping from the platform, the
end of a scrub. `_shownPosition` is what `progress` and every snapshot
report, so a stale value cannot leak out however it got written.

**A report is stale when it is still at the position playback was
LEFT** — not when it is far from the target. Those look equivalent and
are not: a moment after landing, playback has legitimately moved on
from the target, and a rule written the other way starts rejecting the
truth and freezes the clock until it times out. That was a fix that
would have replaced one flash with a longer one.

**And the platform is not believed until it agrees.** Holding the
visual was only half of it: `seek()` resolving means the command was
ACCEPTED, not that the clock has moved, and for a few frames after it
the platform still answers with the position it was seeked away from.
A ticker that trusts every report then shows the target, the old
position, and the target again — at sixty frames a second that is a
flash, reported as "it goes to 10, back to 20 for a split second, then
back to 10".

So every seek ARMS a guard (`_armSeek`), and reports that still
disagree with the target are ignored until one agrees or two seconds
pass. The timeout is not decoration: a seek the engine silently refused
would otherwise leave the ticker extrapolating from a position the
player never reaches, for the rest of the track.

Re-anchoring the interpolator and distrusting the platform are the same
act, so they are one method. A seek path that forgot the first would
crawl; one that forgot the second would flash.

`AudioScrub` carries the two decisions — what a scrub aims at, and
where that lands. Both backends had them inline and identical, and
neither could be tested, because the states need a real engine to
build. The subtle one is the **-1 sentinel**: Flutter's
`DragEndDetails` carries no local position, so the waveform cannot say
where a drag ended and reports -1 meaning "use the last value you were
given". With nothing buffered it falls back to the PLAYHEAD — seeking
to zero there would be worse than not moving at all.

## The visualizer repaints without REBUILDING

Its ticker called `setState` with an empty body sixty times a second —
rebuilding a whole subtree to move numbers the painter already had a
reference to. The bins are mutated in place, so the painter only ever
needed telling that they changed: it takes a `repaint` listenable, and
the tick bumps it.

It is also wrapped in a `RepaintBoundary`, so that repaint stops there
rather than dirtying whatever it sits inside.

**`line` and `wave` are CURVES.** Straight segments between forty-eight
points read as a jagged chart rather than as a sound — the corners were
the loudest thing on screen. Each segment is a quadratic whose control
point is the sample and whose ends are the midpoints either side, which
draws through the data without overshooting between it.

**It is DECORATION.** A picture of a sound says nothing a reader can
use, so it is wrapped in `ExcludeSemantics` and a screen reader walking
the page does not stop on it.

A subscription to the handle's state stream that did nothing has gone:
the ticker already runs every frame and reads the handle directly, so
the stream would only have said the same thing later.

## Presets

A preset is a NAMED BAG. Everything it decides is what the bag already
carries, so it merges with a theme and loses to a per-call override
like any other, and adds no code path.

- **`AudioStyle.voiceNote`** — play and the wave, nothing else. A
  message is heard once at one speed, so speed, loop and skip are
  three controls that would never be pressed.
- **`AudioStyle.spokenWord`** — speed and a THIRTY-second skip, which
  is an ad break rather than a missed word.
- **`AudioStyle.music`** — loop yes, speed no. Nobody listens to music
  at 1.5x, and a control nobody presses is a control in the way.
- **`VisualizerOptions.compact` / `.nowPlaying` / `.monitor` /
  `.ambient`** — chosen by what the numbers do TOGETHER rather than by
  naming a style: a bar count that suits a 96-point box does not suit
  a 40-point one, and smoothing that reads as lively at 48 bins reads
  as noise at 12. `monitor` is deliberately fast and falls fast,
  because a lazy meter looks broken when someone taps the mic to check
  it is hearing them.

## A failed load is a BUTTON, not a plate

The error state used to be a play button wearing an error glyph, which
is a dead end: something went wrong, the module knows what, and the one
control on the surface refused to do anything about it. Nearly every
failure here is transient — a URL that timed out, a file not there yet,
a session that lost the audio device.

So the play button becomes a RETRY button when the load failed. It says
so (`AudioStrings.retry`, not `.error`), and pressing it re-runs the
load. `AudioPlayerHandle.errorMessage` carries the reason for a caller
that wants to show it; the module does not put a paragraph of exception
text on a 56dp row.

**The video-backed retry builds a NEW controller.** `video_player`
cannot re-initialise one that failed — it fails again, for the reason
it already failed. `just_audio` can, so that one just re-runs `_init`.

## Resume is a PAIR, and the module keeps neither half

`initialPosition` + `onPositionChanged`, the same contract the video
module has, for the same reason: `lib/shared/module` has no storage, so
an app pairs them and keeps the value where it keeps everything else.

- **`just_audio` opens AT the position** — `setUrl(initialPosition:)`
  and friends. A seek issued straight after would race the load.
- **`video_player` has no such parameter**, so that backend does seek —
  after `initialize()`, which is the first moment it is safe.
- **Reporting is throttled** to `AudioDefaults.positionReportInterval`.
  The ticker runs every frame and the other end of a position report is
  usually a write to disk.

## The lock screen is a SEAM

An audio player that stops when the phone locks is not an audio player.
But what background playback needs is a foreground service on Android,
a background mode in `Info.plist`, and an `AudioHandler` that outlives
every widget — none of which may live in `lib/shared/module`, which
cannot reach the service layer at all.

So the module ANNOUNCES and an app wires. `AudioBackground.attach` /
`.detach` / `.report` are set in `bootstrap` against `audio_service`
(already a dependency); left null the module behaves exactly as it did.
Same shape as `VideoWakelock`, and for the same second reason: an
un-wired seam is inert, which is what keeps a widget test off a
platform channel.

- **`nowPlaying` is what claims it.** No metadata, no claim — a lock
  screen with nothing on it is worse than none.
- **`AudioBackgroundLink` is PER PLAYER**, not global. A page holds
  several, and the one that goes away must release only its own. A
  claim is taken once and released once; both are guarded, because two
  claims leak a token and none leaves a lock screen driving a player
  that is gone.
- **A play/pause flip always reports**, whatever the throttle says —
  that one changes a glyph rather than a number.
- **The native steps are the adopter's**, and they are the half that
  actually enables this. They are listed on `AudioBackground`.

## A player without a queue HAS one

Of one. `source` / `nowPlaying` / `samples` become a single
`AudioQueueItem` in `initState`, and every path below indexes
`_items` — so there is no "does this have a playlist" branch anywhere
in either backend, which is where the two would have drifted.

Each item carries its OWN metadata and its own samples, because both
are per track: a queue whose lock-screen title never changed would name
the first track all session, and one sharing a set of samples would
draw the first track's waveform under every one after it.

- **Moving throws the old item's state away** — decoded samples, band
  snapshots, the lock-screen claim, the clock, the seek guard. Keeping
  any of it is how the previous track's waveform ends up under this
  one, and a shared decode cache makes that RACE more likely rather
  than less: a decode that finishes after the queue moved is dropped by
  comparing the index it started on.
- **Only the item the player STARTS on resumes.** The ones after it are
  new listenings, and opening every one at the same offset is nonsense.
- **`previous` has two meanings and one button.** Under three seconds
  it is the track before; past that it restarts this one. Every music
  player ever shipped does this, because both presses are the same
  press. `AudioQueue.previousRestarts` is the rule, and it is pure.
- **Wrapping is the APP's decision** (`loopQueue`). A playlist someone
  put on loops; a run of voice notes does not. A queue of ONE never
  wraps either way — that would make "next" a restart button.
- **Auto-advance is ON here**, unlike the video module's. Audio is the
  case where it is expected, and a queue that stopped between every
  track would need a press to do the one thing a queue is for.
- **The video backend builds a NEW controller per item.**
  `video_player` opens one source and keeps it; there is no `setUrl` on
  a live controller. Same reason `retry` rebuilds one.
- **`video_player` has no completion event.** It stops with the
  position at the duration and repeats that on every listener call
  after, so the end is edge-detected against a `_completed` flag that a
  seek clears. Before this, the video backend never fired
  `onCompleted` at all.

## The sleep timer is one value and one control

`AudioSleep` is off, a duration, or the end of the track — one value
rather than a `Duration?` beside a bool, because the two cannot both be
set and a pair of fields that must not disagree eventually will.

- **An armed timer BEATS auto-advance.** Whoever set one did not ask
  for another track. The check is first in `_onTrackComplete`, and the
  order is guarded — put after, the queue moves before it is consulted.
- **"End of track" is not a countdown.** A clock set to "the rest of
  this" is wrong the moment anyone seeks.
- **The chip CYCLES**: off → 15 → 30 → 60 → end of track → off. A menu
  would be a surface to place, dismiss and theme for four values, and
  the cycle always has a way out by pressing the same thing. The
  OPTIONS live in the style, so `ResolvedAudioStyle.nextSleep` takes
  the step and the handle only takes the answer — which is also why
  there is no `cycleSleep` on the handle.
- **It is OFF by default**, alone among the controls. A sleep timer
  belongs to a podcast app and to nothing else.
- **The chip reads the VALUE and says the NAME.** `30m` beside a bed
  glyph is not a sentence, so the semantic label is the sentence.

## A waveform is decoded ONCE

`WaveformCache`, keyed by source kind, source, and sample count.
Decoding is a download plus a plugin pass and it was happening per
WIDGET — a chat thread showing one voice note in a list and again in a
preview decoded it twice.

Two things are needed and only one of them is a cache: a finished
decode is remembered, and an IN-FLIGHT one is SHARED. Ten players
mounting in the same frame all miss the cache together, so a plain map
would start ten downloads and then store the same answer ten times.

- **A failure is not remembered.** Nearly every one is a URL that timed
  out, and caching it means a retry can never succeed this session. An
  EMPTY decode counts as a failure for the same reason.
- **A decode that threw clears its slot too** — left behind, that
  in-flight entry is handed to every later caller, each of whom gets
  the same old error.
- **The braces in `whenComplete` are load-bearing.**
  `=> _inFlight.remove(key)` returns the removed FUTURE, which is that
  very future, and `whenComplete` waits on whatever its callback
  returns — so every decode hung for ever. Found by a test that timed
  out rather than by reading it.
- **The cap evicts the oldest**, which is what the insertion-ordered
  map is for.

## The visualizer is a bag now too

It was the last pre-gold-standard thing in the module: `VisualizerOptions`
with a non-nullable field and an inline default apiece, so a house that
wanted 32 bins everywhere had to say so at every call site, and the
colour was answered inside the widget.

- **`VisualizerStyle` is the BAG; `VisualizerShape` is the shape.** The
  enum used to own the bag's name, which is the whole reason the
  parameter was called `options:`. `style:` now, like everything else.
- **`GlobalVisualizerTheme`** carries the app-wide defaults
  (`MyGlobalVisualizerTheme.build`, wired in `theme.dart` beside the
  player's). Order is `caller > theme > VisualizerStyle.defaults`.
- **The resolve lives on the STATE, not in `build`** — the ticker reads
  the bag and runs between builds. And it is NOT `late`: the ticker
  starts in `initState`, resolving needs the inherited theme, and that
  is only there from `didChangeDependencies`. That exact combination
  shipped broken in the video module and threw on every first frame;
  here it starts from a context-free bag nothing ever paints with.
- **Only a changed BIN COUNT re-allocates.** The buffers are the one
  thing sized by the bag; re-allocating on any change would throw away
  the phases and gains that make the bars move differently from each
  other.
- **The FILL decides whether there is a box**, not the corner. The app
  theme puts a corner on every visualizer in the app, so reading the
  corner would wrap every one of them in a `Container` and a
  `ClipRRect` per frame for nothing. The corner is for when there IS a
  fill.

## Keys, and where they are decided

`AudioShortcuts` is the same shape as the video module's, for the same
reason: `FocusableActionDetector` rather than a bare `Shortcuts`,
because shortcuts only fire for a subtree that HAS focus and a player
is not a text field.

- **Focus follows the POINTER, and nothing autofocuses by default.** A
  page of voice notes that each grabbed focus would fight over it.
- **Off builds NOTHING**, rather than a detector that ignores its keys
  — that one still takes focus from whatever should have it.
- **No media keys.** Those belong to the OS, and an app that claimed
  them would take them from whatever is actually playing.
- **The map is `const`.** One rebuilt every frame re-registers the lot.
- **What a key DOES is a pure function** (`AudioShortcutRunner`) over a
  narrow `AudioShortcutTarget` — six methods rather than the whole
  handle. `GlobalAudioPlayer` cannot be built under `flutter_test`, so
  a key map wired inside it would have no coverage at all; a fake of
  the full handle to prove that `]` means next would be bigger than
  the thing it checks.
- **The skip distance comes from the resolved bag**, so an arrow moves
  by exactly what the button beside it does.

## What lives outside `global_audio.dart`

It was 2186 lines holding a widget, two backend lifecycles, three
control surfaces and the chrome. What left was chosen for what it buys
rather than for the line count:

- **`audio_controls.dart`** — `AudioPlayButton`, `AudioCircleButton`,
  `AudioChipButton`. No state, no knowledge of the player around them.
- **`audio_chrome.dart`** — `AudioPlayerChrome`, everything the player
  DRAWS. It touches neither engine: it reads an `AudioPlayerHandle`
  and nothing else, which is exactly why both backends share it.
- **`audio_shortcuts.dart`** — the key map and what a key means.
- **`audio_background.dart`** — the lock-screen seam.
- **`visualizer_models.dart`** + **`theme/visualizer_theme.dart`** —
  the visualizer's bag and its resolve.

What is LEFT is the widget and the two states, and those two are not
separable from each other in any useful way — each is a lifecycle
around a different engine behind one interface, and splitting them
into a file apiece would move the lines without making either shorter.

**`AudioDefaults.flatWaveform` moved with the chrome.** It was a
private static on the chrome widget that both backend states reached
into — a number in the wrong place, and the split made that obvious.

## Gotchas

- **Two backends, one interface.** `just_audio` cannot reliably demux
  mp4/mov on iOS/macOS, so `AudioSourceSpec.video*` routes through
  `video_player` with the frames decoded and discarded. Both states
  implement `AudioPlayerHandle`, and `_PlayerChrome` reads only that —
  so the visual layer never learns which one it is driving.
- **A player with no surface draws none.** `padding` still applies, but
  a player dropped into a card that already has a surface should not
  paint a second one.
- **The speed cycle WRAPS.** Stopping at the fastest strands anyone who
  overshoots. `ResolvedAudioStyle.nextSpeed` is pure, and a rate the
  list has never heard of starts the cycle over rather than throwing —
  `indexWhere` returns -1, and -1 + 1 is 0.

## Showcase + tests

`/audio-showcase`. `test/audio/audio_style_test.dart` — merge order,
resolution, the palette colours, the speed wrap, the theme extension's
snap. `test/audio/audio_a11y_test.dart` — every control names itself.
`test/audio/audio_shortcuts_test.dart` — what a key means, and that
the map claims no media keys.
`test/audio/visualizer_style_test.dart` — the visualizer's bag, its
resolve order, the palette colour and the snap.
`test/audio/audio_queue_test.dart` — where a queue goes, what previous
means, and the sleep cycle. `test/audio/waveform_cache_test.dart` — one
decode per source, shared in flight, failures not kept.
`test/audio/audio_background_test.dart` — the lock-screen seam: inert
un-wired, claimed once, released once, throttled, and a play/pause flip
that goes through anyway.

## Known gaps

- **The engine cannot be started in a unit test.** `just_audio` and
  `video_player` both want a real platform, so `GlobalAudioPlayer`
  cannot be built under `flutter_test` at all. The accessibility guard
  is a SOURCE scan, which is crude and is the only thing standing
  between this and the state it was in.
- **`global_audio.dart` is ~1600 lines** holding the widget and two
  backend states. Everything separable HAS been separated — see above.
  The two states are not separable from each other.
- **The visualizer has no test that DRAWS anything.** The bag, the
  resolve and the theme are covered; the six shapes are asserted
  structurally, because there are no golden files here.
