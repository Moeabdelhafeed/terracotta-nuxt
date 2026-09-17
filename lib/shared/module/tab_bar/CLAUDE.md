# CLAUDE.md — lib/shared/module/tab_bar

Two widgets over Material's tab plumbing:

- **`GlobalTabBar`** — a `PreferredSizeWidget` over `TabBar`. Six
  indicator styles, badges, dots, counts, closeable and disabled tabs,
  gradient borders, scrollable + adaptive modes, leading/trailing slots,
  a custom tab builder.
- **`GlobalTabView`** — the content side. Keep-alive, lazy build,
  preload-adjacent, per-tab swipe locking, and four transitions beyond
  `TabBarView`'s swipe.

```dart
DefaultTabController(
  length: 3,
  child: Scaffold(
    appBar: AppBar(bottom: GlobalTabBar(tabs: tabs)),
    body: GlobalTabView(children: pages, keepAlive: true),
  ),
)
```

## Two widgets left this module

Both were duplicates of something better that already shipped:

- **`GlobalSegmentedControl`** existed TWICE under one name — a
  non-generic copy here and the real generic `<T>` one in
  `segmented_control/`, which is themeable, tested and backs six commons
  wrappers plus `picker_shell`. Because this file EXPORTED its copy,
  importing both was an ambiguous-import error.
- **`GlobalVerticalTabs`** was 60 lines of what
  `GlobalNavigationRail(extended: true)` already does — labels beside
  icons, badges, dots, disabled items, a bar indicator — and the rail is
  what `GlobalScaffold` already picks on medium+ buckets.

## Contracts

