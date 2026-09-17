import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'edge_back_gesture.dart';
import 'theme/transition_theme.dart';
import 'transition_style.dart';

export 'theme/transition_theme.dart';
export 'transition_style.dart';

// ---------------------------------------------------------------------------
// TransitionOverride — caller-side transition control
// ---------------------------------------------------------------------------

/// Overrides the route's own transition for ONE navigation.
///
/// ```dart
/// context.push('/profile', extra: const TransitionOverride(
///   TransitionType.slideFromBottom,
/// ));
///
/// // Or beside other data:
/// context.push('/profile', extra: {
///   'transition': const TransitionOverride(TransitionType.fade),
///   'userId': '123',
/// });
/// ```
@immutable
class TransitionOverride {
  const TransitionOverride(this.type, {this.duration, this.curve});

  final TransitionType type;
  final Duration? duration;
  final Curve? curve;

  /// The bag form, so an override merges like every other layer instead
  /// of being unpicked field by field at the call site.
  TransitionStyle get style =>
      TransitionStyle(type: type, duration: duration, curve: curve);

  static TransitionOverride? fromExtra(Object? extra) {
    if (extra is TransitionOverride) return extra;
    if (extra is Map<String, dynamic>) {
      final t = extra['transition'];
      if (t is TransitionOverride) return t;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// RouteTransition
// ---------------------------------------------------------------------------

/// Builds the `Page` a `GoRoute` hands back.
///
/// ```dart
/// pageBuilder: (context, state) => RouteTransition.buildPage(
///   context: context,
///   state: state,
///   child: const MyPage(),
///   style: TransitionStyle.push,
/// ),
/// ```
class RouteTransition {
  RouteTransition._();

  /// The one entry point.
  ///
  /// Resolution runs `route style > TransitionOverride >
  /// GlobalTransitionTheme > TransitionStyle.defaults`, and the resolve
  /// folds in reduced motion and the reading direction — so nothing
  /// below this line needs a `BuildContext`.
  static Page<T> buildPage<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    String? title,
    TransitionStyle? style,
  }) {
    final override = TransitionOverride.fromExtra(state.extra);
    final resolved = (style ?? const TransitionStyle())
        .mergedWith(override?.style)
        .resolve(context);

    final pageTitle = title ?? state.name?.replaceAll('-', ' ') ?? '';

    // iOS gets its own page: the native swipe-back and parallax are
    // built into `CupertinoPage`, and wrapping them in ours would give
    // the route two back gestures.
    if (resolved.type == TransitionType.ios) {
      return CupertinoPage<T>(
        key: state.pageKey,
        name: pageTitle,
        child: child,
      );
    }

    return _SwipeablePage<T>(
      key: state.pageKey,
      name: pageTitle,
      swipeEnabled: resolved.swipeEnabled,
      transitionDuration: resolved.duration,
      // Resolved WITH the transition, so the gesture and the travel it
      // scrubs agree about which way is forward.
      textDirection: resolved.textDirection,
      child: Title(
        title: pageTitle,
        color: Theme.of(context).primaryColor,
        child: child,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          buildTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
            style: resolved,
          ),
    );
  }

  /// The imperative twin of [buildPage], for a `Navigator.push`.
  ///
  /// Its absence is why seven modules hand-rolled a `MaterialPageRoute`
  /// — a fullscreen PDF, the FAQ detail, the wizard, the pane's compact
  /// detail — and every one of those got Material's transition instead
  /// of the app's, with no theme, no reduced motion and a back gesture
  /// stuck on the left edge.
  ///
  /// Defaults to the platform's own push rather than to `none`: a
  /// `Navigator.push` with no transition reads as a bug, and
  /// `MaterialPageRoute` — what these all used — animates too.
  static PageRoute<T> route<T>({
    required BuildContext context,
    required Widget child,
    String? name,
    bool fullscreenDialog = false,
    TransitionStyle style = TransitionStyle.push,
  }) {
    final resolved = style.resolve(context);

    if (resolved.type == TransitionType.ios) {
      return CupertinoPageRoute<T>(
        builder: (_) => child,
        settings: RouteSettings(name: name),
        fullscreenDialog: fullscreenDialog,
      );
    }

    return _SwipeablePageRoute<T>(
      settings: RouteSettings(name: name),
      child: child,
      swipeEnabled: resolved.swipeEnabled,
      duration: resolved.duration,
      textDirection: resolved.textDirection,
      fullscreenDialog: fullscreenDialog,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          buildTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
            style: resolved,
          ),
    );
  }

