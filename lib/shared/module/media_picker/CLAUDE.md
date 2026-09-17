# CLAUDE.md — lib/shared/module/media_picker

Four pickers over one contract: images, video, files, and a mixed
attachment picker.

```dart
GlobalImagePicker(
  images: _photos,
  multiple: true,
  onChanged: (v) => setState(() => _photos = v as List<PickerItem>),
  style: MediaPickerStyle.formField,
  recentCache: getIt<RecentUploadsCache>(),
)
```

## Contracts

- **Style is the themeable bag `MediaPickerStyle`** — every field
  nullable, with `defaults` + `mergedWith` + `copyWith`, materialized
  once by `style.resolve(context)` into a `ResolvedMediaPickerStyle`.
- **Resolution order**: `caller > GlobalMediaPickerTheme.style >
  MediaPickerStyle.defaults`, then colours from the palette.
- **Every hard-coded number lives in `MediaPickerDefaults`.**
- **The widget carries what is being PICKED; the bag carries how it
  looks and what it offers.** The value, the callbacks, the validator,
  the layout and the maximum are on the widget. The tile size, the
  corner, the badge, the camera, the clipboard, reordering, the recent
  cache and compression moved.

## `GlobalImagePicker` took thirty-three parameters

That is the reason this pass happened. Nine of them were visual or
"which affordance", every one forwarded by hand, and the file, video
and attachment pickers each carried their own copy of the same numbers
— `circular(14)` eight times, a `0.55` scrim seven times, three
different dot sizes. Each copy was free to drift from the others, and
several had.

A tile in the image picker and a tile in the file picker are the same
tile. The bag is what makes that TRUE rather than a coincidence.

## The module does not reach the DI catalog

`lib/shared/module` may not, and this module did — `getIt<RecentUploadsCache>()`
in four files, which is the one hard rule the directory has.

`recentCache` is a constructor parameter now, the shape
`PdfRecentDocsList.bookmarksCubit` already had. An app hands it
`getIt<RecentUploadsCache>()`; null means no recents UI, which is also
what `style.useRecentCache: false` asks for.

## Every slot is a named node

The module had **not one accessible name in seven thousand lines**: a
whole page of tiles, dots and add slots that announced nothing at all.

- **`PickerInteractable.label` is REQUIRED.** Optional is a slot that
  forgets, and this module was every slot forgetting. Same call the
  video and scanner controls made.
- **A tooltip is not a label.** It is what a POINTER discovers, and
  most of the readers who need this have none.
- **One node per slot.** The label merges everything under it —
  `explicitChildNodes` would hand a reader the badge, the dots and the
  picture separately, which is four stops for one tile.
- **A tile says which one it is and whether it is uploaded**
  (`MediaStrings.itemOf`, `newItem`). The badge that carries the
  second part is a COLOUR, and a colour says nothing out loud, so the
  badge itself is excluded.
- **The download dot was a bare `GestureDetector`** — no name, no
  keyboard, no focus ring — beside two dots that had all three.

## Colours: palette, except on a PICTURE

The chrome resolves from `context.*Colors`: the accent, the empty
slot's surface, the hint, the remove dot, the badge. `Theme.of(context).colorScheme`
appeared eleven times and is gone from the pickers.

**What stays white-on-black is what floats over MEDIA** — the dot
scrims, the lightbox chrome, the upload ring. Those sit on whatever was
photographed, and a surface colour disappears into half of them; it is
the same argument the video controls and the scanner make, and
`MediaPickerDefaults.dotScrim` / `busyScrim` name it rather than
repeating a literal.

## The dots go through `GlobalIcon`

Copy, download, remove and trim were each a `Container` +
`BoxDecoration` + `Icon` — the exact hand-rolled disc
`test/icon/icon_adoption_test.dart` exists to stop, and the guard
caught them the moment their glyphs stopped being `const`. Six of them
across the four pickers, `GlobalIcon.circle` now, sized off
`dotIconSize` + twice `dotPadding` so the disc is the same size it was.

## Presets are named BAGS

`avatar` (one round slot, nothing to reorder, no badge — with one slot
"new" is obvious), `composer` (small, tight, NOT dashed: the composer
around it already has a border and a second one inside reads as a field
inside a field), `formField` (sits in a column of inputs and must not
look like a photo gallery).

