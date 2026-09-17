# CLAUDE.md — core/navigation/transitions

How a page arrives.

```
transitions/
  transition_style.dart      — TransitionType · TransitionDefaults · TransitionStyle · ResolvedTransitionStyle
  theme/transition_theme.dart— GlobalTransitionTheme + TransitionStyle.resolve(context)
  route_transition.dart      — TransitionOverride · RouteTransition · the swipeable page
  edge_back_gesture.dart     — the leading-edge swipe-back, RTL-aware
  nav_animation_style.dart   — NavAnimationDefaults · WidgetAnimation · ResolvedWidgetAnimation
  theme/nav_animation_theme.dart — GlobalNavAnimationTheme + WidgetAnimation.resolve(context)
  navigation_aware_animation.dart — per-WIDGET animations driven by RouteAware
```

## The bag

- **`TransitionStyle` is all-nullable**, floor in `TransitionDefaults`,
  app-wide layer in `MyGlobalTransitionTheme.build(tokens:)`
  (`core/theme/widget_themes/global_transition_theme.dart`, wired in
  `theme.dart`). Order is `route > TransitionOverride >
  GlobalTransitionTheme > TransitionStyle.defaults`. Presets: `push`,
  `modal`, `crossfade`.
- **It takes `tokens` and reads none of them.** A transition is motion,
  not layout — spacing, radii and icon sizes have no opinion about how
  long a page takes to arrive. The parameter is there so the theme reads
  like the other thirty.
- **The template ships an EMPTY app-wide bag**, so an adopter gets
  Flutter's own feel until they say otherwise — in one place, rather
  than in every route.
- **There is no second API.** `RouteAnimation`, `RouteTransition.call` /
  `.none` / `.slide` / `.slideUp` / `.fade` / `.scale` / `.material` /
  `.ios` / `.custom` and `GoRouteTransitionExtension` were ~500 lines
  of near-duplicate factories with **zero** call sites, beside a
  `buildPage` that every route already used. Deleted, not shimmed.

## The resolve is where the reader is served

Both of these used to be missing, and both were missing TWELVE times —
once per builder. They happen once now, in `resolve`, so nothing below
it needs a `BuildContext`:

- **Reduced motion collapses the type to `none`.** A full-screen page
  transition is the largest motion in the app. `respectReducedMotion:
  false` is for the rare screen whose transition IS the content — the
  same call the animation module makes.
- **`none` resolves to a ZERO duration and no swipe-back.** It is not a
  fast transition, it is no transition; a non-zero duration leaves the
  route sitting on an empty animation before it appears.

## Two families, and Arabic is where they differ

- **Physical** — `slideFromRight`, `slideFromLeft`, `slideFromTop`,
  `slideFromBottom`. They name a SIDE and keep it in every language. A
  caller who asks for "from the right" gets the right.
- **Directional** — `slideFromStart`, `slideFromEnd`, and every
  `morph*`, which describe a MOTION rather than a side. They multiply
  their horizontal travel by `ResolvedTransitionStyle.directionSign`, so
  forward navigation enters from the right in English and from the left
  in Arabic, the way the platform does. `TransitionType.isDirectional`
  says which family a value is in.
- Before this, every slide was an absolute `Offset(1, 0)` and Arabic
  pushed the wrong way through the whole app.
- `morphRotate`'s TURN follows its travel too, or a page arriving from
  the left reads as being thrown backwards.
- **The back gesture mirrors as well**, and it is OURS
  (`edge_back_gesture.dart`) rather than a package's. Every package that
  offers this measures from `dx = 0` and commits on a rightward drag —
  hard-coded left-to-right. `CupertinoPage` gets it right natively, so
  in Arabic an `ios` route mirrored and every other route did not: the
  same app with two different back gestures, one of them on an edge
  nobody could reach. `universal_back_gesture` is gone from
  `pubspec.yaml`.
- Everything in that file is measured FROM THE LEADING EDGE and
  multiplied by the same `directionSign` the transitions use, so the
  gesture and the travel it scrubs agree about which way is forward.
  The route carries the resolved `textDirection` for exactly that.

