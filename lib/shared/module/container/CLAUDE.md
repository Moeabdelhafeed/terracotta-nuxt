# CLAUDE.md — lib/shared/module/container

`GlobalContainer` — the app's styled box. Card, surface, tile, glass,
gradient border, background image, badge, ribbon, expandable panel,
selectable frame, dismissible row.

```dart
GlobalContainer(title: 'Plan', onTap: open, child: Text('body'))
GlobalContainer.glass(child: …)   // blur + translucent fill
```

## The files

`global_container.dart` is the library; the rest are `part`s of it, so
everything stays private to the module and no call site changes.

| file | what is in it |
| --- | --- |
| `global_container.dart` | the widget's fields, factories and `build` |
| `container_content.dart` | what goes INSIDE the box — title row, badge, ribbon, placeholder, corner, overlays. An `extension`, so it still reads `_buildContent(rs)` and still sees every field |
| `container_expandable.dart` | `GlobalExpandableContainer` |
| `container_variants.dart` | the animated border and the selectable frame |
| `container_dismissible.dart` | `GlobalDismissibleContainer` |
| `container_effects.dart` | `_FocusRing`, `_PressScale` — stateful, where the container is not |
| `container_painters.dart` | the two inner shadows, the styled border, the wave geometry |
| `container_clamp.dart` | the bucket width clamp behind `.shell` / `.prose` / `.form` |
| `container_defaults.dart` | the enums and `ContainerDefaults` |
| `container_models.dart` | `ContainerStyle` + `ResolvedContainerStyle`, re-exporting the two above |
| `container_decorations.dart` | `ContainerBadge`, `ContainerRibbon` |

It was ONE file of 2122 lines, against this repo's own "prefer splitting
over 400" rule — six widgets and four painters in it. The largest is
now 699.

**Renaming a file moves its allow-list entry.** The icon adoption guard
named `global_container.dart`; the split moved that code into
`container_content.dart` and `container_variants.dart` and the guard
failed, correctly, on the very first run.

## Contracts

- **Style is the themeable bag `ContainerStyle`** — every field
  nullable, with `defaults` + `mergedWith` + `copyWith`, materialized
  once per build by `style.resolve(context)` into a
  `ResolvedContainerStyle`.
- **Resolution order**: `caller > GlobalContainerTheme.style >
  ContainerStyle.defaults`, then colours from the palette.
- **Every hard-coded number lives in `ContainerDefaults`.** They were
  thirty-six private `_k` consts at the top of the widget file, which no
  caller and no test could name.
- **The BOX stays in the bag** — `width`, `height`, the min/max pair,
  `padding`, `margin` — where other modules push layout onto the widget.
  A container IS its box; its size is the first thing a caller restyles.
- **The content, the slots and the flags are on the WIDGET**: `child`,
  `title`, `header`, `badge`, `loading`, `enabled`. What is IN a box is
  not how boxes look.

## Gotchas

- **The colours come from the PALETTE.** The fill was
  `isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface` —
  Material's scheme, plus a brightness branch the palette already does —
  the shadow was `Colors.black`, the border `colorScheme.outline` and a
  badge's text a hard-coded `Colors.white`.
- **The fill is the CONTAINER role, not the surface.** A container sits
  above the page.
- **`shadow: null` and `shadow: const []` are different.** Null asks for
  the house shadow; the empty list is a FLAT container. Collapsing the
  two would make flat impossible to ask for. Guard: "an EMPTY shadow
  list is a flat container, not a default".
- **The radius is NOT in `defaults`.** It comes from the tokens through
  `MyGlobalContainerTheme.build`, and a compile-time floor would win
  over nothing and still hide the token. `borderRadius: null` after
  resolve means "ask the device for its own screen corner", which is
  only known asynchronously — so the widget resolves that separately.
- **`withoutOuterDecoration()` is not `copyWith`.** Passing null to
  `copyWith` means "keep what you had", and the point is to CLEAR the
  margin and flatten the shadow for a container nested inside a wrapper
  that owns the outside — the selection frame, the dismiss background.

## Accessibility

- **A tappable container is ONE button node**; a decorative one gets no
  node at all. There was not a single `Semantics` in this module: a
  tappable card announced whatever text happened to be inside it and
  never that it could be pressed, or that it was disabled.
