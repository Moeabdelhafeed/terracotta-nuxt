import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart' show HapticFeedback;

import '../../../core/localization/strings/common_strings.dart';
import 'refreshable_controller.dart';
import 'refreshable_models.dart';
import 'theme/refreshable_theme.dart';

export 'refreshable_controller.dart';
export 'refreshable_models.dart';
export 'theme/refreshable_theme.dart';

/// Pull-to-refresh, with an adaptive indicator and an optional
/// illustration pinned above the content while the work runs.
///
/// ```dart
/// GlobalRefreshable(
///   onRefresh: () => bloc.refresh(),
///   child: GlobalList.static(items: items, itemBuilder: ...),
/// )
/// ```
///
/// The [child] must contain a `Scrollable`. Without one the pull can
/// never be recognised and this passes straight through.
///
/// Visual configuration is the themeable bag [RefreshableStyle] —
/// `caller > GlobalRefreshableTheme.style > RefreshableStyle.defaults`.
class GlobalRefreshable extends StatefulWidget {
  const GlobalRefreshable({
    required this.onRefresh,
    required this.child,
    this.controller,
    this.illustration,
    this.indicatorBuilder,
    this.lastUpdatedBuilder,
    this.onError,
    this.onSkipped,
    this.style = const RefreshableStyle(),
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.triggerMode = RefreshIndicatorTriggerMode.onEdge,
    this.semanticsLabel,
    this.semanticsValue,
    super.key,
  });

  /// The work to do on pull. The indicator stays up until this
  /// completes, and for at least [RefreshableStyle.minShowDuration]
  /// after it started.
  final Future<void> Function() onRefresh;

  /// The scrollable subtree.
  final Widget child;

  /// Starts a refresh from outside the tree — after a sign-in, from a
  /// toast's "Retry", on resume, when connectivity returns.
  final GlobalRefreshableController? controller;

  /// Faded in below the indicator while the work runs — a brand mark,
  /// a Lottie, whatever the app wants to say while it waits.
  final Widget? illustration;

  /// Draws the indicator INSTEAD of the platform one.
  ///
  /// Material's `RefreshIndicator` owns its own painting and has no
  /// slot for a different spinner, so this is a separate control: the
  /// builder is handed the pull as it happens and the module runs the
  /// work when the finger is released past the trigger. Forces
  /// [RefreshableVariant.custom].
  final Widget Function(BuildContext, RefreshPull)? indicatorBuilder;

  /// Draws something with the time of the last successful refresh —
  /// "Updated 2 minutes ago", the line every mail app has. Null until
  /// one completes.
  ///
  /// Held at the top of the content, so it belongs to short chrome
  /// rather than a long caption.
  final Widget Function(BuildContext, DateTime?)? lastUpdatedBuilder;

  /// Called when [onRefresh] throws.
  ///
  /// Without one the error is reported through `FlutterError.onError`,
  /// which is where the app's own handler and Crashlytics are — it is
  /// NOT swallowed. What is not automatic is telling the READER: a
  /// refresh that fails silently looks exactly like one that succeeded
  /// and changed nothing, so a caller that can show a banner should.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Called instead of [onRefresh] when a pull lands inside
  /// [RefreshableStyle.minRefreshInterval]. The indicator still shows —
  /// the gesture has to feel like it landed.
  final VoidCallback? onSkipped;

  final RefreshableStyle style;

  /// Which scrollable's notifications count. Narrow it when a nested
  /// list would otherwise trigger the outer one's refresh.
  final ScrollNotificationPredicate notificationPredicate;

  /// Where in the scroll range the pull is recognised.
  ///
  /// **`onEdge` only when [indicatorBuilder] is set.** The custom
  /// control follows OVERSCROLL, which by definition only happens at
  /// the end of the scroll range; recognising a pull from the middle
  /// of a list means tracking raw drag deltas instead, which is a
  /// different control. It asserts rather than quietly doing the other
  /// thing.
  final RefreshIndicatorTriggerMode triggerMode;

