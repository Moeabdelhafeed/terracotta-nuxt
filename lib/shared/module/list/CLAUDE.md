# CLAUDE.md — shared/module/list (and grid)

Two collections, one contract. They share their controller, their
selection, their chrome, their pagination vocabulary and their theme.

```
list/
  list_models.dart          — pagination · selection · phases · group headers
  list_style.dart           — ListDefaults · ListStyle · ResolvedListStyle
  theme/collection_theme.dart — GlobalCollectionTheme + BOTH resolves
  global_list_controller.dart — the fetch state machine
  list_selection_controller.dart — selection, kept separate on purpose
  scrubber_models.dart      — ScrubberPlacement
  scrubber.dart             — GlobalScrubber, used by BOTH
  swipe_actions.dart        — SwipeAction · SwipeActions · GlobalSwipeRow
  global_list.dart          — GlobalList
grid/
  grid_models.dart          — the shared re-exports
  grid_style.dart           — GridDefaults · GridStyle · ResolvedGridStyle
  global_grid.dart          — GlobalGrid
```

## The bags

- **`ListStyle` and `GridStyle` are all-nullable**, floors in
  `ListDefaults` / `GridDefaults`, app-wide layer in
  `MyGlobalCollectionTheme.build(tokens:)`
  (`core/theme/widget_themes/global_collection_theme.dart`, wired in
  `theme.dart`). Order is `caller > GlobalCollectionTheme.<bag> >
  <Bag>.defaults`. Presets: `ListStyle.feed` / `.bare`,
  `GridStyle.gallery` / `.bare`.
- **ONE `ThemeExtension` for both.** Two would be two rebrand hooks
  that can disagree, and a house that set a pagination bar height on
  one and not the other would get two different bars on one screen.
  Every field that means the same thing on both is named the same on
  both.
- **Two of the fields are whole bags of their own.** `scrollable` is
  the same `ScrollableStyle` every other scrollable takes, and
  `scrollIn` the same `ScrollInStyle` — so a house sets its edge fade,
  its scroll-to-top button and its row entrances ONCE and the
  collections follow the page shells. They were eleven flat parameters
  none of which any theme could reach.
- **The flat chrome parameters are a SHORTHAND**, not a second home.
  `edgeFade`, `showScrollToTop` and the rest merge on top of
  `style.scrollable` in `_callerStyle`, so the resolve sees them. The
  first cut of this pass left them beside the bag instead of in it,
  and the characterisation tests caught a fade that stopped rendering.
- **It resolves in `didChangeDependencies`, never `initState`** — the
  palette and reduce-motion are inherited reads.

## They had NO tests

Six thousand lines, two hundred and eighty-eight parameters, zero
coverage — and the refactor above moves most of those parameters. The
characterisation suite came FIRST, deliberately: every other module in
this app had tests that caught the gold pass's mistakes, and here there
was nothing to catch them with. It earned its keep twice on the first
day.

- `test/list/list_controller_test.dart` — the fetch state machine: the
  idempotent first load, the dropped concurrent `loadMore`, cursor
  mode, refresh vs initial (a refresh keeps the list the reader is
  looking at; an initial load shows a skeleton), errors that keep the
  items already shown, `retry` picking load vs loadMore, and a page
  landing after `dispose`.
- `test/list/list_selection_test.dart` — the three modes, the range
  select in either order, and the fact that `selected` hands out a
  VIEW rather than the store.
- `test/list/global_list_test.dart` /
  `test/grid/global_grid_test.dart` — the phases, the pagination
  chrome, search, grouping, bulk actions, and that the two agree.
- `test/list/collection_style_test.dart` — the three layers, the
  field-by-field sub-bag merge, the palette, reduced motion, and that
  the shared fields resolve to the same numbers on both.
- `test/list/collection_a11y_test.dart` — what a reader hears.

## Fixed on the way

- **Nothing read `MediaQuery.disableAnimationsOf`.** A list is the
  most-repeated motion surface in an app and every insert, remove,
  reorder and column reflow animated regardless. The resolve zeroes
  the duration — an item that changes is REPLACED rather than raced
  into place — and the scroll-in entrance does not arm at all.
- **Neither module had one `Semantics` node.** A selected row looked
  different and said nothing; a page button was a bare digit in a row
  of digits. Selection now merges a `selected` flag into whatever node
  the caller's builder makes (and a list with no selection controller
  says nothing, rather than telling a reader every row is "not
  selected"), and a page button is a named button that knows whether
  you are on it.
- **Every colour came from Material's own scheme**, so a rebrand moved
  the app and left both collections behind. Fourteen sites now resolve
  through the palette.
