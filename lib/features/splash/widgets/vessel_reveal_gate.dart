import 'package:flutter/material.dart';

import 'vessel_reveal.dart';

/// Where the launch's second half is asked for, and where it is drawn.
///
/// ## Why the animation cannot live on the splash route
///
/// The web splash is an overlay on a page that is ALREADY rendered:
/// `Teleport to="body"`, `fixed inset-0 z-[100]`. Its hole reveals the
/// site by being transparent, because the site is genuinely behind it.
///
/// A Flutter splash is a ROUTE, and the destination does not exist
/// while it is on screen. A hole cut in it reveals the route beneath —
/// which is nothing — so the mark filled in and sat there. Painting a
/// stand-in colour under the hole only moved the problem: the reveal
/// then opened onto a flat rectangle rather than onto the app.
///
/// So the launch is split. The splash route draws the mark
/// ([VesselRevealMode.draw]); then the app navigates to its real
/// destination and THIS overlay — mounted above the whole `Navigator`
/// in `MyApp`, which is the `z-[100]` — opens the hole over it.
///
/// The handover is invisible because both halves paint the same
/// picture at the moment it happens: the same ground, the same mark,
/// the same size, in the same place.
class VesselRevealGate extends ChangeNotifier {
  VesselRevealGate._();

  /// One launch, one gate. A singleton rather than an injected
  /// dependency for the same reason `SplashWarmer` is one: the splash
  /// asks for this from a route, and the overlay that answers is
  /// mounted above every route.
  static final VesselRevealGate instance = VesselRevealGate._();

  bool _opening = false;

  /// Whether the overlay should be on screen.
  bool get opening => _opening;

  /// Cover the app and open the hole.
  ///
  /// Called by the splash as it navigates — BEFORE the navigation, so
  /// the overlay is already covering the screen when the destination
  /// paints its first frame. Otherwise that frame flashes.
  void open() {
    if (_opening) return;
    _opening = true;
    notifyListeners();
  }

  /// The reveal is over and the overlay comes off.
  void close() {
    if (!_opening) return;
    _opening = false;
    notifyListeners();
  }

  /// Back to a state where [open] will play again. For tests, and for
  /// nothing else — an app launches once.
  @visibleForTesting
  void reset() => close();
}

/// The launch's second half, above everything.
///
/// Wraps the app in `MyApp` so the hole it opens is transparent all
/// the way down to the destination screen. Draws nothing at all until
/// the splash asks, which is once per launch.
class VesselRevealOverlay extends StatelessWidget {
  const VesselRevealOverlay({
    required this.child,
    this.gate,
    this.ground = const Color(0xFF81341A),
    this.markHeight = 147.76,
    super.key,
  });

  final Widget child;

  /// The app's, unless a test supplies its own.
  final VesselRevealGate? gate;

  /// Must match the splash route's ground, or the handover blinks.
  final Color ground;

  /// And its mark size, for the same reason.
  final double markHeight;

  @override
  Widget build(BuildContext context) {
    final gate = this.gate ?? VesselRevealGate.instance;

    return ListenableBuilder(
      listenable: gate,
      builder: (context, _) => Stack(
        children: [
          child,
          if (gate.opening)
            // IgnorePointer: the ground is on screen for under two
            // seconds and the app beneath it is live. A tap that lands
            // on the app is better than one swallowed by a decoration.
            Positioned.fill(
              child: IgnorePointer(
                child: VesselReveal(
                  mode: VesselRevealMode.open,
                  ground: ground,
                  markHeight: markHeight,
                  onDone: gate.close,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
