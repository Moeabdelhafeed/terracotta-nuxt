# CLAUDE.md — lib/shared/module/scanner

`GlobalScanner` — a camera, a viewfinder, and what to do with a code,
over `mobile_scanner`.

```dart
final result = await GlobalScanner.scan(
  context,
  formats: const [ScannerFormat.qr],
  captureMode: ScannerCaptureMode.single,
  style: ScannerStyle.wide,
);
```

## Contracts

- **Style is the themeable bag `ScannerStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once by
  `style.resolve(context)` into a `ResolvedScannerStyle`.
- **Resolution order**: `caller > GlobalScannerTheme.style >
  ScannerStyle.defaults`, then the accent from the palette.
- **Every hard-coded number lives in `ScannerDefaults`.**
- **The widget carries what the scan IS; the bag carries how it looks.**
  Formats, capture mode, the callback and the two button labels are on
  the widget. Everything else moved.

## Only the ACCENT is a palette colour

The controls sit on CAMERA pixels, which are arbitrary — a kitchen
counter, a night street, a white receipt. White on a scrim is the only
pairing that holds over all of them, which is why every scanner ever
shipped uses it, and `context.textColors.primary` would put dark glyphs
on a dark frame the moment the theme went light.

The brackets are the exception, for the same reason the video module's
seek bar is: the viewfinder is BRAND, it is what a rebrand actually
wants to change, and it sits over a dim that guarantees contrast.

## The box now MEANS something

A viewfinder was drawn over a picture that was scanned edge to edge.
Anything the camera could see read — a poster behind the code, a
second QR on the same page — and then the reader was told they had
aimed at something.

`restrictToViewfinder` (on) pushes the viewfinder's rect to the plugin
as its scan window, so what is drawn and what is READ are the same
rectangle.

- **One rect, `ResolvedScannerStyle.viewfinderRect(size)`.** The
  painter used to compute its own from the same numbers, which is
  exactly how a drawn box and a scanned region come apart.
- **It is computed in LAYOUT, not in `build`.** The window is a
  fraction of the PREVIEW, and a scanner in a 260-point card is not
  the size of one filling a page.
- **And it is CLAMPED to the preview.** A 300-point window asked for
  on a 200-point card hangs off both sides, and the plugin refuses a
  scan window that leaves the picture — so the box would draw and
  nothing at all would read.
- **The wide preset exists because 1D codes are stripes.** A square
  window over a long barcode refuses reads that are plainly inside the
  picture, and asks someone to line up a shape the code does not have.

## The camera's state is READ, never mirrored

Three local flags used to hold the torch, the facing and the zoom
beside the controller. A mirror is wrong whenever the platform refuses,
and it refuses often: a front camera has no torch on most phones, so
the glyph said "on" over a light that never came on.

`MobileScannerController` is a `ValueListenable`, so the controls are a
`ValueListenableBuilder` over its state — `torchState`, `zoomScale`,
`availableCameras`.

**Nothing appears that cannot work.** No torch on this camera, or no
second camera to flip to, and the control is not drawn at all. An
UNKNOWN camera count is taken as "there is another one", because the
plugin reports null until it has started and a control that appears a
beat after the screen does is worse than one that was always there.

## The lifecycle is OURS

`MobileScanner` wires its own `WidgetsBindingObserver` **only when it
built the controller**. This module passes one in — it has to, for the
format list and the scan window — so stopping and starting is the
caller's job, and nothing was doing it.

- A scanner left for the home screen came back to a **frozen preview**
  on Android.
- The camera stayed **open behind other apps** in the meantime, which
  is both a battery cost and the sort of thing a review flags.

`paused` / `inactive` / `hidden` / `detached` stop it; `resumed`
re-checks the permission (it may have been flipped in Settings while
the app was away) and then starts it again.

## What a read MEANS is a pure function

`ScannerCapture.decide` — the switch it replaces had three cases where
two did the same thing, and none of it could be tested, because
`GlobalScanner` needs a camera to build at all.

- **`single` stops the camera, and stops it BEFORE it reports.** The
  caller usually pops the route, and a camera still reading during that
  pop reports again into a widget on its way out.
- **`noDuplicates` was not enough on its own.** It suppresses the same
  code, so a SECOND code entering the frame during the pop reported
  over the first one's head. `alreadyReported` is what actually makes
  "single" single.
- **`manual` ignores everything while one is held**, rather than
  quietly replacing what the reader is looking at.
- **A read TICKS** (`enableHaptic`), because the screen is usually
  about to close and the picture it was showing is gone before anyone
  has read anything.

## `any` beside real formats means ANY

The plugin takes an EMPTY list as "no restriction", and `ScannerFormat.any`
maps to null — so `[any, qr, ean13]` silently became `[qr, ean13]` after
the `whereType` dropped the null. Someone who asked for everything got a
scanner that ignored most of it. `ScannerFormat.isUnrestricted` is the one
place that knows, and a test walks every format to check that no two of
them map to the same plugin value.

## A scanner that takes any code is the wrong scanner

`validate` is the callback a real flow needs: only OUR tickets, only a
twelve-digit SKU, only a URL on one host. Without it every stray QR in
the room popped the route and the caller reopened the scanner, which
reads as a bug even though every part of it worked.

- **A refused code is not a read at all.** `ScannerCapture.decide`
  takes `accepted` FIRST, before the mode has its say — so a refusal
  does not spend `single`'s one report.
- **It says so, and keeps looking.** The refusal REPLACES the hint
  rather than stacking under it: two lines of white text under a
  viewfinder is a paragraph nobody reads mid-scan. It clears itself
  after `rejectionLinger`, or it would still be up over the code that
  IS accepted a second later.
- **No tick and no flash.** Those mean "that worked".

## An accepted code FLASHES the brackets

A haptic was the only mark a read left, and a haptic is nothing at all
to someone who has them switched off or is wearing gloves. The brackets
carry it rather than a plate: they are already where the reader is
looking, and a plate would cover the code that was just read.

- **`acceptedCount` is a COUNTER, not a flag.** Two reads in a row have
  to flash twice, and a bool that is already true says nothing the
  second time.
- **Reduced motion drops it** with the sweep. The haptic and the
  caller's own answer still happen.

## An image is a way in

A code arrives as a screenshot or a saved ticket at least as often as
it arrives on a wall. `analyzeImage` is one call, and it needs a path.

`onPickImage` is the seam: the picker belongs to the APP — this module
may not reach the media layer — and the DECODE belongs here, beside the
formats the caller already chose. The control appears only when an app
has one to offer, and a picked image lands in the same `_handle` as a
camera read, so validation, the capture mode, the tick and the flash
all apply to it too.

## Pinch, and tap to focus

The two gestures people try on a camera without being told.

- **The gesture layer sits UNDER the chrome**, so a pinch that started
  on the torch button is not a zoom. Same rule as the video module's
  film gestures.
- **A scale recogniser claims nothing until the fingers move**, which
  is what leaves the plugin's own tap-to-focus its taps.
- **One finger is not a pinch.** `onScaleUpdate` fires for a single
  pointer too, and treating that as a zoom makes every swipe move the
  lens.
- **A pinch is a RATIO; the camera's zoom is 0..1.** Half the range per
  full spread — measured, a two-finger spread is about 2.5x, and
  mapping that onto the whole range makes small corrections
  impossible.

## The window is a FRACTION of the short side

A fixed 260-point square was fine on the phone it was written on. This
app rotates, so the same square is most of a landscape phone's height,
and on a tablet it is a postage stamp.

`viewfinderFraction` (0.7) × `viewfinderAspect` (1), off the SHORT side
both ways up — that is the side that constrains. `viewfinderSize` still
pins an exact box for a caller who genuinely needs one everywhere.

**A wide window on a narrow screen keeps its SHAPE**: both sides scale
together, because shrinking one changes the shape the reader is being
asked to line up with.

## Half the controller is STYLE

Detection speed, its timeout, auto-zoom, invert, resolution — all
constructor arguments of `MobileScannerController`, and all decisions
an app makes once. Two things follow:

- **The controller is built on FIRST USE, not in `initState`.**
  Resolving needs a theme that is only there from
  `didChangeDependencies`; built earlier, a caller's detection settings
  were silently the floor's.
- **A bag that changes one of those five builds a NEW controller** (the
  same resync a failed camera uses). They cannot be set on a live one,
  so without this a caller switched detection speed and watched nothing
  happen.

**`detectionTimeout` is the one to reach for first.** A code left
sitting in the frame reports on every frame otherwise, and a continuous
scanner machine-guns its callback.

## Which code, when there are several

`barcodes.first` is whatever the detector happened to list first, which
is arbitrary the moment two are visible — a sheet of labels, a poster
behind the one being scanned. `ScannerCapture.pickNearest` takes the
one closest to the middle of the window.

A barcode with no corners cannot be placed (the web reports none), so
it keeps its listed order behind everything that can, rather than
winning by default.

## Accessibility

- **Every control is a named node.** They were a hand-rolled
  `Material` + `InkWell` + `Icon`: no name, no 48dp target, and a disc
  drawn by hand beside every other one in the app. They are
  `GlobalIconButton` now, and `ScannerControlButton.label` is
  REQUIRED — each is a bare glyph on a picture with no text near it.
- **The torch is a TOGGLE** (`toggled:`), and its label says what
  pressing it will DO — the glyph already shows the current state, so
  "flash off" beside it reads as an instruction rather than a report.
- **The pending plate and both refusal plates are LIVE REGIONS.** A
  code arrives without anyone touching the screen; a reader who cannot
  see it is otherwise told nothing at all.
- **The viewfinder says nothing** — it is decoration, and a screen
  reader walking the page should not stop on it.
- **Reduced motion STILLS the scan line** rather than shortening it.
  It is an affordance, not information; the dim and the brackets stay.

## Nothing is drawn over a camera that is not up yet

There are two waits before a picture: the permission being answered,
and the camera warming up. Both show the same spinner — the first from
`_permission == null`, the second through the plugin's
`placeholderBuilder`, which it calls while `isInitialized` is false.

The chrome waits for BOTH. A viewfinder and a full control row painted
on top of the spinner read as a scanner that has started and is
refusing to see anything, and the torch button pressed in that moment
does nothing — `toggleTorch` returns early when the camera is not
running.

## The route wears the APP's bar

`GlobalAppBar`, not Material's. A raw `AppBar` wrote its own title
style, so the one screen pushed over everything else was the one screen
that ignored the app's typography, its bar theme and its rebrand.

- **`AppBarVariant.transparent` is the variant with no surface.** It
  resolves to a transparent background and a white foreground whatever
  the palette says, which is exactly what a bar floating on a camera
  picture needs — the same white-on-arbitrary-pixels rule the controls
  follow.
- **The leading is a CLOSE, not a back arrow.** It is a fullscreen
  dialog; the gesture is a dismissal rather than a step backwards.

## ONE thing starts the camera

`MobileScanner` starts the controller it is handed whenever `autoStart`
is on — and this state starts it too, on the way back from the
background, which the widget cannot do for a controller it did not
build. Both ran. The platform answered the second with
*"the scanner was already started"*, and that error landed on a camera
that WAS running: an error plate over a live preview, the picture
flashing through whenever a new state rebuilt it.

`autoStart: false`, and the state owns start / stop / restart end to
end. Two more things follow:

- **The re-entrancy guard is OURS.** The controller's own `isStarting`
  is set only AFTER it waits to be attached to a widget — up to half a
  second, during which a second call sails past the guard and reaches
  the platform.
- **"Already started" is not a broken camera**, so it does not get the
  plate. It means this side and the platform disagree about what is
  running — a native scanner left behind by a hot restart, or by a
  route that went away mid-start. It shows the wait and RESYNCS.

## A resync REPLACES the camera; stopping it does nothing

`MobileScannerController.stop` is a no-op when its own state says the
camera is not running — and that is exactly the state it is in after
"already started". So the first resync stopped nothing, the next start
was refused for the same reason, and the retry button spun for ever.
The error was real; the recovery was talking to itself.

`dispose` is the one call that reaches the platform unconditionally, so
the controller is thrown away and a new one built.

- **The new one goes in FIRST**, then the old is disposed — otherwise
  the preview is still mounted on a controller whose platform side has
  already gone.
- **The preview is REMOUNTED under a new key.** `MobileScanner` reads
  its controller once, in `initState`, and would go on talking to the
  disposed one. So does the `ValueListenableBuilder` the chrome hangs
  off — a new controller is a new listenable. **Their keys must
  DIFFER**: both are children of the same `Stack`, and a bare
  `ValueKey(_generation)` on each is *"Duplicate keys found"* on the
  first build, which is how this shipped for one commit.
- **The scan window is forgotten with it.** It belonged to the old
  controller; the new one has never been told about one.
- **Automatic recovery is capped at ONE.** A recovery that keeps
  failing is a spinner for ever, which is what the uncapped version
  shipped as. After the first attempt the plate says what happened and
  a person decides — and pressing the retry hands the budget back,
  because that IS a person deciding.

Every other error is shown rather than papered over: a retry loop
against a camera another app is holding is a spinner for ever.

## A refused camera is not a refused PERMISSION

Two different plates, because the ways out are different. A permission
is the reader's decision and leads to Settings or to a re-ask. A camera
that failed to start is another app holding it, a simulator without
one, or a driver that fell over — all worth a **retry**, where before
they were a black screen with a viewfinder painted on it.

## Gotchas

- **The resolved bag lives on the STATE, not in `build`.** The
  lifecycle handlers and the scan-window sync read it between builds.
  And it is NOT `late`: the controller is built in `initState` while
  resolving needs a theme that is only there from
  `didChangeDependencies` — the combination the video module shipped
  once, where every player threw on its first frame.
- **`ScannerStyle.minimal` turns the dim off**, and that is deliberate:
  dimming three quarters of a 200-point card leaves a stamp-sized
  picture.
- **The route is a shell, not the scanner.** `GlobalScanner.scan`
  pushes `_ScannerRoute`, which is a `Scaffold` around the same widget
  everyone else embeds.

## Showcase + tests

`/scanner-showcase` — the switches ARE the bag's fields, plus the three
presets and an embedded scanner that only starts its camera when asked.

`test/scanner/scanner_style_test.dart` — merge order, resolution, the
palette accent, white-on-scrim controls, the app theme's corner, the
viewfinder rect and its clamp, the lerp snap.
`test/scanner/scanner_capture_test.dart` — what a read means in each
mode, which controls can work, and the format whitelist.
`test/scanner/scanner_a11y_test.dart` — a source scan: every control
named, the torch's state, the live regions, the controller-driven
values, the scan window, the lifecycle, the resolve, the flash, the
refusal, the image path and the gestures.
`test/scanner/scanner_overlay_test.dart` — the bracket paths and the
sweep line, by geometry.

## NOT SEEN RUNNING

Everything here is verified by the analyzer, by 104 tests and by
reading — and **none of it has been watched on a device**. The camera
paths in particular cannot be exercised any other way: `mobile_scanner`
wants real hardware, so nothing in `test/` starts a camera, and the
guards over the widget are source scans.

What that means in practice: the tests say the code SAYS the right
thing, not that the picture is right. Specifically unwatched —

- the scan window actually refusing a code outside the brackets,
- the lifecycle stop/restart across a real background and return,
- the torch, the flip, the pinch and the tap-to-focus on hardware,
- the resync path and its one-shot cap against a genuinely stuck
  native scanner,
- the success flash and the refusal line, both of which are timing,
- reading a code out of a picked image.

Four camera bugs on this module were found by a person looking at a
screen rather than by anything in `test/` — a frozen preview after a
background, an error plate over a live camera, a spinner with a loop
behind it and a duplicate-key throw. Treat this section as open until
someone has held the phone.

## Known gaps

- **Nothing here can be BUILT under `flutter_test`.** `mobile_scanner`
  wants a camera, so the widget half is asserted by scanning its own
  source — crude, and the only thing standing between this module and
  the state it was in.
- **The painter is tested by GEOMETRY, not by appearance.** There are
  no golden files here, so `bracketPaths` and `sweepLineY` are pure and
  checked by their bounds — which catches the copy-paste that builds a
  bottom-right bracket out of `top` and nothing else would.
- **Torch state on the web** is whatever the browser reports, which on
  most of them is `unavailable` — so the control simply is not there.
