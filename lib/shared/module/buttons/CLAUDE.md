# CLAUDE.md — lib/shared/module/buttons

Button family holding the text-field gold standard: app-wide theme
extension, context-resolved colors, style-gated haptics, localized
completion labels, reduced motion. Four public widgets over **one**
shared surface and **one** shared behaviour mixin:

- **`GlobalFilledButton`** — filled surface (renamed from
  `GlobalElevatedButton`: default elevation was always 0, so the old
  name described an opt-in knob, not the widget). `tonal: true` gives
  the M3 soft-tint secondary emphasis; elevation stays a style knob.
- **`GlobalOutlinedButton`** — transparent surface, themed border.
- **`GlobalTextButton`** — bare ink surface, no border/elevation.
  `link: true` switches to web-link presentation: the box hugs the label
  (no side padding, no preset height) and `underline:`
  (`always` / `onHover` / `never`) rules an animated line that grows
  from the LEADING edge — right-to-left in Arabic, via
  `AlignmentDirectional`, with no locale branch. The 48dp hit area is
  kept, and the ring is suppressed (`showFocusRing: false`) — the
  underline IS the focus cue, and a ring around a zero-padding label
  crowds the glyphs. Use it for footnote actions; keep the padded
  default for dialog and sheet action rows, where the box is the
  expected affordance.
- **`GlobalIconButton`** — square icon surface (IconData / asset path /
  widget), optional scroll-fade.

- **`GlobalSwipeButton`** — swipe to confirm. A BUTTON, not a slider:
  no value, one destination, and it reports an ACTION. See "Swipe to
  confirm" below.

**An overflowing label marquees by itself.** The label is measured
against the width it is actually given; when it does not fit it scrolls
so the whole string stays readable. No opt-in — a button label IS the
affordance, and "Delete acc…" and "Delete all…" are the same button as
far as the user can tell. `labelOverflow: LabelOverflow.ellipsis` opts
out (per-call > `GlobalButtonsTheme.labelOverflow` > marquee), and
`marqueeLabel: MarqueeStyle?` tunes the scroll. Reduced motion
truncates. Pause-on-hover/touch are forced OFF whatever is passed —
those install gesture recognizers, and a pan recognizer inside a button
competes with its own InkWell for taps.

Two things that look like implementation detail and are not:

- **The label is always `Flexible`.** The content `Row` is
  `mainAxisSize.min`, so without it a squeezed button threw a RenderFlex
  overflow and the label had to be shortened by hand. A loosely
  constrained button still grows to fit, so nothing changes there.
- **Nothing is wrapped until the label is measured as too wide.**
  Leaving a marquee mounted always would be simpler, and is wrong twice:
  a `SingleChildScrollView` under every button in the app, and a
  horizontal viewport reports an intrinsic width of ZERO — so every
  button inside an `IntrinsicWidth` (every sheet action row) would
  collapse. For the same reason the width is read through a
  `RenderProxyBox` (`_WidthProbe`) and not a `LayoutBuilder`, which
  refuses intrinsic queries outright. Guard:
  `test/buttons/marquee_label_test.dart` → "survives an IntrinsicWidth
  ancestor".

All four share: per-state style bags, `size:` presets
(`ButtonSize.small/medium/large` — height + padding, icon side),
`isLoading` (5 indicator types), `result:` completion flash, debounce,
tooltip, focus plumbing, and a 48dp minimum touch target.

Emphasis ladder, highest → lowest: **filled → tonal → outlined →
text**. "Ghost" is the text button — no separate widget. Icon toggles
(favorite/bookmark/mute) use `GlobalIconButton(isSelected:,
selectedStyle:)`; the selected default is an opaque primary tint with a
`primaryHighContrast` glyph (raw primary on its own tint fell below
AA). Deliberately NOT here: FAB (scaffold/positioning territory) and
split/dropdown buttons (the dropdown module covers menus).

## Architecture — read this before editing

