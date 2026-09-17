import 'dart:async';

import 'package:flutter/foundation.dart';

/// A live resource left behind by a widget that died, held for the
/// widget that replaces it.
///
/// Entering fullscreen in portrait rotates the app, and the page
/// underneath reflows hard enough to destroy the inline player widget —
/// keep-alive does not stop it, because it is not a cull. The widget
/// hands its player to the fullscreen page rather than disposing it
/// (see `VideoOwnership`), which keeps the picture alive while the page
/// is up. But when the page closed it disposed that player, and the
/// widget that came back was a NEW state with a new engine: a black
/// frame, then the clip restarting from zero.
///
/// So the page parks the player here instead, and the returning widget
/// claims it. Nothing is created and nothing is re-opened — the same
/// engine keeps playing at the same position, and the only thing that
/// changed is which widget is showing it.
///
/// Generic because the policy is the whole point and the policy is what
/// needs testing: a `Player` cannot be constructed under `flutter_test`
/// without libmpv, so the tests park strings.
class HandbackSlot<T extends Object> {
  HandbackSlot({
    required this.onExpire,
    this.ttl = const Duration(seconds: 5),
  });

  /// Disposes a payload nobody came back for.
  final void Function(T payload) onExpire;

  /// How long a parked payload waits.
  ///
  /// The claim normally lands within a frame or two of the pop, so this
  /// is a backstop for the case where the widget never returns at all —
  /// the user popped the whole page from inside fullscreen, say. Too
  /// short drops a player that was about to be claimed; too long keeps
  /// an mpv instance and its audio alive with nothing showing it.
  final Duration ttl;

  String? _key;
  T? _payload;
  Timer? _reaper;

  /// Whether something is waiting to be claimed.
  @visibleForTesting
  bool get isOccupied => _payload != null;

  /// Leaves [payload] for the next widget that asks for [key].
  ///
  /// Parking over an occupant expires it. One player is coming back
  /// from fullscreen at a time, so an occupant here is a leak, not a
  /// queue.
  void park(String key, T payload) {
    if (_payload != null) _expire();
    _key = key;
    _payload = payload;
    _reaper = Timer(ttl, _expire);
  }

  /// Takes the payload parked under [key], or null.
  ///
  /// Claiming empties the slot: two widgets cannot end up sharing one
  /// player, which would dispose it twice.
  T? claim(String key) {
    if (_payload == null || _key != key) return null;
    final payload = _payload as T;
    _clear();
    return payload;
  }

  void _expire() {
    final payload = _payload;
    _clear();
    if (payload != null) onExpire(payload);
  }

  void _clear() {
    _reaper?.cancel();
    _reaper = null;
    _payload = null;
    _key = null;
  }

  /// Drops anything parked, expiring it. For tests, so one case cannot
  /// leave a live payload sitting in a static slot for the next.
  @visibleForTesting
  void reset() => _expire();
}