- **It carries NO label of its own.** `container: true` merges what is
  inside into the node, so the title, the badge and the body are already
  the label — spelling them out again gave a reader "Plan, NEW" and then
  "Plan" and then "NEW". Guard: "and says each of them once".
- **The content is NOT excluded**, where a nav destination's is: a
  destination's label is its whole meaning, while a card's content is
  the point of the card.
- **Keyboard focus draws a RING**, in the palette's primary, as a
  FOREGROUND decoration so it costs no layout — a border that changed
  the box's size would shift the row under the focus and move the thing
  the reader is aiming at. There was no focus treatment here at all.
- **The ring is driven by the INK's focus node.** The ink owns it, so a
  `Focus` of our own below that node hears nothing — focus travels down
  from the node that has it. Same trap the bottom nav's icon reactions
  hit.
- **The tree shape stays the same, focused or not**; only the colour
  changes. Adding the ring on focus and removing it reparents everything
  below, which rebuilds the `InkWell`, which builds a new `FocusNode`,
  which loses the focus and fires again. That does not fail — it HANGS.
- **An expandable header is a button that says which way it is.** A
  chevron that rotates says nothing to a reader who cannot see it, so
  the header carries `expanded:` and the glyph is excluded.

## Reduce motion

- **An animated border does not loop.** A border that rotates forever is
  the clearest case the setting has. It is STOPPED and held at the
  start, not shortened — a zero-length repeat still rebuilds every frame
  on the way to nowhere.
- **An expandable ARRIVES instead of sliding**, for the same reason.
- `respectReducedMotion: false` is the way out, for a container whose
  motion IS the content.

## The siblings take the palette too

- `GlobalSelectableContainer`'s frame is the palette PRIMARY and its
  checkmark `textColors.onAccent`; `GlobalDismissibleContainer`'s swipe
  action is `statusColors.error` with `onAccent` on top. They were
  `colorScheme.primary`, `Colors.white` and `Colors.red` — separate
  widgets in the same file, so a rebrand moved the container and left
  its selection frame and its swipe action behind.
- A swipe-away is DESTRUCTIVE, so error is the right meaning. `Colors.red`
  was the right meaning from a colour the app does not own.

## Showcase + tests

`/container-showcase`. `test/container/global_container_test.dart` —
bag merge, resolution order, the token-driven app theme, the palette
colours, the semantics of a tappable box, reduce motion, the border
painters and lerp.

- **The shadow's palette guard swaps the SCRIM.** Every role and both
  brightnesses give `scrim = 0x33000000`, so against the real palette
  `Colors.black` and the scrim are the same colour and the first version
  of that guard passed with the palette reverted. The test injects an
  `AppPalette` with a scrim nothing would hard-code and checks the
  shadow follows it.
- **The wave's seam is measured on the SAMPLES, not the path.**
  `close()` draws the joining segment, so a closed path's first and last
  points coincide however badly the phase lands — and the test rect has
  to have a perimeter that is not a whole number of wavelengths, or the
  bug closes by luck. Two versions of that test passed against a
  reverted painter before both were noticed.
- **The border painters are asserted through `paints`.** Solid strokes
  one `drawRRect`; dashed strokes many separate paths and never the
  continuous rect; dotted is DENSER than dashed, because it reuses the
  dash painter with the stroke width as the dash length; a wave is one
  path. `PaintPattern` is a matcher rather than something with a
  callable `matches`, so the count is found by asking for one more path
  each time until the expectation stops holding.

## The device pass

- **The loading placeholder FITS.** It was a fixed three-line column of
  about 145 points, so `height: 120` — which the showcase asks for —
  struck a yellow-and-black stripe. Below `shimmerFullHeight` it
  degrades to ONE bar filling the box, which still says "loading" and
  cannot overflow.
- **The corner badge goes through `GlobalBadge`.** It was hand-rolled,
  so a count on a card did not match a count on a tab, a destination or
  a drawer row. Only the two shapes `GlobalBadge` does not offer stay
  local: an arbitrary widget, and an ICON in a disc.
- **The shimmer BORDER starts and ends off the box.** It swept from
  `begin: -1`, which is the left edge and already visible, so every lap
  the highlight vanished off the right and popped back in at the left
  instead of arriving from outside.
