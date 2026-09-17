import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/module/debug_overlay/widgets/debug_chrome.dart';
import '../utils/loggers/logger.dart';

/// Debug-only wrapper that keeps a [WidgetInspector] PERMANENTLY mounted
/// so toggling the DevTools/IDE widget inspector never changes the widget
/// tree's structure.
///
/// Why: `WidgetsApp` inserts/removes its root [WidgetInspector] when the
/// IDE flips `debugShowWidgetInspectorOverride`. Inserting a widget into
/// the ancestor chain of the Navigator can't preserve elements — the whole
/// subtree below is torn down and rebuilt, so every page loses its
/// ephemeral state (text fields, scroll, open menus) on EVERY inspector
/// toggle (tracked upstream: flutter/devtools#9123).
///
/// Fix path the framework itself provides:
///  1. [install] sets `WidgetsBinding.debugExcludeRootWidgetInspector`,
///     which tells `WidgetsApp` to NOT mount its structural-churn wrapper.
///  2. This widget mounts one [WidgetInspector] that never unmounts.
///     `_WidgetInspectorState` listens to the override notifier and flips
///     its internal `isSelectMode` via `setState` — behaviour identical,
///     zero structural change, page state survives.
///
/// Release/profile: [install] is `assert`-stripped and [build] returns
/// [child] untouched.
class PersistentWidgetInspector extends StatelessWidget {
  const PersistentWidgetInspector({required this.child, super.key});

  final Widget child;

  /// Call BEFORE `runApp` (bootstrap) so `WidgetsApp`'s very first build
  /// already skips its own inspector wrapper. Calling later risks one
  /// structural toggle before the exclusion takes effect.
  static void install() {
    assert(() {
      WidgetsBinding.instance.debugExcludeRootWidgetInspector = true;
      // Start every run OUT of select mode.
      //
      // Select mode wraps the whole app in an IgnorePointer, so if the
      // IDE/DevTools still has it enabled from a previous session, the
      // inspector mounts in select mode on the FIRST frame and the app
      // is completely dead — no taps, no keyboard — with only the small
      // exit button as a clue. Before this widget existed the inspector
      // was mounted late, so a stale override could not reach cold
      // start; now that it is permanent, the override has to be cleared
      // explicitly. DevTools can turn it straight back on, and then the
      // block is visible and intentional.
      WidgetsBinding.instance.debugShowWidgetInspectorOverride = false;
      // Remove-then-add rather than a "did I already install" flag.
      // Two handlers toggling the same flag cancel out, so a double
      // install would make the shortcut look dead; but a flag would be
      // wrong in the other direction, because the test binding clears
      // keyboard handlers between tests and a second install has to
      // actually re-register. Static tear-offs are canonical, so
      // removeHandler matches, and it is a no-op when nothing is
      // registered.
      HardwareKeyboard.instance
        ..removeHandler(_onKey)
        ..addHandler(_onKey);
      Logger.m.i(
        '[Inspector] shortcuts armed — Cmd/Ctrl+Shift+I (select mode), '
        'Cmd/Ctrl+Shift+T (select on tap)',
      );
      return true;
    }());
  }

  // ── Programmatic control ──────────────────────────────────────────
  //
  // Both pieces of inspector state live on the binding as public
  // ValueNotifiers, so nothing here reaches into private framework
  // state. Exposed as named operations because the call sites (a
  // keyboard handler, a bootstrap restore, a debug tool) should not each
  // have to know which notifier means what.

  /// Whether the inspector is intercepting the app at all.
  static bool get selectMode =>
      WidgetsBinding.instance.debugShowWidgetInspectorOverride;

  static set selectMode(bool value) =>
      WidgetsBinding.instance.debugShowWidgetInspectorOverride = value;

  /// Fires on every entry into and exit from select mode.
  static ValueNotifier<bool> get selectModeNotifier =>
      WidgetsBinding.instance.debugShowWidgetInspectorOverrideNotifier;

  /// Whether a tap SELECTS a widget instead of reaching the app.
  ///
  /// The framework defaults this to true on every launch and resets it
  /// to true whenever select mode is exited. Restoring a persisted
  /// value is therefore a deliberate act, not a default — see
  /// `DebugOverlayPrefs.inspectorSelectOnTap`.
  static bool get selectOnTap =>
      WidgetsBinding.instance.debugWidgetInspectorSelectionOnTapEnabled.value;

  static set selectOnTap(bool value) =>
      WidgetsBinding.instance.debugWidgetInspectorSelectionOnTapEnabled.value =
          value;

  /// Fires whenever [selectOnTap] changes, including the framework's own
  /// reset on exit. Bootstrap listens to persist it.
  static ValueNotifier<bool> get selectOnTapNotifier =>
      WidgetsBinding.instance.debugWidgetInspectorSelectionOnTapEnabled;

  // ── Keyboard ──────────────────────────────────────────────────────

