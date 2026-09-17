import 'package:flutter/widgets.dart';

/// Overrides the corner of every [GlobalContainer] beneath it.
///
/// A list that wants its rows to read as ONE card cannot do it by
/// clipping: a `ClipRRect` with square corners clips nothing, because
/// the tile's own rounded background is already inside the rectangle.
/// The corner has to reach the container that paints it.
///
/// Set by `GlobalList` when `unifyTiles` is on — the first row keeps
/// its top corners, the last its bottom ones, everything between is
/// square.
@immutable
class ContainerCornerScope extends InheritedWidget {
  const ContainerCornerScope({
    super.key,
    required this.borderRadius,
    required super.child,
  });

  final BorderRadius borderRadius;

  /// The nearest override, or null when nothing set one.
  ///
  /// A container whose own `style.borderRadius` is answered ignores
  /// this — a caller being explicit outranks the run it happens to
  /// sit in.
  static BorderRadius? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ContainerCornerScope>()
      ?.borderRadius;

  @override
  bool updateShouldNotify(ContainerCornerScope old) =>
      borderRadius != old.borderRadius;
}
