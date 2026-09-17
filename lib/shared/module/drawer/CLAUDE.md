# CLAUDE.md — lib/shared/module/drawer

`GlobalDrawer` — the app's navigation drawer. Header, sections, rows,
badges, expandable trees, collapsible sections, search, mini/rail mode,
account switcher, swipeable rows, reorderable rows, loading skeleton.

```dart
Scaffold(
  drawer: GlobalDrawer(sections: [DrawerSection(items: [...])]),
)
```

## Contracts

- **Style is the themeable bag `DrawerStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once per
  build by `style.resolve(context, mini:)` into a `ResolvedDrawerStyle`
  whose themed fields are non-null. Build code reads `_rs.selectedColor`;
  there are no `?? cs.primary` ladders left at use sites.
- **Resolution order**: `caller > GlobalDrawerTheme.style >
  DrawerStyle.defaults`, then colours from `context.<group>Colors`, the
  width from the active breakpoint and the row radius from tokens.
- **`DrawerStyle.defaults` carries NO colours and NO width.** Colours
  resolve from the palette so the drawer tracks role, brightness and
  saturation; the width resolves per breakpoint, so a constant would pin
  a phone-sized drawer onto a desktop. Same reason `MyGlobalDrawerTheme`
  sets neither.
- **The background is `backgroundColors.container`, not `surface`.** A
  drawer sits ABOVE the page, so the page's own surface makes it
  disappear into what it is covering.
- **Mini mode owns its width.** `resolve(mini: true)` returns
  `DrawerDefaults.miniWidth` whatever the caller asked for — a 280dp
  "mini" drawer is not one.
- **Every hard-coded number lives in `DrawerDefaults`.** They were 59
  private `_k` constants declared INSIDE `GlobalDrawer` and reached as
  `GlobalDrawer._kFoo` from every helper: invisible to the style bag,
  unreachable from a test, impossible to override.
- **`scrimColor` is CALLER-APPLIED**, like `AppBarStyle.toolbarHeight`.
  The backdrop is `Scaffold.drawerScrimColor` — the `Scaffold` paints it,
  not the `Drawer` — so the bag can carry the value but cannot install
  it. `GlobalDrawer.scrimOf(drawer)` is the seam; it rode along unread
  for a long time because nothing said so.
- **Haptics gate on `style.enableHaptic`** (per-call > theme > true).
  Selection is a `selectionClick`; a long-press is a `mediumImpact`.
- **Every interactive surface carries `Semantics`** — rows, the account
  switcher, swipe actions, expandable parents and collapsible section
  headers. There were none at all in 1345 lines, on a surface whose
  entire job is navigation.
- **A row speaks what it SHOWS.** `DrawerItem.spokenLabel()` folds the
  title, subtitle and badge into one string, because an unread count a
  sighted user can see has to reach everyone else too.
  `DrawerItem.semanticLabel` overrides it.

## Gotchas

- **The staggered entrance is built in `didChangeDependencies`, not
  `initState`.** It needs two things `initState` cannot see: the RESOLVED
  style (the theme can switch it on app-wide) and the reduced-motion
  setting. Under `disableAnimations` it is SKIPPED rather than shortened
  — a staggered reveal is decoration, which is exactly what that setting
  asks to be spared, and the rows are simply there on the first frame.
- **The tree indent is directional.** It was a physical `left`, so in
  Arabic every child row hung off the wrong edge. Guard: "a nested row
  indents from the READING start", which fails by indenting the wrong
  way.
- **Caller-coloured surfaces derive their own foreground.**
  `ResolvedDrawerStyle.onAction(surface)` picks by luminance for badge
  tiles and swipe actions, whose colours come from the caller. They were
  hard-coded white, which is right on a saturated action and invisible on
  a pale one.
- **`muted(opacity)` is the one derivation for greyed text** — section
  headers, item counts, empty states, the collapse chevron. There used to
  be seven different `onSurface.withValues(alpha: …)` literals, each a
  slightly different grey.
- **A swipe action without a `label` is a coloured square to a screen
  reader.** The glyph says nothing; the label is what gets spoken.

## The scaffold hands the drawer over whole

`GlobalScaffold` used to build its own `Drawer` around `GlobalDrawer` —
which already IS one — inside a hard-coded `SizedBox(width: 280)`. Two
bugs in one: the shell was nested twice (the scaffold's background
painted behind a drawer that had already painted its own), and the
breakpoint-aware width was resolved and then thrown away at every screen
size.

The nav drawer is now a FUNCTION returning a `GlobalDrawer`, not a
wrapper widget around one — which is also what lets the modal path
recognise that what it is holding needs no shell. A caller's own
`drawerBuilder` widget is not a drawer, so that one still gets one.
`GlobalScaffold.modalDrawerWidth` defaults to null now (was 280): null
means "let the drawer decide". Guard:
`test/drawer/scaffold_drawer_test.dart`.

## File layout

```
drawer/
  drawer_models.dart      — items, sections, accounts, DrawerDefaults,
                            DrawerStyle + ResolvedDrawerStyle
  global_drawer.dart      — GlobalDrawer + its State (owns the `part`)
  drawer_internals.dart   — the row sub-widgets (`part of`)
  theme/drawer_theme.dart — GlobalDrawerTheme + resolve
```

`drawer_internals.dart` is a `part`, not an importable library: the
sub-widgets are private to the drawer and reach `_GlobalDrawerState`'s
static badge/dot builders. Splitting them properly would mean making all
of that public — a wider API bought for a shorter file.

## Showcase + tests

`/drawer-showcase`. Tests:

- `global_drawer_test.dart` — bag merge, resolution order, palette
  colours, mini width, degradation with no `BreakpointsProvider`, lerp,
  semantics, RTL indent, haptic default, the scrim seam, reduced motion.
- `drawer_features_test.dart` — search (title, subtitle, custom filter,
  empty state), pinned ordering, the loading skeleton, swipe actions
  (reveal, fire, spoken label), reordering, the account switcher.
- `scaffold_drawer_test.dart` — one shell, and the width the drawer
  chose for itself.

## Known gaps

- **Mini/rail mode is thin on tests.** It resolves its own width and is
  exercised by the showcase, but the tooltip, the badge overlay and the
  expand affordance are not covered.
