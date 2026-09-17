# CLAUDE.md — lib/shared/module/text

Typography family holding the text-field gold standard: nullable
themeable bag, app-wide theme extension, context-resolved colors,
tokenized geometry, reduced motion, semantics.

Six widgets over one shared style bag:

- **`GlobalText`** — the workhorse. Presets, gradients, stroke/outline,
  highlight, leading/trailing icons, selectable, auto-size,
  direction auto-detection.
- **`GlobalRichText`** — `TextSegment` list with per-segment style and
  tap targets (links).
- **`GlobalTypewriterText`** — per-character reveal.
- **`GlobalCounterText`** — animated number roll.
- **`GlobalExpandableText`** — clamp + read more / read less.
- **`GlobalAnimatedText`** — 17 entrance animations (`TextAnimation`).

`GlobalText(marquee: MarqueeStyle())` adds a third answer to overflow,
alongside ellipsis and auto-size: SCROLL the text instead of hiding or
shrinking it. It delegates to `GlobalMarquee` (see
`../marquee/CLAUDE.md`) and asserts against `autoSize` and `selectable`
— shrink-to-fit contradicts scroll-to-reveal, and selecting moving text
is hostile. Requires a bounded width, implies one line, and falls back
to truncation under reduced motion. The decoration stack (gradient,
stroke, highlight, icons) does NOT apply on this path: those wrap the
text in boxes that would scroll along with it.

## Contracts

- **Style is the themeable bag** (`GlobalTextStyle`, every field
  nullable): `caller > GlobalTextTheme.style > GlobalTextStyle.defaults
  > context palette/tokens`, materialized once at the top of `build`
  via `textStyle.resolve(context)`. Build code reads the
  `ResolvedGlobalTextStyle` and never re-derives a fallback. Adding a
  themed field → bag, `mergedWith`, `copyWith`,
  `ResolvedGlobalTextStyle`, `GlobalTextTheme._lerpStyle`.
- **`defaults` carries geometry, never colour.** Colours resolve from
  `context.<group>Colors` at build time so text tracks the active role,
  palette and saturation. A colour baked into `defaults` would ignore
  all three.
- **Token lookups must DEGRADE, not throw.** `resolve()` reads spacing /
  radii / icon sizes only when a `BreakpointsProvider` is present and
  falls back to `defaults` otherwise. `GlobalText` renders in places
  outside the app shell — toast overlays, pre-boot surfaces — and a text
  widget must not require the responsive stack to draw. Guarded by the
  toast swipe tests, which mount without a provider.
- **Reduced motion is checked in `didChangeDependencies`, not
  `initState`.** Inherited lookups are illegal before `initState`
  completes, and the typewriter's auto-start fires its first tick from
  there. Both the typewriter and the counter therefore start from
  `didChangeDependencies` behind a `_started` latch.
- **Reduced motion lands on the END state.** The typewriter reveals the
  whole string and still fires `onComplete`; the counter jumps to its
  final value. The text is the information — the reveal is decoration.
- **Decorative glyphs are excluded from semantics.** Leading/trailing
  icons sit beside a label that already carries the meaning, so they are
  wrapped in `ExcludeSemantics`. The expandable toggle is the opposite
  case: it is a real control and gets `Semantics(button:, label:)`.

## Gotchas

- **Line metrics are standardized via `AppTextStrut`.** Flutter places
  text from each font's OWN ascent/descent, and the app's two defaults
  disagree sharply — measured at `fontSize: 14`, Inter reports
  baseline 13.56 of a 17.00 box (0.7978) while Tajawal reports 10.40 of
  the same 17.00 (0.6119). Identical boxes, baselines 3.16px apart, so
  the same widget looks vertically centred in English and wrong in
  Arabic. `StrutStyle(forceStrutHeight: true)` takes the box AND the
  baseline from the strut instead of the font; with it both report
  20.00 / 15.64. `GlobalText` and the button label apply it; add it to
  any new widget that renders its own `Text`.
  A per-family **optical offset** sits on top (`-0.10em` for Tajawal,
  dialled by eye on `/playground` → "Optical nudge"): the strut fixes
  the baseline, which is measurable, but centring the INK is not —
  Flutter exposes no glyph bounds, and Latin and Arabic distribute mass
  differently around a shared baseline. It is applied with
  `Transform.translate`, so nothing reflows. `referenceFamily` is cached
  because resolving it goes through google_fonts and this runs on every
  text build.
  **The strut alone buys consistency, not optical centring** — Latin and Arabic
  distribute ink differently around a shared baseline, and no single box
  centres both. `AppTextStrut.referenceFamily` chooses which script the
  shared metrics favour; the English default keeps the box compact but
  leaves Arabic descenders ~2.2px below it, which only matters in tight
  multi-line text. Judge it on `/playground` → "Descender clearance".
  **Coverage is PARTIAL** — only `GlobalText` and button labels apply it
  so far; everything else still renders with font-native metrics.
  Remaining surfaces in priority order, plus the font-patching
  alternative that would need none of it:
  `docs/plans/font_metrics_coverage.md`.
- **A font's own metrics can misalign it against anything centred
  beside it.** Tajawal (the Arabic default) carries extra space BELOW
  its glyphs in the em box, so text that looks fine in a paragraph sits
  visibly high next to an icon, checkbox or badge — the box being
  centred is taller than the ink in it. `height: 1` plus
  `leadingDistribution: TextLeadingDistribution.even` splits that space
  evenly instead of dumping it under the baseline. Compare both fonts
  against a leading icon on `/playground`.

- `GlobalTextStyle.decoration == highlight` is painted by a `Container`
  wrapper, not a `TextDecoration` — it needs the resolved
  `highlightPadding` / `highlightBorderRadius` / `highlightColor`.
- `strokeWidth > 0` alone does NOT draw a stroke; use
  `ResolvedGlobalTextStyle.hasStroke`, which also requires a colour or
  gradient.
- `autoDetectDirection` derives direction from the TEXT (`AppBidi
  .detect`), overriding the ambient `Directionality`. Use it for
  user-generated/backend content, not for UI chrome.
- The typewriter chains `Future.delayed` per character — a test that
  ends mid-reveal trips the pending-timer check. Pump
  `kTypewriterCharDuration` per character to drain it.
- `kTypewriterCharDuration` / `kCounterRollDuration` are module-local on
  purpose: they are cadences, not shared transition presets.

## Theming

```dart
ThemeData(extensions: [
  GlobalTextTheme(style: GlobalTextStyle(iconSpacing: 8)),
]);
```

`MyGlobalTextTheme.build(tokens:)` in `core/theme/widget_themes/` binds
the active token bucket and is wired into `theme.dart`. Colours are left
null there so they track the palette.

## Showcase + tests

`/text-showcase`. Tests: `test/text/global_text_test.dart` (merge
precedence, resolve non-null guarantees, reduced-motion for the
typewriter, decorative-icon semantics).