- **The wave closes on ITSELF.** The phase was `distance * frequency *
  0.05`, which lands wherever it lands after one lap round the
  perimeter — a visible kink at the seam, on every container.
  `waveCyclesFor` rounds to a whole number of cycles and spreads them
  over the perimeter; the wavelength shifts by a fraction to pay for it.
- **The wave is UNIFORM and closes on itself.** The phase is
  `distance / length * cycles` where `cycles` is whole, so the scallop
  is the same size everywhere and meets itself at the seam. A phase
  taken from raw arc length lands wherever it lands after one lap — a
  visible kink on every container.
- **It is deliberately NOT per-run.** An attempt in between gave each
  of the eight runs — four straights, four arcs — its own whole number
  of half-cycles. That does make the four corners identical, and it also
  pins the wave to ZERO at all eight junctions: eight flat spots, four
  of them exactly where a corner starts. A decorative scallop runs
  unbroken round the whole shape.
- **A scallop is about a QUARTER of its wavelength deep.** At three
  points against a twenty-point wave it was an eighth — a fine ripple
  that read as a saw edge rather than a scallop.
- **The zigzag shares the wave's walk, wavelength and zeros.**
  `waveFrequency` used to mean two different things — cycles per twenty
  points for the wave, "this many zigzags round the WHOLE perimeter" for
  the zigzag. On the showcase's own card that is a 10-point wave beside
  a 68-point zigzag against a 25-point corner arc, so one segment cut
  clean across a corner and the corner read as a lobe.
- **Corners keep their wave.** The painter damped by curvature down to
  eight per cent, so the line waved along every straight and went flat
  round every corner — the one place the eye is looking.
  `safeWaveAmplitude` is a CEILING against the tightest corner radius
  instead: a wave only misbehaves when it is deep enough to fold through
  the inside of the curve. Zigzag had the same damping and the same
  flattening, less visibly.

## The ribbon is sized from the CORNER

- It was a fixed 80x20 band rotated about its own centre and offset
  sixteen points in — geometry with no idea how big the box is. On a
  card a line or two tall the band was most of the card, so it crossed
  the text instead of the corner.
- A 45-degree band whose ends land `d` down each edge has a chord of
  `d * sqrt(2)`. `d` comes from the box's SHORT side, clamped: a tall
  card gets a generous banner, a one-line card a small one, and both
  cross the corner rather than the content.
- **The two insets are NOT the same number.** The box is long and thin,
  so centring it horizontally means backing off half its CHORD and
  vertically half its THICKNESS. One inset for both pushes the band out
  along the top edge and it reads as a tag hanging off the corner
  instead of crossing it. Guard: "the band sits ON the corner diagonal",
  which is the only one of the ribbon tests that catches it — the others
  pass either way.
- **The `Positioned` needs a `Stack` of its own.** The builder is the
  outer stack's child, so a `Positioned` returned straight out of a
  `LayoutBuilder` is not a direct child of it — "Incorrect use of
  ParentDataWidget", every frame.

## Selection says it more than one way

