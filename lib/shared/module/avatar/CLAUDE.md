# CLAUDE.md — lib/shared/module/avatar

`GlobalAvatar` — a face: image, initials from a name, icon placeholder,
or a custom child. `GlobalAvatarGroup` overlaps several with an overflow
count.

## Contracts

- **Style is the themeable bag `AvatarStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once per
  build by `style.resolve(context)` into a `ResolvedAvatarStyle`.
- **Resolution order**: `caller > GlobalAvatarTheme.style >
  AvatarStyle.defaults`, then colours from `context.<group>Colors`.
- **`backgroundColor` stays NULL on the RESOLVED bag.** This is the one
  place the pattern bends on purpose: a named avatar generates its
  colour from the name, and filling a themed default would make every
  face in a list the same colour — the opposite of what a named avatar
  is for. Null means "derive it"; only an explicit value overrides.
- **Initials take `textColors.onPrimary`.** They sit on a saturated
  generated colour, so the old hard-coded white was right only by
  accident — and wrong for any light-primary brand.
- **`backgroundImage` is BEHIND the content; `imageUrl` IS the
  content.** Two different questions that both sound like "an image on
  an avatar". `imageUrl` / `imageProvider` fill the face with a photo;
  `style.backgroundImage` is a `DecorationImage` painted under initials,
  a placeholder icon or a custom child — a branded or textured backdrop
  — and it shows through when a photo fails to load and the initials
  take over. It snaps rather than interpolates in `lerp`: two images
  have no midpoint.
- **The presence dot's ring matches the PAGE**
  (`backgroundColors.background`), which is what lifts it off the avatar
  rather than drawing it onto the face.

## Gotchas

- **A pulsing presence dot is skipped under reduced motion, not
  shortened.** It repeats forever rather than settling. The dot itself
  still paints — it is the STATUS, not decoration; only the pulse goes.
  Find it by `kAvatarPulseKey`: `FadeTransition` is not a usable finder,
  since the avatar's image fade mounts one too.
- **The ripple is STACKED OVER the face, not wrapped around it.** A
  `Material` paints its ink BEHIND its child, and an avatar's whole job
  is to paint an opaque circle — so `Material(child: InkWell(child:
  avatar))` gave a ripple that was always hidden. The taps worked, which
  is why it survived: nothing was broken, nothing was visible. The
  InkWell now sits in a `Positioned.fill` above the avatar with its own
  transparent Material. Find it by `kAvatarInkKey`.
- **It clips with `customBorder`, not `borderRadius`.** A circle clipped
  by a same-radius rectangle leaks ink at the corners.
- **The ink is ON-content and heavier than Material's default**
  (`kAvatarSplashOpacity`). It lands on a saturated generated colour or
  a photo, where a surface-tinted 12% splash is invisible.
  `style.splashColor` / `style.highlightColor` override it.
- **`GlobalAvatar` is the only avatar.** Raw `CircleAvatar` was still in
  use in `drawer/` — the one place in `module/` that had not adopted
  this. Anything showing a face goes through here so the name-colour
  generation, the shapes and the status dot stay in one place.

## `GlobalAvatarGroup`

- **It resolves the bag, like everything else.** It did NOT, and that
  was the visible bug: after `AvatarStyle` went nullable, a caller's
  `const AvatarStyle()` carries `shape: null`, so
  `style.shape == AvatarShape.circle` read false and the group drew a
  rounded SQUARE ring — and a rounded square "+N" chip — around
  perfectly circular faces. Guard: "a default group is CIRCULAR, not
  square".
- **The ring matches the PAGE** (`backgroundColors.background`), the
  same rule as the presence dot. It was `Theme.of(context)
  .scaffoldBackgroundColor` — right by accident on a plain page, wrong
  on any tinted surface, and outside the `context.<group>Colors`
  contract.
- **Overlap runs ONE way.** Faces are painted in reverse so avatar 0
  sits on top, and the "+N" chip is painted FIRST so the last face
  covers its start edge. The chip used to be painted last, which made
  it the single element overlapping from the other side — it ate a
  third of the last avatar and the row's direction visibly flipped at
  the end.
- **`PositionedDirectional`, not `Positioned`.** The row and the chip
  were placed from `left:`, so in Arabic the stack ran against the
  reading direction.
- **A member keeps its OWN properties.** The group rebuilds each avatar
  at its own size, and used to copy four fields — a presence dot,
  tooltip, loading state or semantic label handed to a group silently
  vanished. Style merges `group > member`, so one face in a row can
  still differ.
- **A member's tap goes through `GlobalAvatar`**, so it ripples and
  announces itself exactly like a lone avatar; the bare
  `GestureDetector` did neither. The member's own `onTap` wins, and the
  group's index callback is the fallback.
- **The chip says how many are hidden** (`AvatarStrings.moreCount`,
  `avatar_` ARB prefix) rather than leaving "+2" as unlabelled glyph.

## Showcase + tests

`/avatar-showcase`. Tests: `test/avatar/global_avatar_test.dart` (bag
merge, resolution order, the deliberately-null background, generated
colours differing per name, lerp, reduced motion both ways, semantics,
plus the group: shape resolution, ring colour, paint order, RTL,
per-member pass-through, tap routing and the overflow label).