  /// What a screen reader calls the control. Defaults to the localized
  /// "Refresh" — it had no name at all, on a gesture that has no
  /// visible affordance to discover either.
  final String? semanticsLabel;

  /// What it announces while the work runs. Defaults to the localized
  /// "Loading…".
  final String? semanticsValue;

  @override
  State<GlobalRefreshable> createState() => _GlobalRefreshableState();
}

class _GlobalRefreshableState extends State<GlobalRefreshable> {
  late ResolvedRefreshableStyle _rs;

  /// Material's own indicator, so a caller — or a screen reader — can
  /// start the same refresh a finger would.
  final GlobalKey<RefreshIndicatorState> _indicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _isRefreshing = false;

  /// Whether the haptic has already fired for the pull in progress.
  bool _hapticFired = false;

  /// When the last refresh COMPLETED. Drives both
  /// [GlobalRefreshable.lastUpdatedBuilder] and the minimum interval.
  DateTime? _lastRefreshedAt;

  // ─── Custom-indicator pull state ────────────────────────────
  double _pullExtent = 0;

  @override
  void initState() {
    super.initState();
    _attach(widget.controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Here, not `initState`: the palette and `disableAnimationsOf` are
    // both inherited reads.
    _rs = widget.style.resolve(context);
  }

  @override
  void didUpdateWidget(GlobalRefreshable old) {
    super.didUpdateWidget(old);
    if (old.style != widget.style) _rs = widget.style.resolve(context);
    if (old.controller != widget.controller) {
      old.controller?.detach(owner: this);
      _attach(widget.controller);
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(owner: this);
    super.dispose();
  }

  void _attach(GlobalRefreshableController? controller) {
    controller?.attach(
      owner: this,
      onRefresh: refresh,
      isRefreshing: () => _isRefreshing,
      lastRefreshedAt: () => _lastRefreshedAt,
    );
  }

  /// Starts a refresh as though the reader had pulled.
  ///
  /// The platform indicator has its own `show()`, which is what makes
  /// the spinner appear rather than the work running invisibly; the
  /// custom control has no such thing, so it drives its own state.
  Future<void> refresh() async {
    if (_isRefreshing) return;
    final indicator = _indicatorKey.currentState;
    if (indicator != null) return indicator.show();
    return _handleRefresh();
  }

  Future<void> _handleRefresh() async {
    if (mounted) setState(() => _isRefreshing = true);
    widget.controller?.notify();
    // A Stopwatch, not two `DateTime.now()` readings: the wall clock
    // can move under a long refresh.
    final elapsed = Stopwatch()..start();
    try {
      if (_withinInterval) {
        // The indicator still shows — a gesture that does nothing at
        // all reads as a broken one — but the work is not re-run.
        widget.onSkipped?.call();
      } else {
        await widget.onRefresh();
        _lastRefreshedAt = DateTime.now();
      }
    } catch (error, stack) {
      // NOT swallowed, and not rethrown either: rethrowing from here
      // escapes into the framework's zone with no indicator left to
      // explain it, which is how a failed refresh used to look exactly
      // like a successful one.
      if (widget.onError != null) {
        widget.onError!(error, stack);
      } else {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'GlobalRefreshable',
            context: ErrorDescription('while running onRefresh'),
          ),
        );
      }
    } finally {
      final remaining = _rs.minShowDuration - elapsed.elapsed;
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
      if (mounted) setState(() => _isRefreshing = false);
      widget.controller?.notify();
    }
  }

  /// Whether the last refresh is recent enough to skip this one.
  bool get _withinInterval {
    if (_rs.minRefreshInterval == Duration.zero) return false;
    final last = _lastRefreshedAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < _rs.minRefreshInterval;
  }

