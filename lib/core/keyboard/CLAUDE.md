# CLAUDE.md — lib/core/keyboard

Where the keyboard is, in phases. One observer, one scope, no package.

```
keyboard/
  keyboard_observer.dart — KeyboardPhase · KeyboardEvent · KeyboardDefaults · KeyboardObserver
  keyboard_scope.dart    — GlobalKeyboardScope: one observer for the subtree
```

## There used to be three of these

- `shared/module/popup/controller/keyboard_observer.dart` — phases, a
  `ChangeNotifier`, used by the popup engine only.
- `core/utils/device/system/keyboard_utils.dart` — a static class with a
  stream, no phases, and a mutable public `current` anyone could
  overwrite.
- the `keyboard_detection` package — a poll, a fourth vocabulary
  (`visibling` / `hiding`) for the same four states, and a controller
  that had to be threaded through a `KeyboardDetection` widget.

All three read the same eight lines of view insets in slightly
different ways. The package is gone from `pubspec.yaml`; the other two
are this file.

## Why not `MediaQuery`

`MediaQuery.viewInsetsOf(context).bottom` is the obvious read and it is
wrong under the widget every app already has: **`Scaffold` with
`resizeToAvoidBottomInset: true` CONSUMES the inset**. It subtracts the
keyboard from the `MediaQuery` it hands its body, so a descendant sees
**zero** while the keyboard is up — the resize is exactly the thing
that hides the signal.

`KeyboardObserver` reads
`PlatformDispatcher.views.first.viewInsets.bottom` instead. Nothing in
the widget tree can consume that. It divides by the view's
`devicePixelRatio` because the engine boundary is in PHYSICAL pixels
and `MediaQuery` has already divided — the two numbers have to be
comparable or the showcase's side-by-side means nothing.

`/keyboard-detection-showcase` is that comparison with a toggle on it.

## The settle window

The engine reports metrics continuously while the keyboard animates and
then **simply stops**. There is no "finished" callback, so the last
change seen is a rise — and a naive phase derivation stays `rising` for
as long as the keyboard is up.

`KeyboardDefaults.settle` (120ms) is a timer restarted on every moving
read; when it fires, whatever is non-zero is promoted to `visible` and
whatever is zero to `hidden`. `KeyboardObserver(settleDuration:)` is
the seam a test uses to make that instant.

`KeyboardDefaults.epsilon` (0.5px) is the other half: sub-pixel jitter
at the end of the animation is not a movement, and without it the
settle timer never got to fire.

## Reads are deferred one frame

`didChangeMetrics` fires mid-transition on some platforms with an
intermediate value, so the read happens in a post-frame callback. The
engine fires the callback continuously while the keyboard moves, so one
read per event still catches every step of the rise.

## Two surfaces, both live

- `addListener` / `notifyListeners` — it is a `ChangeNotifier`, so it
  drops into an `AnimatedBuilder` or a `setState`.
- `onChange` — a broadcast `Stream<KeyboardEvent>` for a caller that
  would rather not rebuild. `dispose` closes it.

`current` is a **value** (`KeyboardEvent`), not a mutable field. The
old `KeyboardUtils.current` was public and settable, which meant any
caller could lie to every other one.

## Who uses it

- `MyApp`'s builder wraps the app in `GlobalKeyboardScope`, so
  `GlobalKeyboardScope.maybeOf(context)` works anywhere without a
  second observer attaching.
- `GlobalPopupController` subscribes when a scope is present and falls
  back to `MediaQuery` when it is not — a popup over a resizing
  `Scaffold` is precisely the case `MediaQuery` gets wrong.
- `/device-showcase` prints the phase beside the raw insets.
- Guard: `test/keyboard/keyboard_observer_test.dart`.
