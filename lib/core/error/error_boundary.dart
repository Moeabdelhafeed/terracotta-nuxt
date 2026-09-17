import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../shared/common/buttons/actions/retry_button.dart';
import '../crash_reporting/crash_reporter.dart';
import '../localization/strings/error_strings.dart';
import '../utils/loggers/logger.dart';
import 'debug_error_widget.dart';
import 'error_storm.dart';

/// App-wide error handling. Install once on boot (via
/// [GlobalErrorHandler.install]) to wire:
///  - `FlutterError.onError` — framework errors (build / layout / paint)
///  - `ErrorWidget.builder` — friendlier release placeholder
///    instead of Flutter's red-screen
///
/// `PlatformDispatcher.instance.onError` is intentionally NOT set here.
/// `bootstrap_firebase.dart` installs it after [CrashReporter] is ready
/// so async errors land in the crash reporter.
///
/// For subtree catching, wrap the subtree in [GlobalErrorBoundary].
class GlobalErrorHandler {
  GlobalErrorHandler._();

  static bool _installed = false;

  /// Install global handlers. Safe to call multiple times; only the
  /// first call takes effect. Pass [releaseBuilder] to override the
  /// default release placeholder.
  static void install({
    Widget Function(FlutterErrorDetails)? releaseBuilder,
  }) {
    if (_installed) return;
    _installed = true;

    FlutterError.onError = (FlutterErrorDetails details) {
      if (_isHarmlessFrameworkAssertion(details)) return;
      // A build/layout/paint error repeats EVERY frame. Fold the copies
      // before they reach the logger, or the first occurrence — the only
      // readable one — scrolls away and the log ring buffer is wiped.
      final verdict = ErrorStorm.admit(details.exception, details.stack);
      if (!verdict.log) return;
      // Fold the framework's context nodes ("The relevant error-causing
      // widget was…", overflow specifics) into the logged message —
      // this replaces FlutterError.presentError, whose raw
      // dumpErrorToConsole output bypassed the logger's formatting.
      final info = details.informationCollector?.call();
      final infoText = info == null || info.isEmpty
          ? ''
          : '\n${info.map((n) => n.toString()).join('\n')}';
      Logger.m.e(
        '${details.exceptionAsString()}$infoText${verdict.suffix}',
        stackTrace: details.stack,
        error: details.exception,
      );
      if (verdict.report) CrashReporter.recordFlutterError(details);
    };

    // Flutter's RenderErrorBox takes every pixel it is offered, which
    // hides the widgets around the failure — exactly the ones that
    // identify it — and leaves nothing to tap when it covers the page.
    // Both replacements size to their content instead.
    ErrorWidget.builder =
        releaseBuilder ??
        (kDebugMode ? _debugErrorWidget : _defaultReleaseErrorWidget);
  }

  /// Manually report an error through the pipeline. Use inside `catch`
  /// blocks where you want logging + crash-reporter forwarding without
  /// rethrowing.
  static void report(Object error, [StackTrace? stackTrace]) {
    // Same folding as the framework hook: a `catch` inside a per-frame
    // callback storms exactly as hard as a build error.
    final verdict = ErrorStorm.admit(error, stackTrace);
    if (!verdict.log) return;
    Logger.m.e(
      '[reported] $error${verdict.suffix}',
      error: error,
      stackTrace: stackTrace,
    );
    if (verdict.report) {
      CrashReporter.recordError(error, stackTrace: stackTrace);
    }
  }

  static Widget _debugErrorWidget(FlutterErrorDetails details) {
    return DebugErrorWidget(details: details);
  }

  static Widget _defaultReleaseErrorWidget(FlutterErrorDetails details) {
    return _ReleaseErrorPlaceholder(details: details);
  }
}