  /// The type → widget mapping.
  ///
  /// PUBLIC, and deliberately takes an animation rather than a route:
  /// the showcase drives it from an `AnimationController` to preview a
  /// transition in a box, and a test drives it to check what each type
  /// actually builds. Both used to be impossible — comparing two
  /// transitions meant pushing, going back, and pushing again.
  static Widget buildTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    required ResolvedTransitionStyle style,
  }) {
    if (style.type == TransitionType.none || style.type == TransitionType.ios) {
      return child;
    }

    final curved = CurvedAnimation(parent: animation, curve: style.curve);
    final reverse = CurvedAnimation(
      parent: secondaryAnimation,
      curve: style.curve.flipped,
    );

    return switch (style.type) {
      TransitionType.morphScale => _morphScale(curved, reverse, child, style),
      TransitionType.morphSlide => _morphSlide(curved, child, style),
      TransitionType.morphFade => _morphFade(curved, child),
      TransitionType.morphRotate => _morphRotate(curved, child, style),
      TransitionType.slideFromRight => _slide(
        curved,
        const Offset(1, 0),
        child,
      ),
      TransitionType.slideFromLeft => _slide(
        curved,
        const Offset(-1, 0),
        child,
      ),
      TransitionType.slideFromTop => _slide(curved, const Offset(0, -1), child),
      TransitionType.slideFromBottom => _slide(
        curved,
        const Offset(0, 1),
        child,
      ),
      // The DIRECTIONAL pair: a leading edge is on the left in English
      // and on the right in Arabic.
      TransitionType.slideFromStart => _slide(
        curved,
        Offset(-style.slideFraction * style.directionSign, 0),
        child,
      ),
      TransitionType.slideFromEnd => _slide(
        curved,
        Offset(style.slideFraction * style.directionSign, 0),
        child,
      ),
      TransitionType.fade => FadeTransition(opacity: curved, child: child),
      TransitionType.scale => ScaleTransition(
        scale: Tween(begin: style.scaleBegin, end: 1.0).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      ),
      TransitionType.none || TransitionType.ios => child,
    };
  }

  // ─── Morph builders ───────────────────────────────────────

  /// Slide + scale + fade, with the OUTGOING page moving the other way.
  ///
  /// The outgoing half used to animate a `const SizedBox()` — four
  /// nested transitions wrapping an empty box, so the effect the name
  /// promises never happened. It animates the real child now, which is
  /// what `secondaryAnimation` is for: this route being covered.
  static Widget _morphScale(
    Animation<double> anim,
    Animation<double> secondary,
    Widget child,
    ResolvedTransitionStyle style,
  ) {
    final travel = TransitionDefaults.morphScaleSlide * style.directionSign;

    // Covered: slide back, shrink, fade out.
    final leaving = SlideTransition(
      position: Tween(
        begin: Offset.zero,
        end: Offset(-travel, 0),
      ).animate(secondary),
      child: ScaleTransition(
        scale: Tween(
          begin: 1.0,
          end: TransitionDefaults.morphScaleExit,
        ).animate(secondary),
        child: FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.0).animate(secondary),
          child: child,
        ),
      ),
    );

    // Arriving: in from the trailing edge, growing.
    return SlideTransition(
      position: Tween(begin: Offset(travel, 0), end: Offset.zero).animate(anim),
      child: ScaleTransition(
        scale: Tween(
          begin: TransitionDefaults.morphScaleBegin,
          end: 1.0,
        ).animate(anim),
        child: FadeTransition(opacity: anim, child: leaving),
      ),
    );
  }

  /// Staggered: slide first, fade through the middle, scale last.
  static Widget _morphSlide(
    Animation<double> anim,
    Widget child,
    ResolvedTransitionStyle style,
  ) {
    return SlideTransition(
      position:
          Tween(
            begin: Offset(style.slideFraction * style.directionSign, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: anim,
              curve: TransitionDefaults.morphSlideInterval,
            ),
          ),
      child: ScaleTransition(
        scale:
            Tween(
              begin: TransitionDefaults.morphSlideScaleBegin,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: anim,
                curve: TransitionDefaults.morphSlideScaleInterval,
              ),
            ),
        child: FadeTransition(
          opacity: Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: anim,
              curve: TransitionDefaults.morphSlideFadeInterval,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Fade with a hint of scale. No direction, so nothing to mirror.
  static Widget _morphFade(Animation<double> anim, Widget child) {
    return FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale:
            Tween(
              begin: TransitionDefaults.morphFadeScaleBegin,
              end: 1.0,
            ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOut),
            ),
        child: child,
      ),
    );
  }

  /// Slide + rotation + scale + fade.
  static Widget _morphRotate(
    Animation<double> anim,
    Widget child,
    ResolvedTransitionStyle style,
  ) {
    final travel = TransitionDefaults.morphRotateSlide * style.directionSign;

    return SlideTransition(
      position: Tween(begin: Offset(travel, 0), end: Offset.zero).animate(anim),
      child: RotationTransition(
        // The turn follows the travel: a page arriving from the left
        // rotates the other way, or it reads as being thrown backwards.
        turns:
            Tween(
              begin: TransitionDefaults.morphRotateTurns * style.directionSign,
              end: 0.0,
            ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOut),
            ),
        child: ScaleTransition(
          scale: Tween(
            begin: TransitionDefaults.morphRotateScaleBegin,
            end: 1.0,
          ).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
      ),
    );
  }

  static Widget _slide(
    Animation<double> anim,
    Offset direction,
    Widget child,
  ) => SlideTransition(
    position: Tween(begin: direction, end: Offset.zero).animate(anim),
    child: child,
  );
}

