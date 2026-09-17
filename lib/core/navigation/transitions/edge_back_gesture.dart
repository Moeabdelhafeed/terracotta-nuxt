import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'transition_style.dart';

/// A drag from the LEADING edge that pops the route.
///
/// Ours, because every package that does this measures from `dx = 0`
/// and commits on a rightward drag — hard-coded left-to-right. In
/// Arabic the leading edge is on the RIGHT, and `CupertinoPage` gets
/// that right natively, so on an iOS route the gesture mirrored and on
/// every other route it did not: the same app, two different back
/// gestures, one of them unreachable.
///
/// Everything here is measured FROM THE LEADING EDGE and multiplied by
/// [ResolvedTransitionStyle.directionSign] on the way out, so there is
/// one implementation rather than two.
class EdgeBackGesture extends StatefulWidget {
  const EdgeBackGesture({
    required this.route,
    required this.textDirection,
    required this.child,
    super.key,
  });

  final PageRoute<dynamic> route;

  /// Resolved once, with the rest of the transition — the same value
  /// the builders mirrored their travel by.
  final TextDirection textDirection;

  final Widget child;

  @override
  State<EdgeBackGesture> createState() => _EdgeBackGestureState();
}

class _EdgeBackGestureState extends State<EdgeBackGesture> {
  late final HorizontalDragGestureRecognizer _recognizer =
      HorizontalDragGestureRecognizer(debugOwner: this)
        ..onStart = _onStart
        ..onUpdate = _onUpdate
        ..onEnd = _onEnd
        ..onCancel = _onCancel;

  /// Whether the drag has been ACCEPTED — a touch inside the strip is
  /// not yet a back gesture, and a vertical scroll starting there must
  /// still scroll.
  bool _dragging = false;

  double _startX = 0;

  /// `1` when the leading edge is on the left, `-1` when it is on the
  /// right.
  double get _sign => widget.textDirection == TextDirection.rtl ? -1 : 1;

  double get _width => MediaQuery.sizeOf(context).width;

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.route.popGestureEnabled || _dragging) return;

    // How far in from the LEADING edge the finger landed.
    final fromLeadingEdge = _sign > 0
        ? event.localPosition.dx
        : _width - event.localPosition.dx;

    if (fromLeadingEdge <= _width * TransitionDefaults.swipeDetectionArea) {
      _recognizer.addPointer(event);
    }
  }

  void _onStart(DragStartDetails details) {
    _startX = details.localPosition.dx;
  }

  void _onUpdate(DragUpdateDetails details) {
    final navigator = widget.route.navigator;
    final controller = widget.route.controller;
    if (navigator == null || controller == null) return;

    if (!_dragging) {
      // Only a drag AWAY from the leading edge is a back gesture — into
      // it is someone pushing against the wall.
      if ((details.primaryDelta ?? 0) * _sign <= 0) return;
      _dragging = true;
      navigator.didStartUserGesture();
    }

    final travelled = (details.localPosition.dx - _startX) * _sign;
    final progress =
        (travelled / (_width * TransitionDefaults.swipeTransitionRange)).clamp(
          0.0,
          1.0,
        );
    // The route's own animation runs 1 → 0 as the page leaves, so the
    // page tracks the finger through whichever transition built it.
    controller.value = 1 - progress;
  }

  void _onEnd(DragEndDetails details) {
    _finish(details.velocity.pixelsPerSecond.dx * _sign);
  }

  void _onCancel() => _finish(0);

  void _finish(double velocity) {
    _dragging = false;

    final navigator = widget.route.navigator;
    final controller = widget.route.controller;
    if (navigator == null || controller == null) return;

    // A flick decides on its own; a slow drag decides on distance.
    final commit = velocity.abs() >= TransitionDefaults.swipeVelocity
        ? velocity > 0
        : (1 - controller.value) >= TransitionDefaults.swipeCommitProgress;

    final duration = widget.route.reverseTransitionDuration;

    if (commit) {
      // Only if it is still the top of the stack: a route popped from
      // under the finger by something else must not pop twice.
      if (widget.route.isCurrent) navigator.pop();
      controller.animateBack(
        0,
        duration: duration,
        curve: TransitionDefaults.swipeCommitCurve,
      );
    } else {
      controller.animateTo(
        1,
        duration: duration,
        curve: TransitionDefaults.swipeCancelCurve,
      );
    }

    // The navigator has to be told the gesture ended, or it keeps
    // treating the route as user-driven and later pops fight it.
    if (controller.isAnimating) {
      void onDone(AnimationStatus status) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(onDone);
      }

      controller.addStatusListener(onDone);
    } else if (navigator.userGestureInProgress) {
      navigator.didStopUserGesture();
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _handlePointerDown,
    // Translucent, so the page underneath still gets every touch that
    // does not become a back gesture.
    behavior: HitTestBehavior.translucent,
    child: widget.child,
  );
}
