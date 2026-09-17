# CLAUDE.md — shared/module/refreshable

One gesture, and almost nothing on screen to explain it. That is the
whole difficulty of pull-to-refresh: the affordance is invisible, so
what little the module DOES show has to be right.

```
refreshable/
  refreshable_models.dart      — RefreshableDefaults · RefreshableStyle · Resolved…
  refreshable_controller.dart  — GlobalRefreshableController · RefreshPull
  theme/refreshable_theme.dart — GlobalRefreshableTheme + the resolve
  global_refreshable.dart      — GlobalRefreshable
```

## The bag

- **All-nullable `RefreshableStyle`**, floor in `RefreshableDefaults`,
  app-wide layer in `MyGlobalRefreshableTheme.build(tokens:)`
  (`core/theme/widget_themes/global_refreshable_theme.dart`, wired in
  `theme.dart`). Order is
  `caller > GlobalRefreshableTheme.style > RefreshableStyle.defaults`.
  Presets: `material`, `cupertino`, `quiet`.
- It used to be a NON-nullable bag with its defaults baked into the
  constructor and three convenience constructors that each re-stated
  them. Nothing could layer: a house that wanted one spinner colour had
  to pass a style at every call site, and `copyWith` could not tell
  "unset" from "set to the default".
- **Resolved in `didChangeDependencies`**, never `initState` — the
  palette and `MediaQuery.disableAnimationsOf` are inherited reads.
- **`adaptive` is resolved ONCE**, in the resolve, so
  `ResolvedRefreshableStyle.variant` is always concrete and no switch
  downstream asks the platform again.

## Fixed on the way

- **`cupertino` did not mean cupertino.**
  `RefreshIndicator.adaptive` reads the platform off the ambient
  `Theme`, so asking for the Cupertino spinner on Android handed back
  the Material one — the variant that named it was a lie on every
  device that was not an iPhone. The module overrides
  `Theme.platform` for the INDICATOR alone and hands the child the real
  theme back: a child told it is on iOS would change how every
  scrollable and every switch beneath it behaves.
- **The haptic fired once per app, not once per pull.** `_hapticFired`
  was cleared only when a refresh COMPLETED, so a reader who pulled
  part-way and let go — the most common thing to do by accident — got
  a tick that time and silence afterwards. It clears on
  `ScrollEndNotification` now, whether or not anything was triggered.
- **A word in `semanticsValue` THREW.** Material's indicator is a
  progress node, and its value has to be a number: passing "Loading…"
  raised `Progress bar value, minValue, and maxValue must be valid
  numbers` out of the semantics update. The old code had the same
  shape, but its default was null so nobody reached it. What the
  reader hears now comes from the module's own live region.
- **It had no accessible name** — on a gesture with no visible
  affordance to discover either. It defaults to the localized
  "Refresh", and announces "Loading…" while the work runs.
- **Nothing read reduced motion.** The illustration's fade resolves to
  zero. `minShowDuration` deliberately does NOT: it is a floor on how
  long the indicator is READABLE, not an animation, and a reader who
  asked for less motion has not asked to be told less.
- **The illustration was outside the indicator**, hard-coded 88 points
  down, and in the semantics tree. It is inside now (so the `Stack`
  cannot swallow the notifications the indicator needs), the offset is
  a style knob, and it is `ExcludeSemantics` — the indicator already
  says what is happening.
- **`DateTime.now()` twice** measured the minimum show time, which the
  wall clock can move under. A `Stopwatch` cannot.

## Six additions

Two of them were holes rather than features.

- **A failing refresh vanished.** `onRefresh` had no catch, so a throw
  escaped into the framework's zone: the indicator came down and the
  screen looked untouched, which is indistinguishable from a refresh
  that succeeded and changed nothing — on the one gesture whose whole
  purpose is "did that work?". `onError` takes it now, and with no
  handler it goes to `FlutterError.reportError` (where the app's own
  handler and Crashlytics are). It is never swallowed. Telling the
  READER stays the caller's job: the module has no banner of its own
  and should not grow one.
