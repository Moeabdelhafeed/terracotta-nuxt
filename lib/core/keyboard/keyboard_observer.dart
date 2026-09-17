import 'dart:async';

import 'package:flutter/widgets.dart';

/// Phase of a keyboard transition.
enum KeyboardPhase { hidden, rising, visible, falling }

/// One keyboard change: whether it is up, and how tall.
@immutable
class KeyboardEvent {
  const KeyboardEvent({
    required this.phase,
    required this.height,
  });

  final KeyboardPhase phase;

  /// Logical pixels. Zero when hidden.
  final double height;

  bool get isVisible => phase == KeyboardPhase.visible;

  @override
  bool operator ==(Object other) =>
      other is KeyboardEvent && other.phase == phase && other.height == height;

  @override
  int get hashCode => Object.hash(phase, height);
}

/// The compile-time floor under [KeyboardObserver].
abstract final class KeyboardDefaults {
  /// How long the insets must hold still before the keyboard counts as
  /// SETTLED.
  ///
  /// The engine reports metrics continuously while the keyboard
  /// animates and then simply stops; there is no "finished" callback.
  /// Without a settle window the last change seen is a rise, so the
  /// phase stayed `rising` for as long as the keyboard was up.
  static const settle = Duration(milliseconds: 120);

  /// A change smaller than this is noise, not a movement.
  static const epsilon = 0.5;
}

/// Watches the keyboard, in phases.
///
/// Reads the bottom view inset straight off
/// [PlatformDispatcher.views] rather than `MediaQuery`, which is what
/// makes it independent of the host `Scaffold`: `resizeToAvoidBottomInset`
/// consumes the inset from `MediaQuery` and leaves the underlying
/// `FlutterView` untouched, so a widget reading `MediaQuery` inside a
/// resizing Scaffold sees ZERO while the keyboard is up.
///
/// ```dart
/// // App-wide, installed by `GlobalKeyboardScope` in MyApp:
/// final keyboard = GlobalKeyboardScope.maybeOf(context);
///
/// // Or one of your own:
/// final keyboard = KeyboardObserver()..attach();
/// keyboard.addListener(() => print(keyboard.phase));
/// ```
///
/// There used to be TWO of these — this one under `popup/`, and a
/// static `KeyboardUtils` under `core/utils/` with a stream, no phases
/// and a mutable public `current` anyone could overwrite. They read the
/// same eight lines of insets in slightly different ways.
class KeyboardObserver extends ChangeNotifier with WidgetsBindingObserver {
  KeyboardObserver({this.settleDuration = KeyboardDefaults.settle});

  /// How long the insets must hold still before the phase settles.
  final Duration settleDuration;

  bool _attached = false;
  double _bottomInset = 0;
  double _lastNonZero = 0;
  KeyboardPhase _phase = KeyboardPhase.hidden;
  Timer? _settle;

  final StreamController<KeyboardEvent> _events =
      StreamController<KeyboardEvent>.broadcast();

  /// Current keyboard height in logical pixels (0 when hidden).
  double get bottomInset => _bottomInset;

  /// The last non-zero height seen — for sizing something before the
  /// keyboard has finished coming up.
  double get lastKnownSize => _lastNonZero;

  KeyboardPhase get phase => _phase;

  bool get isVisible => _phase == KeyboardPhase.visible;
  bool get isHidden => _phase == KeyboardPhase.hidden;
  bool get isTransitioning =>
      _phase == KeyboardPhase.rising || _phase == KeyboardPhase.falling;

  /// The current state, as a value.
  KeyboardEvent get current =>
      KeyboardEvent(phase: _phase, height: _bottomInset);

  /// Every change, for a caller that would rather listen than rebuild.
  Stream<KeyboardEvent> get onChange => _events.stream;

  /// Start watching. Idempotent.
  void attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
    _readInsets();
  }

  /// Stop watching. Safe to call twice.
  void detach() {
    if (!_attached) return;
    _attached = false;
    _settle?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void dispose() {
    detach();
    _events.close();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Deferred to the next frame: read mid-transition and some
    // platforms hand back an intermediate value. The engine fires this
    // continuously while the keyboard moves, so one read per event
    // still catches every step.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_attached) return;
      _readInsets();
    });
  }

  void _readInsets() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return;
    final view = views.first;

    // `FlutterView.viewInsets` is in PHYSICAL pixels at the engine
    // boundary; `MediaQuery` has already divided. Match MediaQuery.
    final raw = view.viewInsets.bottom / view.devicePixelRatio;

    final previous = _bottomInset;
    _bottomInset = raw;
    if (raw > 0) _lastNonZero = raw;

    final moved = (raw - previous).abs() > KeyboardDefaults.epsilon;
    final next = _phaseFor(previous: previous, current: raw);
    final changed = next != _phase || moved;
    _phase = next;

    // The engine never says "done", it just stops reporting. Anything
    // still moving is promoted once the insets hold still.
    _settle?.cancel();
    if (_phase == KeyboardPhase.rising || _phase == KeyboardPhase.falling) {
      _settle = Timer(settleDuration, _settleNow);
    }

    if (changed) _emit();
  }

  void _settleNow() {
    if (!_attached) return;
    final settled = _bottomInset > 0
        ? KeyboardPhase.visible
        : KeyboardPhase.hidden;
    if (settled == _phase) return;
    _phase = settled;
    _emit();
  }

  void _emit() {
    notifyListeners();
    if (!_events.isClosed) _events.add(current);
  }

  KeyboardPhase _phaseFor({
    required double previous,
    required double current,
  }) {
    if (current == 0) {
      return previous > 0 ? KeyboardPhase.falling : KeyboardPhase.hidden;
    }
    if (previous == 0 || current > previous) return KeyboardPhase.rising;
    if (current < previous) return KeyboardPhase.falling;
    // Equal and non-zero: it has stopped moving.
    return KeyboardPhase.visible;
  }
}
