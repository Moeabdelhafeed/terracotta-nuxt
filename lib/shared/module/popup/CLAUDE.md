# CLAUDE.md — lib/shared/module/popup

Unified popup design system. One module, four entry points, layered
internals organized by concern.

## Table of contents

- [Folder layout](#folder-layout)
- [Choosing an entry point](#choosing-an-entry-point)
- [Four entry points](#four-entry-points)
- [Convenience factories](#convenience-factories)
- [Configs](#configs)
- [Pre-built surfaces](#pre-built-surfaces)
- [Per-field merge (compound objects)](#per-field-merge-compound-objects)
- [Resolved-options invariant](#resolved-options-invariant)
- [Keyboard handling — native observer](#keyboard-handling--native-observer)
- [Scope (paint hierarchy)](#scope-paint-hierarchy)
- [Theming](#theming)
- [Hard rules (project conventions)](#hard-rules-project-conventions)
- [Anti-flicker invariants (don't touch)](#anti-flicker-invariants-dont-touch)
- [Deferred TODOs](#deferred-todos)
- [Showcase](#showcase)

## The arrow follows the drift

A CENTERED arrow is centered on the **anchor**, not on the surface.

The placement engine slides a popup sideways when the anchor sits near a
screen edge, so the surface does not bleed past `screenPadding`, and it
reports how far it slid in `GlobalPopupLayout.followerOffset`. Nothing
read that: the arrow stayed in the middle of a surface that had moved,
and ended up pointing at the margin beside the thing it describes.

`_ArrowRail` walks a centered arrow back by the WHOLE correction and
stops only where the tail would leave the surface's straight edge — a
corner radius clear of either end, since a tail on the rounded corner
has nothing to merge into.

The bound used to be half the ANCHOR's width, which bounds nothing about
the arrow: a 40dp icon capped the tail at 20dp of travel while the
surface had slid 80 to clear the screen edge, so it stopped a long way
short of the icon and pointed at the card behind it.

The correction is read at LAYOUT time, from two places that add up:
`followerOffset` (everything already folded in) plus
`GlobalPopupLayout.liveClampShift` (what the pass currently running is
applying). Without the second the tail is centred on the surface for one
frame and then jumps, because the clamp only reaches `followerOffset`
through a post-frame report. `ScreenClampX` measures its child DRY and
publishes before laying it out, so a reader in that subtree always sees
the current pass's value — which is why the channel is read and never
listened to.

`start` / `end` alignments are untouched: those are measured from the
surface's own corner, which is what the caller asked for.

This is also the capability the tooltip merge rests on. Material's
`Tooltip` clamps too but never reports by how much, so the same bug is
UNFIXABLE there and a small correction here.

Guard: `test/popup/arrow_drift_test.dart`.

## A content-sized popup is capped by the SCREEN

The anchor-side space is a PLACEMENT concern, not a width cap. A menu
opened from a tile near the right edge had thirty points to its right,
so it resolved thirty points wide — and every row overflowed by exactly
the width of its icon. Reported from a device as *"A RenderFlex
overflowed by 18 pixels on the right"*, once per item.

`WidthContent` and `WidthMinAnchor` size to their CONTENT and are
clamped into the viewport by layout afterwards, so the padded screen
width is the honest cap for both. `WidthMatchAnchor` is untouched: that
one is meant to track the anchor, edge or no edge.

Guard: `test/popup/placement_engine_test.dart`.

**And the measured clamp runs for EVERY intrinsic-width placement**,
not only the centred ones it was wired for. A menu anchored near the
right edge aligns its own right edge to the anchor's, and nothing about
that keeps it on screen — it simply ran off. The clamp is told which
point of the surface lands on the anchor (`followerFactor`: 0 its left
edge, 0.5 its centre, 1 its right), where hard-coding half the width is
why a start- or end-aligned popup was never corrected at all.

## A content-sized popup is placed by LAYOUT, not by the engine

The engine resolves a width BUDGET before anything is laid out. For
`WidthContent` / `WidthMinAnchor` that budget is only a CAP — the
surface renders at whatever its content needs — so drifting the
follower by what the cap would need to clear `screenPadding` moved
every off-centre popup sideways by a constant amount whatever it
actually measured. On a phone that was 32px: a short tooltip sat beside
the icon it pointed at.

The follower already centres the surface on the anchor using its REAL
size, so the only correction those strategies need is the screen clamp
— and only layout knows how wide that has to be. `ScreenClampX`
(`controller/overlay_builder.dart`) measures the child, shifts it by the
smallest amount that keeps both edges inside the padding, and REPORTS
the total back to the controller, which folds it into the next
`followerOffset`.

The report is a TOTAL (drift already applied + shift added), which makes
it a fixed point: once folded in, the next pass measures a shift of zero
and reports the same number, so it settles instead of ping-ponging.

Reporting matters because `followerOffset` is what the arrow walks back
along. A correction applied at layout and never reported would leave the
tail pointing at the margin — the bug the whole mechanism exists to fix.

Fixed / fraction / match-anchor widths are untouched: the engine knows
those up front, so its own clamp is exact and the measured one never
runs.

Guard: `test/popup/screen_clamp_test.dart`.

## Folder layout

```
popup/
  popup.dart                     — barrel (re-exports every public symbol)
  CLAUDE.md
  global_popup.dart              — declarative widget + .menu/.tooltip/.panel + showAt
  global_popup_menu.dart         — trigger-widget facade (popup_menu-style API)
  popup_compat.dart              — PopupMenuContent/Separator/Header shims

  controller/
    global_popup_controller.dart   — imperative engine. Internal phases:
                                     placement / flip / keyboard / listeners
    keyboard_scope.dart            — optional KeyboardDetection wrapper

  models/
    popup_models.dart              — barrel for the five model files
    popup_options.dart             — GlobalPopupOptions + GlobalPopupLayout
    popup_enums.dart               — Animation / Trigger / Placement enums
    popup_geometry.dart            — Width sealed + PlacementGeometry + resolvePlacement
    popup_surface_style.dart       — GlobalPopupSurfaceStyle
    popup_arrow_backdrop.dart      — Arrow + Backdrop + Hooks + ClipResolver/Bounds

  surfaces/
    popup_surfaces.dart            — barrel for the four surface files
    surface_base.dart              — GlobalPopupSurface + arrow + gradient painters
    menu.dart                      — GlobalPopupMenuView + GlobalPopupMenuItem
    panel.dart                     — GlobalPopupPanel + GlobalPopupAsyncPanel
    tooltip.dart                   — GlobalPopupTooltip

  theme/
    popup_theme.dart               — GlobalPopupTheme ThemeExtension
```

## Choosing an entry point

| You want… | Use | Why |
|---|---|---|
| Anchor a popup to a widget on tap / hover / focus | `GlobalPopup` declarative widget | Handles LayerLink + TickerProvider + trigger wiring + auto-dispose |
| Common menu / tooltip / panel above the anchor | `GlobalPopup.menu` / `.tooltip` / `.panel` static factories | Pre-baked overlay builder for the 80% case |
| Drive open / close imperatively (e.g. text-field suggestions) | `GlobalPopupController` directly + your own `LayerLink` | Full control over lifecycle, no trigger wiring needed |
| Open at a cursor / right-click / list-row position with no anchor widget | `GlobalPopup.showAt(context, anchor: Offset, ...)` | Uses `showGeneralDialog` under the hood; pops the future when caller pops |
| Open at the user's tap point on the anchor widget | `GlobalPopup` with `placement: GlobalPopupPlacement.atTap` | Controller positions absolutely at the captured pointer offset |
| App-wide visual rebrand | `MyGlobalPopupTheme.build(...)` in `core/theme/widget_themes/` | Theme-extension layer; per-call options still override |

If you're unsure, start with `GlobalPopup.menu` / `.panel`. Drop down to the controller only when you outgrow the widget API.

## Four entry points

### 1. Declarative widget — preferred
```dart
GlobalPopup(
  trigger: GlobalPopupTrigger.tap,
  options: const GlobalPopupOptions(placement: GlobalPopupPlacement.bottomEnd),
  overlay: (ctx, layout) => GlobalPopupMenuView<String>(
    layout: layout,
    items: [
      const GlobalPopupMenuItem(value: 'a', label: 'Apple'),
      const GlobalPopupMenuItem(value: 'b', label: 'Banana'),
    ],
    onSelected: (v) => print(v),
  ),
  child: ElevatedButton(onPressed: () {}, child: const Text('Open')),
);
```

### 2. Trigger-widget facade — matches popup_menu API
```dart
GlobalPopupMenu<String>(
  items: const [
    GlobalPopupMenuItem(value: 'a', label: 'Apple'),
    GlobalPopupMenuItem(value: 'b', label: 'Banana'),
  ],
  onSelected: (v) => print(v),
  triggerOnLongPress: false,
  child: ElevatedButton(onPressed: () {}, child: const Text('Open')),
);
```

### 3. Imperative controller — text-field-style suggestions
```dart
final ctrl = GlobalPopupController();
ctrl.show(
  context: context,
  anchorContext: anchorCtx,
  link: layerLink,
  vsync: this,
  options: const GlobalPopupOptions(closeOnScroll: false),
  builder: (ctx, layout) => MySurface(layout: layout),
);
```

### 4. Programmatic `showAt` — cursor / Rect anchored
```dart
final picked = await GlobalPopup.showAt<String>(
  context,
  anchor: details.globalPosition,
  builder: (ctx) => GlobalPopupMenuView<String>(...),
);
```

## Convenience factories

- `GlobalPopup.menu(...)` — anchor + items → returns full widget.
  **Sizes to its CONTENT** (`autoWidth: true`), unlike every other
  popup, which matches its anchor. A menu's commonest anchor is an icon
  button, and a 32px-wide menu overflows its own rows by twenty-odd
  pixels — the row `Expanded`s its label, but the icon and its gap
  alone are wider than the surface. Pass an explicit
  `options: GlobalPopupOptions(width: …)` for a menu that should line
  up with a wide field instead.
- `GlobalPopup.tooltip(...)` — anchor + message → tooltip popup
- `GlobalPopup.panel(...)` — anchor + child → styled panel
- `GlobalPopup.showAt(...)` — static, programmatic anchor

## Configs

`GlobalPopupOptions` groups every knob. See
[`models/popup_options.dart`](models/popup_options.dart) for the full
field list with docs. Highlights:

| Field | Default | Purpose |
|---|---|---|
| `animation` | `reveal` | reveal / scale / fade / none |
| `placement` | `auto` | 13 anchor-relative + `atTap` |
| `width` | `matchAnchor` | sealed: matchAnchor / minAnchor / fixed / fraction / content |
| `height` | null | Fixed override of min/max |
| `minHeight` / `maxHeight` | 100 / 300 | Dynamic resize range |
| `dynamicResizeOnKeyboard` | true | Shrink + flip when keyboard rises |
| `arrow` | null | Optional pointer tail |
| `backdrop` | null | Color + blur + modal flag |
| `hooks` | null | onOpen / onClose / onWillClose |

## Pre-built surfaces

- `GlobalPopupSurface` — base styled container (composes child with
  arrow + border + shadow + gradient).
- `GlobalPopupMenuView<T>` — list surface with section headers,
  dividers, optional search filter.
- `GlobalPopupPanel` — generic styled child wrapper.
- `GlobalPopupAsyncPanel` — `FutureBuilder`-backed surface.
- `GlobalPopupTooltip` — compact inverseSurface bubble.

## Keyboard handling — native observer

The controller observes keyboard transitions in two modes:

- **MediaQuery fallback** (default) — `viewInsets.bottom` polling
  inside the build path. Works everywhere, slightly coarser timing.
  Doesn't work under a parent `Scaffold` with
  `resizeToAvoidBottomInset: true` (Scaffold consumes the inset before
  the controller's `MediaQuery.of` sees it).
- **Phase-accurate** (opt-in) — wrap a subtree in
  `GlobalKeyboardScope` (`lib/core/keyboard/` — see its own
  [CLAUDE.md](../../../core/keyboard/CLAUDE.md)). The scope owns a
  `KeyboardObserver` (native, NO package dependency) that reads
  `PlatformDispatcher.views.first.viewInsets.bottom` directly off the
  engine and exposes it via inherited widget. Controllers under the
  scope subscribe to `rising → visible → falling → hidden` phase
  changes for sharper transition timing. Works regardless of the
  Scaffold's resize setting.

```dart
MaterialApp(
  builder: (ctx, child) => GlobalKeyboardScope(child: child!),
  ...
);
```

Either way, `dynamicResizeOnKeyboard: true` (default) makes the popup
shrink within `minHeight..maxHeight` as the keyboard rises, then flip
to the opposite side when below the floor.

## Scope (paint hierarchy)

`GlobalPopupController.show` always uses the **nearest** Overlay
(`rootOverlay: false`). Wrap content in `GlobalPopupScope` (= local
Overlay) anywhere you want the popup to live in.

`ShowcasePage` wraps its body in `GlobalPopupScope` so Scaffold's FAB /
AppBar paint above the popup.

## Per-field merge (compound objects)

`GlobalPopupArrow` and `GlobalPopupSurfaceStyle` declare every field
nullable. They each carry a `defaults` static const + a `mergedWith`
overlay method + a `resolved()` materializer:

```dart
// theme arrow has size: 10, baseFillet: 3
// per-call arrow only sets color: red
// merge = size: 10 + baseFillet: 3 + color: red
final merged = themeArrow.mergedWith(callerArrow);

// `resolved()` materializes against `defaults` so every themable
// field is guaranteed non-null at paint time.
final paintArrow = merged.resolved();
```

`GlobalPopupOptions.merged(theme)` does this automatically for the
`arrow` + `surfaceStyle` fields — by the time options reach the
controller, the compound objects are already field-merged.

When you write a surface widget that exposes `arrow:` / `style:`
parameters, follow this pattern:

```dart
final r = (theme?.arrow ?? const GlobalPopupArrow())
    .mergedWith(callerArrow)
    .resolved();
final size = r.size!;  // non-null after resolved()
```

For surfaces that just render whatever they get (no theme lookup),
calling `.resolved()` once on the merged input is enough.

## Resolved-options invariant

`GlobalPopupOptions` exposes every themeable field as nullable. Inside
`GlobalPopupController` `_options` always points to a fully MATERIALIZED
instance — `_materialize(options, anchorContext)` runs at `show()` and
`refresh()` entry, stacking `widget > theme > defaults`. Internal code
reads `_options.foo!` confidently.

Two places enforce this:
- `_materialize` runs an `assert` covering every themeable field
- `GlobalPopupOptions.defaults` is the single source of truth for
  hardcoded fallbacks

If you add a new themeable field, you must (1) add it to `defaults`,
(2) wire it into `merged()`, (3) extend the assertion list above. The
assert will catch the omission in debug.

## Theming

App-wide defaults via `GlobalPopupTheme` ThemeExtension:

```dart
ThemeData(extensions: [
  GlobalPopupTheme(
    surface: const GlobalPopupSurfaceStyle(elevation: 8),
    animation: GlobalPopupAnimation.scale,
  ),
]);
```

Resolution: per-instance options > theme > hard-coded fallbacks.

## Hard rules (project conventions)

- **Tokens only**: padding / spacing / radii / elevation values come
  from `context.spacing.X` / `context.radii.X` / `context.elevation.X`.
  No hard-coded `EdgeInsets.fromLTRB(8, 8, 8, 4)` or
  `BorderRadius.circular(12)` in surface code. Surfaces accept context
  and read.
- **Role-aware colors**: `context.primaryColors.X`,
  `context.statusColors.error`, `context.backgroundColors.X`,
  `context.textColors.X`. `Theme.of(context).colorScheme.X` only when
  feeding a Material framework widget that requires `Color` (e.g.
  `Material.color`). No hex literals (`Color(0xFFE53935)`).
- **No `getIt` in surface code** — surfaces are pure widgets, accept
  dependencies via constructor params.
- **`Semantics` on every interactive surface**, with `selected:` /
  `enabled:` / `button:` reflecting state. `ExcludeSemantics` around
  decorative dividers + icons.

## Anti-flicker invariants (don't touch)

Inside `controller/global_popup_controller.dart`:

- `_flipInProgress` guard — prevents re-entry while
  reverse → side-swap → forward sequence runs.
- `_recomputeLayout` bails when `_flipInProgress && !isFlipping` —
  external recomputes (scroll, MediaQuery rebuilds) would otherwise
  swap layout mid-reverse and teleport the popup.
- `await WidgetsBinding.instance.endOfFrame` between reverse and
  forward of `_animateFlip` — ensures the new-side rebuild paints
  before forward begins.
- Triggers use raw `Listener` instead of `GestureDetector` so they do
  not compete in the gesture arena with interactive children (button
  InkWell, etc.).

## Compat shims (`popup_compat.dart`)

- `PopupMenuContent<T>` extends `GlobalPopupMenuItem<T>` so existing
  `[PopupMenuContent.item(...), PopupMenuContent.divider()]` lists
  assign covariantly to `List<GlobalPopupMenuItem<T>>`.
- `PopupMenuSeparator`, `PopupMenuHeader` — pass-through configs.

New code should use `GlobalPopupMenuItem` directly with `.divider()` /
`.section('X')` factories.

## Showcase

`/popup-showcase` — documentation-style tour. 14 chapters, each
section uses [`DocSection.live`](../../common/showcase/doc/doc_section.dart)
to pair a live widget with the exact source asset that produced it.
Add a new demo:

1. Drop a `<name>_demo.dart` under
   `lib/features/showcases/popup_showcase/demos/<chapter>/`.
2. Wrap the demo body in `// #docregion main` … `// #enddocregion main`.
3. Make sure the file's parent directory is in `pubspec.yaml` under
   `flutter.assets`.
4. Add a `DocSection.live` entry in `popup_showcase_page.dart`.

## Deferred TODOs

- **Controller decomposition** — extract `_PlacementEngine` (pure
  layout computation), `_FlipAnimator` (anti-flicker reverse → forward
  sequence), `_OverlayBuilder` (backdrop + entrance + AnimatedSize
  wrap) from `controller/global_popup_controller.dart`. Target: drop
  controller to ~250 lines (lifecycle + listeners only). Each subclass
  independently reviewable + unit-testable.
- `atTap` placement currently treated as `auto` — to fully honor,
  switch from `CompositedTransformFollower` to absolute `Positioned`
  using captured pointer offset.
- Multi-popup-per-anchor stacks: supported via multiple controllers
  (`final secondary = GlobalPopupController();` alongside the widget's
  default), each managing its own `OverlayEntry`. They layer naturally
  in the host `Overlay` (later `insert` paints on top). Single-controller
  "stack" semantics (push/pop within one controller) is intentionally
  not built — it'd require duplicating every state field per entry.
- Test predicates + `debugFillProperties` on `GlobalPopupOptions`,
  `SurfaceStyle`, `Arrow`, `Layout`.
- Per-item arrow-key navigation in menus.
- Live region announcements on open/close.
- Per-field merge for `GlobalPopupArrow` + `GlobalPopupSurfaceStyle`
  (requires nullable defaults — moderate API change).

## Keyboard

- **Escape closes, always.** Wired whatever the trigger is, so a
  keyboard is never trapped by an open overlay.
- **Enter and Space OPEN a `tap`-triggered popup**, and a tap-triggered
  anchor can take focus so Tab reaches it. The trigger is raw pointer
  events; without this a keyboard could land on the anchor and do
  nothing with it — the "+N" on a collapsed toggle group was focusable
  and dead.
- **`anchorFocusNode`** hands the caller the node the anchor focuses
  on, for a trigger that wants to paint its own focus. The toggle
  group's collapsed "+N" needs it: with no tap handler of its own it
  has no `InkWell` focus to paint from.
- **Only the TAP trigger.** `hover`, `longPress` and `secondaryTap` are
  pointer gestures with no keyboard equivalent, and an anchor of theirs
  that took a tab stop would be a stop that does nothing. `focus` opens
  on focus already.
