# CLAUDE.md — lib/shared/module/toast

Transient feedback for the whole app. `GlobalToast` is a static facade
(no widget), backed by `ToastOverlay` — our own overlay engine.

```dart
GlobalToast.s('Saved');
GlobalToast.e('Upload failed', description: 'Check your connection');
GlobalToast.undo('Item deleted', onUndo: restore);
```

## This module replaced a package

`toastification` used to supply six things: insert an `OverlayEntry`,
place it by alignment, stack several, animate them in and out, run the
auto-close timer, hand back a handle. Everything VISIBLE was already
here, so the dependency was paying for scheduling, not for looks.

It also leaked: `ToastificationType` and `ToastificationStyle` appeared
in `GlobalToast.show`'s signature, so even the showcase had to import
the package. Those are `ToastType` and `ToastVariant` now, with
`ToastHandle` replacing the item.

## Contracts

- **Style is the themeable bag `ToastStyle`** — every field nullable,
  with `defaults` + `mergedWith` + `copyWith`, materialized once per
  toast by `style.resolve(context)` into a `ResolvedToastStyle` whose
  themed fields are non-null. Resolution is
  `caller > GlobalToastTheme.style > ToastStyle.defaults > tokens`.
- **`ToastStyle.defaults` carries NO severity colours.** They resolve
  from `context.statusColors`, so a toast tracks role, brightness and
  saturation; four constants would freeze all three. Same reason
  `MyGlobalToastTheme` sets none.
- **Every toast ANNOUNCES itself** to assistive tech
  (`SemanticsService.sendAnnouncement`) unless `announce: false`. This
  is the one thing a `SnackBar` did that a toast did not, and until it
  landed, replacing a SnackBar with a toast was an accessibility
  regression. Errors are `assertive` (they interrupt); everything else
  is `polite`.
- **The toast is a semantics OBJECT, not just an utterance.** The
  announcement speaks it once; a `Semantics(container:, label:,
  onDismiss:)` node makes it focusable, re-readable and closable.
  Without it the swipe and the close button were sighted-only
  affordances. Deliberately NOT a `liveRegion`: that re-announces on
  every rebuild, and the imperative announcement already reads it once
  with the right assertiveness.
- **How long it stays scales with how much there is to read**
  (`toastReadingDuration`, ~14 chars/second, floored at
  `kToastAutoClose` and capped at 10s). A fixed window gave "Saved" and
  a two-line explanation the same time. An explicit `duration` — from
  the caller or a preset — is a decision and is always honoured.
- **`onTap` makes the whole toast a target**, and closes it after
  running: a notification that stays on screen after being opened sits
  over the very thing it opened. The close button and the action still
  win their own taps — they are deeper hit-test targets and the tap
  layer is translucent.
- **An action-bearing toast gets a duration floor**
  (`kToastActionMinDuration`, 8s). WCAG 2.2.1: a control that vanishes
  on a timer fails anyone slow to read it. An explicit LONGER duration
  is honoured; an explicitly shorter one is not. Anything genuinely
  important belongs in a `GlobalBanner` or a dialog, which do not
  expire.
- **One renderer, `_ToastSurface`.** There used to be two — a custom
  path for gradients and the package's container for everything else —
  so a change to padding or the close button had to be made twice.
- **The ROOT overlay, not the nearest one.** A toast raised inside a
  dialog belongs above that dialog; a nearest-overlay entry would be
  buried by it, or die with the route.

## Variants

`vivid` (default) · `filled` · `flat` · `outlined` · `minimal`.

**`vivid`** is `filled` with a gradient DERIVED from the severity colour
— lifted toward the leading edge, deepened at the trailing one, so it
reads as a sheen rather than two toasts joined together. Derived, not
configured, so it tracks the palette like every other variant.
`ToastPreset.vivid` is the everyday toast wearing it.

Both saturated fills (`filled`, `vivid`) force a WHITE foreground: the
background is the severity colour, not the surface, so the surface's own
`onSurface` would sink into it whatever the app's brightness.

## Gotchas

- **Built-in title/description are plain `Text`, not `GlobalText`.**
  `GlobalText` resolves a colour from the type scale and pins it, which
  beat the surface's `DefaultTextStyle` and left dark text on a
  saturated background. The strut still comes along, so metrics stay
  standardized.
- **Stacking measures.** Each toast reports its height after layout and
  the pile offsets by real sizes plus a gap. A constant step per index
  cannot work: a toast with a description is half again as tall as one
  without, so a fixed spacing either overlaps them or leaves holes.
- **The countdown is a `Timer` unless a progress bar needs otherwise.**
  A ticking `AnimationController` schedules a frame every vsync for the
  toast's whole life, and `pumpAndSettle` runs it to completion — so
  every settling widget test in the app would dismiss its own toast. The
  controller is created only when `showProgressBar` is on, where the
  ticking is paying for something.
- **The progress bar DRAINS** (`1 - value`) and sits inside the
  container, clipped to its radius. Appended below it, it fell outside
  the rounded edge and read as a separate object.
- **The glyph carries NO colour of its own.** A colour on the `Icon`
  beats the surface's `IconTheme`, so a baked white survived onto flat
  and outlined toasts and vanished against the surface. The variant
  decides, so the surface does — saturated fills get the foreground,
  surface variants get the severity colour. Loading indicators are the
  exception: they take a colour parameter rather than reading
  `IconTheme`, so they read it themselves and pass it on.