- **`GlobalGrid.static` carried the gesture assert and not the column
  one**, so a static grid with no column slot went into the responsive
  resolve with every bucket null. Same mistake, same message, both
  constructors now.
- **Four dead style fields** — `dividerThickness`, `dividerIndent`,
  `dividerEndIndent`, `skeletonShimmerColor` — were configuration
  nothing read. Deleted rather than carried.
- **A reorder gives haptic feedback**, gated on `enableHaptic`. It is
  the one gesture in a list where the finger has left the thing it
  moved and the eye may be elsewhere.
- **`ListItemAnimation.slideFromStart` / `slideFromEnd`** mirror in
  Arabic; the physical pair does not. See
  `../scrollable/CLAUDE.md`.
- **`GlobalGrid.static` demanded a column slot even from a grid that
  had already answered with `tileMaxExtent`** — the other way to say
  how wide a tile is. It asked for the same answer twice and threw on
  the demo that gave it once.
- **The grid kept its OWN copy of the A-Z strip**, a year behind the
  list's: a plain `GestureDetector` that lost the gesture arena to the
  scroll view (so the page scrolled under the finger), no keyboard, no
  magnification, no sampling when the sections outnumbered the room,
  and a hard-coded `right:` that put it on the wrong side in Arabic.
  There is now ONE strip — `scrubber.dart` — and both modules lay it
  out through `scrubberOverlay`, which is where `ScrubberPlacement`
  becomes a `PositionedDirectional`.
- **The grid's section jump asked the BUILT header where it was.**
  Below the fold a header has no render object at all, and a pinned
  one reports the top of the viewport — so the strip either did
  nothing or landed somewhere unrelated to the letter pressed. It now
  falls back to counting rows (`_estimatedSectionOffset`), which is
  what the list already did.
- **The reflow grid is a `Stack`, and a `Stack` has no reading
  direction.** It took `left:` literally, so Arabic put column 0 on
  the left and every insert slid the wrong way past it. Positions are
  START-relative now; the reorder hit test mirrors the pointer once
  rather than every comparison.
- **The strip budgeted a flat fourteen points a mark**, which is what
  a ten-point letter measures at 100% and nineteen at 130% — and it
  measured that budget against its own full height rather than the
  room inside its padding. Twenty-three marks went into room for
  seventeen. The budget scales with `MediaQuery.textScalerOf` now, and
  counts the usable extent.
- **The grid had no `searchField` slot**, so its only search bar was
  the deliberately bare one a primitive can build for itself. Same
  seam as the list's now.

## Added after the gold pass

Four gaps, found by reading the two parameter surfaces against each
other rather than by guessing at features.

- **`swipeActions` — swipe-to-act.** The most common list affordance in
  a phone app, and NOTHING in the repo offered it: no `Dismissible`
  anywhere in either module, no `swipe` module. A pane behind each
  side, per ITEM rather than per list (a pinned row offers "unpin"),
  with a full swipe committing to the first action on its side.
  - `leading` / `trailing` are DIRECTIONAL. The drag is converted to a
    start-relative offset once, at the top of the handler, and back to
    a physical one once, at the paint — so nothing in between has to
    know which way the language runs.
  - **Every action is also a `CustomSemanticsAction` on the row.** A
    swipe is invisible to a screen reader; without them the row simply
    has no delete and no archive.
  - **One row open at a time**, and scrolling closes it — a pane left
    open above the fold is one the reader has forgotten about, and it
    will act on their next tap.
  - **List only.** A vertical list has a spare horizontal axis; a grid
    does not, and a horizontal list's spare axis is the one it
    scrolls on. Both are refused rather than half-working.
  - The offset is carried on an `AnimationController.unbounded` — an
    ordinary one clamps to 0..1, and a trailing pane at -144 was
    clamped to zero, so the row never moved. The tests caught it.
