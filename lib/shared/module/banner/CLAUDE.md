# CLAUDE.md — lib/shared/module/banner

`GlobalBanner` — a notice that stays on the page until it is dismissed.
Toast is the ephemeral overlay; this one sits in the tree.

```dart
GlobalBanner(title: 'Update ready', type: BannerType.info)
GlobalBanner(title: 'Saved', type: BannerType.success, autoDismissDuration: …)
```

## Contracts

- **Style is the themeable bag `BannerStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once per
  build by `style.resolve(context, type:)` into a `ResolvedBannerStyle`.
- **`resolve` takes the TYPE.** Three colours depend on it and the bag
  cannot know it, which is also why `defaults` carries none: a
  compile-time colour would have to pick one of five and be wrong for
  the other four.
- **Resolution order**: `caller > GlobalBannerTheme.style >
  BannerStyle.defaults`, then colours from `context.statusColors`.
- **Every hard-coded number lives in `BannerDefaults`.**

## Gotchas

- **The status colours come from the PALETTE.** `Color(0xFF4CAF50)`,
  `Color(0xFFFF9800)`, `Color(0xFF2E7D32)` and `Color(0xFFE65100)` were
  written into this module — Material's own green and orange, fixed —
  so a success banner stayed Material green on a rebranded palette and
  in dark mode both. The other two came from
  `Theme.of(context).colorScheme`, which is themed but is not the app's
  status set. Guard: "success is the palette green, not Material
  0xFF4CAF50".
- **The surface is that colour WASHED** (8%), the outline is it at 20%.
  A banner is a notice the page keeps showing, not an alert; at full
  strength it out-shouts the content above it.
- **`custom` is not a status.** It takes the page's own container and
  text colours, which is the point of having it.
- **Reduced motion resolves the animation to `none`**, not to a shorter
  one. An entrance is decoration; the notice is the point.
- **The collapse chevron is a NAMED button.** It was a
  `GestureDetector` around a bare `Icon` — the control that hides half
  the banner's text was invisible to a screen reader and had no name —
  and it renames itself between "Expand" and "Collapse" as it flips.
  Both strings are new ARB keys.
- **The wrapper sets `explicitChildNodes`, never `excludeSemantics`.**
  The close button, the chevron and any actions are controls in their
  own right; a live region that swallowed them would announce a notice
  nobody could act on.
- **A gradient border is PAINTED over the box**, so the solid border is
  suppressed when one is set — leaving both draws two lines.

## Gotchas (continued)

- **The auto-dismiss timer PAUSES with the app.** A banner set to five
  seconds used to expire in a pocket — the timer kept running with the
  app backgrounded, so the notice was gone before anyone saw it. It
  records what is left on `paused` and restarts with that on `resumed`.
  Testing it has a trap: a paused binding stops producing frames, so
  the dismissal animation cannot finish either way and `onDismiss`
  stays unfired whether or not the timer was cancelled. The guard
  asserts on RESUME; the first version passed with the pause removed.
- **The gradient border painter comes from `core/painters`.** TEN
  modules carried a private copy of the same twelve lines — popup,
  buttons, toast, chip, checkbox, switch, segmented control, toggle
  group, image and this one — differing only in the ways copies drift:
  some guarded an empty canvas, one called the width `strokeWidth`.
  Flutter has no gradient `BoxBorder`, which is why everyone wrote it.
  Guard: `test/banner/painter_adoption_test.dart`; the radio's is
  allow-listed because it strokes a CIRCLE.

## Layout

`Row(icon, Column(Row(title, controls), message, actions))`.

- **Actions run along the BOTTOM**, under the description, at the end.
  They used to share the title's line, where a short button squeezed
  the title and a long title squeezed the button; the bottom edge is
  the one place in the box whose width nothing else wants.
- **An action is DECLARED, not passed in** — `BannerAction(label:,
  onPressed:, icon:)`. Callers used to hand over whole widgets, and
  every one of them had to remember `shrinkWidth` (a fill-width button
  in a `Row` asks for infinity and throws), a small size, a compact
  padding and a colour that matched the notice — so no two banners in
  the app looked alike. The banner builds them, in its own type colour.
  A null `onPressed` disables rather than hides.
- **Actions are LINKS** (`link: true`, `LinkUnderline.onHover`), and
  the 48dp touch floor is OFF so the row is a link's height. Two rules
  are traded for a look here, and this is the only place in the module
  where that happens: a filled or outlined button inside a notice
  competes with the page's own primary action, so it is a ruled label
  instead — but the rule only appears under a pointer, which leaves
  colour as the sole affordance on a phone, and the tap target is the
  label's box rather than a square inch. `LinkUnderline.always` and
  `enforceMinTouchTarget: true` are the fixes if either matters more
  than the shape.
- **Both controls ripple in a CIRCLE.** A bare glyph has no container,
  so its splash takes the glyph's square box and reads as a rectangle
  flashing behind an icon; the shape plus a little padding is what
  gives the ink something round to fill.
- **The inset is UNIFORM, less the trailing control's own.** It was
  `horizontal: 16, vertical: 12`, which reads as a squashed box the
  moment the banner is taller than one line. **Both** ends had to
  change: `MyGlobalBannerTheme` set `horizontal: md, vertical: sm` and
  the app theme WINS over `BannerDefaults`, so fixing only the module's
  own default changed nothing on screen. And the controls carry an
  invisible inset of their own — the one that gives their ripple a
  circle to fill — so at full padding the ✕ sat a control's-worth
  further from the edge than the glyph opposite, leaving a conspicuous
  hole after a long title. Guard: "the ✕ sits as far from its edge as
  the glyph does".
- **The glyph is placed by an `Align`, not a `crossAxisAlignment`**:
  `IntrinsicHeight` + `CrossAxisAlignment.stretch` gives the leading
  column the row's full height, and the `Align` puts the glyph anywhere
  on it. Top whenever the block is worth more than one line — a
  wrapping message (measured with a `TextPainter`) or an action row
  under it — and centred otherwise, since a glyph pinned to the top of
  a short block sits visibly high. "Has a message" was the wrong
  question, and so was "does the message wrap": one line plus actions
  is not a short block either.
- **That alignment is CONSTANT.** Interpolating it toward the centre as
  the message folded away made the glyph drift down and come back: the
  offset from the top is `(rowHeight − glyph) × (1 + y) / 2`, and with
  both terms moving at once that product peaks in the middle and
  returns to zero at both ends. It never needed to move — collapsed,
  the row is the glyph's own height and the alignment stops mattering.
  Guard: "and STAYS PUT while the message folds away", which measures
  distance from the block's TOP (its distance from the centre must
  change — the block is shrinking around it).
  - The `LayoutBuilder` must stay OUTSIDE the `IntrinsicHeight`: one
    inside cannot answer an intrinsic query and throws. That is also
    why `_FunnellingText` takes an explicit width.
  - The glyph is wrapped in a **min-height `Column`**. The `Align`
    hands its child the row's height as a LOOSE bound, and a
    `GlobalIcon` with a container behind it takes all of it — ending up
    a paragraph tall and centred whatever the alignment said.
- **A long title SCROLLS** (`marqueeTitle`, on). It shares its line
  with both controls, so it is the first thing to run out of room, and
  a cut-off notice is a notice you cannot read. `marqueeTitle: false`
  ellipsises instead.
  - **Pause-on-touch is forced OFF on that marquee.** It installs a pan
    recognizer, which wins the gesture arena against the banner's own
    swipe-to-dismiss — turning the marquee on by default meant no
    banner could be swiped away at all. `GlobalTextButton` forces it
    off for the same reason.
  - It was off while a scrolling title was the suspect in a UI-thread
    hang. That was a re-entry bug in the marquee itself and is fixed
    there — see `../marquee/CLAUDE.md`.

## Motion

Five entrances — `slide`, `fade`, `slideFade` (default), `scale`,
`expand` — and every one of them **collapses the banner's height**. A
hidden banner used to keep its box: faded to nothing but still holding
a gap in the page, which reads as a layout bug rather than a dismissal.

- **The box and the paint take SEPARATE halves of the controller** —
  size over `[0, 0.5]`, everything visual over `[0.5, 1]`. One shared
  range meant the banner slid, faded or scaled while its own height was
  still moving, and the height CLIPS: every entrance was watched
  through a shutter closing over it, and the nicer the motion the worse
  it looked. Now the box opens alone, then the banner paints. Guard:
  "the box and the paint never move at the same time".
- **The message funnels away a LINE at a time.** An
  `AnimatedCrossFade` swapped the whole block at once, which reads as a
  flicker; one height factor over the lot was better but still a single
  gesture — the text was a curtain. `_FunnellingText` gives each
  measured line its own slice of the controller and its own slide back
  toward the start, so the paragraph empties from the bottom up. At
  rest it is the plain paragraph again, one text run instead of many.
- **A swipe dismisses it** (`swipeToDismiss`, on when `dismissible`).
  It is EXCLUDED from semantics: a drag detector publishes a node with
  scroll actions and swallows everything under it, so the title, the
  close button and the chevron all merged into one unnamed scrollable
  and the banner had no controls left. The ✕ is the accessible path.
- **A dismissing swipe comes HOME as it goes.** It used to keep the
  finger's offset all the way out, so it flew off the side of whatever
  bounded it — a card, a padded list — and read as being scissored
  rather than as leaving. The offset is the finger's exactly while a
  finger is down (an implicit animation would put a frame between the
  two) and animates back to zero the moment it lifts, dismissing or
  not.
- **The swipe says where the threshold is.** Two things do that, and
  both are keyed to the threshold rather than to the banner's width —
  against the width the banner was still at two-thirds opacity when the
  swipe was already far enough to dismiss, so nothing said the decision
  had been made.
  - **Resistance.** Past the point of commitment it follows only a
    quarter of the finger. The drag going heavy is the feedback;
    distance alone is not, because nobody is measuring it. The raw
    travel is tracked separately (`_dragged`) so the mapping stays
    invertible — damping the accumulated offset in place would make
    dragging back a different curve from dragging out.
  - **Fade and shrink**, to a floor rather than to nothing: the banner
    has not gone yet, and a swipe released below the threshold has to
    look recoverable.
- **A swipe can be UNDONE** (`onUndo`), via a `GlobalToast` carrying an
  Undo action and the dismissed banner's own title — two notices can be
  on a page, and "Dismissed" alone does not say which one went.
  - **Only the swipe.** The ✕ is deliberate and aimed and an
    auto-dismiss expires on its own; a swipe is the one that happens by
    accident, and the only one with no target you meant to hit.
  - **`onUndo` null means no toast**, rather than one whose button does
    nothing. A module cannot invent how to reverse a decision its owner
    made — `onDismiss` has usually already flipped some `show` flag,
    and restoring the banner from inside would only fight it.
  - Testing it needs `GlobalToast.navigatorKey` and a `MaterialApp`
    that uses it: the toast goes into the app's overlay, not the
    banner's subtree.
- **An auto-dismissing banner shows its remaining time**
  (`autoDismissProgress`). A notice that vanishes unannounced reads as
  a glitch.
- **Re-showing restarts the clock.** It started once, in `initState`,
  so a banner shown again after an auto-dismiss stayed up for good.
- **`TickerProviderStateMixin`, not the single one** — four
  controllers: entrance, the message's reveal, the swipe's return, and
  the countdown.

## Canonical banners

`shared/common/banners/` — `OfflineBanner`, `UpdateAvailableBanner`,
`MaintenanceBanner`. Copy, glyph and type already decided, because the
MODULE must not know what an app calls things; without them every
feature that goes offline invents its own wording. Same reason
`shared/common/empty_states/` exists.

- Offline and maintenance are **not dismissible** — the state is still
  true after you close it. Update available IS: it invites rather than
  blocks, and the update GATE is what blocks.
- Their copy is translated, and the guard reads it back in Arabic.

## The freeze, closed

Hiding a banner froze the app hard enough to need a restart, with
nothing in the log. It was the title MARQUEE, and the mechanism is
written up in `../marquee/CLAUDE.md`: a superseded scroll drive woke
its own callback, which started another, forever, through the microtask
queue. Nothing was thrown, so no error handler had anything to catch —
which is why `lib/core/error/ui_watchdog.dart` now exists.

`marqueeTitle` stays off by default on its own merits (a banner
persists), not as a workaround.

## `ConnectivityBanner` stays separate — decided

`connectivity_banner/` is a second implementation of a banner's LOOK,
and it is staying that way on purpose. What it does beyond this module
is not styling:

- It lerps the body's `MediaQuery` top padding against its own height,
  so the app bar's status-bar inset shrinks at exactly the rate the
  strip grows — the column's total height never changes, so there is no
  flash and no gap.
- Its background runs edge to edge under the status bar, whose icon
  brightness it overrides with an `AnnotatedRegion`.
- Asymmetric curves, 240ms in and 180ms out: gentle arrival, decisive
  exit.
- A five-state matrix off `ConnectivityCubit` — boot grace, VPN
  allow/warn/block, offline, just-recovered — including cold-start
  suppression, because `connectivity_plus` emits a spurious `[none]`
  before the first real event.

If it is ever folded in, it should KEEP all of that and render a
`GlobalBanner` inside for the strip itself. Merging the two outright
would trade the choreography for the palette, which is the wrong way
round.

## Showcase + tests

`/banner-showcase`. Tests: `test/banner/global_banner_test.dart` — bag
merge, resolution order, the token-driven app theme, all five types
against the palette, the washed surface, the caller override, both
controls' semantics, the chevron renaming itself, dismissal, reduced
motion, lerp, the two motion phases never overlapping, the uniform
inset, the glyph's travel, the line-by-line fold and the swipe coming
home.