- **A screen reader could not refresh at all.** The control had a NAME
  but no ACTION, and pulling is not something you can do with a screen
  reader on — there is no other path to the same result. Every
  instance now carries a `CustomSemanticsAction`, the same argument
  the swipe actions make.
- **`GlobalRefreshableController`** starts one from outside the tree —
  after a sign-in, from a toast's Retry, on resume, when connectivity
  returns. None of those has a finger. It reports `isRefreshing` and
  `lastRefreshedAt`, and goes inert when its widget is gone (the
  `owner`-guarded detach `GlobalDropdownController` documents: a
  replaced State's deferred dispose must not tear down its
  successor's wiring). `refresh()` goes through the platform
  indicator's own `show()`, so the spinner appears rather than the
  work running invisibly — which also means the indicator ANIMATES IN
  before `isRefreshing` turns true.
- **`indicatorBuilder`** draws it instead. Material's `RefreshIndicator`
  owns its own painting and has no slot for a different spinner, so
  this is a separate control: the builder is handed a `RefreshPull`
  (extent, progress, armed, isRefreshing) as the finger moves, and the
  work runs when it is released past `customTriggerExtent`. Passing
  the builder IS the request — asking a caller to also set
  `variant: custom` would only create a way to pass a builder nothing
  calls.
  A custom indicator is `onEdge` ONLY: it follows overscroll, which by
  definition happens at the end of the scroll range, so `triggerMode:
  anywhere` asserts rather than quietly doing the other thing.
  Recognising a pull from the middle of a list means tracking raw drag
  deltas instead — a different control, not a flag.
- **`minRefreshInterval`** skips the work when a pull lands inside the
  window, and tells the caller through `onSkipped`. The indicator
  still shows: a gesture that does nothing at all reads as a broken
  one. **Zero by default** — a reader who pulls twice usually means
  it, and a module that quietly ignored the second pull would be
  lying about what it did.
- **`lastUpdatedBuilder`** gets the time of the last COMPLETED refresh
  — "Updated 2 minutes ago", the line every mail app has. A failed
  refresh does not count as an update, which is the whole reason to
  track it separately from "when did we last try".

## The showcase threw forty-two warnings

Every demo list was raw `ListTile`s inside a `DecoratedBox` with a
fill, and a `ListTile` paints its background and its ink on the
nearest `Material` ANCESTOR — which the box was hiding. Flutter said
so on the way into the page, forty-two times, and nothing in the suite
noticed because a framework *warning* is only ever printed.

`test/refreshable/refreshable_showcase_test.dart` captures `debugPrint`
and fails on that string, which is what turns a warning into a test.
The demos use `GlobalList` + `GlobalContainer.tile` now, which paint
their own surface.

(Restoring `debugPrint` — or any foundation debug variable — has to
happen INSIDE the test body. `addTearDown` runs after the framework's
invariant check, so it fails the test it was meant to clean up after.)

## One pull in the app

`GlobalList`, `GlobalGrid` and the FAQ page each built their own raw
`RefreshIndicator` — the two collections being the widgets most people
would actually pull on. All three go through the module now, and
`test/refreshable/refreshable_adoption_test.dart` fails on a new raw
one anywhere in `lib` (the module itself and `debug_overlay/` are the
only exemptions, and the allow-list is currently EMPTY — the first
entry should have to argue for itself).

The regex matches the constructor call, not the word: these files'
doc comments name `RefreshIndicator.adaptive` when explaining what the
module does, and a guard that failed on prose would teach people to
stop writing it.

## Who uses it

Pull-to-refresh anywhere. Pair it with `GlobalList` / `GlobalGrid`,
whose own `onRefresh` slot builds one of these.

- Showcase: `/refreshable-showcase`.