- **`selectOnTap` — the module owns the anchor. On BOTH now.**
  `ListSelectionController.selectRange` existed from the start and
  nothing drove it: every screen wanting shift-click kept its own
  anchor field and its own tap branch. Tap toggles and anchors,
  Shift+tap takes the run, Ctrl/Cmd+tap adds without moving the
  anchor, Shift+arrow extends by one, and a long-press then a drag
  paints a range. The modifiers are read off `HardwareKeyboard` —
  a tap knows nothing about what is held down, and every caller was
  passing the same two booleans.
  - **`selectAt` defaults its modifiers to what is HELD DOWN**, so a
    caller's own control in the row — a checkbox, say — gets Shift and
    Ctrl/Cmd for free and behaves like the row around it. Passing them
    explicitly still decides.
  - The drag finds its row by hit-testing a `MetaData` marker, not by
    arithmetic: deriving an index from the scroll offset needs every
    row to be the same height, which a list does not promise.
  - The keyboard keeps a CURSOR as well as the anchor, so shift-down
    twice then shift-up shrinks the range instead of stranding a row.
  - A caller who set `onItemContextMenu` keeps it and loses only the
    drag-paint. One gesture cannot be two things.
  - **The grid's Shift+arrow counts in ROWS**, not tiles: sideways is
    one tile, up and down is a whole row, because that is the step its
    plain arrow takes. The step follows the resolved column count, so
    it stays right across a bucket change. Everything else — the
    anchor, the modifiers, the drag-paint, the auto-scroll, the
    `Listener` that owns the move and the end — is the same code path
    the list uses, ported rather than re-invented.
- **`unifyTiles` on the GRID too**, and it means something different
  there: a list has two outside corners, a grid has four. The first
  tile keeps its top-start, the last tile of the FIRST ROW its
  top-end, the first tile of the LAST ROW its bottom-start, and the
  last tile its bottom-end — everything else square. Which tile owns
  which is recomputed from the resolved column count, so it follows a
  bucket change or a pinch-zoom. Start and end are directional, so the
  block mirrors in Arabic; grouped grids get no top corners at all,
  for the same reason a grouped list's first row loses its.
  **Off by default**, where the list's is on: a list is a card with
  rules through it, and a grid is usually a tray of separate things.
- **`stickyHeader`, on both.** `stickyFooter` existed; the top needed
  `headerSlivers` and a `SliverPersistentHeader` delegate to stay put.
  A column header or a "40 shown" line wants a slot, not a lesson in
  slivers.
- **`GlobalGrid.scrollToTopBuilder`** — the list has had it all along
  and the grid hard-coded its button.

Four things device testing turned up straight after, all of them real:

- **Nothing here takes the focus any more.** Two separate thefts:
  `autofocus: index == 0` meant a list took focus the moment it was
  built — off whatever the reader was on — and took it again every
  time scrolling recycled a row into index 0. And
  `Scrollable.ensureVisible` reveals its target in EVERY scrollable
  ancestor, so a row taking focus hauled the whole PAGE to the list.
  The autofocus is gone (`Tab` reaches row 0 by itself, and `focus()`
  is there for a caller who means it), and the reveal moves only the
  viewport the list owns. A TAP still moves focus, which is not
  stealing — the reader aimed there — and it is what lets Shift+arrow
  carry on from the row they hit.
- **The RING follows the highlight mode, not the focus.** A tap moves
  focus deliberately (so Shift+arrow carries on from the row the
  reader hit), but a finger has no focus ring to see —
  `hasPrimaryFocus` cannot tell a tap from a Tab, and
  `onShowFocusHighlight` is Flutter's own answer to exactly that. The
  first key press lights it up.
- **The reveal moves MINIMALLY**, and only when the row is off screen.
  At `alignment: 0.5` every row that took focus was centred, so
  tapping one near the top scrolled the list under the finger.
- **The drag-select's MOVE belongs to the list too**, not only its
  end. The starting row takes its recogniser with it when the
  auto-scroll carries it off screen, so `onLongPressMoveUpdate`
  stopped arriving: the scroller kept the last edge position it had
  been given and drove the list to the end however the finger moved
  after that. Both come off the list's own `Listener` now.
- **A focus stop that does nothing is a trap.** `enableKeyboardNav`
  made every row a stop whether or not there was anything to activate,
  so on the scrubber demos each inert tile took focus and lit a ring on
  the way past while Enter did nothing. A row earns a stop when it has
  an `onItemActivate`, or a selection the module drives
  (`selectOnTap`). The showcases' scrubber demos never needed the flag
  at all — the strip carries its own stop.
- **A drag-select could not reach past what was rendered.** It runs the
  shared `DragAutoScroller` now, with `onTick` re-running the hit test
  so rows scrolling INTO a still finger keep joining the range. The
  END of the drag belongs to the LIST, not the row that started it:
  once the auto-scroll carries that row off screen the sliver disposes
  it, its recogniser goes with it, and no `onLongPressEnd` ever
  arrives — the ticker ran forever.
- **The overlay's builder slots handed a caller's widget to a
  `Positioned` with only an edge**, so a full-width button asserted
  `BoxConstraints forces an infinite width` and took the page's layout
  down. The Stack knows its room; the slot passes it on.