## The English that was baked in

`'NEW'`, `'Crop'`, `'Clipboard'`, `'Clipboard (empty)'` and two
tooltips were literals in a module where everything else went through
the ARB. They are `MediaStrings` now, along with the names every
control needed for the semantics above.

## The validator is the one testable part, and had no tests

`MediaPickerValidator` decides whether a pick is ACCEPTED, and it is
pure enough to run against real files in a temp directory. Every rule
reads bytes, so the tests write actual PNGs — a fake `File` would be
testing the fake.

Worth knowing about the rules themselves:

- **The floor measures the SHORTEST side.** A 200×10 strip passes a
  naive width check and is still unusable as an avatar.
- **Exactly the cap is allowed.** A limit stated as "max 2 MB" that
  refuses a 2 MB file is a limit nobody can hit.
- **Extensions are case-insensitive.** Cameras write `.JPG`.
- **Image rules SKIP a non-image.** The validator is shared with the
  file picker, where a PDF is a perfectly good pick.
- **The first failure short-circuits**, and custom rules run last.

## The full-screen view

`showPickerLightbox` — one route, one page per item, swipeable.

- **It wears `GlobalAppBar`**, transparent variant. The old bar was a
  hand-rolled `Stack` of pills inside a `SafeArea`, and under
  `immersiveSticky` a `SafeArea` reads `padding` — which immersive
  mode ZEROES — so the close button and the counter sat under the
  dynamic island. `viewPadding` is the one that still reports the
  housing there, the same call the video module's fullscreen page
  makes.
- **The title is the item's NAME, marqueed.** A counter says where you
  are, not what you are looking at; it moves to the subtitle, and only
  when there is more than one.
- **A drag is ONE pan when both axes are ours.** A vertical recogniser
  and a horizontal one cannot both win — the arena takes whichever
  crossed its slop first and the other never fires — so a diagonal
  flick moved the picture straight down or straight sideways and never
  at an angle. With several items the `PageView` owns the horizontal
  axis, so there it stays two drags.
- **A video is `GlobalVideo`.** It was a raw `media_kit` `Player` plus
  `Video`: a second video implementation with no controls, no seek bar,
  no keyboard and nothing a `VideoStyle` or `GlobalVideoTheme` could
  reach. In a fullscreen SHAPE rather than the module's fullscreen
  route — this page already IS the full screen, and pushing that route
  on top would put a second bar over the first.
- **A PDF opens HERE.** Handing it to `open_filex` sent the reader into
  another app for a document this one has a viewer for, with
  bookmarks, search, night mode and a resume position. `enableHero`
  and `panEnabled` are off: the lightbox owns the frame and the
  gestures.
- **Both of those FILL the page.** A `Center` hands loose constraints
  to something that sizes itself to what it is given, and neither takes
  the background tap — one owns its controls, the other its scroll.

## What a device said about the full-screen view

Every one of these was found by looking at it, and none by the suite.

- **The bar was inset TWICE.** It carries a `SafeArea` of its own, and
  padding it by hand as well is a strip of black above it. What it
  needed was the right NUMBER, not a second inset — so the bar is
  handed `viewPadding` AS its padding and applies it once.
- **The title was hand-written.** A 16-point weight-600 `Text` in a
  `GlobalMarquee`, beside every other bar in the app wearing the
  theme's. `GlobalAppBar` styles its own title and marquees it when it
  overflows: the name goes in as a STRING.
- **A pan could not win.** The picture underneath is a `PhotoView`, and
  its scale recogniser is in the arena for every drag that starts on
  it, so an ancestor pan recogniser never won and the page could not be
  dragged at all. A `Listener` sees pointers WITHOUT joining the arena
  — the same reason the video module drives its tap-to-show that way —
  and `canDrag` keeps the two from fighting: at rest the drag
  dismisses, zoomed in it belongs to the picture.
- **Realign comes BEFORE rotate.** It is the button that appears and
  disappears, so with it second, pressing rotate pushed rotate itself
  sideways and the next press landed on whatever had taken its place.
- **The player and the document are BOUNDED**, like the picture. Filled
  to the screen they read as a different screen, and they left the
  `PageView` no margin to take a swipe in.
