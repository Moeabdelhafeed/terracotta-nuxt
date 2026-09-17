# CLAUDE.md — lib/shared/module/image

`GlobalImage` — a picture from any of four sources, in a themeable
frame.

```dart
GlobalImage.n('https://…/photo.jpg', width: 120, height: 80)
GlobalImage.a('assets/images/logo.png', semanticLabel: 'Acme')
GlobalImage.auto(source)   // picks the source kind from the string
```

## Contracts

- **Style is the themeable bag `ImageStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once per
  build by `style.resolve(context)` into a `ResolvedImageStyle`. There
  were TWENTY-SEVEN flat visual parameters on the widget, forwarded by
  hand through five factories: the parameter lists were most of the
  module's four hundred lines.
- **The split is source / layout / behaviour on the WIDGET, paint in the
  BAG.** `width`, `height`, `aspectRatio` and the source stay on the
  widget because they are per-instance facts; the corner, the frame and
  the failed-to-load plate are what an app rebrands once.
- **Resolution order**: `caller > GlobalImageTheme.style >
  ImageStyle.defaults`, then colours from `context.<group>Colors`.
- **`defaults` carries NO colours.**
- **Every hard-coded number lives in `ImageDefaults`.**

## An EXTENSION does not make a URL an image

`Validators.isValidImageUrl` demanded `.jpg|.png|.gif|.webp|.svg`, and
the widget refused anything that failed it — before trying. Most real
image URLs carry no extension at all:
`picsum.photos/id/237/400/400`, an S3 presigned link, a Cloudinary
transform, a Gravatar hash. Every one of them drew an error plate for a
picture that loads perfectly, which is what a picker hydrated from a
server showed on a device.

`ImageUrls.looksFetchable` is the rule now: http(s), with a host.
Anything that is not a picture still ends at the error plate — it gets
there by FAILING TO LOAD rather than by failing a regex, and the
content type is what actually decides.

The validator itself is unchanged and still strict: it is a form rule
for a human typing a URL, where the stricter answer is the useful one.

## Gotchas

- **RTL mirroring is OFF by default.** It was ON for every image
  (`isFollowingDirectionality: true`), so an Arabic build mirrored
  photographs, logos and screenshots — text inside them included. A
  picture is not a directional glyph. `mirrorInRtl: true` is there for
  the rare asset that genuinely is one.
- **The corner is resolved against the AMBIENT direction, ONCE.** It
  used to be resolved against a hard-coded `TextDirection.ltr`, in three
  separate places — the frame, the content clip and the inner shadow —
  so a `BorderRadiusDirectional` both landed on the wrong side in Arabic
  AND could disagree with itself. `ResolvedImageStyle.borderRadius` is
  already resolved; nothing downstream resolves again.
- **The content clip is the frame's radius MINUS its line**
  (`clipRadius`), or the picture paints over its own border. The width
  comes from whichever frame is in play — `frameWidth` reads the
  gradient border's width when there is one, the solid border's
  otherwise.
- **A gradient frame suppresses the solid border**, because it is
  painted on top as a foreground; leaving both would draw two lines.
- **The tap layer's `Stack` is `StackFit.passthrough`.** A bare `Stack`
  LOOSENS the constraints it hands its children, so the tap layer cost
  the picture its size: told `width: double.infinity, height: 180` it
  fell back to its own aspect ratio and sat square in a wide box. Only
  the tappable path had it. Guard: "a TAPPABLE picture still fills the
  box it was given" — which measures the PICTURE's box, since the outer
  container is the right width either way and the first version of that
  test passed with the bug still in.
- **The BlurHash is asked for a TRANSPARENT fill.** The package paints
  `Container(color:)` while its own decode runs, and that default is
  `Colors.blueGrey` — a solid slab arriving before the blur does, which
  is the grey flash a BlurHash exists to avoid.
- **The ripple drops its radius when padding insets it**
  (`inkRadius`) — the ink sits in a smaller box, so a rounded splash cut
  for the frame's corners would float away from them.
- **Semantics say one of three things.** A picture with a
  `semanticLabel` is an image; without one it is DECORATION and stays
  out of the tree entirely; with an `onTap` it is a button. It said
  NOTHING before — there was no label parameter at all, so every image
  in the app was invisible to a screen reader whether or not it carried
  meaning.
- **A TAPPABLE picture is named at the INK layer, not at the frame.**
  The name, the button flag and the tap action have to be one node —
  `InkWell` supplies the action but not the flag, and a label on an
  ancestor is a label BESIDE an anonymous button. The frame's own
  wrapper is skipped entirely when there is a tap.
- **Never `excludeSemantics` here.** It was set unconditionally, which
  swallowed the InkWell's tap action — the node announced a button a
  screen reader had no way to press — and every node in the `overlay`
  slot, so a play button on a video thumbnail did not exist. Measured:
  `actions=0`, `overlay semantics=0`.
- **The error plate is a gap, not a warning.** `Colors.grey.shade100`
  behind `Colors.grey` before — the same two greys on a white page and a
  black one. It takes the quiet `outline` and a washed `container`, and
  draws its glyph through `GlobalIcon`.
- **A custom `errorWidget` composes with `retryOnError`.** It replaces
  the plate, not the retry: the caller's widget used to return before
  the retry wrapper, leaving anyone who passed both with no way to try
  again.
- **The retry control is a `GlobalFilledButton`, and it has to be.** It
  was hand-rolled first — a `GestureDetector` around a `DecoratedBox`
  and a raw `Text`, which looked like a button and was not one, so a
  screen reader got a tap action with no name and no button flag. The
  fix reached for `GlobalTextButton`, whose background is transparent BY
  DESIGN: the scrim was dropped and a white label sat on a pale plate,
  leaving a control that worked and could not be seen. Guard: "the retry
  control is VISIBLE, not just tappable", which asserts the rendered
  background is opaque enough to read against.
- **The placeholder covers a LOCAL decode too.** It was wired to the
  network path alone, so a large asset or a camera file showed nothing
  at all for the frame or two it took to decode.
- **The retry pill's two colours are fixed against EACH OTHER**, not
  against the page: it sits on a scrim over arbitrary imagery, where a
  role colour cannot be relied on to stay readable. That is the one
  place in this module where the palette deliberately does not decide.
- **EVERY source decodes at its drawn size** (`cacheExtent`), not just
  the network one: a 4000px asset in a 100px tile cost its full bitmap
  too, and asset lists are where that adds up fastest. `cacheWidth` is
  folded into a `ResizeImage` provider, so a test reads it there rather
  than off the widget.
- **`filterQuality` defaults to `medium`.** A photograph drawn at a size
  other than its own — which, in a tile, is always — aliases at
  `FilterQuality.none`.
- **The fade only runs for a picture that was NOT ready synchronously.**
  One already in the image cache appears at once, or scrolling back
  through a list re-fades pictures that never went away. Reduced motion
  resolves it to `Duration.zero`.
- **Failures are `Logger.m.w`, not `debugPrint`.** Six call sites used
  `debugPrint`, which the bootstrap zone reroutes but never tags.

## Adoption

- **Fourteen sites drew a picture raw** — `Image.network` / `.asset` /
  `.file` / `.memory` or a bare `CachedNetworkImage`: both markdown
  paths and its lightbox, the HTML renderer, the chart legend and
  tooltip marks, the splash hero, the crop sheet, the video picker's
  thumbnails, three sliver-app-bar backgrounds and a captured frame.
  Each missed whatever this module had learnt last — the themed frame,
  the palette error plate, decoding at the drawn size, `filterQuality`,
  the fade. Guard: `test/image/image_adoption_test.dart`.
- **Markdown and HTML were also throwing away their ALT TEXT.** Both
  carry one and handed it to a widget with nowhere to put it; it is the
  `semanticLabel` now, so a picture in a document finally has a name.
- **`cacheNetwork` exists because of that sweep.** Both renderers expose
  `cacheNetworkImages`, and honouring it was the only reason either kept
  a raw `Image.network` to fall back to.
- **Five files are allow-listed with reasons**: the PDF viewer's page
  bitmaps, the video controls' decoded frame, the feedback screenshot,
  the URL field's link preview and the image picker's mid-crop bytes.
  None of those is a picture FROM a source — they are bytes the app
  produced. `debug_overlay/` is exempt as usual.

## The full-screen viewer

`GlobalImageViewer` — pinch-zoom, swipe between pictures, drag down to
dismiss, hero in and out.

```dart
GlobalImage.n(url, lightbox: true)          // from a thumbnail
GlobalImageViewer.open(context, sources: [...], initialIndex: 2)
```

- **`GlobalImageSource` is a sealed four-way**, not four nullable
  fields. `GlobalImage` takes the latter because it is one widget with
  an assert; a viewer takes a LIST, and a list of "one of four nullable
  fields" is unusable.
- **`lightbox: true` is ignored when `onTap` is set.** A caller with
  their own action wants it.
- **The route is TRANSPARENT** so the thumbnail underneath stays on
  screen and a hero has somewhere to fly back to.
- **Drag-to-dismiss reads RAW POINTERS, not a `GestureDetector`.**
  `PhotoView` claims pan in the gesture arena and wins it, being deeper
  in the tree, so a drag handler wrapped around the gallery never fired
  at all — the first version of this viewer simply could not be dragged
  away, and the test that proved it was written after the code. A
  `Listener` sees the pointer before the arena does.
- **It only engages at rest.** A zoomed picture owns single-finger
  drags — that is how you move around inside one — so the viewer asks
  the page's `PhotoViewScaleStateController` first.
- **Drag-to-dismiss is vertical only.** Horizontal belongs to the pager;
  a viewer that fought it would swallow every swipe between pictures.
- **Two lightboxes existed.** Markdown carried its own — a route, a
  scrim, an `AppBar` and an `InteractiveViewer` — and the media picker
  a much larger one. Markdown's is gone. The picker's STAYS, because it
  also shows videos and files and deletes, which are not this module's
  business; what it no longer keeps is its own idea of how an image
  behaves inside it — its image page is `GlobalZoomableImage`, the same
  widget this viewer pages over. The two had already drifted apart on
  loading and error states.

## A provider the caller already holds

- **`GlobalImage.p` / `ImageType.provider`** is the escape hatch for an
  API that hands you an `ImageProvider` and nothing else. Three widgets
  in this app do: a container's background, a sliver app bar's backdrop
  and an avatar's picture. All three drew a bare `Image(image:)`, and
  the adoption guard's pattern named only `Image.network` and friends —
  so none of them was ever in scope for it.
- **Prefer `.n` / `.a` / `.f` / `.m`.** They let the module pick the
  loader, the cache extent and the error plate; a provider has already
  decided where its bytes come from. Everything AFTER the fetch is still
  the module's: the fit, the fade, the placeholder gate, the error
  widget.
- **`ImageType.provider` has no format list.** A provider is opaque —
  it may be a network fetch, an asset, a memory blob or something an app
  wrote itself — so claiming one would be a guess.
- **An avatar keeps its own fallback.** A picture that will not load
  falls back to the INITIALS, which no generic error plate knows about.

## Known gaps

- **Only an SVG pays for `opacity` with a layer.** Every raster path
  hands the value to `Image.opacity`, which fades in the image's own
  paint — no `saveLayer`. `SvgPicture` has no equivalent, so that one
  path still wraps.
- **`Image.asset` / `Image.file` failures arrive through an ASYNC error
  builder**, so the error plate is not on the first frame for a missing
  file — only for a rejected extension, which is checked up front. The
  placeholder covers that window now, rather than the blank the widget
  used to show. Tests use the synchronous kind on purpose.
- **A viewer test cannot use `pumpAndSettle`.** `PhotoView` spins a
  loading indicator until its provider resolves, and an image decode is
  real async work that fake-async never runs — so the tree never settles
  and the test times out instead of failing on its own assertion. Pump
  fixed durations, and pump past the double-tap window (300ms) before
  the test ends or a pending recogniser timer fails it.

## Showcase + tests

`/image-showcase` — whose "broken URL" is a loopback port that refuses,
guarded by a test. It used to be
`invalid-url-that-does-not-exist.com`, a REAL registered domain that
answers 200 with a real JPEG, so all three error cards rendered its
parked-page artwork instead of the fallback they were demonstrating.

Tests: `test/image/global_image_test.dart` — bag
merge, resolution order, palette error plate and border, the retry
pill's fixed pair, the directional corner, the content clip, the
gradient frame's width, the ripple radius, the RTL default, all three
semantics shapes, and lerp.