  /// One tick per pull, when it crosses the threshold.
  ///
  /// `_hapticFired` used to be cleared only when a refresh COMPLETED,
  /// so a reader who pulled part-way and let go — the most common
  /// thing to do by accident — got a tick that time and silence for
  /// every pull afterwards. It is cleared when the pull ends now,
  /// whether or not it triggered anything.
  bool _onNotification(ScrollNotification n) {
    if (_rs.enableHaptic) {
      if (n is OverscrollNotification &&
          !_hapticFired &&
          n.overscroll < -_rs.hapticThreshold) {
        _hapticFired = true;
        HapticFeedback.mediumImpact();
      } else if (n is ScrollEndNotification) {
        _hapticFired = false;
      }
    }
    if (_variant == RefreshableVariant.custom) _trackPull(n);
    return false;
  }

  /// Follows the finger for a caller's own indicator.
  ///
  /// Overscroll is reported as a NEGATIVE delta at the top of a
  /// scrollable, so the extent accumulates the other way; a scroll that
  /// goes back down cancels it, and letting go past the trigger runs
  /// the work.
  void _trackPull(ScrollNotification n) {
    if (!widget.notificationPredicate(n)) return;
    if (n is OverscrollNotification && n.overscroll < 0) {
      _setPull(_pullExtent - n.overscroll);
    } else if (n is ScrollUpdateNotification &&
        _pullExtent > 0 &&
        (n.scrollDelta ?? 0) > 0) {
      _setPull((_pullExtent - n.scrollDelta!).clamp(0, double.infinity));
    } else if (n is ScrollEndNotification) {
      final armed = _pullExtent >= _rs.customTriggerExtent;
      _setPull(0);
      if (armed && !_isRefreshing) _handleRefresh();
    }
  }

  void _setPull(double value) {
    if (_pullExtent == value) return;
    setState(() => _pullExtent = value);
  }

  RefreshPull get _pull => RefreshPull(
    extent: _pullExtent,
    progress: _rs.customTriggerExtent <= 0
        ? 0
        : (_pullExtent / _rs.customTriggerExtent).clamp(0.0, 1.0),
    armed: _pullExtent >= _rs.customTriggerExtent,
    isRefreshing: _isRefreshing,
  );

  /// The variant actually drawn.
  ///
  /// Passing an `indicatorBuilder` IS the request for a custom
  /// indicator — asking a caller to say it twice only creates a way to
  /// pass a builder that is never called.
  RefreshableVariant get _variant =>
      widget.indicatorBuilder != null ? RefreshableVariant.custom : _rs.variant;