- **The pinned section header declared `groupHeaderHeight` and then
  painted the caller's child at ITS size** — a shorter header meant
  `layoutExtent exceeds paintExtent` and a dead page. The slot is
  sized to the extent it declared, which makes `groupHeaderHeight` the
  contract: set the style, not the child, to change it.

## The pull goes through the refreshable module

Both collections built a raw `RefreshIndicator` for their `onRefresh`,
so the most common pull in the app got none of what
`GlobalRefreshable` does: no haptic, no minimum show time (a fast
fetch flashed), no error handling (a throw escaped into the zone), no
semantics action for a reader who cannot pull, no theme hook, and the
Material spinner even on an iPhone. Two modules, two different
pull-to-refreshes, on one screen if a list sat beside an FAQ — the
same drift the shared scrubber was extracted to stop.

Both now wrap in `GlobalRefreshable`, and both take a
`refreshController` so a caller can start one from outside the tree.
The colour passed down is the UNRESOLVED `loadingIndicatorColor`, so
it only overrides the refresh theme when the collection was actually
told one — the resolved value is never null and would shout down a
house style. `test/refreshable/refreshable_adoption_test.dart` fails
on a new raw indicator anywhere in `lib`.

## What it costs

Measured over a thousand rows in a 600-point viewport, sixty drag
frames, against a raw `ListView.builder` doing the same work.

**Read the method before the numbers.** The first variant timed in a
test file pays for the JIT — whichever one goes first looks about
twice as slow as it is. The table below is the best of four
interleaved rounds after a throwaway warm-up run. An earlier version
of this section was not, and it was wrong in a way that changed a
default: it reported the module at 2.9× raw and blamed `unifyTiles`
for most of it, so `unifyTiles` was turned off. Timed properly it
costs a millisecond.

| configuration | ms / 60 frames | vs raw |
| --- | --- | --- |
| raw `ListView.builder` | 15 | — |
| plain | 14 | 1.0× |
| `unifyTiles` | 16 | 1.1× |
| selection + `selectOnTap` | 16 | 1.1× |
| scroll-in entrance | 17 | 1.1× |
| keyboard navigation | 17 | 1.1× |
| grouped (pinned headers) | 21 | 1.4× |
| everything at once | 26 | 1.7× |

- **Virtualisation is intact in every configuration.** Sixteen rows
  built for the viewport, out of a thousand — the same as the raw
  list, with selection, keyboard navigation, scroll-in, grouping, the
  edge fade and the overlays all on. None of the chrome makes the list
  build rows it does not show, which is the property that matters, and
  it is a COUNT rather than a timing, so no warm-up can distort it.
- Grouping is the only feature that shows up clearly, and pinned
  headers are sliver work rather than per-row work.
- **The selection path was O(n²)** and is not any more. `_wrapItem`
  needs to look an item up by index and re-filtered the WHOLE list to
  do it, once per row — an O(n) walk and a fresh list allocation per
  row, on every build of any list with selection on. The filtered list
  is stashed once per build. That one was real, and the profiling that
  turned it up is why the rest of this section exists.

The numbers are widget-test timings: single-threaded, no raster. A
device profile is what settles it.

## The two controllers

- **`GlobalListController` is the fetch state machine** — items, the
  phase, the cursor or page number, and the four flags. `phase` is
  what the widget renders: error beats everything, then initial,
  refreshing, loadingMore, empty, idle.
- **`ListSelectionController` is separate on purpose.** A paginated
  list should not carry selection plumbing it never uses, and a
  selection-only list should not instantiate fetch state.
- **`load()` is idempotent** — a widget that loads in `initState` and
  a caller that loads on the same frame must not double-fetch.
- **`loadMore` drops a concurrent call.** Infinite scroll fires on
  every frame near the bottom.
- **A failed `loadMore` KEEPS the items already shown**, and the error
  phase puts the retry row under them.

## Who uses it

`GlobalList` and `GlobalGrid` are the answer for a VIRTUALISED
collection — a builder over a caller's data.
`test/list/collection_adoption_test.dart` fails on a new one and lists
every remaining site with its reason: chrome strips (a thumbnail rail
is furniture ON a page), overlay contents (they measure against their
own constraints and close on a pick), a short bounded list of the
caller's own widgets, the calendar's own geometry, the shimmer
placeholders the two modules render THEMSELVES while loading, and the
restoration wrappers which exist to be raw.

That is the other half of the scroll sweep's answer: a
`ListView.builder` over a hundred rows is not the scroll SHELL's
problem (`test/scrollable/scrollable_adoption_sweep_test.dart`), it is
this pair's.

- Showcases: `/list-showcase`, `/grid-showcase`.
