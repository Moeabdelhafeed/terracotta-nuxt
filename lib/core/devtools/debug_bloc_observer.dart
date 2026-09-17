import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Single transition captured for the debug overlay.
class BlocTransitionEntry {
  BlocTransitionEntry({
    required this.blocType,
    required this.kind,
    required this.summary,
    required this.at,
    this.detail,
  });

  final String blocType;
  final BlocTransitionKind kind;
  final String summary;
  final DateTime at;

  /// Full state/event dump for the inspector's detail sheet. Each
  /// side is capped at [DebugBlocObserver._kDetailCap] chars so a fat
  /// state object can't balloon the ring buffer.
  final String? detail;
}

enum BlocTransitionKind { create, change, transition, error, close }

/// Project-wide [BlocObserver] that records every cubit/bloc lifecycle
/// + state change into a ring buffer the debug overlay reads. Process-
/// lifetime memory only; no disk persistence.
///
/// Register from `bootstrap_di.dart` BEFORE any bloc is constructed —
/// `Bloc.observer = DebugBlocObserver()`.
class DebugBlocObserver extends BlocObserver {
  static const int _kCap = 200;
  static const int _kDetailCap = 1500;

  static String _snip(Object? o) {
    final s = o.toString();
    return s.length <= _kDetailCap ? s : '${s.substring(0, _kDetailCap)}…';
  }

  static final List<BlocTransitionEntry> _entries = [];
  static final StreamController<void> _changes =
      StreamController<void>.broadcast();

  /// Newest-first snapshot for the inspector.
  static List<BlocTransitionEntry> get snapshot =>
      List.unmodifiable(_entries.reversed);

  /// Fires after each entry lands.
  static Stream<void> get changes => _changes.stream;

  static void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    _changes.add(null);
  }

  static void _push(BlocTransitionEntry entry) {
    _entries.add(entry);
    while (_entries.length > _kCap) {
      _entries.removeAt(0);
    }
    if (!_changes.isClosed) _changes.add(null);
  }

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    _push(
      BlocTransitionEntry(
        blocType: bloc.runtimeType.toString(),
        kind: BlocTransitionKind.create,
        summary: '<created>',
        at: DateTime.now(),
      ),
    );
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    _push(
      BlocTransitionEntry(
        blocType: bloc.runtimeType.toString(),
        kind: BlocTransitionKind.change,
        summary:
            '${change.currentState.runtimeType} → '
            '${change.nextState.runtimeType}',
        at: DateTime.now(),
        detail:
            'from: ${_snip(change.currentState)}\n\n'
            'to: ${_snip(change.nextState)}',
      ),
    );
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    _push(
      BlocTransitionEntry(
        blocType: bloc.runtimeType.toString(),
        kind: BlocTransitionKind.transition,
        summary:
            '${transition.event.runtimeType}: '
            '${transition.currentState.runtimeType} → '
            '${transition.nextState.runtimeType}',
        at: DateTime.now(),
        detail:
            'event: ${_snip(transition.event)}\n\n'
            'from: ${_snip(transition.currentState)}\n\n'
            'to: ${_snip(transition.nextState)}',
      ),
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _push(
      BlocTransitionEntry(
        blocType: bloc.runtimeType.toString(),
        kind: BlocTransitionKind.error,
        summary: error.toString(),
        at: DateTime.now(),
        detail:
            'error: ${_snip(error)}\n\n'
            'stack:\n${stackTrace.toString().split('\n').take(8).join('\n')}',
      ),
    );
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    _push(
      BlocTransitionEntry(
        blocType: bloc.runtimeType.toString(),
        kind: BlocTransitionKind.close,
        summary: '<closed>',
        at: DateTime.now(),
      ),
    );
  }
}
