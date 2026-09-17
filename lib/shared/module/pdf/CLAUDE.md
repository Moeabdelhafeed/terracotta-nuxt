# CLAUDE.md — lib/shared/module/pdf

`GlobalPdfViewer` — a document reader over `pdfrx`, in four variants:
`compact` (a card-sized first-page preview), `full` (paged, with a
transport bar), `continuous` (scrolling), and `custom` (you supply the
chrome).

```dart
GlobalPdfViewer(source: PdfSourceSpec.url(url))
GlobalPdfViewer(source: …, variant: PdfViewerVariant.compact, heroTag: 'doc')
```

## Contracts

- **Style is the themeable bag `PdfStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once in
  `didChangeDependencies` by `style.resolve(context)` into a
  `ResolvedPdfStyle`.
- **Resolution order**: `caller > GlobalPdfTheme.style >
  PdfStyle.defaults`, then colours from the palette.
- **Every hard-coded number lives in `PdfDefaults`.**
- **`initialPage` and `heroTag` are on the WIDGET, not the style.**
  Where a reader is in a document is a property of that reading, and a
  hero tag is an identity — neither is how viewers look. They sat on
  the style bag beside the corner radius.
- **The engine type never escapes.** `PdfStateSnapshot`,
  `PdfOutlineItem` and `PdfSourceSpec` wrap pdfrx so callers take no
  dependency on it. Keep it that way — the whole point is that the
  engine is replaceable.

## Gotchas

- **The colours come from the PALETTE**, not
  `Theme.of(context).colorScheme`. It read Material's scheme in SEVEN
  places — surface, controls, outline, error, the thumbnail strip and
  the bottom bar — so a rebranded palette left every one of them
  behind. Guard: "the accent is the palette primary, not the
  ColorScheme".
- **A search hit is the accent WASHED; the FOCUSED one is it at full
  strength.** Every hit at full strength gives a page of highlights
  with no way to see which one you are on.
- **`persistKey` is what bookmarks and the thumbnail cache hang off**,
  falling back to the source's value. `cacheKey` exists so one document
  served at two URLs still resumes where you left it.
- **`autoResumeAtLastPage` beats `initialPage`** when a last-read page
  is stored for that key. Pass `false` to always open where the caller
  says.
- **The search row's match counter has a FIXED slot.** It swings
  between "—", "…", "1 / 3" and "128 / 660"; sized to its content,
  every one of those moved the three buttons beside it, which is what
  made the row look mis-spaced as you typed.
- **Night mode does not turn photographs into negatives.** A plain
  inversion flips every pixel, so the text reads and every picture on
  the page becomes a negative. `pdfSmartInvertMatrix` is invert
  composed with a half-turn hue rotation — CSS's
  `invert(1) hue-rotate(180deg)`, what iOS calls Smart Invert. An
  approximation, not a segmentation: strongly saturated flat artwork
  still shifts, and doing it properly means knowing which parts of the
  page are images, which the raster does not say.

  The coefficients are the SVG `feColorMatrix` hue rotation at 180°,
  negated and offset — not numbers picked by eye. A hand-guessed
  version cast every photograph orange because its rows did not sum to
  −1, so grey stopped inverting to grey. Guard: "inverts grey to grey".
- **The resume toast fires once per document per SESSION**, and never
  from a compact preview. The flag was per-State, so a card and the
  fullscreen viewer it opened both announced the same resume — two
  identical toasts, stacked — and every re-entry announced it again.
- **The thumbnail strip sits on the SURFACE, not the container.** In
  dark the container is a deep navy that framed the white pages in
  something nothing else on screen was.
- **The compact card absorbs pointers inside its tap target.** The
  viewer swallows them, so an `InkWell` around the card only ever heard
  the strip of chrome outside the preview.
- **`compact` is not a viewer, it is a preview** — a rasterized first
  page, a filename and a page count, with a tap target. Its scrim
  colours are FIXED rather than themed, because they sit over the
  page, whose colour nothing here controls.

## The bottom bar fits itself

Controls are declared as GROUPS and each is shown whole or moved into
the overflow menu whole. `pdfBarFit` is that decision, split out and
pure — the viewer needs a real PDF engine to build at all, so a test
driving the widget could not reach it.

- **A zoom-in with no zoom-out is a broken control, not a compact one.**
  The bar used to hide buttons one at a time under a single width
  threshold, which produced exactly that — and still overflowed by 8px,
  because the zoom pair were the two buttons that never took the
  compact sizing.
- **Nothing is hidden, only MOVED.** Every dropped group contributes
  its own items to the "more" menu, so a control is always reachable.
- **The overflow button's width comes off the budget FIRST.** Dropping
  a control to make room for the button that holds it would be the
  wrong way round.
- **Order is priority.** The group list is written worst-to-give-up
  first, so greedy-in-order is the rule. A later narrow group is still
  considered after a wide one is dropped — a pair that does not fit
  must not strand the singles behind it.
- Paging is not in the droppable set: a pager without page controls is
  not a compact pager.

## Gestures

- **`panEnabled` is ON, and embedded viewers should turn it OFF.** A
  drag belongs to the document or to the page around it, never to both:
  with panning on inside a scrolling page the arena hands it to
  whichever recognizer claims first, which a reader cannot predict from
  looking at it. Off, the page scrolls and the viewer's own controls do
  the paging. The showcase's embedded demos all set it false.

## The module owns the download

- **A URL document is fetched by THIS module, not by pdfrx.** Two
  viewers over one URL — a compact card and the fullscreen route it
  opens — each asked the network for the same document, so the hero
  flew and landed on a loading banner, which is precisely the seam a
  hero exists to hide.
- The cost is real and deliberate: pdfrx's range requests and
  progressive rendering are given up, so a whole document is read
  before the first page paints. In exchange every viewer over the same
  key shares one download, and opening fullscreen is free.
- **`_kPdfBytes` is bounded to three documents.** A PDF is megabytes
  and a static map is forever.
- **The handover carries the persist key** as the bytes source's label,
  so bookmarks, the last-read page and the thumbnail cache still
  resolve — a bytes source keys off its label. The password rides along
  too, or the destination would prompt again for something already
  unlocked.

## The thumbnail overlay

A cached page-one raster laid over the live viewer while it opens. It
exists to cover a viewer that has NOT painted a page yet — and both of
its bugs came from covering one that had.

- **It is not re-shown on the way BACK from a sub-route** unless the
  viewer is still loading or errored. The compact card never unmounts
  while the fullscreen route is up: its document is open and its page
  is painted. Covering that put a differently-scaled still frame over a
  live page and cross-faded back — the stutter the overlay prevents,
  performed on the way out instead of the way in. Guard:
  `pdfShouldRecoverOnReturn`.
- **The HERO flies the thumbnail, not the viewer.** A `Hero` with no
  shuttle flies the source widget, which here is a live pdfrx viewer
  showing wherever the reader happens to be — so coming back from page
  three the card briefly wore page three and then swapped to its own
  page one, an in-between state with a flash at the end of it. Both
  ends supply the same still frame through `flightShuttleBuilder`, so
  there is nothing to swap. Falls back to flying the widget when no
  thumbnail exists, which is only the first tap on a cold document.
- **It is width-fitted from the TOP**, because that is where the viewer
  puts page one. Contain-fitted it was centred and scaled to the whole
  box, so the cross-fade at the end of the flight swapped one framing
  for another — which reads as the document loading a second time.
- **The HEIGHT must not be allowed to constrain it.** `pdfStillFrame`
  hands the page an unbounded `maxHeight` and clips, because `Image`
  answers a height it cannot meet by SHRINKING to preserve aspect. Under
  an `Align` — which loosens down to the box — a tall page in a short
  card came back small and floating in the middle of a box the live
  viewer fills edge to edge. It only shows in a SHORT box: on a full
  screen a page fits its height anyway, which is why the fullscreen end
  of the flight looked right and the card end did not. Guard: "does not
  let the HEIGHT shrink it".
- **The card's CHROME flies with it** — the corner, the outline and the
  label bar, each resolved against the flight's own animation, where
  zero is the card end in BOTH directions (a push runs the arriving
  route's animation forwards, a pop the leaving route's backwards).
  Carrying only the page meant the flight landed on a page and the
  rounded corner and the file-name bar arrived in the frame after it.
- **Only the CARD supplies a `flightShuttleBuilder`.** Flutter takes the
  destination's first, so one at each end means the outbound flight is
  defined by the fullscreen route and the return flight by the card —
  two definitions of one movement, of which only the card's knows the
  corner and the bar it has to land on.
- **The shuttle carries its own `Material`.** It is built in the
  OVERLAY, not in either route, so the card's is not above it — and a
  `Text` with no `DefaultTextStyle` is painted red on a yellow double
  underline. That striping ran across the file name and the page count
  for the length of every flight. Guard: "the label needs a text style
  to inherit, in the overlay".

## The hero flies by default

- **Both ends derive the tag from the DOCUMENT.** They are different
  widgets on different routes and the document is the only thing they
  share. It used to need a caller to invent a tag and repeat it at the
  destination, so the default experience of tapping a preview was a
  cut.
- **`defaultHeroTag` is namespaced** (`pdf-hero:<persistKey>`) so it
  cannot collide with a caller's own tag for something else.
- **`heroTag` is the OVERRIDE, not the way in.** The one case the
  derived tag cannot handle is two previews of the same document on one
  screen: `Hero` requires tags to be unique within a route and two
  identical ones throw. `enableHero: false` is the other way out.
- **The thumbnail pre-warm keys off `enableHero`, not off a tag.**
  Gating it on a tag nobody passes leaves the default path flying a
  live viewer, which is the bug the shuttle exists to prevent.

## The fullscreen route

- **It is a WIDGET, so the bar can carry the page count**, which an
  inline `Scaffold` could not.
- **`GlobalPdfViewer.openFullscreen` is the route**, and a caller
  wiring `onTapCompact` should push it rather than build a `Scaffold`.
  Both of the showcase's own taps hand-rolled one and both ended up
  with `AppBar(title: Text('PDF'))` over a document that had a name —
  `onTapCompact` means the caller picks the DESTINATION, not that it
  rebuilds the chrome. Guard: "no showcase hand-rolls a viewer route".
- **The FILE NAME is the title**, extension stripped and separators
  turned back into spaces. Reaching for the document's own `/Info`
  title first was the obvious idea and the wrong one: half the PDFs in
  the world carry `Title: PDF`, or the name of whatever exported them,
  or a string that is not quite empty. The file name is what the reader
  clicked on.
- The state listener filters on page count alone, or every page turn
  would rebuild the bar.

## Motion

- **A rotation TURNS.** It used to snap between quarter turns, which
  reads as the page being replaced rather than rotated — the one
  control whose motion IS the point. The box swaps instantly and the
  contents turn; animating both makes the page shear, because the two
  interpolate on different curves.
- **A system intent shows it is working.** Share, print and save-as
  each read the whole document before the OS sheet can open, which on a
  5MB file is a second or two of a screen that looks like it ignored
  the tap. The overflow glyph becomes a spinner for exactly that gap,
  with no grace period — the tap is the reason it is there.

## Loading

- **Nothing for the first 200ms, then a page-shaped SHIMMER.** A
  spinner that appears and vanishes inside a few frames reads as a
  glitch rather than as progress — the flash is worse than the wait it
  covered. Same gate `GlobalImage` applies, reusing its
  `placeholderDelay`.
- A spinner is also the wrong SHAPE: it says "something is happening"
  where a shimmer says "a page is coming".
- **It FILLS the surface.** Inset inside a padding it read as a card
  floating on a background rather than as the page itself arriving; a
  placeholder has to occupy the space the real thing will, or it is not
  standing in for anything. The determinate bar rides OVER it rather
  than stacking above, which would push the placeholder out of the
  shape it is holding.
- **The determinate bar returns the moment there is a real percentage**
  — a download with a known length — because then there is something
  better to say than "soon".

## Strings

- **Every literal goes through `PdfStrings`.** Seven did not: the two
  bookmark tooltips and their menu labels, "Bookmarks…", "More" twice,
  "Previous", the recent-docs page number and the card's "4 pp". They
  read as English in Arabic, in a viewer whose other thirty-one strings
  were already translated.
- **"More" is `ButtonStrings.moreTooltip`**, not a pdf key. A generic
  overflow tooltip is not this module's word.
- **The card's page count is a SHORT form** (`pageCountShort`), not a
  plural. An abbreviation does not inflect, and the card has the width
  for two characters rather than "4 pages".

## Showcase + tests

`/pdf-showcase`. Tests: `test/pdf/global_pdf_test.dart` — bag merge,
resolution order, the token-driven app theme, the palette colours, the
washed-versus-focused match pair, the custom-variant assertion, and
lerp.

The viewer itself needs a real PDF engine and a real document, so the
tests cover the CONTRACT rather than the rendering; the showcase is
where the pixels get looked at.

## Accessibility

- **The compact card is ONE node.** A preview is a button however much
  is drawn on it, and the live viewer underneath publishes a tree of
  its own — pages, a scroll view, selectable text — none of which can
  be acted on from a card. `ExcludeSemantics` inside, one labelled
  button outside. Guard: "the compact preview announces itself as ONE
  button".
- **The page indicator is a button, and says which page.** "3 / 128" is
  read out as two numbers and a slash, and nothing about the bare text
  says that tapping it jumps to a page. It is a live region too: the
  page it names changes under a reader who did not ask for it — a
  swipe, a bookmark, a link.
- **The match counter speaks its state.** A dash and an ellipsis are
  typography, not an answer, and the counter is the only thing that
  reports whether a search found anything at all.
- The buttons carry tooltips, which is where their labels come from —
  `GlobalIconButton` publishes them. Nothing else in the bar is
  interactive.
- **A narrow bar shrinks what a button PAINTS, never its target.** It
  used to shrink both, to 40dp, on exactly the screens where a control
  is hardest to hit — and the width that bought was width taken off a
  finger. Tight mode is a density now; what pays for a narrow bar is
  the overflow menu, which is what it is for. A control reachable at
  full size in a menu beats one on the bar too small to press. Guard:
  "every bar button keeps a 48dp target on a NARROW bar".

## The keyboard, the picker and the caches

- **Shortcuts are on EVERYWHERE, not gated to desktop.** A tablet with
  a keyboard attached is the case a platform check would break, and a
  device without one has nothing to intercept — the gate would only
  ever have removed working behaviour. `⌘F`, `←`/`→`, `+`/`-`, `⌘0`,
  `R`, `⌘P`, `Esc`; `enableKeyboardShortcuts: false` turns them off.
- **A BARE key stands down while the search row is open**, or searching
  for "rotate" turns the page on every letter. The modified ones stay
  live, because `⌘F` while already searching is how every other
  application re-focuses the field. `PdfShortcutCommand.isBareKey` is
  that split, and it is public so a test can drive a command without
  synthesising a key event on a viewer that needs a real engine.
- **Both `control:` and `meta:` are bound**, rather than switching on
  the platform: a Mac keyboard on Linux and a PC keyboard on a Mac both
  exist.
- **The search row's state lives in the BAR**, so the viewer reaches it
  through a `GlobalKey`. The row is the bar's business; `⌘F` is the
  only thing outside it with an opinion.
- **`pickFromDevice` returns a PATH on native and BYTES on web**, because
  web has no filesystem to point at. Null means dismissed, which is a
  normal outcome — a caller that treats it as failure shows an error to
  someone who changed their mind.
- **`PdfCache` clears what outlives a viewer**: the downloaded bytes,
  the page-one thumbnails, the resume-announced set. It does NOT clear
  bookmarks or the last-read page — those are the reader's, not the
  cache's.

## Metadata

- **`/Info` is parsed out of the BYTES** (`pdf_metadata.dart`), because
  pdfrx-engine does not expose the dictionary and
  `PdfStateSnapshot.title` / `.author` were API surface that was always
  null.
- **It is a reader, not a PDF parser**, and returns nothing rather than
  guessing: a compressed cross-reference STREAM hides the `/Info`
  reference behind deflate, and an ENCRYPTED document's strings are
  ciphertext that decodes to something which *looks* like a title.
- **A literal string is not "up to the next `)`".** Parentheses nest,
  either can be escaped, and `\251` is one character. Half the titles in
  the world are fine with the naive version and the other half come
  back cut in half.
- **Never over the network.** A URL document is already in hand because
  this module downloads it itself; a local file over
  `_kPdfMetadataMaxBytes` is skipped rather than read whole to find two
  strings.
- The app bar still titles itself from the FILE NAME — see the
  fullscreen route. Metadata feeds the share subject and the print job
  name, where a real title is worth having.

## Known gaps

- **The fixture only covers what the ENGINE draws.** `flutter test`
  runs pdfrx — see `test/pdf/pdf_fixture_test.dart` for the two things
  the harness will not give it — so page count, page text, the raster
  the thumbnail cache is built from, and the widget opening a document
  are all under test now. What is NOT is anything that needs pages laid
  out on a surface: the state snapshot's page NUMBER stays 0, and with
  it the thumbnail strip, search highlighting and the outline sheet. A
  golden or an integration test on a device would close the rest.
- **Two previews of ONE document on a screen now THROW.** The hero tag
  is derived, and `Hero` requires tags to be unique within a route, so
  a list that can show the same document twice has to pass
  `enableHero: false` or its own `heroTag`. Before the tag was derived
  this case was silently inert, so it is a new failure mode on an old
  layout — check any screen that lists documents.
- **A junk `/Title` now reaches the share subject and the print job
  name.** Those two call sites always read `_docTitle ?? filename`, but
  `_docTitle` was permanently null, so in practice they always used the
  filename. They do not any more, and half the PDFs in the world carry
  `Title: PDF` or the name of whatever exported them. The app BAR is
  unaffected — it titles from the file name deliberately, see the
  fullscreen route. If a shared document arrives called
  "Microsoft Word - Document1", this is why.
- **Reading ORDER is unverified**, and so is whether a "go to page N"
  announcement actually fires under TalkBack and VoiceOver rather than
  merely being wired. Both need a device with a screen reader on; the
  semantics themselves are guarded.
- **Annotation EDITING is not here** — ink, highlight, free text, form
  filling, signature capture. Rendering them is a toggle; writing them
  needs a writer, which pdfrx does not give us. See
  `PDF_FUTURE_PLAN.md`.
- **The picker has no Android scoped-storage write-up** in
  `docs/setup/`. The code path works; what is missing is the
  permissions note an adopter shipping to Play will want.
- **`PdfCache` is memory only.** pdfrx keeps its own on-disk temp files
  and they are its business — nothing here deletes them.