/// Framework false-positives filtered out before logging / reporting.
/// Keep this list TIGHT — every entry is a known harmless assertion
/// that fires during legitimate flows. Don't swallow real bugs here.
bool _isHarmlessFrameworkAssertion(FlutterErrorDetails details) {
  if (!kIsWeb) return false;
  // DDC throws a private `_AssertionError` subtype that isn't
  // `AssertionError` by `is` check — match by stack content instead.
  final stack = details.stack?.toString() ?? '';
  final message = details.exceptionAsString();
  // Mouse tracker fires `!_debugDuringDeviceUpdate` when a hover-aware
  // widget mutates during the mouse-update phase — common during route
  // transitions on web with animated buttons. Framework recovers.
  // See https://github.com/flutter/flutter/issues/138550.
  if (stack.contains('mouse_tracker.dart') ||
      message.contains('_debugDuringDeviceUpdate')) {
    return true;
  }
  return false;
}

class _ReleaseErrorPlaceholder extends StatelessWidget {
  const _ReleaseErrorPlaceholder({required this.details});

  // ignore: unused_element_parameter
  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    // Defensive: this widget can be inserted anywhere in the tree,
    // including outside MaterialApp where Theme.of(context) returns
    // a fallback. Use neutral colors that work everywhere.
    return Material(
      color: const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 8),
              Text(
                ErrorStrings.boundaryReleaseTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                ErrorStrings.boundaryReleaseBody,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Subtree-scoped boundary ────────────────────────────────────────────

/// Catches Flutter errors raised while building [child] and renders
/// [fallbackBuilder] (or a default "something went wrong" card)
/// instead of letting the error bubble up.
///
/// ```dart
/// GlobalErrorBoundary(
///   child: RiskyFeature(),
///   fallbackBuilder: (context, error, stack, retry) => ErrorCard(
///     message: 'Couldn\'t load this section',
///     onRetry: retry,
///   ),
/// );
/// ```
///
/// ## How scoping works
///
/// This widget hooks into [FlutterError.onError] while mounted and
/// restores the previous handler on dispose. Nested boundaries stack
/// — the innermost one catches first (last-installed wins). The hook
/// is global by nature of Flutter's error API, so in pathological
/// cases (e.g. an error fires from a completely unrelated isolate
/// while this boundary is mounted), the boundary may still catch it.
/// In practice this is extremely rare.
///
/// [GlobalErrorHandler.install] still runs for crash-reporting
/// purposes even when a boundary intercepts — errors are always
/// logged + forwarded, the boundary just prevents the red screen.
class GlobalErrorBoundary extends StatefulWidget {
  const GlobalErrorBoundary({
    super.key,
    required this.child,
    this.fallbackBuilder,
  });

  final Widget child;

  /// Builder for the error fallback UI. Receives the error, stack
  /// trace, and a `retry` callback that clears the boundary's error
  /// state (forces a rebuild of [child]).
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
    VoidCallback retry,
  )?
  fallbackBuilder;

  @override
  State<GlobalErrorBoundary> createState() => _GlobalErrorBoundaryState();
}

class _GlobalErrorBoundaryState extends State<GlobalErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;
  FlutterExceptionHandler? _previousHandler;

  @override
  void initState() {
    super.initState();
    _installHandler();
  }

  @override
  void dispose() {
    _restoreHandler();
    super.dispose();
  }

  void _installHandler() {
    _previousHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      _previousHandler?.call(details);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });
      });
    };
  }

  void _restoreHandler() {
    FlutterError.onError = _previousHandler;
    _previousHandler = null;
  }

  void _retry() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallbackBuilder?.call(
            context,
            _error!,
            _stackTrace,
            _retry,
          ) ??
          _DefaultErrorFallback(error: _error!, onRetry: _retry);
    }
    return widget.child;
  }
}

class _DefaultErrorFallback extends StatelessWidget {
  const _DefaultErrorFallback({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              ErrorStrings.boundaryFallbackTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                '$error',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            RetryButton(
              variant: CommonButtonVariant.outlined,
              showIcon: true,
              shrinkWidth: true,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
