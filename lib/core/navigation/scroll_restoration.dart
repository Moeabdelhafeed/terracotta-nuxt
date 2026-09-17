import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Helpers for state restoration of scrollables — when the OS kills
/// and relaunches your app (Android backgrounded app recovery, iOS
/// memory pressure restore), these make sure scroll positions come
/// back where the user left them.
///
/// ## The Flutter model in one paragraph
/// Every scrollable (ListView / GridView / SingleChildScrollView / …)
/// accepts a `restorationId`. When present + the enclosing
/// [RestorationScope] has an id + the root `MaterialApp` has a
/// `restorationScopeId`, the scroll position is persisted with the
/// OS and restored on relaunch. Our root already has
/// `restorationScopeId: 'app_router'` (see [go_router_config]), so
/// most of the plumbing is done — you just need per-scrollable ids.
///
/// ## What this file adds
///  - [restorationIdFor] — generates a stable, route-scoped id so you
///    don't collide when the same ListView renders on two routes.
///  - [RestorableListView] / [RestorableGridView] / [RestorableSingleChildScrollView]
///    — drop-in wrappers that auto-wire the id from the current route.
///  - [RestorableScrollScope] — wrap a subtree with its own named
///    restoration bucket, useful for nested scrollables on the same
///    page (e.g. tabs, side-by-side panels).

/// Stable, route-scoped id for a scrollable. Combines the current
/// GoRouter path with [key] so the same `key='feed'` on `/home` and
/// `/profile` ends up with distinct ids — no cross-route collisions.
///
/// Call from `build()`:
/// ```dart
/// ListView(
///   restorationId: restorationIdFor(context, 'feed'),
///   children: ...,
/// );
/// ```
String restorationIdFor(BuildContext context, String key) {
  // GoRouter is optional — graceful fallback for uses outside a
  // GoRouter subtree (e.g. dialog content).
  String? path;
  try {
    path = GoRouterState.of(context).uri.path;
  } catch (_) {
    path = null;
  }
  final prefix = path ?? 'root';
  return '${prefix.replaceAll('/', '_')}__$key';
}

/// Wrap a subtree with a named [RestorationScope]. Use for pages that
/// have multiple restorable scrollables — each nested
/// `restorationId` becomes unique within this scope.
class RestorableScrollScope extends StatelessWidget {
  const RestorableScrollScope({
    super.key,
    required this.id,
    required this.child,
  });

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      RestorationScope(restorationId: id, child: child);
}

/// Drop-in replacement for [ListView] that auto-derives its
/// `restorationId` from the current route + [id]. The rest of the
/// parameters pass through unchanged.
class RestorableListView extends StatelessWidget {
  const RestorableListView({
    super.key,
    required this.id,
    this.children = const [],
    this.padding,
    this.physics,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.shrinkWrap = false,
    this.primary,
    this.keyboardDismissBehavior,
    this.itemExtent,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
  });

  final String id;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final Axis scrollDirection;
  final bool reverse;
  final bool shrinkWrap;
  final bool? primary;
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
  final double? itemExtent;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;

  @override
  Widget build(BuildContext context) {
    return ListView(
      restorationId: restorationIdFor(context, id),
      padding: padding,
      physics: physics,
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      shrinkWrap: shrinkWrap,
      primary: primary,
      keyboardDismissBehavior:
          keyboardDismissBehavior ?? ScrollViewKeyboardDismissBehavior.manual,
      itemExtent: itemExtent,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      children: children,
    );
  }
}

/// [ListView.builder] variant that auto-wires `restorationId`.
class RestorableListViewBuilder extends StatelessWidget {
  const RestorableListViewBuilder({
    super.key,
    required this.id,
    required this.itemBuilder,
    required this.itemCount,
    this.padding,
    this.physics,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.shrinkWrap = false,
    this.primary,
    this.itemExtent,
    this.separatorBuilder,
  });

  final String id;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final Axis scrollDirection;
  final bool reverse;
  final bool shrinkWrap;
  final bool? primary;
  final double? itemExtent;
  final IndexedWidgetBuilder? separatorBuilder;

  @override
  Widget build(BuildContext context) {
    final restorationId = restorationIdFor(context, id);
    if (separatorBuilder != null) {
      return ListView.separated(
        restorationId: restorationId,
        padding: padding,
        physics: physics,
        controller: controller,
        scrollDirection: scrollDirection,
        reverse: reverse,
        shrinkWrap: shrinkWrap,
        primary: primary,
        itemBuilder: itemBuilder,
        separatorBuilder: separatorBuilder!,
        itemCount: itemCount,
      );
    }
    return ListView.builder(
      restorationId: restorationId,
      padding: padding,
      physics: physics,
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      shrinkWrap: shrinkWrap,
      primary: primary,
      itemExtent: itemExtent,
      itemBuilder: itemBuilder,
      itemCount: itemCount,
    );
  }
}

/// [GridView.builder] variant that auto-wires `restorationId`.
class RestorableGridView extends StatelessWidget {
  const RestorableGridView({
    super.key,
    required this.id,
    required this.gridDelegate,
    required this.itemBuilder,
    required this.itemCount,
    this.padding,
    this.physics,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.shrinkWrap = false,
    this.primary,
  });

  final String id;
  final SliverGridDelegate gridDelegate;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final Axis scrollDirection;
  final bool reverse;
  final bool shrinkWrap;
  final bool? primary;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      restorationId: restorationIdFor(context, id),
      gridDelegate: gridDelegate,
      itemBuilder: itemBuilder,
      itemCount: itemCount,
      padding: padding,
      physics: physics,
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      shrinkWrap: shrinkWrap,
      primary: primary,
    );
  }
}

/// Auto-restoring [SingleChildScrollView].
class RestorableSingleChildScrollView extends StatelessWidget {
  const RestorableSingleChildScrollView({
    super.key,
    required this.id,
    required this.child,
    this.padding,
    this.physics,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.primary,
  });

  final String id;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final Axis scrollDirection;
  final bool reverse;
  final bool? primary;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      restorationId: restorationIdFor(context, id),
      padding: padding,
      physics: physics,
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      child: child,
    );
  }
}

/// Mixin for a [State] that needs a restorable [ScrollController] —
/// the scroll offset survives app kill / restart (via
/// [RestorableDouble]) without you threading the id around manually.
///
/// ```dart
/// class _MyPageState extends State<MyPage>
///     with RestorableScrollControllerMixin, RestorationMixin {
///   @override
///   String get restorationId => 'my_page';
///
///   @override
///   Widget build(BuildContext context) {
///     return ListView(controller: scrollController, ...);
///   }
/// }
/// ```
mixin RestorableScrollControllerMixin<T extends StatefulWidget>
    on State<T>, RestorationMixin<T> {
  final _offset = RestorableDouble(0);
  late final ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.hasClients) _offset.value = scrollController.offset;
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_offset, 'scroll_offset');
    if (_offset.value != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) scrollController.jumpTo(_offset.value);
      });
    }
  }
}
