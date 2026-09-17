import 'package:clock/clock.dart';
import 'loading_show_options.dart';

/// Disposable handle returned by [LoadingCubit.show]. Caller must
/// call [dispose] when the underlying operation finishes (success or
/// failure). Use [LoadingCubit.run] for one-off ops where the
/// try/finally is wrapped automatically.
///
/// Ref-counted internally — multiple live tokens stack the overlay
/// stays visible until all are disposed.
class LoadingToken {
  LoadingToken({
    required this.id,
    required this.options,
    required void Function(LoadingToken) onDispose,
  }) : _onDispose = onDispose;

  final int id;
  final LoadingShowOptions options;
  final void Function(LoadingToken) _onDispose;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  /// Wall-clock when the token was created. Used by the cubit's
  /// auto-timeout watchdog.
  final DateTime createdAt = clock.now();

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _onDispose(this);
  }
}
