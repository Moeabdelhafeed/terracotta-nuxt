# CLAUDE.md — lib/shared/module/divider

`GlobalDivider` — a rule. Plain, dashed, dotted, wavy or zigzag; with a
label, icon or badge in the middle; horizontal or vertical; or carrying
a progress value. `GlobalExpandableDivider` puts a disclosure toggle on
one.

```dart
const GlobalDivider()                  // a plain rule
GlobalDivider.text('OR')               // label in the middle
GlobalDivider.progress(value: 0.4)     // a value, not a separator
```

## Contracts

- **Style is the themeable bag `DividerStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once per
  build by `style.resolve(context)` into a `ResolvedDividerStyle`. There
  were 25 flat visual parameters on the widget before, none themeable.
- **`style` is the BAG; `lineStyle` is the enum.** The line style used
  to own the name `style`, which is the one every other module gives its
  bag. Renaming it was the only way to keep the pattern.
- **Resolution order**: `caller > GlobalDividerTheme.style >
  DividerStyle.defaults`, then colours from `context.<group>Colors`.
- **A rule takes `textColors.secondary` at half strength**, not the
  outline. An outline is the border of a CONTROL and reads heavier; a
  rule has to be quieter than the text it separates.
- **The painter takes the RESOLVED bag**, not ten loose numbers, so the
  widget and the painter cannot disagree about what a divider looks
  like — they read the same object.
- **Every hard-coded number lives in `DividerDefaults`.**

## Gotchas

- **A vertical rule honours `indent` / `endIndent`.** It ignored them
  entirely — the vertical path never read them, so `indent` on a
  vertical divider did nothing at all. They run along ITS axis, which
  is top/bottom. Guard: "honours indent, which it used to ignore
  entirely".
- **`spacing` runs ACROSS the rule, whichever way it points** —
  vertical padding for a horizontal rule, horizontal for a vertical
  one. It is the gap between the rule and what it separates.
- **The entrance grows along the rule's OWN axis.** It grew its WIDTH
  whichever way the rule ran, so `animate` did nothing visible on a
  vertical divider. Find it by `kDividerEntranceKey`.
- **Reduced motion SKIPS the entrance rather than running it at zero.**
  A zero-duration run still mounts a `FractionallySizedBox` that reports
  a different size for one frame. Guard: "is SKIPPED under reduced
  motion, not run at zero".
- **A curved line needs a taller box than its stroke.** A wave and a
  zigzag leave their own lane, so `extentFor` adds twice the amplitude;
  a box the height of the stroke clips the crests off.
- **Only a plain solid line skips the painter.** `roundedCaps` counts as
  needing it too — a rounded cap is a stroke, not a box.
- **The progress rail fills from the READING edge**
  (`AlignmentDirectional.centerStart`), so it runs right-to-left in
  Arabic. Filling the other way reads as emptying. Its fill is the BRAND
  colour: it is the only part of a divider that reports a value, and its
  track is the rule's own colour faded.
- **A plain rule says NOTHING to a screen reader.** It is decoration,
  and announcing every separator on a settings page reads out furniture.
  A labelled rule speaks its label; a tappable one is a button. Only
  those two earn a node.
- **A tappable rule is bigger than its line.** `tapPadding` gives a 1dp
  rule a reachable target — without it the target is 1dp tall.
- **The second line of a `doubleLine` takes the same indents.** It was
  built without them and sat wider than the line above it. It works on a
  VERTICAL rule too — the flag was read on the horizontal path only, so
  a doubled vertical divider drew one line.
- **`animateTextFade` fades the CENTRE, and only the centre.** It used
  to wrap the whole rule in an `Opacity`, so the lines faded in with the
  label — which is not what the name says, and left nothing on screen at
  the start of a rule that is supposed to be drawing ITSELF out. The
  divider is now built INSIDE the entrance, which hands the centre a
  `FadeTransition` to ride; the rule's own expansion is a separate flag
  (`animate`), so fading a label no longer implies drawing a line.
- **A vertical rule has no centre content, and says so.** `text`, `icon`
  and `badge` were silently dropped on that path; the constructor
  asserts now rather than quietly rendering something else.
- **A badge outranks text, which outranks an icon.** One centre slot,
  checked in that order.

## It does not report a value

`GlobalDivider.progress` lived here for a while: a rule with a filled
portion, a track and a `progressColor`. It is gone.

It was a weaker copy of `GlobalProgress(type: linear)` — no buffer
value, no indeterminate mode, no tick marks, no label or sublabel, and
`ProgressStyle` already carries colour, track colour, track opacity and
thickness. It also had ZERO callers outside its own showcase.

A separator and a value are different jobs. Guard: "the divider does NOT
report a value".

## Adoption

Ten surfaces drew their own rule with Material's `Divider` or
`VerticalDivider` — `scaffold/` (both rails), `pane/`, `popup/`,
`checkbox/`, `wizard/`, `faq/`, `pdf/`, `date_time_picker/` and
`text_field/surfaces/` — each picking its own colour: `onSurface @ 8%`,
`@ 10%`, `@ 15%`, `outlineVariant`, or Material's default. None tracked
the palette.

`ShowcaseDivider` in commons was the same story twice over: a
hand-rolled 1dp box, plus a labelled variant that reimplemented
`GlobalDivider.text` down to its two `Expanded` halves — so the
showcase furniture was a different colour from the rule the showcases
demonstrate.

Guard: `test/divider/divider_adoption_test.dart` fails on any Material
divider named under `lib/shared/module` (outside `debug_overlay/`) or
`lib/shared/common`. Feature showcase demo content is not swept.

## Known gaps

- **A gradient does not animate.** `GlobalDividerTheme.lerp` interpolates
  one, but the widget paints whatever it resolves — there is no
  per-frame gradient tween on the divider itself.
- **The wave is sampled, not curved.** `DividerDefaults.waveStep` walks
  the path a pixel at a time rather than emitting cubics, which is fine
  at rule thicknesses and would show at 20dp.

## Showcase + tests

`/divider-showcase`. Tests:

- `global_divider_test.dart` — bag merge, resolution order, palette
  colours, curved extent, painter selection, indent + spacing on both
  axes, RTL for the plain AND centred layouts, the entrance axis,
  reduced motion, doubleLine on both axes, shadow, badge precedence,
  the centre-only fade, semantics for all four cases including
  `semanticLabel`, the tap target, lerp, and every factory.
- `global_expandable_divider_test.dart` — collapsed / expanded /
  `initiallyExpanded`, the arrow's turn (`kDividerExpandArrowKey`), the
  line style reaching both halves, and the expanded state in semantics.
- `divider_painter_test.dart` — where a line lands, the dash period,
  the clipped last dash, a dot being as long as the stroke is thick,
  vertical dashes, one path per curve, a zero frequency drawing nothing,
  a zero-size canvas drawing nothing, and `shouldRepaint`. It records
  the canvas through a `noSuchMethod` sink rather than a golden.
- `divider_adoption_test.dart` — no Material divider anywhere in
  `lib/shared`, and no progress rail here.