- **The player's swipe gestures are OFF.** A player that seeks on a
  swipe takes every page change with it.

## A long press opens ONE thing

`GlobalPopupTrigger.longPress` listens to raw POINTERS and never joins
the gesture arena — which is deliberate, and wrong for an anchor that
already has a tap of its own. The slot's tap recogniser was never
rejected, so a long press opened the source menu AND the source sheet
underneath it.

`secondaryTap` is the same menu on a real `GestureDetector`, so the tap
loses to the long press the way it should. Right-click comes free with
it, which is what a desktop reader tries first.

## What the lightbox's controls look like

- **Every bar control is `GlobalIconButton` on a scrim disc**, at one
  size. They were a hand-rolled `Material` + `InkWell` + `Icon`, and
  the CLOSE button had no disc at all — a white cross on a white
  photograph is invisible.
- **The player and the document are SQUARE.** A rounded frame inside a
  black page draws a card nobody asked for, and the picture beside
  them has no corner.
- **The document is bounded by what is actually FREE**, and starts
  BELOW the bar. A fraction of the screen cannot know where the bar
  ends — 82% of an 844-point screen leaves 76 points at the top, and
  the bar with its housing inset is nearer 115, so the first page slid
  under the title. The height is `screen − bar − a gap`, running to
  the bottom EDGE: the viewer's own control bar is wrapped in a
  `SafeArea`, so paying the home indicator here as well left its white
  inset and then a strip of black beneath it. It is TOP-aligned: centring a box that is
  short by the bar's height puts half that space at each end, which is
  half a bar of overlap up top and a strip of dead black underneath.
- **Tapping the space around them closes the page.** It closed for a
  picture and did nothing for a video, which is one gesture answering
  differently on two pages of the same viewer. `_BackdropDismiss` is
  the outer-tap-dismisses / inner-tap-absorbs pattern the file plate
  already used.
- **The player wears the shape the video module already had**: the
  transport centred in the bar, the clock split to either end of the
  timeline, and the fullscreen button — the control a reader looks for
  first, even inside a full-screen page, because it is what takes a
  portrait clip to landscape.

## A video tile shows a FRAME

`VideoThumbnailService` decodes one and the multi-tile path always used
it; the SINGLE preview did not, so the commonest case — a "single
video" field — was a play glyph over a filename. Both paths decode now,
with the glyph on a scrim so it reads over a bright frame.

## Upload is a SEAM now, and can be stopped

The module had the whole upload UI — a ring per tile, an error
overlay, retry on tap — and nothing to drive it: a caller had to build
an `UploadController` and hand it to every picker, so most call sites
had no upload at all.

`MediaUpload.uploader` is the same shape as `AudioBackground`: an app
wires it once in `bootstrap` against its API layer, and
`MediaUpload.controller()` hands every picker one. Un-wired it returns
NULL rather than a controller that throws, because a picker given one
of those draws upload chrome for an upload that cannot happen.

- **The tile in flight IS the stop button.** It was wrapped in an
  `IgnorePointer` — the one state a reader most wants to interrupt,
  and no way to.
- **A cancel WINS over a result that lands after it.** A `Future`
  cannot be cancelled, so the transport finishes whatever chunk it was
  on; reporting success for something the reader stopped is the one
  answer they will not expect.
- **A stop is not painted as a failure.** Red says something went
  wrong when nothing did.
- **`retryFailed` and `inFlight`** are for the submit button that
  should not fire yet.

## What a pick leaves behind is SAID

- **Over the limit is reported.** A multi-select that brought back
  eight for four slots dropped four of them without a word, which
  reads as the picker having lost them.
- **The same file twice is ONE tile.** Picking it again gave the
  reader two identical tiles and the server two identical uploads.
- **Preparing shows and ANNOUNCES itself.** Compressing a
  twelve-megapixel photograph takes seconds, and the picker showed
  nothing at all in that time — a tap, a choice, and an unchanged
  screen.

## Reordering without a drag

Drag-only is no order at all for a keyboard, a screen reader, or anyone
who cannot hold and drag. `PickerReorderable` adds the two moves as
`CustomSemanticsAction`s and as ⌥←/⌥→, and the move ANNOUNCES where it
landed — a silent reorder tells a screen-reader user that nothing
happened.