  Widget _buildIndicator(Widget child) {
    switch (_variant) {
      case RefreshableVariant.custom:
        // Checked HERE rather than in the constructor: an assert in a
        // const constructor may only read potentially-constant
        // expressions, and `style.variant` is a property access on a
        // parameter.
        assert(
          widget.indicatorBuilder != null,
          'RefreshableVariant.custom needs an indicatorBuilder — there '
          'is nothing else to draw.',
        );
        assert(
          widget.triggerMode == RefreshIndicatorTriggerMode.onEdge,
          'A custom indicator follows overscroll, which only happens at '
          'the end of the scroll range — so it can only trigger '
          'onEdge. Silently ignoring `anywhere` would make the knob a '
          'lie.',
        );
        // No `RefreshIndicator` at all — the caller's widget is the
        // indicator, and the pull is tracked from the notifications.
        return Stack(
          children: [
            child,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedSlide(
                  duration: _rs.customSettle,
                  offset: Offset(0, _isRefreshing || _pullExtent > 0 ? 0 : -1),
                  child: ExcludeSemantics(
                    child: widget.indicatorBuilder!(context, _pull),
                  ),
                ),
              ),
            ),
          ],
        );
      case RefreshableVariant.material:
        return RefreshIndicator(
          key: _indicatorKey,
          onRefresh: _handleRefresh,
          color: _rs.color,
          backgroundColor: _rs.backgroundColor,
          displacement: _rs.displacement,
          edgeOffset: _rs.edgeOffset,
          strokeWidth: _rs.strokeWidth,
          notificationPredicate: widget.notificationPredicate,
          triggerMode: widget.triggerMode,
          semanticsLabel: widget.semanticsLabel ?? CommonStrings.refresh,
          // NO `semanticsValue` here. Material's indicator is a
          // PROGRESS node, and its value has to be a number — a word
          // in that slot throws `Progress bar value, minValue, and
          // maxValue must be valid numbers` out of the semantics
          // update. What the reader hears while it runs is announced
          // by the live region below instead.
          child: child,
        );
      case RefreshableVariant.cupertino:
      case RefreshableVariant.adaptive:
        // The PLATFORM is overridden for the indicator alone.
        //
        // `RefreshIndicator.adaptive` reads `Theme.of(context).platform`
        // — so asking for the Cupertino spinner on Android handed back
        // the Material one, and the variant that named it was a lie on
        // every device that was not an iPhone. `adaptive` never reaches
        // here: it has already been resolved to a concrete variant.
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(platform: TargetPlatform.iOS),
          child: RefreshIndicator.adaptive(
            key: _indicatorKey,
            onRefresh: _handleRefresh,
            color: _rs.color,
            backgroundColor: _rs.backgroundColor,
            displacement: _rs.displacement,
            edgeOffset: _rs.edgeOffset,
            strokeWidth: _rs.strokeWidth,
            notificationPredicate: widget.notificationPredicate,
            triggerMode: widget.triggerMode,
            semanticsLabel: widget.semanticsLabel ?? CommonStrings.refresh,
            // See the Material branch: a word in the progress node's
            // value slot throws.
            // The theme override is for the SPINNER, not the content:
            // handing the child a platform it is not on would change
            // how every scrollable and every switch under it behaves.
            child: Theme(data: theme, child: child),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.semanticsLabel ?? CommonStrings.refresh;
    var content = widget.child;
    if (widget.illustration != null) {
      content = _TopOverlay(
        offset: _rs.illustrationOffset,
        fade: _rs.illustrationFade,
        visible: _isRefreshing,
        child: widget.illustration!,
      );
      content = _IllustrationHost(overlay: content, child: widget.child);
    }
    if (widget.lastUpdatedBuilder != null) {
      content = _IllustrationHost(
        overlay: _TopOverlay(
          offset: 0,
          fade: _rs.illustrationFade,
          // The line is about the LAST refresh, so it has nothing to
          // say while the next one is running.
          visible: !_isRefreshing,
          child: widget.lastUpdatedBuilder!(context, _lastRefreshedAt),
        ),
        child: content,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: Semantics(
        // A live region only WHILE it runs — a permanent one announces
        // the whole subtree every time anything under it changes.
        liveRegion: _isRefreshing,
        label: label,
        value: _isRefreshing
            ? (widget.semanticsValue ?? CommonStrings.loading)
            : null,
        // A screen reader cannot PULL. Without this the one gesture the
        // control has is unreachable, and there is no other way to the
        // same result — the same argument the swipe actions make.
        customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
          CustomSemanticsAction(label: label): refresh,
        },
        child: _buildIndicator(content),
      ),
    );
  }
}

/// Holds an overlay over the scrollable without taking its pointers.
///
/// INSIDE the indicator rather than around it: wrapped outside, the
/// `Stack` swallowed the scroll notifications the indicator needs, and
/// the overlay slid up with the content instead of holding still.
class _IllustrationHost extends StatelessWidget {
  const _IllustrationHost({required this.overlay, required this.child});

  final Widget overlay;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(children: [child, overlay]);
}

/// One faded strip pinned below the top of the scrollable.
class _TopOverlay extends StatelessWidget {
  const _TopOverlay({
    required this.offset,
    required this.fade,
    required this.visible,
    required this.child,
  });

  final double offset;
  final Duration fade;
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: offset,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: fade,
          // DECORATION: the indicator already says what is happening,
          // and the reader does not need it twice.
          child: ExcludeSemantics(child: Center(child: child)),
        ),
      ),
    );
  }
}