- **The trailing inset SUBTRACTS the close button's own padding.** That
  button centres an 18dp glyph in a 48dp target, so it already brings
  15dp of empty space; matching the leading inset on the end produced a
  visibly bigger gap. The surface computes `end = start - 15` when a
  close button is shown, so the two match by construction rather than by
  a tuned constant that drifts when either size changes. **That
  subtraction happens in DIRECTIONAL space** — it used to resolve the
  padding first and then write `right:`, which in Arabic is the LEADING
  edge, so the icon sat flush against the toast's start while the close
  button kept the full inset. Guard: the "gaps still match in Arabic"
  test, which wraps `Directionality` via `MaterialApp.builder` — a toast
  goes into the ROOT overlay, so one under `home:` never reaches it.
- **The theme factory's padding OVERRIDES `ToastStyle.defaults`.** It is
  asymmetric for the reason above, and must stay so — a symmetric value
  there silently beat the defaults, which is why tuning the constants
  alone changed nothing on screen.
- **The close control is a `GlobalIconButton`**, not Material's. A raw
  `IconButton` was the one control in the app without the module's
  focus, hover and touch-target behaviour.
- **`kToastStackSpacing` is a GAP, not a step.** It was 68 when it had
  to stand in for a whole toast's height; once heights were measured,
  leaving it there added that height twice.

- **The entry must outlive its own dismissal.** Removing it when
  dismissal STARTS cuts the exit animation off at that frame. Removal
  waits for the controller.
- **The host owns the AnimationController**, because it created it
  against its own vsync. The entry only borrows a reference and drops it
  in `detach()`. Disposing from both throws.
- **A toast torn down WITH its tree must cancel its timer.** Otherwise
  an armed `Timer` outlives the widget — harmless at runtime, fatal to
  any widget test that ends with a toast showing.
- **`maxVisible` counts the overlay, not a private tally.** A separate
  `_activeCount` used to shadow it and was decremented only on the
  normal dismissal path, so a toast removed with its route left the
  count high — and once it reached `maxVisible`, EVERY new toast cleared
  the screen. Exceeding it now drops the oldest toast, which is what the
  knob always claimed.
- **Stacking is per ALIGNMENT.** Bottom-pinned toasts stack against each
  other; a top-pinned toast is a separate pile. Survivors reflow when
  one leaves.
- **The swipe shell stops building its `Dismissible`** once a dismissal
  completes. A toast is still on screen through its exit, so its element
  keeps rebuilding — and a live `Dismissible` there trips Flutter's "A
  dismissed Dismissible widget is still part of the tree".

- **Queue mode defers a CLOSURE, never a re-listed call.** It used to
  re-invoke `show` with all thirty parameters written out by hand, and
  the copy had already fallen behind — `toastStyle` was added and never
  forwarded, so a queued toast silently lost its style bag. A closure
  captures whatever the signature happens to be.
- **`navigatorKey` is a `GlobalKey`, not the app's `NavigationService`.**
  The module needs exactly one thing from it, and importing the service
  would drag a primitive module into the data layer. It was typed
  `dynamic` to dodge that, which bought loose coupling at the price of
  turning every mistake into a runtime `debugPrint`.
- **Every control is the app's own.** Close is a `GlobalIconButton`, the
  action is a `GlobalTextButton(link: true)` — the exact shape of an
  inline action in running text. Raw Material controls here were the
  only ones in the app without the module's focus and touch-target
  behaviour.

## Notification toasts live in commons

`shared/common/toasts/NotificationToast` renders a
`NotificationPayload`, shaped by CATEGORY rather than severity, and
wires the tap to `Notifications.reportTap` so an in-app tap routes
exactly like an OS one. It is not in this module because it needs the
notification domain — knowledge a generic UI primitive should not hold.

The in-app display used to call `GlobalToast` directly with `title` and
`body`, dropping the deep link (so a notification could not be opened at
all), the image, the timestamp and the priority — and mapping five
categories onto four severity colours, which put an app-update notice in
error red and a direct message in "info".

## No SnackBars

Transient feedback goes through `GlobalToast`, never
`ScaffoldMessenger.showSnackBar`. A toast paints above dialogs and
sheets, works with no `Scaffold`, survives route changes, and now
announces itself the same way.

`test/toast/no_snackbars_test.dart` FAILS the build on a new
`showSnackBar` in `lib/`, with a short allow-list:

- `system_pages/error_app.dart` — the bare fallback app shown when
  bootstrap fails. No overlay, no DI; it cannot reach `GlobalToast`.
- `debug_overlay/views/debug_ui_lab_view.dart` — a lab whose job is to
  exercise Material surfaces, the SnackBar theme included.

A second test fails if an allow-list entry goes stale, so the exceptions
cannot quietly outlive their reason. `MySnackBarTheme` stays wired for
foreign snackbars raised by third-party packages.

## Showcase + tests

`/toast-showcase`. Tests: `toast_overlay_test.dart` (lifecycle,
stacking, reflow, control surface, timing), `toast_style_test.dart`
(bag merge, resolution order, palette colours, lerp, announcement),
`global_toast_swipe_test.dart` (the swipe/exit race),
`no_snackbars_test.dart` (the convention).