- `ContainerSelectionEffect`: `outline` (what it always did), `fill` (a
  stronger wash instead of a heavier line — a two-point border is quiet
  in a grid), `lift` (a small scale and a shadow, the one effect that
  survives a card with its OWN border and fill, because it changes the
  card's relationship to the page rather than its decoration), and
  `outlineLift`.
- `ContainerSelectionMark` turns the corner tick off, for a grid where
  the fill or the lift already says it.
- **It reports `selected` to a screen reader**, which it did not before
  — there was no `Semantics` on it at all.
- Reduce motion makes the change ARRIVE rather than ease; the lift is
  the part that matters for.

## It mirrors for an Arabic reader

- **The swipe actions swap sides.** `offset > 0` is a drag to the
  physical RIGHT, and in Arabic the right is where a row STARTS — so
  archive-on-the-start-side and delete-on-the-end-side silently traded
  places for every RTL reader. `start` and `end` are reading positions;
  the drag that reveals them mirrors with the text. The background uses
  `AlignmentDirectional` and `EdgeInsetsDirectional` for the same
  reason.
- **Both shimmers sweep toward the reading END.** `GlobalShimmer.direction`
  defaulted to `ltr` outright, so every placeholder in the app swept
  against an Arabic reader — a shimmer stands in for text that is not
  there yet. It is nullable now and follows the ambient
  `Directionality`; the animated BORDER shimmer mirrors its own sweep
  the same way.
- **A test's `Directionality` must go INSIDE the `MaterialApp`.**
  `MaterialApp` installs its own from the locale, so wrapping the app
  never reaches the widget — the first version of these guards did that
  and measured LTR four times.
- `ContainerBadgePosition` and `ContainerRibbonPosition` are
  deliberately PHYSICAL. A caller asking for `topRight` means the top
  right; those are placements, not reading positions.

## It is the SOURCE for rows and cards

- **`GlobalContainer.tile`** is what `ListTile` was for. The anatomy was
  already here — with no `child` the content builder makes
  `Row(leading, Column(title, subtitle), trailing)` — it just had no
  name, no floor and no slot sizing, so every caller reached for
  Material's instead.
- **A tile stands at `tileMinHeight`** (48, or 40 dense). A card shrinks
  to its content; a row in a list must not.
- **A slot is a FLOOR, not a ceiling.** `slotSize` is a minimum, on a
  tile only. A hard `SizedBox(40)` gives the row an even rhythm and also
  squeezes anything legitimately wider than a glyph — a `GlobalSwitch`
  is about sixty points across, so every setting row overflowed by
  exactly twenty. `ListTile` constrains its own the same way: a floor so
  a small icon still reserves a target, and no ceiling, because a
  control knows its own size. Guard: "a control wider than the slot does
  not overflow".
- **`titleWidget` / `subtitleWidget`** because `ListTile.title` is a
  Widget: a factory that only takes a String is a wall.
- **`selected` is on the BASE container**, washed with the selection
  tint — a row that can be picked should not need a second widget
  wrapped round it. `GlobalSelectableContainer` is for the framed,
  checkmarked kind.
- **A DISABLED control is still a button.** `button:` follows whether
  callbacks exist; `enabled:` reports the state. Tying both to
  "interactive" made a disabled container vanish from the semantics
  tree, which an existing guard caught.
- `enableHaptic` is OFF: a list of fifty rows that all buzz is not
  feedback. `pressScale` is 1 for the same reason — a whole list that
  shrinks is noise, but a single card that is the page's one action
  wants it.
- **`AppSectionCard` is the group**: one heading, rules between the
  rows, and the padding on the ROWS rather than the card — a shadow per
  row inside a card that already has one reads as a stack of cards
  rather than a list. Every settings screen was hand-rolling its own
  header and its own dividers.
- The named shapes live in `shared/common/containers/containers.dart`;
  `test/container/container_adoption_test.dart` is what stops them being
  bypassed, and `test/container/containers_wrappers_test.dart` checks
  each one actually passed everything on. A thin pass-through is exactly
  where a wrong parameter name goes unnoticed — six of the nine had no
  test at all, including `AppMediaCard`, the only one with real wiring
  rather than a straight forward.

## Gotcha: a builder that closes over the variable it is assigned to

The focus ring is built through a `builder` callback, and the result is
assigned back to `content`. A closure that said `child: content` reads
the `_FocusRing` it is building and builds itself for ever — so the
inner value is captured into a `final` first. It does not throw: the
widget test HANGS, and bisecting it took reverting the whole file,
because a no-op stand-in for the ring hung exactly the same way.

## Known gaps

- **The wave and the zigzag still do not look right at the corners.**
  Three attempts: damping by curvature (flat corners), whole cycles per
  RUN (eight flat spots, four of them at the corners), and now a uniform
  scallop that closes on itself. The scallop is right on the straights
  and the seam is gone, but a corner arc of about 25 points carries only
  1.26 cycles, so the turn reads as a distortion of the rhythm rather
  than part of it. What would actually fix it is a base path whose
  corners are gentle enough for the wave to flow round — a larger corner
  radius on the border's own path than the box wears — and that changes
  what the border traces, which is a decision.
- **No golden files.** The painters are asserted by the SHAPE of their
  canvas calls, not by what they look like — a wave that waves the wrong
  way still draws one path. There is no golden infrastructure in this
  repo yet.
