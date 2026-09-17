import 'package:flutter/widgets.dart';

/// Forces every widget below the router to be built from scratch —
/// `State` objects disposed and recreated, `initState` run again.
///
/// ## Why a rebuild is not enough
///
/// The failure this exists for is the hot-reload late-init: a `late`
/// field is added to a `State` that is ALREADY mounted, so `initState`
/// never runs again and every subsequent build throws
/// `LateInitializationError`. The page is now permanently broken —
/// rebuilding calls `build` on the same broken `State`, so it throws
/// again, and the only escape is a full restart.
///
/// Remounting swaps the key on the subtree, which makes the framework
/// throw the old elements away entirely and inflate new ones. The
/// `State` is recreated, `initState` runs, the late field is
/// initialized, and the page works — without losing the running app.
///
/// The route stack survives because the router delegate lives ABOVE the
/// keyed subtree and is asked to rebuild from its current
/// configuration. In-page state (scroll offsets, form contents,
/// animations) does not — this is a restart of the page, and callers
/// should say so.
class AppRemount {
  AppRemount._();

  /// Bumped to trigger a remount. Watched by [AppRemountScope].
  static final ValueNotifier<int> generation = ValueNotifier<int>(0);

  /// Throw away and rebuild everything below the scope.
  static void remount() => generation.value++;
}

/// Wraps [child] in a key that [AppRemount.remount] changes.
///
/// Mount this INSIDE the app-wide chrome (debug overlay, toasts,
/// overlays) and directly around the router's child, so a remount
/// replaces the pages without taking the escape hatches with them.
class AppRemountScope extends StatelessWidget {
  const AppRemountScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppRemount.generation,
      builder: (_, generation, _) => KeyedSubtree(
        key: ValueKey<int>(generation),
        child: child,
      ),
    );
  }
}
