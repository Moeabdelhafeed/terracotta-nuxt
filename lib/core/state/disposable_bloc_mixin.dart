import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Collects disposable handles and cancels them all in [close].
///
/// Eliminates the "forgot to cancel that subscription" class of leak.
/// Supports [StreamSubscription] and [Timer]. Replaces the old
/// `DisposableMixin on GetxController` (which also handled GetX
/// `Worker` — gone with the GetX migration).
///
/// ```dart
/// class MyCubit extends Cubit<int> with DisposableBlocMixin<int> {
///   MyCubit() : super(0) {
///     disposeOnClose(someStream.listen(_onData));
///     disposeOnClose(Timer.periodic(const Duration(seconds: 1), _tick));
///   }
/// }
/// ```
mixin DisposableBlocMixin<S> on BlocBase<S> {
  final List<StreamSubscription<Object?>> _subs = [];
  final List<Timer> _timers = [];

  /// Register [handle] for cleanup. Returns [handle] for chaining.
  T disposeOnClose<T>(T handle) {
    switch (handle) {
      case StreamSubscription<Object?> s:
        _subs.add(s);
      case Timer t:
        _timers.add(t);
      default:
        throw ArgumentError(
          'DisposableBlocMixin: unsupported handle type ${handle.runtimeType}. '
          'Supported: StreamSubscription, Timer.',
        );
    }
    return handle;
  }

  @override
  Future<void> close() {
    for (final s in _subs) {
      s.cancel();
    }
    for (final t in _timers) {
      t.cancel();
    }
    _subs.clear();
    _timers.clear();
    return super.close();
  }
}
