# CLAUDE.md — lib/shared/module/sheet

Modal sheet family holding the text-field gold standard: themeable
style bag, context-resolved colors, style-gated haptics, localized
chrome, reduced motion. Four surfaces from one style vocabulary:

- **`GlobalBottomSheet`** — `.show` (plus `responsive: true` →
  side-sheet on medium+), `.resizable` (DraggableScrollableSheet),
  `.multiPage` (PageView + localized Back/Next/Done).
- **`GlobalTopSheet`** — `.show`, `.multiPage`, `.resizable`; slides
  from the top, handle at the BOTTOM edge, drag-up dismisses.
- **`GlobalCombinedSheet`** — coordinated top + bottom pair; shared
  dismiss offset, budget-clamped heights.
- **`_ResponsiveSurface`** — single-route bottom↔side morph backing
  `responsive: true`; content Element survives bucket flips via a
  GlobalKey (forms keep state through window resizes).

## Contracts

- **Style is the themeable bag** (`SheetStyle`, every field nullable):
  `caller > GlobalSheetTheme.style > SheetStyle.defaults >
  context.<group>Colors`, materialized ONCE per `show()` call via
  `style.resolve(ctx)` — widget internals only read
  `ResolvedSheetStyle`. Adding a themed field → bag, `mergedWith`,
  `copyWith`, `ResolvedSheetStyle`, `GlobalSheetTheme._lerpStyle`.
- **Shadow is edge-aware** — `ResolvedSheetStyle.resolveShadow(isTop:)`
  throws the default shadow toward the anchored edge; only the caller
  `shadow:` skips it.
- **Barrier + transition live in the bag** (`barrierColor`,
  `animationDuration`, `animationCurve`) — there are no per-call
  transition params. `resolve()` collapses `animationDuration` to zero
  under `MediaQuery.disableAnimationsOf` (drag still works, snaps
  instead of gliding; multiPage jumps instead of animating).
- **Haptics gate on `style.enableHaptic`** (resolved, default `true`):
  close-button tap + successful drag dismiss.
- **Localized chrome**: barrier labels + Back/Next/Done via
  `CommonStrings` (never hardcoded English); close button is
  `Semantics(button:, label: CommonStrings.close)`; handles + page
  dots are `ExcludeSemantics` (decorative).
- **Radius resolution**: explicit `borderRadius` > device physical
  corner radius (`useDeviceRadius`, `DeviceRadius`) > 24 fallback.
- **`navigatorKey` fallback** — all three facades accept
  `context: null` and fall back to their static `navigatorKey`
  (wired in bootstrap); return `Future.value(null)` when neither
  exists.
- **`SheetSizing`** covers the cross-axis only: width/alignment for
  bottom+top, height/alignment for side sheets. Fixed + adaptive on
  the same axis assert.

## Gotchas

- `GlobalTextButton` defaults to fill-width; inside the multiPage
  indicator Row it MUST keep `shrinkWidth: true` or layout forces
  infinite width.
- `responsive: true` hosts ONE route for both layouts. Don't "fix"
  the bucket flip by reopening routes — the in-place morph is what
  preserves form state.
- The combined sheet's Stack + `spaceBetween` Column layout is
  deliberate (see inline comment) — Expanded spacers overflow when
  the top panel is tall.
- `hideBottomBorder` only applies non-floating; it trims the border's
  bottom edge by shifting it below the screen edge
  (`_kBorderHideExtra`).

## Showcase + tests

`/sheet-showcase` (anatomy only). Tests: `test/sheet/global_sheet_test.dart`
(resolve merge, reduced motion, chrome + close plumbing, localized
multiPage nav en+ar, caller style override).