  /// `Cmd/Ctrl + Shift + I` toggles select mode, `+ T` toggles
  /// select-on-TAP.
  ///
  /// Handled at [HardwareKeyboard] rather than through `Shortcuts`
  /// deliberately. Select mode wraps the app in an `IgnorePointer`, so
  /// the moment it is on there is nothing to click except one small
  /// exit button — and the escape hatch must not itself depend on the
  /// app's focus tree being in a usable state.
  /// Logs every key the handler is offered.
  ///
  /// The failure this diagnoses is silence: a shortcut that does nothing
  /// looks identical whether the chord is wrong, the handler was never
  /// installed, or the platform is not delivering hardware keys to the
  /// engine at all (the iOS Simulator swallows Cmd chords, and forwards
  /// nothing until a text input client has attached). Turn this on and
  /// the three become distinguishable in one keypress.
  static bool debugTraceKeys = false;

  static bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final keyboard = HardwareKeyboard.instance;
    if (debugTraceKeys) {
      Logger.m.d(
        '[Inspector] key ${event.logicalKey.keyLabel} '
        'meta=${keyboard.isMetaPressed} ctrl=${keyboard.isControlPressed} '
        'shift=${keyboard.isShiftPressed}',
      );
    }
    // Meta OR control, so one binding covers macOS and Linux/Windows.
    if (!keyboard.isShiftPressed) return false;
    if (!keyboard.isMetaPressed && !keyboard.isControlPressed) return false;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyI) {
      selectMode = !selectMode;
      Logger.m.i('[Inspector] select mode -> $selectMode');
      return true;
    }
    if (key == LogicalKeyboardKey.keyT) {
      // Only meaningful — and only PERSISTED — while select mode is on.
      // Whoever wires persistence records changes made in select mode
      // and ignores everything else, because the framework itself
      // writes to this notifier when select mode is exited. Keeping the
      // shortcut to the same window means that rule has no exceptions.
      if (!selectMode) {
        Logger.m.i(
          '[Inspector] select-on-tap shortcut ignored — select mode is off',
        );
        return false;
      }
      selectOnTap = !selectOnTap;
      Logger.m.i('[Inspector] select on tap -> $selectOnTap');
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;
    return WidgetInspector(
      exitWidgetSelectionButtonBuilder: _exitButton,
      moveExitWidgetSelectionButtonBuilder: _moveButton,
      tapBehaviorButtonBuilder: _tapBehaviorButton,
      child: child,
    );
  }

  // The framework's inspector buttons, in the DEBUG CHROME's language.
  //
  // They used to be a Material `FloatingActionButton` in
  // `colorScheme.primary` plus two `GlobalIconButton`s reading
  // `Theme.of(context).colorScheme` — app theming, on the one surface
  // that has to sit outside it. A purple FAB landed next to the black
  // debug pill and neither looked deliberate.
  //
  // `DebugChromeButton` is the pill's own capsule: near-black fill, a
  // thin flavour-tinted stroke, a white glyph. It reads as "this is the
  // harness" whatever the app is painting underneath, including a
  // half-finished theme.
  //
  // NO Tooltip anywhere: these render ABOVE the Navigator, so there is
  // no Overlay ancestor and Tooltip asserts. Semantics carries the label
  // — which is what the framework's own buttons do.

  static Widget _exitButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required String semanticsLabel,
    required GlobalKey key,
  }) => DebugChromeButton(
    key: key,
    icon: Icons.close_rounded,
    onPressed: onPressed,
    semanticsLabel: semanticsLabel,
  );

  /// The side-swap button, which sits BESIDE the stack rather than in
  /// it.
  ///
  /// The framework lays the group out as
  /// `Row(crossAxisAlignment: end, [column, moveButton])` — so this one
  /// bottom-aligns with the EXIT button and needs no vertical padding of
  /// its own. A `bottom` gap here (which the first version had, copied
  /// from the button above the exit) lifts the chevron off the exit
  /// button's baseline and the two read as unrelated.
  ///
  /// The horizontal gap goes on whichever side FACES the column, which
  /// flips with `usesDefaultAlignment` because the Row reverses its
  /// children — directional insets, so it mirrors in Arabic too.
  static Widget _moveButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required String semanticsLabel,
    bool usesDefaultAlignment = true,
  }) => Padding(
    padding: EdgeInsetsDirectional.only(
      start: usesDefaultAlignment ? DebugChrome.gap : 0,
      end: usesDefaultAlignment ? 0 : DebugChrome.gap,
    ),
    child: DebugChromeButton(
      icon: usesDefaultAlignment
          ? Icons.chevron_right_rounded
          : Icons.chevron_left_rounded,
      onPressed: onPressed,
      semanticsLabel: semanticsLabel,
    ),
  );

  static Widget _tapBehaviorButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required String semanticsLabel,
    required bool selectionOnTapEnabled,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: DebugChrome.gap),
    child: DebugChromeButton(
      // Same glyph MaterialApp and DevTools use for this toggle.
      icon: const IconData(0x1F74A),
      onPressed: onPressed,
      semanticsLabel: semanticsLabel,
      // ON fills the capsule with the flavour colour rather than
      // tinting it. The framework's own toggle changed so little that
      // it read as a button that did not react.
      selected: selectionOnTapEnabled,
    ),
  );
}