## Fixed on the way

- **`morphScale` animated a `const SizedBox()`.** Its outgoing half
  wrapped an empty box in four nested transitions, so the effect the
  name promises never happened — the covered page just sat there. It
  animates the real child now, which is what `secondaryAnimation` is
  for.
- **`buildPage` returns `Page<T>`**, not a bare `Page`.
- **Every magic number is in `TransitionDefaults`** — the 0.3 travel,
  the 0.8 and 0.95 scales, the rotate's 0.1 turns, the three stagger
  intervals, and the back gesture's detection area.

## Widgets that animate on a navigation event

`NavigationAwareAnimation` is the other half: not how the PAGE arrives,
but how a widget ON it reacts to `didPush` / `didPushNext` / `didPop` /
`didPopNext`. It uses `RouteAware`, because GoRouter's routing is
declarative and offers no callback to hang this on.

- **`WidgetAnimation` is the same shape as everything else**:
  all-nullable, floor in `NavAnimationDefaults`, app-wide layer in
  `MyGlobalNavAnimationTheme.build(tokens:)`, resolved through
  `resolve(context)`. It used to be non-nullable with baked defaults —
  no merge, no theme, no equality.
- **Only the OPEN fields belong in the theme** — duration, curve, delay.
  A slide there would move every widget in the app.
- **Reduced motion cancels it outright**, and the widget then skips the
  controller entirely rather than running a zero-length animation. It
  also stops holding the widget at its starting opacity: an entrance
  that fades from zero would otherwise hide it for good, because the
  entrance never runs.
- **The same two families as the page transitions.**
  `slideFromStart` / `slideToStart` / `slideFromEnd` / `slideToEnd`
  mirror (`mirrorInRtl: true`); `slideFromLeft` / `slideFromRight` and
  the vertical pair do not. Every preset used to be an absolute offset,
  so a column of them travelled the wrong way in Arabic.
- **The delay is a cancellable `Timer`.** A bare `Future.delayed`
  outlives the widget — the third time that bug turned up in this
  codebase.
- **The controller is built in `initState`, not lazily.** A `late final`
  is created on first touch, and the first touch can be `dispose` when
  nothing ever played — constructing a ticker while the element
  unmounts looks up an ancestor that is already gone.

## Nothing else builds a page route

`RouteTransition.route` is the imperative twin of `buildPage`, for a
`Navigator.push`. Its absence is why nine modules hand-rolled a
`MaterialPageRoute` — a fullscreen PDF, the FAQ detail, the wizard, the
pane's compact detail, the scanner, the feedback screen, the range
picker, the video trimmer, and a dialog promoted to a full screen.
Every one of them got Material's transition instead of the app's, with
no theme, no reduced-motion collapse, and a back gesture nailed to the
left edge.

`test/navigation/transition_adoption_test.dart` fails on a new one.
Three surfaces are allow-listed WITH REASONS — the lightbox, the image
viewer and fullscreen video are transparent or immersive overlays, not
pages — plus `debug_overlay/` by the same agreement every other
adoption guard makes.

## The showcase

`/transitions-showcase`, and **one route** behind it —
`/transitions/:type` — where seventeen near-identical `GoRoute`s used
to sit, two of them duplicates (`/transitions/rt-fade` was
`/transitions/fade`). A new `TransitionType` needs no route and no
showcase edit: the page builds its list from `TransitionType.values`.

The page also PREVIEWS a transition in a box, driven by an
`AnimationController` through the same `RouteTransition.buildTransition`
the router calls. Comparing two of them used to mean pushing, going
back, and pushing again.

- Guards: `test/navigation/transitions_test.dart` (the three layers,
  reduced motion, both families in both directions, what each type
  builds, the override, `buildPage` through a real `GoRouter`, and the
  back gesture dragged from both edges),
  `test/navigation/nav_animation_test.dart`, and
  `test/navigation/transition_adoption_test.dart`.
