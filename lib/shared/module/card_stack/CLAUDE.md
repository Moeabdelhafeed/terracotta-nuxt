# CLAUDE.md — shared/module/card_stack (and layered_stack)

Two modules, one idea of depth. `GlobalCardStack` and
`GlobalLayeredStack` both draw a pile of cards at one anchor, scaled
and offset by how deep each one is. What they do with that pile is
the whole difference.

```
card_stack/
  stack_models.dart        — StackDefaults · StackStyle · ResolvedStackStyle
  theme/stack_theme.dart   — GlobalStackTheme + the resolve
  global_card_stack.dart   — GlobalCardStack + its controller
layered_stack/
  global_layered_stack.dart — GlobalLayeredStack + its controller
```

## Which one

| | what it does | why the index moves |
| --- | --- | --- |
| `GlobalCardStack` | a queue the reader CONSUMES | a card LEFT |
| `GlobalLayeredStack` | a pile the reader LOOKS at | the CALLER said so |

The card stack is a gesture: drag the top card, it tilts, and past a
threshold it flies off and is **removed**. Undo rewinds it. Tinder.

The layered stack has no drag at all (only an optional
`tapToAdvance`). Nothing is ever removed — it draws N items with one
on top and the rest peeking behind. A notification pile, a wallet, a
stack of photos.

Neither is `GlobalPageView`'s `PageTransition`, which transforms
whole pages during a scroll.

## ONE bag for the two

- **All-nullable `StackStyle`**, floor in `StackDefaults`, app-wide
  layer in `MyGlobalStackTheme.build(tokens:)`
  (`core/theme/widget_themes/global_stack_theme.dart`, wired in
  `theme.dart`). Presets: `flat`, `notifications`, `decisive`.
- **It lives in `card_stack/` and the layered stack imports it** — the
  same shape as the carousels importing the page view's bag. The card
  stack is the superset: every depth field means something to both,
  and the swipe fields mean nothing to the pile.
- **The rebrand hook is GEOMETRY, not a palette.** Neither module
  paints anything — the caller's `itemBuilder` draws every card. What
  a house sets once is how deep a deck looks, and that is exactly what
  was drifting: each module had its own `scaleStep`, its own peek
  offset and its own visible-layer cap, so deepening one left the
  other on its own numbers.
- **Resolved in `didChangeDependencies`** — the extension and
  `disableAnimationsOf` are inherited reads. The card stack's two
  `AnimationController`s are created bare in `initState` and TIMED in
  the resolve, because reading the bag from `initState` is the
  `LateInitializationError` the page family and the carousel both
  shipped.
- **The geometry is pure functions on the resolved bag** —
  `scaleAt`, `opacityAt`, `peekAt` — so it is testable without
  pumping a widget, which is where the RTL mirroring is pinned down.

## Fixed on the way

- **Neither had a single `Semantics` node**, and the card stack is the
  worse case: a swipe is not a gesture assistive tech can make, and a
  deck has no other affordance at all, so a screen reader met a wall
  of cards it could neither count nor act on. Every allowed direction
  is a `CustomSemanticsAction` now, with undo beside them when there
  is something to undo. **`directionLabels` is where the MEANING
  goes** — the module can only honestly say "Swipe left"; a caller
  knows it means Pass.
- **The layered stack is an ADJUSTABLE only when something can drive
  it.** No controller and no `tapToAdvance` means a picture: a label,
  no actions. With one, `value` / `increasedValue` / `decreasedValue`
  go together (Flutter asserts otherwise) and the arrows move a
  layer. Only the TOP item is announced — announcing four would read
  the pile out four items at a time.
- **`loop` + `undo` DEALT A DUPLICATE.** A looping dismissal puts the
  card at the bottom of the deck rather than removing it, but it was
  still recorded for undo — so undoing inserted a second copy of a
  card that had never left, and the deck grew by one every time.
  Looping records nothing now.
- **A FLICK is a dismissal.** Distance was the only test, so a short,
  fast flick — the gesture people make once they know a deck — snapped
  back every time. `flingVelocity` (700 px/s) dismisses under the
  threshold. A flick picks its axis by SPEED, not by how far the
  finger drifted.
- **The controller could not count its own deck.** `next()` walked the
  index past the end forever while the widget clamped on the way out,
  so coming back took as many `previous()` calls as had overshot — and
  `loop` never wrapped for a controller at all, only for
  `tapToAdvance`. It is told the length and the loop on every build,
  clamps or wraps at the source, and reports `canGoNext` /
  `canGoPrevious` so a caller's buttons can go dead at the ends.