**The direction names follow READING order**: "move left" in an Arabic
layout moves the tile the way the reader means, and `Directionality` is
what knows which that is.

## A picked item can be BYTES

`PickerItem.bytes` — the web has no `File` to give, and a pasted image
or a camera frame is the same shape. Adding a third variant to a sealed
type lights up every exhaustive switch in the module, which is the
honest cost of the feature and is exactly what made each of these
decisions explicit:

- **The recents cache does not keep them.** It remembers WHERE
  something is; bytes are neither a path nor a URL, and holding them
  would make it a store of files it has to write, name and clean up.
- **A video cannot be played from memory.** `media_kit` opens paths and
  URLs, so the lightbox says what it cannot do rather than writing the
  clip down somewhere and guessing where.
- **A PDF can** — the viewer takes bytes directly.
- **The upload key is the name and the LENGTH**, since there is no path
  to identify it by.

## A menu row that is still working SPINS

Share and open are round trips through the OS — a second or two on a
cold start — and until one appeared the menu simply sat there, so the
second press queued a second sheet behind the first.

The spinner goes on the ROW, in the leading slot where that row's glyph
was. The menu is what the reader is looking at and the row is the thing
that has not answered; a scrim over the picture behind it answers a
question nobody asked. It is sized to the glyph, or the label jumps
sideways as it swaps in.

- **Every other row goes quiet meanwhile.** Two native sheets at once
  is not a thing to allow.
- **Delete never spins.** It is instant and pops the page.
- **It clears in a `finally`** — the sheet closing IS the app coming
  back.
- **The open menu follows a rebuild**: `GlobalPopup` forwards a fresh
  builder into a live overlay, so a `setState` on the page updates the
  rows that are already on screen.

## A round tile clips its PICTURE, not itself

The dots sit at a tile's corners, and a corner is exactly where a round
slot has no room. `MediaPickerStyle.avatar` is a 60-point radius, so
clipping the whole tile took the remove and download buttons off with
it — reported from a device as an avatar with no way to clear it.

`PickerFilledSlot.clip` is off for tiles, which clip the picture
themselves and leave the overlay layer alone.

## Gotchas

- **The resolved bag lives on the STATE, not in `build`.** The pick
  handlers read it between builds. And it is NOT `late`: resolving
  needs a theme that is only there from `didChangeDependencies` — the
  trap the video module shipped once, where every player threw on its
  first frame.
- **`PickerItem` is sealed and mixed on purpose.** An update screen
  hydrates with `PickerItem.url`s from the server, the reader adds
  `PickerItem.file`s, and the form submits both — which is why the NEW
  badge exists at all, and why it only appears once a URL has been
  seen.
- **`onChanged` is `ValueChanged<dynamic>`** because single mode emits
  a `PickerItem?` and multi emits a `List<PickerItem>`. Two asserts in
  the constructor keep the pairing honest.

## Showcase + tests

`/media-picker-showcase`.

`test/media_picker/media_picker_style_test.dart` — merge order,
resolution, the palette colours, the presets, the app theme's corner,
the lerp snap.
`test/media_picker/media_picker_validator_test.dart` — every rule,
against real files.
`test/media_picker/media_picker_a11y_test.dart` — a source scan: every
slot named, one node per slot, no DI in the module, the resolved bag on
the state, and the literals that are no longer written by hand.

## NOT SEEN RUNNING

The bag, the validator and the guards are verified; **none of this has
been watched on a device since the pass**. Nothing here can be built
under `flutter_test` — every picker reaches for the gallery, the
camera, the clipboard or the file system — so the widget half is a
source scan.

Specifically unwatched: the tiles at their new sizes, the dashed frame,
the NEW badge, reordering, the recents overlay, the crop-review sheet,
the lightbox, and every screen-reader announcement added here.

## Known gaps

- **No golden files**, so the tiles' geometry is asserted structurally.
- **`upload_controller.dart` is a seam with no transport.** It tracks
  per-item progress and retry; what actually uploads is the app's.
- **The four pickers still duplicate their SHAPE** — `_addSlot`,
  `_thumb`, `_removeDot` and friends exist four times over, differing
  only in which kind they hold. The bag removed the drift between
  their numbers; it did not merge the widgets, and that is the next
  honest piece of work here.
