# CLAUDE.md — lib/shared/module/shimmer

`GlobalShimmer` — the sweeping placeholder. Wraps a block, or stands in
for one via the `.text` / `.circle` / `.card` / `.placeholder` factories.
`GlobalSkeleton` (`../skeleton/`) composes these into whole-page
placeholders and handles the swap to real content.

## Contracts

- **The child is painted ONCE, inside the effect.** This used to be a
  `Stack` with the child drawn twice — once shimmering and once opaque,
  on top. Every placeholder factory passes `SizedBox.shrink()`, so two
  of nothing looked correct and hid it; but `GlobalShimmer` and `.wrap`
  take a REAL child, and there the opaque copy covered the effect
  completely. Guard: "a real child is painted ONCE, inside the effect".
- **Reduced motion stops the sweep and keeps the block.** A shimmer
  sweeps FOREVER rather than settling, which is precisely the motion
  `disableAnimations` exists to stop — but the placeholder shape is what
  says "loading", so it still paints. An explicit `enabled: false` still
  wins.
- **The direction enum is the module's own.** `ShimmerDirection` used to
  appear in `GlobalShimmer`'s signature, so naming a direction meant
  importing `package:shimmer` — the showcase did exactly that. It is
  `GlobalShimmerDirection` now, with `toPackage()` as the only seam, and
  the package is confined to this one file. Same leak the toast had
  before it grew its own types.
- **Colours come from `context.shimmerColors`** — base and highlight —
  with the block itself on `backgroundColors.surface`.

## Skeleton

- **`SkeletonStyle` is the themeable bag**, nullable with `defaults` +
  `mergedWith` + `copyWith`, resolved through `GlobalSkeletonTheme`.
- **Reduced motion collapses the swap to instant** rather than skipping
  it: the real content still replaces the placeholder, it just does not
  travel to get there. That is the opposite call from the drawer's
  staggered entrance, which is skipped outright — a crossfade that
  finishes instantly still delivers the content, whereas a stagger only
  ever adds delay.

## Showcase + tests

`/shimmer-showcase`. Tests: `test/shimmer/shimmer_skeleton_test.dart`
(single child, the effect wrapping it, reduced motion both ways, an
explicit `enabled: false`, the enum seam, and the skeleton's bag merge +
resolution order).