- **Nothing read reduced motion.** It flattens the motion and keeps
  the deck WORKING: the tilt goes to zero and the travel goes to
  nothing — the card is simply gone and the next one simply there.
  What does not go is the dismissal itself (it is the control), the
  DEPTH (it is layout), or the flick (an input, not an animation).
  The snap-back takes its own branch, because a zero-duration
  controller never ticks and there would be no frame to put the card
  back on.
- **The peek MIRRORS in Arabic.** `right` means the reading end, which
  is where a reader's eye already goes; it used to fan the same
  physical way in every language. Vertical peeks do not mirror.
- **The card stack's peek was a bare vertical offset** baked into the
  widget, so a deck could not fan the way the pile could. It takes
  `peekDirection` off the shared bag now.
- **A dead `AnimatedSlide`** sat above every layer of every pile with
  `offset: Offset.zero` hard-coded — a widget that animated nothing,
  and the comment under it admitted as much. One `AnimatedContainer`
  carries the transform.
- **`3.14159` was written out** where `math.pi` was meant.

## The second pass

- **A rebuild UNDID a swipe.** `didUpdateWidget` compared the item
  lists with `identical`, and a caller who builds their list in
  `build()` — the normal thing, and what three demos on our own
  showcase do — hands over a new instance every frame. Measured: after
  dismissing one of three cards, an unrelated `setState` anywhere up
  the tree put `remaining` back to 3 and wiped the undo history.
  `const` lists survived by canonicalization, which is why it hid. It
  is `listEquals` now, so a genuinely different deck still replaces
  the old one.
- **Neither took a KEYBOARD.** Not one `Focus`, `Shortcuts` or key
  handler in nineteen hundred lines — so on desktop and web, where
  most of the ways in have no touchscreen, a swipe deck was
  unreachable and a pile could only be tapped. The semantics actions
  cover a screen reader; they do nothing for a sighted keyboard user.
  Arrows deal the top card (Ctrl / Cmd + Z rewinds one) and move a
  layer on the pile, MIRRORED in Arabic on the horizontal axis only.
  **Never autofocus** — TAB reaches them, the same rule the page
  family and the collections were fixed to.
- **A pile nothing can drive takes no tab stop.** It is a picture, and
  the `Focus` is only wrapped when a controller or `tapToAdvance` can
  actually move it — the same call its semantics node makes.
- **An empty deck drew a BLANK BOX.** `SizedBox.expand()` and nothing
  else, on the one screen in the app where running out is the expected
  ending. It renders `GlobalEmptyState` now, with `emptyBuilder` for a
  caller's own.
- **`tapToAdvance` was silently dead with a controller.** The gate was
  `tapToAdvance && controller == null`, so wiring both gave a pile
  that ignored every tap — no assert, no hint. `_step` already routed
  through the controller.
- **`onSwipe` had no opposite.** A caller that sent a request when a
  card left had no hook to call it off; `onUndo` carries the card, its
  index and the way it had gone. `onIndexChanged` does the same for
  the pile, which otherwise could not be followed without owning a
  controller you did not need.
- **The undo history was unbounded** — a triage session that dealt a
  thousand cards kept every one. `undoLimit` (10) drops the oldest;
  zero turns undo off as surely as `allowUndo: false`.
- **The card PIVOTS now.** It rotated about its own centre, which
  reads as a card being twisted; a real deck pivots about a point
  below the card, near where a thumb would be, so the top swings
  further than the bottom (`rotationAnchorY`). The tilt is applied
  SEPARATELY from the scale — folding it into the one transform would
  pivot the scale about that point too, which is a card growing out of
  the floor. Reduced motion drops the pivot with the tilt, and the
  `flat` preset has neither.

## They had NO tests

Nineteen hundred lines across the two, no bag, no theme, no
semantics, no reduced motion — and not one test. The suite came with
the pass: `test/stack/` covers the bag and the three layers, the
theme lerp, the pure geometry (including the RTL mirror), the deal /
snap / flick, the loop-and-undo duplicate, the controller's clamp and
wrap, both semantics contracts, and an overflow sweep of both
showcases.

- Showcases: `/card-stack-showcase`, `/layered-stack-showcase`. Both
  were rewritten into the `ShowcaseSection` / `ShowcaseDemoCard`
  pattern; both used to hand-roll their own headers and captions.