Three pieces in `button_internals.dart` back every variant. They exist
because these were previously copy-pasted per file, and the copies
drifted: seven real defects were found living in two-to-four
duplicates each.

- **`ButtonSurface`** — the painted, interactive surface.
  `ButtonSurfaceKind` picks solid / gradient / blur / flat; `padding:
  null` centres the content (icon buttons). Owns the InkWell, hover,
  elevation, border wrap and focus.
- **`ButtonBehaviorMixin`** — completion-flash timer and debounce.
  Call `syncButtonResult` from `initState` **and** from
  `didUpdateWidget` on `result` *or* `isLoading` change;
  `disposeButtonBehavior` from `dispose`.
- **`MinTouchTarget`** — expands the HIT AREA to 48dp without
  stretching the painted size (mirrors Material's `_InputPadding`).

Anything that applies to all four variants belongs in one of those. If
you find yourself pasting into a second variant file, stop.

## Contracts

- **Style is per-STATE bags**: `style` (base) + `disabledStyle` /
  `loadingStyle` / `successStyle` / `errorStyle`. App-wide defaults come
  from `GlobalButtonsTheme` — per-variant base bags (`filledStyle` …
  `iconStyle`) plus app-wide `disabledStyle` / `loadingStyle` /
  `successStyle` / `errorStyle` / `debounceDuration` / `enableHaptic`.
  Everything merges **theme ← caller** (caller's non-null fields win).
- **A caller `textStyle` MERGES over the preset.** It used to replace it
  outright, so passing a partial style (only a `fontFamily`, say) silently
  dropped the preset's size and weight — and with no `fontSize` the
  label's `AppTextStrut` had nothing to anchor to, so the metric
  standardization vanished too. Guard:
  `test/buttons/label_strut_test.dart`.
- **`successStyle`/`errorStyle` MERGE over the built-in defaults**, they
  do not replace them: `successStyle: ButtonStateStyle(text: 'Saved!')`
  keeps the checkmark and the status colours.
- **`merge` always means "other wins"**, including
  `ButtonLoadingStyle.merge`, which used to override its parent with the
  opposite precedence.
- **Colors resolve from context groups**: elevated bg
  `buttonsColors.primary`, outlined/text fg `primaryColors.primary`,
  icon fg `iconColors.primary`, disabled `textColors.disabled` +
  `buttonsColors.disabled`, completion `statusColors.success/error`.
- **Gradients**: the RESOLVER emits the final gradient — an explicit
  `disabledStyle.backgroundGradient` paints exactly as given, while a
  button with only a base gradient gets it dimmed to
  `kDisabledGradientAlpha`. `ButtonSurface` never re-dims.
- **Haptics** gate on `enableHaptic`: per-call > theme > `true`. Tap =
  light, long-press = medium, fired inside the debounced callbacks so a
  swallowed tap is silent. Tap and long-press keep **independent**
  debounce windows.
- **Reduced motion** zeroes the morph duration and skips the hover
  scale; loading indicators keep animating (semantic activity).
- **Focus affordances only paint for KEYBOARD focus.** A tap focuses a
  button, and a ring on a tapped button reads as "still focused" long
  after the user moved on. `ButtonSurface` tracks whether the CURRENT
  focus arrived from a pointer press on itself (`onTapDown`, cleared on
  focus loss) and suppresses the ring while it did; variants that draw
  their own affordance (the link underline) subscribe via
  `onFocusVisibilityChanged` rather than re-deriving it.
  `FocusManager.highlightMode` is deliberately NOT the gate: Android
  ignores IME-forwarded hardware keys for highlight purposes, so Tab
  moved focus while the ring never appeared.
- **Never wrap the content CONDITIONALLY.** The focus ring's
  `DecoratedBox` is always in the tree; only its `border` toggles.
  Adding/removing a wrapper changes the tree SHAPE at that slot, which
  remounts the whole content subtree — every descendant `State` is
  disposed and rebuilt, so in-flight animations restart at their end
  value. That is what made the link underline appear fully drawn instead
  of ruling in.
- **The ring TRACES itself** around the perimeter once
  (`AnimatedFocusRing` + `FocusRingPainter`, `kFocusRingDuration` =
  150ms) and then holds. Deliberately short: an indicator that lags
  behind fast tabbing is worse than one that just appears. It traces
  away from the leading edge — reversed in RTL — matching the link
  underline. Un-focusing clears it INSTANTLY rather than un-drawing; a
  ring still animating on a control that no longer has focus is a lie.
  Reduced motion jumps straight to the complete ring.
- **Focus feedback is surface-dependent.** An opaque fill gets a 28%
  foreground overlay (the default ~12% vanishes on it); a TRANSPARENT
  surface (text / outlined) gets a focus RING instead — that same 28%
  painted a slab where there was no button shape, so text buttons read
  as filled. The ring is a foreground decoration, so focus never
  changes layout, and it is the better WCAG 2.2 "Focus Appearance"
  answer: an outline against the page beats a tint blended into it.
- **Disabled presses always ripple** — a muted splash (drawn from the
  disabled foreground) confirms the tap LANDED even though nothing will
  happen. The handler lives on `ButtonSurface`'s own InkWell; an
  external wrapper's ink painted BEHIND the opaque background and was
  invisible. Without `onDisabledPressed` the button stays out of the
  tab order (`canRequestFocus: false`) — feedback is not an action.
- **`onDisabledPressed`** additionally makes the disabled button
  focusable and keyboard-activatable, firing that hook instead of
  `onPressed` — the "tap the dead submit to see why" pattern. Inert
  while loading / flashing a result.
- **A11y**: one `Semantics(button:)` node per button with a
  state-aware label, the tooltip text re-exposed, `enabled` reflecting a
  null `onPressed`, and `liveRegion` while loading or flashing (the
  loading label differs from the idle one on purpose — an identical
  string announces nothing).
- **Contrast**: `debugCheckButtonContrast` logs a `Logger` warning once
  per offending combo when a rendered label misses WCAG AA 4.5:1.
  Debug-only, `assert()`-wrapped. Grep the log for `[Buttons]`.

## Gotchas

- **The height measurement uses the SAME strut the label renders with.**
  It did not, and that is why an Arabic button came out taller than the
  identical English one while both labels reported the same height. The
  rendered `Text` takes its line box from `AppTextStrut` — deliberately
  font-independent — but `textSize()` measured with a bare
  `TextPainter`, so the BOX followed whatever font the script resolved
  to (Arabic falls back to a deeper-descent family than Inter, 3.16px of
  baseline apart at `fontSize: 14`; see `AppTextStrut`'s own numbers)
  while the INK did not. `finalHeight = measuredSize.height * 2` then
  multiplied the discrepancy.
- **No widget test can catch that class of bug.** The test font gives
  every glyph identical metrics, so English and Arabic measure the same
  in `flutter test` whatever the code does. The playground's two-script
  bench prints each button's laid-out height instead — a real device
  with the real fallback is the only place the numbers diverge.
- **The strut's reference family is part of the size cache key.** It is
  global and swappable (tests set it), so a size cached before a swap
  would be the previous font's.

- `shrinkWidth: false` (default) = fill-width; inside an unbounded Row
  you MUST pass `shrinkWidth: true` or layout forces infinite width.
- **The overflow decision costs one frame.** The available width is
  known only after layout, so the first frame renders the label
  truncated and the marquee appears on the next. Tests must `pump()`
  once before asserting on `GlobalMarquee`.
- `MinTouchTarget.hitTest` **must** bounds-check before its
  forced-centre fallback, or every button claims every tap on the page
  and the last-painted one wins.
- `textSize` needs the ambient `TextScaler` — box height is
  `measured * 2`, so measuring unscaled clips labels for large-font
  users. The cache key includes height, fontStyle and the scaler.
- Completion `result:` starts a Timer; tests must pump past
  `completionDuration` (1.5s default) or the pending-timer check trips.
- `enableBlur` is deliberately absent on `GlobalTextButton` — a blurred
  transparent surface is meaningless.
- Slot `AnimatedSwitcher` keys derive from the slot's `runtimeType`, not
  identity: pass a `Key` on the slot to crossfade two same-typed slots.
- **Do NOT swap leading/trailing for RTL.** The content `Row` is given
  the ambient `textDirection`, so it already places the first child at
  the reading start — right in Arabic. Swapping as well flips it twice
  and puts leading icons on the wrong side. Guard:
  `test/buttons/rtl_slot_order_test.dart`.

## Showcase + tests

`/button-showcase` family pages (anatomy). Pre-built variants live in
`shared/common/buttons/` (Common Hub catalog). Tests:
`test/buttons/global_buttons_test.dart` (theme merge, localized result
labels en+ar, reduced motion, tap gating, touch target, disabled hook)
and `test/buttons/disabled_contrast_test.dart` (every role's disabled
label clears 4.5:1 on both the button block and the surface).

## Swipe to confirm

`GlobalSwipeButton` is the fifth variant, and the only one that is not
built on `ButtonSurface`.

- **It lives HERE, not in `slider/`.** The test is whether it has a
  VALUE: it does not. One destination, and what it reports is an
  action. A screen reader must hear "button". The slider only lends it
  the mechanics of dragging something along a track.
- **It does NOT use `ButtonSurface`** — the one place a variant departs
  from "anything shared belongs in internals". That surface is built
  around an `InkWell`, and **a tap must not confirm**: the friction is
  the feature. It reuses everything else — `ButtonBehaviorMixin` for
  the completion flash and the debounce, the per-state bags, the
  haptic gate, and `GlobalButtonsTheme` via a `swipeStyle` field beside
  the other four. No second ThemeExtension.
- **`SwipeButtonStyle` is its own bag type.** A track, a thumb and a
  distance to travel are not expressible in the `ButtonStateStyle` the
  others share.
- **It commits on RELEASE, not on crossing.** Committing at the
  threshold would let a fast flick fire something nobody meant;
  releasing is the deliberate act. `confirmThreshold` defaults to 0.9 —
  not 1.0, because a track that only commits when the thumb is pinned
  to the far wall makes the last few points feel broken.
- **Enter, Space and a screen reader's tap fire it in ONE step.** That
  looks like it defeats the deliberateness and does not: the friction
  is for a thumb that might brush the screen, and forcing a drag on
  someone who cannot make one is a barrier, not a confirmation.
- **It claims the gesture arena on the THUMB only.** A swipe button
  lives in a checkout sheet or a page view, and a plain
  `GestureDetector` loses the horizontal axis to whichever of those it
  is inside. Claiming the whole track would be worse — a page with one
  in it could not be swiped away. Same recognizer shape as the circular
  slider's.
- **It MIRRORS in Arabic.** The opposite call to the video timeline: a
  timeline runs one way because the frames were shot in that order,
  and this is progress through an action, so it follows reading
  direction.
- **Three haptics**: light on grab, selection at the threshold — so the
  commit point is felt BEFORE letting go — and medium on confirm. The
  debounce wrapper's own haptic is suppressed, or the confirm stutters.
- **An ERROR result runs the travel BACKWARDS**, because the action did
  not happen and the control has to be ready to be asked again.
  Snapping home instead looked like a different control appearing and
  gave the reader no sense that what they did had been undone. A
  success leaves it at the end.
- **`GlobalSwipeButtonController.reset()` puts a confirmed one back.**
  Once the thumb has landed the control is spent, and an action that
  turns out to be wrong — or a form being filled in again — needs it
  back; the widget cannot know when that is. It detaches by IDENTITY,
  so a controller handed to a new button is not unhooked by the old
  one tearing down.
- **The thumb's contents MORPH.** Swapped outright it went empty for a
  frame between the chevron and the spinner and read as a glitch. The
  `AnimatedSwitcher`'s key is the STATE, not the widget — two icons of
  the same type are the same widget to a switcher, so an icon-to-icon
  change would not animate at all.
- **A custom thumb has to carry its own KEY to morph.** The state key
  includes it, so a `thumbBuilder` whose widget is keyed animates like
  every built-in state and one whose widget is not swaps instantly.
  Only the caller knows what "different" means for their widget —
  `Widget.canUpdate` compares runtime type and key, and two `Icon`s
  differ in neither.
- **The focus ring paints for KEYBOARD focus only**
  (`onShowFocusHighlight`), and is always in the tree with only its
  colour moving: adding and removing a wrapper changes the tree shape
  at that slot and remounts the track, restarting the thumb mid-travel.
  Same rule the toggle group follows.
- **The hint shimmer SWEEPS THREE TIMES and stops.** It is an
  invitation, not a loading bar — and one that never stops means the
  tree never goes idle: every frame of a page that has one is spent
  repainting it, and nothing that waits for quiescence ever gets it.
  Its pause is a cancellable `Timer`, not a bare `Future.delayed`,
  which outlived the widget.
- **Reduced motion** kills the shimmer and makes the spring-back
  instant.
- The clip is `Clip.antiAliasWithSaveLayer`: a soft clip leaves a
  hairline of the fill outside the curve, which is the bleed the toggle
  group's corners had.
- **It MIRRORS in Arabic on the horizontal axis, and NOT on the
  vertical one.** Up is forward on both sides of the world; only a
  horizontal axis has a reading direction.
- **`axis: Axis.vertical` starts the thumb at the BOTTOM**, keeps the
  track's own width whatever box it is handed — a tight horizontal
  constraint would smear the pill sideways — and turns the label a
  quarter turn so it reads bottom-to-top with the travel. `extent`
  sets the throw when the box is open-ended, which a column always is;
  otherwise it takes the constraint, falling back to
  `SwipeButtonDefaults.verticalExtent`.
- **A track too short to swipe ASSERTS.** Below
  `trackHeight × SwipeButtonDefaults.minLengthFactor` the thumb has no
  travel and the control becomes a tap target that refuses taps —
  `GlobalButton` is the widget for that, so the assert says so rather
  than shipping a stub.
- **`flingVelocity` is opt-IN.** A fast release short of the threshold
  can commit, but only when a caller asks: a flick is the gesture most
  likely to happen without meaning, and this control exists so that
  cannot fire anything. The recognizer carries a `VelocityTracker` for
  it — a release is only a fling if the pointer was still moving.
- **`dragAnywhere` is opt-in for the same reason the arena claim is
  narrow.** It takes the whole track, so a page view carrying one
  could not be swiped away.
- **`resetAfter` is the timer version of the controller.** For a
  control that will be used again once the action has been
  acknowledged. It is cancelled on dispose and by an explicit reset.
- **`onProgress` fires on the ANIMATION, not the drag** — so a
  spring-back, a settle and a keyboard activation all report too — and
  is skipped for a frame that moved less than 0.001.
- **`confirmedLabel` is READ, not faded.** The resting label fades as
  the thumb covers it, but once confirmed the label is the RESULT: it
  sits at full strength in `confirmedLabelColor`, which defaults to
  what reads on the fill. `confirmedIcon` replaces the glyph the thumb
  arrived with.
- **`fillEndRadius` rounds the fill's MOVING edge only.** The other end
  is pinned to the track's corner and takes its curve from the clip.
  Square by default so the fill reads as one surface with the track;
  rounded, it becomes a capsule chasing the thumb.
- Showcase: `/swipe-button-showcase`, reached from the buttons hub
  like every other variant — the hub is a directory of nav cards, not a
  page of demos.
- Guard: `test/buttons/global_swipe_button_test.dart`.
