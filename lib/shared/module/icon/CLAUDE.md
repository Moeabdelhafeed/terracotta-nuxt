# CLAUDE.md — lib/shared/module/icon

`GlobalIcon` — a glyph, optionally in a container, optionally tappable.

```dart
GlobalIcon(icon: Icons.star)
GlobalIcon.circle(Icons.home, backgroundColor: brand)
GlobalIcon.outlined(Icons.edit, onTap: edit)
```

## Contracts

- **Style is the themeable bag `IconStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once per
  build by `style.resolve(context)` into a `ResolvedIconStyle`. It had
  seventeen non-nullable fields with baked-in defaults before, which is
  the same thing as having no theme: a bag that always answers cannot
  say "ask the theme".
- **Resolution order**: `caller > GlobalIconTheme.style >
  IconStyle.defaults`, then colours from the ambient `IconTheme` and
  `context.<group>Colors`.
- **`defaults` carries NO colours.**
- **Every hard-coded number lives in `IconDefaults`.**

## Gotchas

- **The glyph asks the ambient `IconTheme` BEFORE the palette.** An icon
  inside a button, an app bar or a selected row is meant to take that
  surface's foreground, and a palette colour forced here would be the
  one thing on the surface ignoring it. That is not a bypass: the app's
  `ThemeData.iconTheme` is itself built from `iconColors`, so the
  ambient value IS the palette unless a surface deliberately overrode
  it. The `iconColors.secondary` fallback in `resolve` is a null-guard
  for a context with no theme, and close to unreachable — `IconTheme.of`
  hands back an opaque black fallback there rather than null.
- **RTL mirroring is OFF by default.** It used to be on for EVERY icon,
  so an Arabic build rendered a house, a person and a magnifier back to
  front. Only directional glyphs mean the opposite thing mirrored.
- **A self-mirroring glyph is never flipped twice.** Material sets
  `IconData.matchTextDirection` on the directional ones (arrows, send,
  chevrons) and Flutter's own `Icon` flips those in RTL before this
  module sees them. `mirrorInRtl: true` on one of those used to mirror
  it again, pointing it back the way it came — right-looking in Arabic
  only by accident. `_applyRtlMirror` skips them.
- **The badge is `GlobalBadge`'s job.** This module used to `Stack` it
  itself with a hard -4dp overhang and shipped its own `IconBadge` dot /
  count / label / icon constructors, each with `Colors.red` and a white
  ring baked in — a second badge implementation standing beside a themed
  one. `badge:` takes any widget and is handed to `GlobalBadge` as a
  custom one; the common cases are `GlobalBadge.standalone(count: 3)`.
- **`backgroundOpacity` SCALES the fill's alpha, it does not set it.**
  It used to overwrite, so `backgroundColor: Colors.blue.withValues(
  alpha: 0.1)` — the way every tinted icon in this app is written —
  painted a fully opaque disc, and a glyph in the same blue disappeared
  into it. Guard: "SCALES the alpha the caller already put on the
  colour".
- **The outline colour and the stroke colour come from the palette.**
  `Colors.grey` and `Colors.black` before — the same grey on a white
  page and a black one, and a stroke that stayed black on a dark page,
  where what the stroke imitates is the PAGE showing through.
- **A gradient border's middle is `cardBackground`,** not
  `scaffoldBackground` — wrong the moment the icon sits on a card, which
  is where a bordered icon usually is.
- **The ripple is clipped by the container**: `Ink` outside, `InkWell`
  inside, with the radius inset by the border's width so the splash sits
  inside the outline rather than over it.
- **`shapedRipple` masks the splash to the glyph's own pixels** via
  `_MaskedRippleCompositor` — two `saveLayer`s and a `dstIn` blend. It
  is for a bare glyph with no container; inside one, the container's own
  clip is the shape you want.
- **A tappable icon is a `Semantics` button** and takes the tooltip as
  its name — an icon-only control has no other text. The tooltip stops
  publishing its own anchor node in that case (`announceOnAnchor:
  false`), or the same string is read twice.
- **Haptics are style-gated** (`enableHaptic`, on by default): selection
  click on tap, medium impact on long-press.
- **The default SIZE comes from the tokens**, set by
  `MyGlobalIconTheme.build(tokens:)` to `tokens.iconSizes.lg` — 24 on a
  phone, 28 on a desktop. The hook took `tokens` and ignored them at
  first, so every bare icon stayed 24 at any window width. Guard: "the
  app theme sizes a bare icon from the tokens", written against the
  EXPANDED bucket on purpose — compact's `lg` is 24, the same as the
  module's own floor, so a test written there cannot fail.
- **`enabled: false` dulls, refuses and ANNOUNCES.** Dimming with
  `opacity` and dropping the callback leaves a node still saying
  "button". Two gates back the refusal — the container never builds an
  `InkWell`, and the handlers return null — so a single one being
  removed does not change behaviour; the test proves the guarantee, not
  either gate.
- **`resolve` takes `enabled:`** for that reason: the glyph and its
  container both drop to `IconDefaults.disabledOpacity`, and the bag
  cannot know the state.
- **`opacity` is FOLDED into the colours** rather than painted as a
  layer — an `Opacity` widget costs a `saveLayer` on what is usually a
  leaf in a list. It falls back to the layer when a gradient is
  involved, since gradient stops are not a colour to fade.
- **`semanticLabel` names an icon without a tooltip.** The tooltip was
  the only way, and it also makes the icon hover- and
  long-press-interactive — a price a NAME should not carry.
- **Badge shorthands**: `badgeCount:` / `badgeLabel:` / `badgeDot:`
  build the `GlobalBadge` for you. More than one, or one alongside
  `badge:`, asserts.
- **Every factory takes a `style:`** merged OVER its own bag. They were
  all-or-nothing before: reaching `enableHaptic` or `padding` meant
  abandoning the factory and writing the whole bag by hand.
- **A glyph swap can crossfade** (`animateIconChange`, OFF by default —
  a switcher that never switches is a widget layer every icon would
  carry). Keyed on the glyph's code point, so a rebuild with the same
  icon does not re-run the fade, and skipped under reduced motion.

## The stroke is a real outline

An icon is TEXT — a glyph in a font — so an outline is what a stroking
`Paint` on that text does, in one rasterization.

It used to be eight copies of the glyph stamped around the fill at 45°
steps: nine rasterizations for a ring that showed facets at any real
width, and a box padded by FOUR times the stroke to hold stamps that
only ever travelled one.

`Icon` cannot do it — it has no `foreground` — so the glyph is built as
`Text` with the icon's font. That has one cost: the RTL flip `Icon`
performs for `matchTextDirection` glyphs has to be done by hand here,
and is.

## Known gaps

- **The stroked path is `Text`, not `Icon`**, so anything `Icon` does
  beyond drawing the glyph (its own semantics, `IconTheme` size
  inheritance) does not apply on that path — this module supplies both
  already, but a future `Icon` feature would not arrive for free.

## Adoption

- **Thirteen sites hand-rolled a glyph in a tinted disc** — a
  `Container` with a `BoxDecoration`, its own padding, its own radius
  and its own `withValues(alpha: 0.12)`: both showcase section headers,
  the banner, the dialog, the scorecard, the animation module's error
  state, all three media pickers, the legal index, the sheet header, the
  preference picker shell. All go through `GlobalIcon` now. Guard:
  `test/icon/icon_adoption_test.dart`.
- **That sweep depended on the alpha fix.** Every one of those call
  sites passes a colour that already carries alpha; routed through the
  module before `backgroundOpacity` started scaling rather than
  overwriting, each would have turned into an opaque disc.
- **It is NOT a ban on Material's `Icon`.** A bare glyph in a
  `ListTile.leading` or an `IconButton.icon` is exactly what this module
  renders, and there are ~780 of them. The anti-pattern is the
  hand-rolled container around one, which is what the guard matches.
- **Four decorated boxes are allow-listed with reasons**: the badge, the
  checkbox, the empty state's disc and the container's badge slot each
  render their OWN themed surface from their own resolved style, and
  routing them here would put one module's style bag in charge of
  another's. `debug_overlay/` is exempt by agreement.
- **Showcase pages still hand-roll ~50**, nearly all in the `_h()`
  section-header helper each page copies. Decorative chrome in demo
  code, left alone deliberately — the guard covers `lib/shared` only.

## Showcase + tests

`/icon-showcase`. Tests: `test/icon/global_icon_test.dart` — bag merge,
resolution order, the ambient-IconTheme rule, palette outline and
stroke, the RTL default plus the double-flip guard, badge delegation,
button semantics, style-gated haptics, geometry (circle radius,
explicit radius, stroked box), lerp, the disabled state, the
`semanticLabel`, the badge shorthands, the factory `style:` override,
the real stroke, the folded opacity, the animated swap, the shaped
ripple and the gradient border.