// ---------------------------------------------------------------------------
// Swipeable page infrastructure
// ---------------------------------------------------------------------------

class _SwipeablePage<T> extends Page<T> {
  const _SwipeablePage({
    required this.child,
    required this.swipeEnabled,
    required this.transitionDuration,
    required this.textDirection,
    required this.transitionsBuilder,
    super.key,
    super.name,
  });

  final Widget child;
  final bool swipeEnabled;
  final Duration transitionDuration;
  final TextDirection textDirection;
  final RouteTransitionsBuilder transitionsBuilder;

  @override
  Route<T> createRoute(BuildContext context) => _SwipeablePageRoute<T>(
    settings: this,
    child: child,
    swipeEnabled: swipeEnabled,
    duration: transitionDuration,
    textDirection: textDirection,
    transitionsBuilder: transitionsBuilder,
  );
}

class _SwipeablePageRoute<T> extends PageRoute<T> {
  _SwipeablePageRoute({
    required this.child,
    required this.swipeEnabled,
    required Duration duration,
    required this.textDirection,
    required this.transitionsBuilder,
    bool fullscreenDialog = false,
    super.settings,
  }) : _duration = duration,
       _fullscreenDialog = fullscreenDialog;

  final Widget child;
  final bool swipeEnabled;
  final TextDirection textDirection;
  final Duration _duration;
  final bool _fullscreenDialog;

  @override
  bool get fullscreenDialog => _fullscreenDialog;
  final RouteTransitionsBuilder transitionsBuilder;

  @override
  Duration get transitionDuration => _duration;

  @override
  Duration get reverseTransitionDuration => _duration;

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get popGestureEnabled => swipeEnabled && super.popGestureEnabled;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: child,
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // ANDROID'S OWN BACK, when the route is one you can go back from.
    //
    // The system gesture only shows the page BEHIND — the thing that
    // makes it "predictive" — if the route hands the animation over to
    // Flutter's predictive builder. Ours did not, so a back swipe on
    // Android popped the route and the previous page appeared already
    // arrived: it worked, and it told the reader nothing while it was
    // happening.
    //
    // It costs the app's own transition on Android, and that is the
    // trade: `slideFromEnd` is described here as "the platform's own
    // forward-navigation direction", and on Android the platform's own
    // is this. iOS keeps ours, because `CupertinoPage` has the
    // equivalent built in and is what the `ios` type already uses.
    //
    // `EdgeBackGesture` is left OFF underneath it for the same reason
    // `TransitionType.ios` skips it: two back gestures on one route is
    // one too many.
    if (swipeEnabled &&
        Theme.of(context).platform == TargetPlatform.android &&
        !kIsWeb) {
      return const PredictiveBackPageTransitionsBuilder().buildTransitions<T>(
        this,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }

    final result = transitionsBuilder(
      context,
      animation,
      secondaryAnimation,
      child,
    );

    if (!swipeEnabled) return result;

    // OURS, not a package's: every one of those measures from `dx = 0`
    // and commits on a rightward drag, so in Arabic the back gesture
    // lived on the wrong edge and pulled the wrong way — while the iOS
    // route beside it, on `CupertinoPage`, mirrored correctly.
    return EdgeBackGesture(
      route: this,
      textDirection: textDirection,
      child: result,
    );
  }
}
