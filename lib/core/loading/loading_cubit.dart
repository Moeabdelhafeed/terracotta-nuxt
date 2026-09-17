import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/loggers/logger.dart';
import 'loading_options.dart';
import 'loading_show_options.dart';
import 'loading_state.dart';
import 'loading_token.dart';

/// Owns the loading-stack state machine.
///
/// Three caller styles, all backed by the same token mechanism:
/// - [show] returns a [LoadingToken] you must `dispose()`.
/// - [run] wraps a `Future` in `try/finally`.
/// - [showWithCancel] returns the token plus the cancel callback.
///
/// Behaviours:
/// - **Debounce** (`appearAfter`): tokens that finish within this
///   window never trigger a paint.
/// - **Min visible** (`minVisible`): once the overlay is rendered
///   it stays at least this long even if all tokens disposed.
/// - **Auto timeout** (`autoTimeout`): tokens older than this are
///   force-disposed and a warning is logged. Catches forgotten
///   `dispose()` calls.
class LoadingCubit extends Cubit<LoadingState> {
  LoadingCubit({LoadingOptions options = const LoadingOptions()})
    : _options = options,
      super(const LoadingState()) {
    _watchdog = Timer.periodic(const Duration(seconds: 5), (_) => _sweep());
  }

  LoadingOptions _options;
  LoadingOptions get options => _options;

  int _nextId = 1;
  Timer? _appearTimer;
  Timer? _hideTimer;
  Timer? _watchdog;
  DateTime? _firstVisibleAt;

  // Tag → token, for de-dupe `show(tag: 'X')` calls.
  final Map<String, LoadingToken> _byTag = {};

  void updateOptions(LoadingOptions next) {
    _options = next;
  }

  // ─── Public API ──────────────────────────────────────────

  /// Push a token onto the stack and return it. The overlay shows
  /// after [LoadingOptions.appearAfter] (or the per-show override).
  /// Caller MUST dispose the token when the operation finishes.
  LoadingToken show([LoadingShowOptions options = const LoadingShowOptions()]) {
    // De-dupe by tag.
    final tag = options.tag;
    if (tag != null) {
      final existing = _byTag[tag];
      if (existing != null && !existing.isDisposed) return existing;
    }

    final token = LoadingToken(
      id: _nextId++,
      options: options,
      onDispose: _onDispose,
    );
    if (tag != null) _byTag[tag] = token;

    final next = List<LoadingToken>.from(state.tokens)..add(token);
    emit(state.copyWith(tokens: next));
    _scheduleAppear();
    return token;
  }

  /// Convenience — wraps a `Future` so the token is auto-disposed.
  /// Re-throws any error from [task] after disposing.
  Future<T> run<T>(
    Future<T> task, {
    String? label,
    LoadingShowOptions? options,
  }) async {
    final token = show(options ?? LoadingShowOptions(label: label));
    try {
      return await task;
    } finally {
      token.dispose();
    }
  }

  /// Wipe the stack — used by logout / "forget everything" flows so
  /// stale tokens from prior session can't keep the overlay alive.
  void clear() {
    if (state.tokens.isEmpty && !state.visible) return;
    _byTag.clear();
    emit(state.copyWith(tokens: const [], visible: false));
    _appearTimer?.cancel();
    _hideTimer?.cancel();
    _firstVisibleAt = null;
  }

  // ─── Internals ───────────────────────────────────────────

  void _onDispose(LoadingToken token) {
    if (!state.tokens.contains(token)) return;
    final tag = token.options.tag;
    if (tag != null && _byTag[tag] == token) _byTag.remove(tag);
    final next = state.tokens.where((t) => t.id != token.id).toList();
    emit(state.copyWith(tokens: next));
    if (next.isEmpty) {
      _scheduleHide();
    }
  }

  void _scheduleAppear() {
    if (state.visible) return;
    _appearTimer?.cancel();
    final delay = _resolveAppearAfter();
    _appearTimer = Timer(delay, () {
      if (state.tokens.isEmpty) return;
      _firstVisibleAt = clock.now();
      emit(state.copyWith(visible: true));
    });
  }

  void _scheduleHide() {
    _appearTimer?.cancel();
    if (!state.visible) {
      _firstVisibleAt = null;
      return;
    }
    _hideTimer?.cancel();
    final shownFor = _firstVisibleAt == null
        ? Duration.zero
        : clock.now().difference(_firstVisibleAt!);
    final remaining = _options.minVisible - shownFor;
    final delay = remaining.isNegative ? Duration.zero : remaining;
    _hideTimer = Timer(delay, () {
      // If new tokens arrived during the wait, stay visible.
      if (state.tokens.isNotEmpty) return;
      emit(state.copyWith(visible: false));
      _firstVisibleAt = null;
    });
  }

  Duration _resolveAppearAfter() {
    final perToken = state.top?.options.appearAfter;
    return perToken ?? _options.appearAfter;
  }

  void _sweep() {
    if (state.tokens.isEmpty) return;
    final now = clock.now();
    final stuck = <LoadingToken>[];
    for (final token in state.tokens) {
      final cap = token.options.autoTimeout ?? _options.autoTimeout;
      if (now.difference(token.createdAt) > cap) {
        stuck.add(token);
      }
    }
    if (stuck.isEmpty) return;
    for (final t in stuck) {
      Logger.m.w(
        '[Loading] auto-timeout firing on token #${t.id} '
        '(label="${t.options.label}", tag="${t.options.tag}") — '
        'caller probably forgot dispose()',
      );
      // Reported BEFORE the dispose: the token's options are what
      // name the caller, and a listener that wants to log this needs
      // them while they still mean something.
      _options.onTimeout?.call(t.options.label, t.options.tag);
      t.dispose();
    }
  }

  @override
  Future<void> close() {
    _appearTimer?.cancel();
    _hideTimer?.cancel();
    _watchdog?.cancel();
    _byTag.clear();
    return super.close();
  }
}