- **Style is the themeable bag `TabBarStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once per
  build by `style.resolve(context)` into a `ResolvedTabBarStyle` whose
  themed fields are non-null. Build code reads `rs.selectedColor`; there
  are no `?? cs.primary` ladders left at use sites.
- **Resolution order**: `caller > GlobalTabBarTheme.style >
  TabBarStyle.defaults`, then colours from `context.<group>Colors` and
  spacing from tokens.
- **`TabBarStyle.defaults` carries NO colours.** They resolve from the
  palette at build time so a tab bar tracks role, brightness and
  saturation; constants would freeze it against all three. Same reason
  `MyGlobalTabBarTheme` sets none.
- **`height` is CALLER-ONLY.** `PreferredSizeWidget.preferredSize` is a
  getter with no `BuildContext`, so it cannot read a theme — a themed
  height would change what the bar PAINTS while `preferredSize` kept
  reporting the old number and the Scaffold laid out to it.
  `GlobalTabBarTheme` asserts against it. `style.preferredHeightFor(tabs)`
  is the one path that answers without a context, and it takes the tabs
  because the stacked-icon layout's height depends on the content.
- **A shown divider is reserved.** It paints INSIDE the bar's box, so
  `preferredHeightFor` adds it — unreserved, it came out of the tabs.
- **Every hard-coded number lives in `TabBarDefaults`.** Values an app
  would rebrand belong in `TabBarStyle`; geometry that only changes when
  the module changes stays in `TabBarDefaults`.
- **Colours are set on `TabBar`, not on the glyphs.** `labelColor` /
  `unselectedLabelColor` become the ambient `DefaultTextStyle` and
  `IconTheme`, and that is what CROSSFADES a tab's colours mid-swipe.
  Painting the icon or label directly pins it and loses the transition
  for free — the same lesson as the toast glyph.

  This was tried the other way and MEASURED. Driving the foreground from
  the controller's animation inside each tab is worse, not better: for a
  two-tab jump the outgoing tab reaches fully-unselected about a third
  of the way through and then sits there, because `1 - |value - index|`
  bottoms out as soon as the animation passes the next tab. Flutter's
  own per-tab `_ChangeAnimation` has no such floor. Do not "fix" the
  crossfade here without sampling `DefaultTextStyle.of` across the
  animation first.
- **Focus gets the strongest ink overlay of the three states**
  (`TabBarDefaults.focusOverlayOpacity`, via `style.focusColor`).
  Material's ~10% default is invisible on a tab — a transparent surface
  with an indicator already pulling the eye — and it has to be ONE value
  for every tab, or focus looks different depending on which tab holds
  it. Deliberately not a focus RING like the buttons module: `TabBar`
  owns the InkWell ABOVE each tab's child and exposes no focus state to
  it, so a child has nothing to draw against. `splashBorderRadius`
  already gives the overlay the tab's real shape.
- **The label sits ON a `filled` indicator**, whose whole surface is the
  indicator colour, so `ResolvedTabBarStyle.selectedLabelColor` hands it
  `onIndicatorColor` instead. That used to be a hard-coded
  `Colors.white`, wrong for any light-primary brand.
- **`enableHaptic` defaults to TRUE**, matching every other module. It
  was `hapticFeedback` and defaulted to off, so the app's own haptic
  preference never reached a tab.

## Selection-aware tabs

A tab used to be built ONCE as a static widget handed to `TabBar`, which
knows nothing about which tab is selected. Everything selection-dependent
was therefore dead code:

- `activeIcon` never rendered anywhere
- `activeCustomIcon` was not read at all
- the count sat in the unselected colour on the selected tab, and
  vanished entirely on a filled one

Each tab is now a `_TabSlot` rebuilt against `controller.animation`, so
the same interpolated progress the custom `tabBuilder` already received
drives the built-in rendering too. `GlobalTabItem.iconFor` is the single
place the active/idle fallback lives.

## Gotchas

- **`Flexible` only inside the Flex.** Wrapping the label
  unconditionally handed `FlexParentData` to a `Semantics` with no Flex
  ancestor — "Incorrect use of ParentDataWidget" on every bar without
  icons. A text-only tab returns a bare `Text`.
- **A disabled tab is refused TWICE, and the second one is the real
  guard.** The bar is one of two widgets driving the same
  `TabController`, so swiping the `TabBarView`, arrowing across with a
  keyboard or calling `animateTo` all land on a disabled tab without
  ever passing through `onTap` — "I can't tap it but I can swipe to it".
  `_refuseDisabled` listens to the controller, waits for
  `indexIsChanging` to clear (bouncing mid-drag fights a finger still on
  the screen) and walks back to the nearest enabled tab, preferring the
  direction the user came FROM so they land where they were rather than
  being thrown past it.
- **That correction is deferred one frame, and must stay deferred.** The
  listener fires from inside `TabBarView`'s own settle, and `TabBarView`
  ignores controller changes it believes it is already servicing — so an
  immediate `animateTo` moved the INDICATOR back while the PAGE stayed
  on the dead tab. A bar that lies about which page you are looking at
  is worse than the bug it replaced.
- **Tapping a blocked tab runs `onDisabledTap`**, and nothing else
  moves. That hook is the point: a locked tab that silently ignores you
  is a dead end, and users tap it twice before deciding the app is
  broken — so it is where the paywall sheet or upgrade prompt goes.
  Mirrors `GlobalIconButton.onDisabledPressed`, including leaving the tab
  disabled to assistive tech; it genuinely is not selectable, and saying
  otherwise promises a page that never arrives. No haptic either — a
  refusal must not feel like a selection.
- **The VIEW has to ignore the round trip too.** `TabBar` owns the
  InkWell and calls `animateTo` before the bar can refuse, so the
  controller really does visit the blocked index and come straight back —
  and the view animated BOTH hops, a full transition through a page the
  user is not allowed to see. `GlobalTabView` skips any index in
  `disabledTabs` without touching `_shownIndex`, which makes the return
  trip the no-change case and leaves nothing to animate. Guard: "tapping
  the BLOCKED tab itself animates nothing" — 16 blended frames without
  it. This is the second reason `disabledTabs` has to be passed; the
  swipe skip is the first.
- **It continues in the direction of TRAVEL, it does not reverse.**
  Swiping from Posts toward a disabled Premium lands on Archive. Going
  back the way the user came is a different answer to the same gesture —
  the swipe appears to work and then undo itself. Reversing is only the
  fallback when nothing enabled lies further on.
- **Correcting afterwards is still second best**, because the dead page
  is on screen for the beat before the correction lands. Give
  `GlobalTabView` the same indices via `disabledTabs` and the swipe steps
  over them without ever building the page. Only the custom transitions
  can do that: `TabTransition.swipe` hands paging to Material's own
  `TabBarView`, which owns its scrolling and offers no way in. The
  showcase's demo page swaps views when a bar has a dead tab for exactly
  this reason — to `TabTransition.slide`, so the swap costs the disabled
  page and NOT the sliding content. It first shipped on `fade`, which
  quietly traded one for the other.
- **A skipping swipe scrubs the indicator SLOWLY, then carries it the
  rest of the way.** `TabController.offset` is clamped to ±1, so the
  indicator can never be aimed past the ADJACENT tab — a framework
  limit, not a choice. Both obvious readings are wrong: scrubbing at full
  rate parks it on the dead tab as though that were the destination, and
  not scrubbing at all stops it following the finger. Both were tried and
  both were reported. It advances at `1 / stepsToDestination` instead —
  moving with the gesture, stopping well short of the tab it will not
  land on — and the commit animates from wherever it stopped, keeping the
  path one continuous motion. An adjacent hop is unscaled and commits
  with `index =`, since the indicator is already in place. `offset`
  ASSERTS while an index change is in flight, so the reset after the
  commit is guarded on `indexIsChanging`.
- **Every animated index change notifies TWICE** — once on start and
  once on landing — and `TabController.previousIndex` reads the SAME on
  both, so the controller alone cannot tell them apart. The landing
  therefore looked like a fresh change and the view ran the whole
  transition again: a second crossfade after a skipping swipe had
  arrived, and a visible double switch when TAPPING a tab past a
  disabled one. `_shownIndex` tracks what the view is already showing or
  moving toward and drops the repeat. Guards: "does not switch the page a
  SECOND time when it lands" and "TAPPING a tab past a blocked one
  transitions once" — 16 blended frames each without it.

  Both are invisible to a test that pumps one large duration: it skips
  straight over the frames the second transition occupies. Step frame by
  frame.
- **A disabled tab is refused in `onTap`, not by `IgnorePointer`.**
  `TabBar` owns the InkWell ABOVE each tab's child, so an `IgnorePointer`
  inside the child never saw the tap — it was decoration. `TabBar` also
  offers no veto: by the time `onTap` runs it has already called
  `animateTo`. The selection is put back with `index =` rather than
  `animateTo`, because animating flew the indicator over to the dead tab
  and home again, which reads as "it worked, then undid itself".
- **A disabled tab RECOLOURS, it does not fade.** `Opacity` dimmed the
  whole subtree — an unread badge on a locked tab became unreadable —
  and ignored `disabledColor`, so the palette had no say. The dimming is
  kept for the badge/dot overlay alone, which is decoration.
- **The close control is a `GlobalIconButton` at 32dp, not 48.** A 48dp
  control inside a 48dp-tall tab IS the tab, and would force every
  closeable tab wide enough to hold one. 32 clears WCAG 2.5.8 (24×24)
  with room, against the bare 16dp `GestureDetector` it replaced, which
  cleared nothing and had no semantics at all. `style.closeButtonSize`
  raises it. `enforceMinTouchTarget: false` is deliberate for the same
  reason — leave it on and `MinTouchTarget` re-expands to 48.
- **A stacked icon+label row sizes itself from the STYLE, not a
  constant** (`TabBarStyle.stackedHeight`). `TabBar` lays that row out at
  its content height and ignores whatever the enclosing widget reported,
  so a frozen number can only be wrong in one of two directions: too
  small and the label paints past the bar's bottom edge (a frozen 68
  did), too large and the `AppBar` reserves a band of dead space above
  the icons that `TabBar` never fills (Material's own 72 does). `_TabSlot`
  is a `PreferredSizeWidget` reporting the same value, which is also what
  lets `TabBar` see the bar as icon-and-text at all.
- **A closeable tab's END inset SUBTRACTS the close button's own
  padding**, exactly like the toast: the button centres a 16dp glyph in a
  32dp box and already brings 8dp, so the full inset on top of it left a
  visibly bigger gap after the ✕ than the label had before it. Per-BAR,
  since `TabBar.labelPadding` is — a bar mixing closeable and plain tabs
  tightens both, which costs nothing for the browser-tab pattern this
  serves, and an explicit `style.tabPadding` opts out entirely.
- **The badge and dot share the trailing corner, so the badge wins.**
  Both use `PositionedDirectional`; `Positioned(right:)` pinned them to
  the wrong side in Arabic.
- **`TabAdaptiveMode.scrollOnNarrow` reads `MediaQuery`, not
  `context.windowSize`.** A tab bar can be built with no
  `BreakpointsProvider` above it, and the whole resolve path degrades
  the same way — `kTabScrollOnNarrowWidth` is the compact breakpoint
  spelled out.
- **`splashBorderRadius` follows the SHAPE the tab has.** It used to
  take `pillRadius` unconditionally, so a square underlined tab rippled
  with rounded corners that were nowhere on screen.
- **`bounceOnTap` keys on SELECTION, not the raw tap**, so a swipe and a
  keyboard move bounce too and a tap on the current tab does not. Skipped
  under reduced motion. Find it by `kTabBounceKey` — `ScaleTransition`
  alone is not a usable finder, since Material's own `TabBar` mounts one.
- **A tab speaks its badge and count.** They are visible information;
  the label alone left an unread marker silent. `GlobalTabItem.semanticLabel`
  overrides the derived string.

### `GlobalTabView`

- **Every page holds its own slot for the life of the view**, in index
  order, hidden with `Offstage` rather than removed. That single decision
  answers three separate bugs:
  - The slot never changes shape, so beginning a swipe cannot remount the
    page under it. There used to be two returns — an `AnimatedSwitcher`
    at rest, a bare `Stack` while dragging — and swapping between them
    disposed every descendant `State`, so a scrolled list snapped to the
    top the moment the user swiped away. Same rule the buttons module
    states for its focus ring.
  - A page you LEAVE keeps its element, and therefore its scroll
    position, so coming back puts you where you were.
  - There is no `AnimatedSwitcher` left to fire a second crossfade after
    a drag has already finished one, which is what flashed the previous
    page on a swipe.

  Guard: `test/tab_bar/tab_view_state_test.dart` — the offset survives
  both starting a swipe (it failed by resetting 580px to 0) and a full
  round trip, and no more frames blend two pages than the settle needs.
- **`keepAlive` does NOT do this**, despite the name. It relies on
  `AutomaticKeepAliveClientMixin`, which needs a lazy list above it to
  honour the request — a `Stack` is not one, so the wrapper is inert on
  this path. It still works on the `swipe` path, where a real
  `TabBarView` is doing the building. Hidden pages get
  `TickerMode(enabled: false)` so they are kept, not left running.
- **Nothing may `setState` from the custom-transition build path.** It
  marks the drag's target page visited before it can render it, and that
  runs inside `build` — inside LAYOUT, since the `LayoutBuilder` below —
  where asking for a rebuild throws. `_recordVisit` mutates without
  notifying; `_markVisited` (the listener path) still calls `setState`.
  The recording must also happen BEFORE `_wrapChildren`, or under `lazy`
  the page being dragged toward renders as an empty box for that frame.
- **Custom transitions measure the VIEW, not the window.**
  `MediaQuery.sizeOf(context).width` was the screen, so inside a
  `GlobalPane`, a split layout or any padded shell the 30% commit
  threshold was measured against a box the view does not occupy and a
  full-width swipe registered as a fraction of one. A `LayoutBuilder`
  supplies the real width.
- **The drag is mirrored for RTL.** `_dragProgress` is in PAGE space —
  positive always means "toward the previous tab" — so a raw pixel delta
  walked the pages backwards in Arabic, fighting the tab bar's indicator,
  which mirrors correctly on its own.
- **Reduced motion collapses the TAP transition only.** The drag is the
  user's own finger; freezing it would leave the page stuck under it.
  Same line the app bar's hide-on-scroll draws.
- **`transition: swipe` uses a real `TabBarView`** and none of the above
  applies — the custom path exists only for fade / scale / fadeScale /
  none.

## Known gaps

Things that are deliberately not done, so nobody re-derives them:

- **`TabTransition.swipe` cannot skip a disabled tab.** It hands paging
  to Material's `TabBarView`, which owns its scrolling. The bar's
  controller guard is the backstop there, and it corrects AFTER the fact,
  so the dead page shows for a beat. Use a custom transition — `slide`
  matches the stock feel — when a bar has disabled tabs.
- **`GlobalTabView.keepAlive` is inert on the custom transitions.** They
  keep every page alive by construction. It still does its job on
  `swipe`, where a real `TabBarView` builds the pages.
- **`swipeablePerTab`, `preloadAdjacentPages` and `dynamicHeight` have no
  tests.** They predate this rewrite and were carried through unchanged.
- **The tab-change DURATION is not themeable** and cannot be: it lives on
  `TabController`, which the caller owns. `TabBarStyle` carried an
  `animationDuration` / `animationCurve` pair for a while that nothing
  read — the same dead-knob defect this rewrite set out to remove — and
  they are gone.

## Open: the selected label's colour on a small drag

**Reported, not reproduced, not fixed.** Left here so the next attempt
starts from the measurements instead of the theory.

The report: on `/tab-bar-showcase` → Underline, the selected tab's label
is one colour at rest and a visibly lighter one "after slightly starting
to scroll to a different tab". Two screenshots one frame apart show the
indicator having travelled ~6px of a ~306px tab — roughly a 1.5% drag —
with what looks like a much larger change in the label.

What was measured, driving a real `TabBarView` drag and reading
`DefaultTextStyle.of(...).style.color` per frame:

| controller animation | label |
| --- | --- |
| 1.000 (at rest) | 100% selected |
| 1.025 | 99.25% |
| 1.125 | 96.3% |
| 1.425 | 87.3% |

Linear in drag distance, continuous, no threshold and no jump. A 1.5%
drag moves the colour 1.5%, which is not visible. Also checked and NOT
the cause:

- distant tabs falling outside `TabBar`'s three-tab `_TabStyle` window —
  they resolve to the correct unselected colour at rest anyway
- the app's real theme vs a bare `ThemeData` — same numbers under
  `AppTheme.getTheme`
- driving the foreground from the controller's animation ourselves —
  measurably WORSE, see the crossfade gotcha above

Two possibilities left, and they need a device to tell apart:

1. It is the **indicator or the ripple**, not the label. `MyTabBarTheme`
   sets an `overlayColor` whose RESTING value is a permanent
   `primary @ opacitySubtle` tint, and the module now sets a much
   stronger focus overlay. A tint appearing or moving under the label
   would read as the label changing colour.
2. It is Flutter's crossfade being **immediate** — no dead zone, so an
   accidental nudge starts washing the colour out at once. If that is
   what it is, the fix is a curve that holds the selected colour for the
   first ~25% of a drag, not a bug fix.

Next step: on device, drag one pixel and watch whether the UNDERLINE or
the LABEL changes first.

## Showcase + tests

`/tab-bar-showcase`. Tests: `test/tab_bar/global_tab_bar_test.dart`
(bag merge, resolution order, palette colours, `preferredSize` incl. the
divider, lerp, themed-height assert, indicator sizing + splash shape,
`activeIcon` / `activeCustomIcon`, disabled refusal, close-button target,
RTL badge side, semantics, haptic default, bounce + reduced motion).
